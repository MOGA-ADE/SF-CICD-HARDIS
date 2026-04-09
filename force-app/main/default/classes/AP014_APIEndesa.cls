global with sharing class AP014_APIEndesa {
    @invocableMethod(callout=true label='GET prix gaz Endesa')
    public static List<FlowOutput> GET_PrixGaz(List<FlowInput> params){
        Map<String,Object> mapJSONBody = new Map<String,Object>();
        Endesa_API__mdt endesaAPI;
        String token;
        String url;
        FlowInput input = params.get(0);
        FlowOutput output  = new FlowOutput();
        HttpResponse res;
        Boolean isCopro = isCopro(input.acc.Id);
        Boolean runningInASandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        Account acc = [ SELECT  Id,
                                Code_Postal__c,
                                Name,
                                Numero_voie__c,
                                Siret__c,
                                Syndic__c,
                                Syndic__r.Name,
                                Voie__c,
                                Ville__c
                        FROM Account
                        WHERE Id =: input.acc.Id
                       ];                 
        Quote quote = [ SELECT  Id,
                                Maximum_date_de_fin__c,
                                Minimum_date_de_debut__c,
                                Opportunity.Demande_Cotation__c,
                                Opportunity.Demande_Cotation__r.signataire__r.LastName,
                                Opportunity.Demande_Cotation__r.signataire__r.FirstName,
                                Opportunity.Demande_Cotation__r.signataire__r.Salutation,
                                Opportunity.Demande_Cotation__r.signataire__r.Phone,
                                Opportunity.Demande_Cotation__r.signataire__r.Email
                        FROM Quote
                        WHERE Id =: input.recordId
                        ];
        
        String siret_siren = acc.Siret__c;
        if(Test.isRunningTest()){
            endesaAPI = new Endesa_API__mdt();
            endesaAPI.url__c = 'xxx';
            endesaAPI.token__c =  'xxx';
        }
        else{
            if(runningInASandbox){
                endesaAPI = Endesa_API__mdt.getInstance('Preprod');  
            }
            else{
                endesaAPI = Endesa_API__mdt.getInstance('Prod');  
            }
        }
        token = endesaAPI.token__c;
        url = endesaAPI.url__c;

        String type_prospect = isCopro ? 'Copropriete' : 'Entreprise';
        String date_debut = String.valueOf(quote.Minimum_date_de_debut__c.format());
        String date_fin = String.valueOf(quote.Maximum_date_de_fin__c.format());
        String type_offre = input.type_offre;
        String date_fin_validite = String.valueOf(Date.valueOf(input.duree_offre).format());
        List<WrapSitesAPIEndesa> sites = input.listSites;

        //Information Générales
        mapJSONBody.put('siret_siren',siret_siren);
        mapJSONBody.put('token',token);
        mapJSONBody.put('type_offre',type_offre);
        mapJSONBody.put('type_prospect',type_prospect);        
        mapJSONBody.put('type_paiement',input.type_paiement);        
        mapJSONBody.put('date_debut',date_debut);
        mapJSONBody.put('date_fin',date_fin);
        mapJSONBody.put('date_fin_validite',date_fin_validite);

        Map<String,String> entite_principale = new Map<String,String>();
        if(isCopro){
            //Information Entitée principale
            entite_principale.put('contact_commercial_titre', convertSalutation(quote.Opportunity.Demande_Cotation__r.Signataire__r.Salutation));
            entite_principale.put('contact_commercial_nom', quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName );
            entite_principale.put('contact_commercial_prenom', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName );
            entite_principale.put('contact_commercial_email', quote.Opportunity.Demande_Cotation__r.Signataire__r.Email );
            entite_principale.put('contact_commercial_phone', quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone.deleteWhitespace() );
            entite_principale.put('representant_legal', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName + ' '+ quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName);
            entite_principale.put('forme_sociale','[9110] Syndicat de copropriété');
            entite_principale.put('secteur_activite','Tertiaire');
            entite_principale.put('raison_sociale',acc.Syndic__r.Name);

            //Information Entitée secondaire
            Map<String,String> entite_secondaire = new Map<String,String>();
            entite_secondaire.put('contact_commercial_titre', convertSalutation(quote.Opportunity.Demande_Cotation__r.Signataire__r.Salutation));
            entite_secondaire.put('contact_commercial_nom', quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName );
            entite_secondaire.put('contact_commercial_prenom', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName );
            entite_secondaire.put('contact_commercial_email', quote.Opportunity.Demande_Cotation__r.Signataire__r.Email );
            entite_secondaire.put('contact_commercial_phone', quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone.deleteWhitespace() );
            entite_secondaire.put('representant_legal', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName + ' '+ quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName);
            entite_secondaire.put('adresse',acc.Numero_voie__c + ' '+ acc.Voie__c );
            entite_secondaire.put('ville',acc.Ville__c );
            entite_secondaire.put('code_postal',acc.Code_Postal__c );
            entite_secondaire.put('forme_sociale','[9110] Syndicat de copropriété');
            entite_secondaire.put('secteur_activite','Tertiaire');
            entite_secondaire.put('raison_sociale',acc.Name);

            mapJSONBody.put('entite_principale',entite_principale);
            mapJSONBody.put('entite_secondaire',entite_secondaire);
        }
        else{
            //Information Entitée principale
            entite_principale.put('contact_commercial_titre', convertSalutation(quote.Opportunity.Demande_Cotation__r.Signataire__r.Salutation));
            entite_principale.put('contact_commercial_nom', quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName );
            entite_principale.put('contact_commercial_prenom', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName );
            entite_principale.put('contact_commercial_email', quote.Opportunity.Demande_Cotation__r.Signataire__r.Email );
            entite_principale.put('contact_commercial_phone', quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone.deleteWhitespace() );
            entite_principale.put('representant_legal', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName + ' ' + quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName);
            entite_principale.put('secteur_activite','Tertiaire');
            mapJSONBody.put('entite_principale',entite_principale);
        }

        //Information Sites
        mapJSONBody.put('sites',sites);
        String JSONBody =  JSON.serialize(mapJSONBody);

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setTimeout(120000);
        req.setBody(JSONBody);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept','application/json');
        System.debug('JSONBody '+JSONBody);

        // Send the request, and return a response
        try {
            res = h.send(req);
        } catch (Exception e) {
            System.debug('erreur '+e.getMessage());
            output.StatusCode = 400;
            output.response = 'l\'API n\'a pas répondu à temps\n'+e.getMessage();
        }
        if(res.getStatusCode() == 200) {
            System.debug('200');
            WrapResponse200 body = (WrapResponse200) JSON.deserialize(res.getBody(), WrapResponse200.class);
            System.debug('body '+body);
            String updateErrorMessage = AP014_APIEndesa.updateRecords(body,input.recordId,sites,input.type_offre,Date.valueOf(input.duree_offre)); 
            if(updateErrorMessage == null){
                output.StatusCode = 200;
                output.response  = 'Les prix ont bien été mis à jour'; 
            }
            else{
                output.StatusCode = 400;
                output.response = 'Il y a eu un soucis interne lors de la mise à jour des prix : ' + updateErrorMessage;
            }
        }
        else{
            WrapResponse400 response400 = new WrapResponse400();
            System.Debug('response 400 res.getBody() '+res.getBody());
            Map<String,Object> body = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            String fieldError =  new list<String>(body.KeySet()).get(0);
            System.Debug('response 400 body.get(fieldError) '+body.get(fieldError));
            try {
                response400 = (WrapResponse400) JSON.deserialize(JSON.serialize(body.get(fieldError)),WrapResponse400.class);
                response400.fieldError =  fieldError;
                output.StatusCode = 400;
                if(response400.errors != null && response400.fieldError != null){
                    output.response = 'L\'appel réseau n\'a pas abouti'+
                    '\nCode d\'erreur : '+response400.errors.get(0).code_error + 
                    '\nChamps concerné : '+ response400.fieldError + 
                    '\nMessage d\'erreur de Endesa : '+response400.errors.get(0).message;
                }
                else{
                    output.response = JSON.serialize(body.get(fieldError));
                }
            } catch (Exception e) {
                output.response = JSON.serialize(body.get(fieldError));
            }
            
            
        }
        List<FlowOutput> outputs = new List<FlowOutput>();
        outputs.add(output);
        return outputs;
    }
    
    private static Boolean isCopro(Id accId){
        Id syndicId = [SELECT Syndic__c FROM Account WHERE Id =:accId].Syndic__c;
        return syndicId != null;
    }

    private static String convertSalutation(String Salutation){
        if(Salutation == 'Monsieur' || Salutation == 'M'){
            return 'mr';
        }
        else if (Salutation == 'Madame' || Salutation == 'MME'){
            return 'mme';
        }
        return '';
    }

    private static String updateRecords(WrapResponse200 response, Id quoteId,list<WrapSitesAPIEndesa> listSitesWithCommission,String typeOffre, Date dateFinValidite){
        Map<String,QuoteLineItem> mapPDENameQLI = new Map<String,QuoteLineItem>();
        Map<String,WrapSitesAPIEndesa> mapPDENameCommission = new Map<String,WrapSitesAPIEndesa>();
        List<PDE__c> listPDEToUpdate = new List<PDE__c>();
        List<QuoteLineItem> listQLIToUpdate = new List<QuoteLineItem>();
        Quote quote = [SELECT Id,OpportunityId FROM Quote WHERE Id=:quoteId];
        List<QuoteLineItem> listQLIEndesa = new List<QuoteLineItem>([SELECT Id, PDE__c,pde__r.TECH_num_compteur__c,pde__r.CARGaz__c,DureeEngagement__c,DebutDeFourniture__c,Nouvelle_Echeance__c FROM QuoteLineItem WHERE QuoteId =:quoteId]);
        List<QuoteLineItem> listQLIAutreFournisseurs = new List<QuoteLineItem>([SELECT Id, PDE__c,pde__r.TECH_num_compteur__c FROM QuoteLineItem WHERE QuoteId <>:quoteId AND Opportunit__c=:quote.OpportunityId]);
        quote.url_offre_endesa__c = 'https://ppc-endesa.fr/offre/'+response.numero_offre.right(6);

        // Ajout DateTime fin de l'offre à 17h00
        Time targetTime = Time.newInstance(17, 0, 0, 0);
        DateTime finalDateTime = DateTime.newInstance(dateFinValidite, targetTime);
        quote.Date_Validite_Offre__c = finalDateTime;

        for(QuoteLineItem qli : listQLIEndesa){
            mapPDENameQLI.put(qli.pde__r.TECH_num_compteur__c,qli);
        }

        for(WrapSitesAPIEndesa site : listSitesWithCommission){
            mapPDENameCommission.put(site.pce,site);
        }

        for(String key : response.sites.keySet()){
            QuoteLineItem qli = mapPDENameQLI.get(key);
            if (typeOffre == 'B1' || typeOffre == 'B2'){
                qli.AbonnementMois__c = Decimal.valueOf(response.sites.get(key).atrd_fix/12).setScale(2);
            } else {
                qli.AbonnementMois__c = Decimal.valueOf((response.sites.get(key).atrd_fix + response.sites.get(key).stockage + response.sites.get(key).atrt) / 12).setScale(2);
            }
            qli.PrixMolecule__c = Decimal.valueOf(response.sites.get(key).prix_molecule).setScale(2);
            qli.CeeMwh__c  = Decimal.valueOf(response.sites.get(key).cee).setScale(2);
            qli.CTA__c = Decimal.valueOf(response.sites.get(key).cta/12).setScale(2);
            qli.CARGaz__c = Decimal.valueOf(response.sites.get(key).car).setScale(2);
            if(qli.DureeEngagement__c == null){
                qli.DureeEngagement__c = qli.DebutDeFourniture__c.monthsBetween(qli.Nouvelle_Echeance__c);
                qli.UnitPrice = Decimal.valueOf(mapPDENameCommission.get(qli.PDE__r.TECH_num_compteur__c).commission * (response.sites.get(key).car / 12) * (qli.DebutDeFourniture__c.monthsBetween(qli.Nouvelle_Echeance__c) + 1)).setScale(2);
            }
            else{
                qli.UnitPrice = (mapPDENameCommission.get(qli.PDE__r.TECH_num_compteur__c).commission * (response.sites.get(key).car / 12) * (qli.DureeEngagement__c + 1)).setScale(2) ;
            }

            listQLIToUpdate.add(qli);
            listPDEToUpdate.add(new PDE__c(Id = qli.PDE__c, CARGaz__c = Decimal.valueOf(response.sites.get(key).car).setScale(2)));
        }
        
        for(QuoteLineItem qli: listQLIAutreFournisseurs){
            qli.CARGaz__c = Decimal.valueOf(response.sites.get(qli.PDE__r.TECH_num_compteur__c).car).setScale(2);
            listQLIToUpdate.add(qli);
        }

        try {
            update listPDEToUpdate;
            update quote;
            update listQLIToUpdate;
            return null;
        } catch (Exception e) {
            System.debug('Exception '+ e);
            return e.getMessage();
        }
    }

    public class FlowInput {
        @invocableVariable public Quote quote;
        @invocableVariable public Account acc;
        @invocableVariable public Opportunity opp;
        @invocableVariable public List<OpportunityPDERelation__c> listOPR;
        @invocableVariable public List<WrapSitesAPIEndesa> listSites;
        @invocableVariable public String type_offre;
        @invocableVariable public String duree_offre;
        @invocableVariable public Integer type_paiement;
        @invocableVariable public Id recordId;
    }

    public class FlowOutput {
        @InvocableVariable public Integer StatusCode;
        @InvocableVariable public String response;
    }

    private class WrapResponse200 {
        String numero_offre;
        String date_fin_validite;
        Map<String,WrapSiteResponse> sites;
    }

    private class WrapResponse400{
        String fieldError;
        String value;
        List<WrapError> errors;
    }

    private class WrapError{
        String message;
        String code_error;
    }

    private class WrapSiteResponse{
        Double atrd_fix;
        Double atrd_variable;
        Double atrt;
        Double car;
        Double cee;
        Double cta;
        Double prix_molecule;
        Double stockage;
    }
}