public class GazelAPI {

    /**
     * Demande de cotation à l'API Gazel
     * Endpoint : /v1/demande-cotation
     */
    public static GazelDTO.Response sendQuote(GazelDTO.DemandeCotation payload, Boolean isGaz, GazelActionSendQuote.Input input) {
        HttpRequest req = new HttpRequest();
        String path = isGaz ? '/v1/demande-cotation/gaz' : '/v1/demande-cotation';

        req.setEndpoint('callout:Gazel_API_NC' + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + GazelAuthService.getAccessToken());
        req.setTimeout(120000);
        
        // Body
        req.setBody(JSON.serialize(payload, true));

        Http http = new Http();
        HttpResponse res = http.send(req);

        // PUBLICATION DU LOG VIA PLATFORM EVENT
        ApiLogger.publish('GazelApi.sendQuote', 'GAZEL', req.getEndpoint(), req.getBody(), res.getBody(), res.getStatusCode(), req.getMethod(), input.quoteId);
        
        return parseResponse(res, input);
    }

    /**
     * Récupère le PDF du contrat
     * Endpoint : /v1/contrats/{id} (Elec) ou /v1/contrats/{id}/gaz (Gaz)
     */
    public static String getContractPdf(Id quoteId) {

        Quote quote = [SELECT Id, Name, API_Offre_ID__c, TECH_OppRecordTypeName__c, Owner.Email FROM Quote WHERE Id = :quoteId LIMIT 1];

        HttpRequest req = new HttpRequest();
        
        String path = '/v1/contrats/' + quote.API_Offre_ID__c;
        if (quote.TECH_OppRecordTypeName__c != null && quote.TECH_OppRecordTypeName__c.containsIgnoreCase('gaz')) path += '/gaz';
        
        // Paramètre isEsign=false pour récupérer le PDF binaire directement
        path += '?isEsign=false'; 
        req.setEndpoint('callout:Gazel_API_NC' + path);
        req.setMethod('GET');
        
        // Auth Headers
        req.setHeader('Authorization', 'Bearer ' + GazelAuthService.getAccessToken());
        req.setTimeout(120000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        ApiLogger.publish('GazelApi.getContractPdf', 'GAZEL', req.getEndpoint(), req.getBody(), res.getBody(), res.getStatusCode(), req.getMethod(), quoteId);

        if (res.getStatusCode() == 200) {
            // Le contenu est un fichier PDF binaire
            Blob pdfBlob = res.getBodyAsBlob();
            return sendMailWithDocuments(pdfBlob, quote);
        } else {
            throw new CalloutException('Erreur récupération Contrat: ' + res.getStatusCode() + ' ' + res.getBody());
        }
    }

    private static GazelDTO.Response parseResponse(HttpResponse res, GazelActionSendQuote.Input input) {
        GazelDTO.Response result = new GazelDTO.Response();
        
        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            Map<String, Object> offreObj = (Map<String, Object>) jsonMap.get('offre');
            
            result.isSuccess = true;
            result.message = 'Cotation transmise avec succès.';
            if (offreObj != null) result.cotationId = (String) offreObj.get('id');

            if (result.isSuccess && result.cotationId != null && input.quoteId != null) {

                Quote qte = new Quote(
                    Id = input.quoteId,
                    API_Offre_ID__c = result.cotationId,
                    API_Date_demande__c = Datetime.now(),
                    Date_Validite_Offre__c = null,
                    API_Marge_Choisie__c = input.marge,
                    API_status__c = 'Demande de prix reçue chez le fournisseur',
                    API_Complement_Prix_Spot__c = input.isComplementPrixSpot,
                    API_Derogation_Penalites_Retard__c = input.isClauseDerogationPenalitesRetardPaiement,
                    API_Formule_Prix__c = input.formulePrix == 1 ? 'Marché' : 'CDC Marché',
                    API_Type_Client__c = input.clientType,
                    API_Immatriculation_SDC__c = input.immatriculation,
                    API_Contournement_Liasse_Fiscale__c = input.demandeContournementLiasse,
                    API_cP_Manuel__c = input.cPmanuel,
                    API_pE_Manuel__c = input.pEmanuel,
                    API_rE_Manuel__c = input.rEmanuel,
                    API_Taux_Garantie_Origine__c = input.tauxGarantieOrigine,
                    API_Prix_Horosaisonnier__c = input.prixHorosaisonnier == 1
                );
            
                update qte;
            }
            
        } else {
            result.isSuccess = false;
            result.message = 'Erreur Gazel (' + res.getStatusCode() + ')';
            result.technicalErrorDetail = res.getBody() != null ? res.getBody() : 'Pas de détail technique fourni';
        }
        return result;
    }

    private static String sendMailWithDocuments(Blob pdfBlob, Quote quote) {

        // Get Infos
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'tech@alliancedesenergies.fr'];

        // Generate PDFs from base64 string
        Messaging.EmailFileAttachment pdfContrat = new Messaging.EmailFileAttachment();
        pdfContrat.setFileName('Contrat_' + quote.Name + '.pdf');
        pdfContrat.setBody(pdfBlob);
        pdfContrat.setContentType('application/pdf');

        // Create subject and email body text
        String subject = 'Contrat Gazel. Devis ' + quote.Name;
        String emailBody = 'Bonjour,\n\n';
        emailBody += 'Vous venez de télécharger le contrat de l\'offre Gazel numéro ' + quote.API_Offre_ID__c + '.\n';
        emailBody += 'Ce contrat est associé au devis Salesforce : ' + quote.Name + '.\n';
        emailBody += 'Veuillez trouver ci-joint le contrat à faire signer à votre client.\n\n';
        emailBody += 'Bien à vous.\n\n';

        // Create email and send it
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{quote.Owner.Email});
        email.setSubject(subject);
        email.setPlainTextBody(emailBody);
        email.setUseSignature(false);
        email.setCharset('utf-8');
        if ( owea.size() > 0 && !Test.isRunningTest() ) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{pdfContrat});

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

        if (results[0].success) {
            return 'Contrat envoyé par mail avec succes !';
        } else {
            return 'Impossible de vous envoyer le mail contenant le contrat à faire signer.\n Merci de vous connectez à la plateforme Gazel pour le récupérer. Numéro offre : ' + quote.API_Offre_ID__c;
        }
    }
}