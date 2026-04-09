public with sharing class AP022_GetEndesaElecPriceController {
    private static Config_Endesa_API_Elec__c config = Config_Endesa_API_Elec__c.getInstance();

    @invocableMethod(callout=true label='GET Prix Elec Endesa')
    public static List<FlowOutput> getPrices(List<FlowInput> params) {

        List<FlowOutput> outputs = new List<FlowOutput>();
        FlowOutput output = new FlowOutput();
        FlowInput param = params.get(0);

        // Send the AccessToken request
        String accessToken = getAccessToken();

        // Check the response
        if(accessToken != null) {

            // Get Quote Info
            Quote quote = [ SELECT  Id,
                                    Minimum_date_de_debut__c,
                                    Maximum_date_de_fin__c,
                                    Opportunity.TECH_Account_Siret__c,
                                    Opportunity.Account.Name,
                                    Opportunity.Account.RecordType.Name,
                                    Opportunity.Account.Syndic__r.Name,
                                    Opportunity.Demande_Cotation__r.Signataire__r.Title,
                                    Opportunity.Demande_Cotation__r.Signataire__r.Salutation,
                                    Opportunity.Demande_Cotation__r.Signataire__r.Name,
                                    Opportunity.Demande_Cotation__r.Signataire__r.FirstName,
                                    Opportunity.Demande_Cotation__r.Signataire__r.LastName,
                                    Opportunity.Demande_Cotation__r.Signataire__r.Email,
                                    Opportunity.Demande_Cotation__r.Signataire__r.Phone
                            FROM Quote
                            WHERE Id = :param.quote.Id
                            LIMIT 1];

            // Construct the JSON Body
            Map<String, Object> bodyMap = new Map<String, Object>();
            bodyMap.put('callback_url', config.URL_Callback__c + quote.Id);
            bodyMap.put('siret_siren', quote.Opportunity.TECH_Account_Siret__c);
            bodyMap.put('type_offre', param.type_offre);           
            bodyMap.put('date_debut', quote.Minimum_date_de_debut__c.format());          
            bodyMap.put('date_fin', quote.Maximum_date_de_fin__c.format());        
            bodyMap.put('date_fin_validite', param.date_validite_offre.format());       
            bodyMap.put('prix_unique', 'true');

            // Check RecordTypeName
            if (getTypeProspect(quote.Opportunity.Account.RecordType.Name) == 'Entreprise'){
                Map<String, String> entitePrincipaleMap = new Map<String, String>();
                entitePrincipaleMap.put('raison_sociale', quote.Opportunity.Account.Name);
                entitePrincipaleMap.put('secteur_activite', 'tertiaire');
                entitePrincipaleMap.put('representant_legal', quote.Opportunity.Demande_Cotation__r.Signataire__r.Name + ' - ' + quote.Opportunity.Demande_Cotation__r.Signataire__r.Title);
                entitePrincipaleMap.put('contact_commercial_titre', getContactCommercialTitre(quote.Opportunity.Demande_Cotation__r.Signataire__r.Salutation));
                entitePrincipaleMap.put('contact_commercial_nom', quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName);
                entitePrincipaleMap.put('contact_commercial_prenom', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName);
                entitePrincipaleMap.put('contact_commercial_email', quote.Opportunity.Demande_Cotation__r.Signataire__r.Email);
                entitePrincipaleMap.put('contact_commercial_phone', quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone.deleteWhitespace());

                bodyMap.put('type_prospect', 'Entreprise'); 
                bodyMap.put('entite_principale', entitePrincipaleMap);
            } else {
                Map<String, String> entitePrincipaleMap = new Map<String, String>();
                entitePrincipaleMap.put('raison_sociale', quote.Opportunity.Account.Syndic__r.Name);
                entitePrincipaleMap.put('secteur_activite', 'tertiaire');
                entitePrincipaleMap.put('representant_legal', quote.Opportunity.Demande_Cotation__r.Signataire__r.Name + ' - ' + quote.Opportunity.Demande_Cotation__r.Signataire__r.Title);
                entitePrincipaleMap.put('contact_commercial_titre', getContactCommercialTitre(quote.Opportunity.Demande_Cotation__r.Signataire__r.Salutation));
                entitePrincipaleMap.put('contact_commercial_nom', quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName);
                entitePrincipaleMap.put('contact_commercial_prenom', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName);
                entitePrincipaleMap.put('contact_commercial_email', quote.Opportunity.Demande_Cotation__r.Signataire__r.Email);
                entitePrincipaleMap.put('contact_commercial_phone', quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone.deleteWhitespace());

                Map<String, String> entiteSecondaireMap = new Map<String, String>();
                entiteSecondaireMap.put('raison_sociale', quote.Opportunity.Account.Name);
                entiteSecondaireMap.put('secteur_activite', 'tertiaire');
                entiteSecondaireMap.put('representant_legal', quote.Opportunity.Demande_Cotation__r.Signataire__r.Name + ' - ' + quote.Opportunity.Demande_Cotation__r.Signataire__r.Title);
                entiteSecondaireMap.put('contact_commercial_titre', getContactCommercialTitre(quote.Opportunity.Demande_Cotation__r.Signataire__r.Salutation));
                entiteSecondaireMap.put('contact_commercial_nom', quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName);
                entiteSecondaireMap.put('contact_commercial_prenom', quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName);
                entiteSecondaireMap.put('contact_commercial_email', quote.Opportunity.Demande_Cotation__r.Signataire__r.Email);
                entiteSecondaireMap.put('contact_commercial_phone', quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone.deleteWhitespace());

                bodyMap.put('type_prospect', 'Copropriete'); 
                bodyMap.put('entite_principale', entitePrincipaleMap);
                bodyMap.put('entite_secondaire', entiteSecondaireMap);
            }

            bodyMap.put('sites', param.sites);

            // Price callout
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();

            // Setup Request
            req.setEndpoint('callout:Endesa_Elec/api/api-offre-elec/2.0/');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeout((Integer)config.Timeout__c);
            req.setBody(JSON.serialize(bodyMap));

            System.debug('bodyMap ' + JSON.serialize(bodyMap));
            try {
                // Send the Price request
                res = http.send(req);
            
                // Check the response
                if (res.getStatusCode() == 200) {
                    System.debug('response ' + res.getBody());
                    // Infos demandée à Endesa
                    wrapperPrice response = (wrapperPrice)JSON.deserialize(res.getBody(), wrapperPrice.class);
                    output.StatusCode = res.getStatusCode();
                    output.response = updateQliWithApiResponse(response, param);
                } else {
                    output.StatusCode = res.getStatusCode();
                    output.response = res.getBody();
                }
            } catch (Exception e) {
                output.StatusCode = null;
                output.response = 'Erreur ' + e.getMessage();
            }
        } else {
            output.StatusCode = null;
            output.response = 'Erreur accessToken';
        }
        outputs.add(output);
        return outputs;
    }

    /*
    * Helpers
    */
    public static String getAccessToken() {
        // AccessToken callout
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

        req.setEndpoint('callout:Endesa_Elec/api/login/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout((Integer)config.Timeout__c);

        Map<String, String> bodyMap = new Map<String, String>();
        bodyMap.put('username', config.Username__c);
        bodyMap.put('password', config.Password__c);

        req.setBody(JSON.serialize(bodyMap));

        try {
            // Send the AccessToken request
            res = http.send(req);
        
            // Check the response
            if (res.getStatusCode() == 200) {
                // Request was successful
                API_Endesa_Elec_Token resToken = (API_Endesa_Elec_Token)JSON.deserialize(res.getBody(), API_Endesa_Elec_Token.class);
                return resToken.login.access_token;
            } else {
                return null;
            }
        } catch (Exception e) {
            return null;
        }
    }

    private static String getTypeProspect(String recordTypeName) {
        return recordTypeName == 'Entité Juridique Principale' ? 'Entreprise' : 'Copropriete';
    }

    private static String getContactCommercialTitre(String Salutation) {
        return Salutation == 'Monsieur' ? 'Mr' : 'Mme';
    }

    private static String updateQliWithApiResponse(wrapperPrice apiResponse, FlowInput param) {

        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();
        
        Quote quoteToUpdate = new Quote();
        quoteToUpdate.Id = param.quote.Id;
        quoteToUpdate.Numero_Dossier_API_Endesa_Elec__c = apiResponse.num_dossier;
        quoteToUpdate.Numero_Offre_API_Endesa_Elec__c = '';
        quoteToUpdate.Api_status__c = 'Demande de prix envoyée par Salesforce';
        quoteToUpdate.Api_error_message__c = '';

        if (param.type_offre == 'Prix fixe marché-1')  {
            quoteToUpdate.TypeOffre__c = 'PRIX FIXE';
        } else if (param.type_offre == 'Simplicité-1' || param.type_offre == 'Sérénité-1') {
            quoteToUpdate.TypeOffre__c = 'ARENH SANS ÉCRÊTEMENT';
        } else {
            quoteToUpdate.TypeOffre__c = 'ARENH AVEC ÉCRÊTEMENT';
        }

        // Infos demandée à Endesa
        Map<String,WrapSiteElecEndesa> mapSiteFromFlow = new Map<String,WrapSiteElecEndesa>();
        for (WrapSiteElecEndesa siteFromFlow : param.sites) {
            mapSiteFromFlow.put(siteFromFlow.prm, siteFromFlow);
        }

        for (QuoteLineItem qli : [SELECT Id, TECH_PdeReference__c FROM QuoteLineItem WHERE QuoteId = :param.quote.Id]) {

            // Update QLI
            QuoteLineItem newQLI = new QuoteLineItem();
            newQLI.Id = qli.Id;
            newQLI.Abonnement_Endesa_Elec_Souhaitee__c = mapSiteFromFlow.get(qli.TECH_PdeReference__c).abonnement;
            newQLI.Commission_Endesa_Elec_Souhaitee__c = mapSiteFromFlow.get(qli.TECH_PdeReference__c).commission;

            qliToUpdate.add(newQLI);
        }

        // Update QLI
        List<Database.SaveResult> listSRQLI = Database.update(qliToUpdate);
        for(Database.SaveResult sr : listSRQLI){
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()){
                    System.debug(err);
                }
                return 'Erreur Update QLI';
            }
        }

        // Update Quote
        Database.SaveResult srQuote = Database.update(quoteToUpdate);
        if (!srQuote.isSuccess()) {
            for(Database.Error err : srQuote.getErrors()){
                System.debug(err);
            }
            return 'Erreur Update Quote';
        }

        return 'Demande de prix envoyée avec succes !';
    }

    /*
    * Wrappers
    */
    private class API_Endesa_Elec_Token {
        public String last_name;
	    public String first_name;
	    public String email;
	    public Login login;
    }

    private class Login {
        public String access_token;
        public String client_id;
        public String client_secret;
        public String refresh_token;
    }

    private class wrapperPrice {
        public String num_dossier;
        public String message;
        public String code;
    }

    public class FlowInput {
        @invocableVariable public Quote quote;
        @invocableVariable public List<WrapSiteElecEndesa> sites;
        @invocableVariable public String type_offre;
        @invocableVariable public Date date_validite_offre;
    }

    public class FlowOutput {
        @InvocableVariable public Integer StatusCode;
        @InvocableVariable public String response;
    }
}