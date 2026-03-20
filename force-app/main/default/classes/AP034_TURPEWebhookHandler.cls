public without sharing class AP034_TURPEWebhookHandler {

    public void handle(RestRequest req) {
        String body,event,status,idAnalyse;
        Map<String, Object> data,outputs,error;
        AP034_TURPEOptimisationService.TurpeDataExtractor callbackJson;
        Boolean appelSucces = true;

        try {
            if (req.requestBody == null || req.requestBody.toString().trim() == '') {
                throw new CalloutException('Corps de requête vide');
            }

            body = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(body);
            // Cas d'un appel vide (pas de data')
            if (payload == null) {
                System.debug('Payload vide');
                return;
            }

            data = (Map<String, Object>)payload.get('data');
            event = (String)payload.get('event');
            System.debug('event : ' + event);
            if(event == null || event != 'optimturpe_finished') {
                System.debug('Evenement non pris en charge : ' + event);
                return;
            }
            //Cas Otpimturpe_finished

            idAnalyse = (String) data.get('_id');
            if (idAnalyse == null) {
                System.debug('IdAnalyse null impossible d\'identifier le PDE ou la QLI ');
                return;
            }

            // Recherche PDE & QLI liés
            List<PDE__c> lstPDE = [
                SELECT Id, Email__c
                FROM PDE__c
                WHERE IdAnalyse__c = :idAnalyse
                LIMIT 1
            ];

            List<QuoteLineItem> lstQLI = [
                SELECT Id
                FROM QuoteLineItem
                WHERE IdAnalyse__c = :idAnalyse
                LIMIT 1
            ];

            callbackJson = AP034_TURPEOptimisationService.extractTurpeData(body);

            // Envoi d'email UNIQUEMENT pour le PDE (pas de QLI)
            if (!lstPDE.isEmpty()) {
                System.debug('MAJ du PDE et Envoie du MAIL');
                Id pdeId = lstPDE[0].Id;
                updateRecordWithTurpeData(new PDE__c(Id = pdeId), callbackJson);
                // Envoi d'email si Email__c présent puis purge
                sendAndFlushEmailIfAny(pdeId);
            }

            // QLI: mise à jour + envoi email devis complet si TOUTES les QLI de la quote sont à jour
            if (!lstQLI.isEmpty()) {
                Id qliId = lstQLI[0].Id;
                updateRecordWithTurpeData(
                    new QuoteLineItem(Id = qliId),
                    callbackJson
                );
                    handleQuoteCompletionEmail(qliId);
            }
        } catch (Exception e) {
            System.debug('Exception : ' + e.getMessage());
            System.debug('Exception : ' + e.getStackTraceString());
            throw e;
        }
    }

    public static void updateRecordWithTurpeData(
        SObject record,
        AP034_TURPEOptimisationService.TurpeDataExtractor valueToUpdate
    ) {
        Date today = Date.today();
        record.put('DateAppel__c', today);
        record.put('AppelEnCours__c', false);
        if (valueToUpdate.idAnalyse != null)
            record.put('IdAnalyse__c', valueToUpdate.idAnalyse);
        if (valueToUpdate.idBuilding != null)
            record.put('IdBuilding__c', valueToUpdate.idBuilding);
        if (valueToUpdate.dateFrom != null)
            record.put('DateAnalyseFrom__c', valueToUpdate.dateFrom);
        if (valueToUpdate.dateTo != null)
            record.put('DateAnalyseTo__c', valueToUpdate.dateTo);


            record.put('Message_retour_optimisation_TURPE__c', valueToUpdate.errorMessage);
            record.put('HCEActuel__c', valueToUpdate.HCEActuel);
            record.put('HCEOptimal__c', valueToUpdate.HCEOptimal);
            record.put('HCHActuel__c', valueToUpdate.HCHActuel);
            record.put('HCHOptimal__c', valueToUpdate.HCHOptimal);
            record.put('HPEActuel__c', valueToUpdate.HPEActuel);
            record.put('HPEOptimal__c', valueToUpdate.HPEOptimal);
            record.put('HPHActuel__c', valueToUpdate.HPHActuel);
            record.put('HPHOptimal__c', valueToUpdate.HPHOptimal);
            record.put('POINTEActuel__c', valueToUpdate.POINTEActuel);
            record.put('POINTEOptimal__c', valueToUpdate.POINTEOptimal);

            record.put('PartFixeCSActuel__c', valueToUpdate.PartFixeCSActuel);
            record.put('PartVariableCSActuel__c', valueToUpdate.PartVariableCSActuel);
            record.put('DepassementActuel__c', valueToUpdate.actuelleTurpeCMDPS);
            record.put('TaxeCTAActuel__c', valueToUpdate.TaxeCTAActuel);

            record.put('PartFixeCSOptimal__c', valueToUpdate.PartFixeCSOptimal);
            record.put('PartVariableCSOptimal__c', valueToUpdate.PartVariableCSOptimal);
            record.put('DepassementOptimal__c', valueToUpdate.meilleureTurpeCMDPS);
            record.put('TaxeCTAOptimal__c', valueToUpdate.TaxeCTAOptimal);

            Decimal budgetActuel =
                (valueToUpdate.TaxeCTAActuel != null ? valueToUpdate.TaxeCTAActuel : 0) +
                (valueToUpdate.PartFixeCSActuel != null ? valueToUpdate.PartFixeCSActuel : 0) +
                (valueToUpdate.PartVariableCSActuel != null ? valueToUpdate.PartVariableCSActuel : 0) +
                (valueToUpdate.actuelleTurpeCMDPS != null ? valueToUpdate.actuelleTurpeCMDPS : 0);

            Decimal budgetOptimal =
                (valueToUpdate.TaxeCTAOptimal != null ? valueToUpdate.TaxeCTAOptimal : 0) +
                (valueToUpdate.PartFixeCSOptimal != null ? valueToUpdate.PartFixeCSOptimal : 0) +
                (valueToUpdate.PartVariableCSOptimal != null ? valueToUpdate.PartVariableCSOptimal : 0) +
                (valueToUpdate.meilleureTurpeCMDPS != null ? valueToUpdate.meilleureTurpeCMDPS : 0);

            record.put('BudgetTotalActuel__c', budgetActuel);
            record.put('BudgetTotalOptimal__c', budgetOptimal);
            record.put('EconomieIdentifie__c', budgetActuel - budgetOptimal);
        update record;
    }

/**
 * Envoie un email (PDE uniquement) si Email__c est renseigné puis le vide.
 * - Email HTML structuré
 * - Lien Lightning vers l'enregistrement PDE
 */
private static void sendAndFlushEmailIfAny(Id pdeId) {

    if (pdeId == null) return;

    try {

        PDE__c pde = [
            SELECT Id,
                   Name,
                   Email__c,
                   BudgetTotalActuel__c,
                   BudgetTotalOptimal__c,
                   EconomieIdentifie__c,
                   DateAnalyseFrom__c,
                   DateAnalyseTo__c,
                   Message_retour_optimisation_TURPE__c
            FROM PDE__c
            WHERE Id = :pdeId
            LIMIT 1
        ];

        if (String.isBlank(pde.Email__c)) return;

        // Org Wide Email sécurisée
        OrgWideEmailAddress owea = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = 'tech@alliancedesenergies.fr'
            LIMIT 1
        ];

        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        String recordUrl = baseUrl + '/lightning/r/PDE__c/' + pde.Id + '/view';

        // Formatage des valeurs
        String budgetActuel  = formatCurrency(pde.BudgetTotalActuel__c);
        String budgetOptimal = formatCurrency(pde.BudgetTotalOptimal__c);
        Decimal ecoValue = pde.EconomieIdentifie__c;
        String economie  = formatCurrency(ecoValue);

        // Couleur dynamique
        String ecoColor = ecoValue > 0 ? '#27ae60' : '#c0392b';
        String dateFrom      = formatDate(pde.DateAnalyseFrom__c);
        String dateTo        = formatDate(pde.DateAnalyseTo__c);

        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new String[] { pde.Email__c });
        msg.setOrgWideEmailAddressId(owea.Id);

        String subject;
        String htmlBody;
        String textBody;

        // ==========================
        // CAS ERREUR
        // ==========================
        if (pde.Message_retour_optimisation_TURPE__c != null) {
            System.debug('Envoie email KO');
            subject = '❌ Optimisation TURPE non aboutie - ' + pde.Name;

            htmlBody =
                '<div style="font-family:Arial, sans-serif; font-size:14px;">' +
                '<h2 style="color:#c0392b;">Optimisation TURPE non aboutie</h2>' +
                '<p>Bonjour,</p>' +
                '<p>Votre optimisation TURPE n’a pas pu être finalisée.</p>' +
                '<p><strong>Période analysée :</strong> ' + dateFrom + ' → ' + dateTo + '</p>' +
                '<p><strong>Motif : </strong>'+pde.Message_retour_optimisation_TURPE__c+'</p>' +
                '<br/>' +
                '<a href="' + recordUrl + '" style="background:#2c3e50;color:white;padding:10px 15px;text-decoration:none;border-radius:4px;">'
                + 'Consulter le dossier'
                +'</a>' +
                '<br/><br/><br/><br/><br/>' +
                '<p>Cordialement,<br/><strong>Alliance des Énergies</strong></p>' +
                '</div>';

            textBody =
                'Optimisation TURPE non aboutie\n\n' +
                'Période : ' + dateFrom + ' → ' + dateTo + '\n' +
                'Motif : ' + pde.Message_retour_optimisation_TURPE__c + '\n\n' +
                'Dossier : ' + recordUrl;

        }
        // ==========================
        // CAS SUCCÈS
        // ==========================
        else {
            System.debug('Envoie email OK');

            subject = '✅ Optimisation TURPE terminée - ' + pde.Name;

            htmlBody =
                '<div style="font-family:Arial, sans-serif; font-size:14px;">' +
                '<h2 style="color:#27ae60;">Optimisation TURPE terminée</h2>' +
                '<p>Bonjour,</p>' +
                '<p>Votre optimisation TURPE a été réalisée avec succès.</p>' +
                '<table style="border-collapse:collapse;margin-top:15px;">' +
                '<tr><td style="padding:8px;border:1px solid #ddd;"><strong>Budget actuel</strong></td>' +
                '<td style="padding:8px;border:1px solid #ddd;">' + budgetActuel + '</td></tr>' +
                '<tr><td style="padding:8px;border:1px solid #ddd;"><strong>Budget optimal</strong></td>' +
                '<td style="padding:8px;border:1px solid #ddd;">' + budgetOptimal + '</td></tr>' +
                '<tr style="background:#ecf9f1;"> <td style="padding:8px;border:1px solid #ddd;"><strong>Économie identifiée</strong></td>' +
                '<td style="padding:8px;border:1px solid #ddd;color:' + ecoColor + ';"><strong>' + economie + '</strong></td> </tr>' +
                '<tr><td style="padding:8px;border:1px solid #ddd;"><strong>Période</strong></td>' +
                '<td style="padding:8px;border:1px solid #ddd;">' + dateFrom + ' → ' + dateTo + '</td></tr>' +
                '</table>' +
                '<br/><br/>' +
                '<a href="' + recordUrl + '" style="background:#2c3e50;color:white;padding:10px 15px;text-decoration:none;border-radius:4px;">'
                + 'Consulter le dossier'
                + '</a>' +
                '<br/><br/><br/><br/><br/>' +
                '<p>Cordialement,<br/><strong>Alliance des Énergies</strong></p>' +
                '</div>';

            textBody =
                'Optimisation TURPE terminée\n\n' +
                'Budget actuel : ' + budgetActuel + '\n' +
                'Budget optimal : ' + budgetOptimal + '\n' +
                'Économie : ' + economie + '\n' +
                'Période : ' + dateFrom + ' → ' + dateTo + '\n\n' +
                'Dossier : ' + recordUrl;
        }

        msg.setSubject(subject);
        msg.setHtmlBody(htmlBody);
        msg.setPlainTextBody(textBody);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg }, false);

        // Flush Email__c
        update new PDE__c(Id = pde.Id, Email__c = null);

    } catch (Exception ex) {
        System.debug('Exception : ' + ex.getMessage());
        System.debug('Exception : ' + ex.getStackTraceString());
        throw ex;
    }
}


/* ==========================
   MÉTHODES UTILITAIRES
   ========================== */

private static String formatCurrency(Decimal value) {
    if (value == null) return 'N/A';
    return value.setScale(2) + ' €';
}

private static String formatDate(Date d) {
    if (d == null) return 'N/A';
    return d.format();
}


    /**
     * Si toutes les QLI de la Quote sont à jour (AppelEnCours__c = false), envoie un email
     * à l'adresse Quote.Email avec lien vers l'Opportunity associée, puis vide Quote.Email.
     * Sujet: "Optimisation TURPE terminée – Devis complet"
     */
    private static void handleQuoteCompletionEmail(Id qliId) {
        if (qliId == null) return;
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'tech@alliancedesenergies.fr'];


        // Charger la QLI et sa quote
        QuoteLineItem qli = [
            SELECT Id, QuoteId
            FROM QuoteLineItem
            WHERE Id = :qliId
            LIMIT 1
        ];
        if (qli.QuoteId == null) return;

        // Vérifier s'il reste des QLI en cours pour cette quote
        Integer remaining = [
            SELECT COUNT()
            FROM QuoteLineItem
            WHERE QuoteId = :qli.QuoteId
              AND (AppelEnCours__c = true OR AppelEnCours__c = null)
        ];
        if (remaining != 0) {
            // Encore des appels en cours, ne rien faire
            return;
        }

        // Récupérer les infos de la Quote et de l'Opportunity associée
        Quote q = [
            SELECT Id, Email, OpportunityId
            FROM Quote
            WHERE Id = :qli.QuoteId
            LIMIT 1
        ];
        if (String.isBlank(q.Email) || q.OpportunityId == null) {
            return;
        }

        // Construire l'URL Lightning de l'opportunité
        String base = System.Url.getOrgDomainUrl().toExternalForm();
        String oppUrl = base + '/lightning/r/Opportunity/' + q.OpportunityId + '/view';

        // Préparer et envoyer l'email
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new String[] { q.Email });
        msg.setSubject('Optimisation TURPE terminée – Devis complet');
        msg.setOrgWideEmailAddressId(owea.get(0).Id);

        String body =
                    'Bonjour,' + '\n\n' +
                    'Toutes les lignes de votre devis sont à jour suite aux optimisations TURPE.' + '\n\n' +
                    'Consulter l’opportunité dans Salesforce :' + '\n' + oppUrl + '\n\n' +
                    'Bien cordialement,' + '\n' +
                    'Alliance des Énergies';

        msg.setPlainTextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { msg }, false);

        // Purger l'email sur la Quote comme demandé
        update new Quote(Id = q.Id, Email = null);
    }
}