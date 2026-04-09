public with sharing class AP022_StatusEndesaElecOfferController {
    private static Config_Endesa_API_Elec__c config = Config_Endesa_API_Elec__c.getInstance();
    
    @invocableMethod(callout=true label='Changement Statut Offre Elec Endesa')
    public static List<FlowOutput> changeStatus(List<FlowInput> params) {

        List<FlowOutput> outputs = new List<FlowOutput>();
        FlowOutput output = new FlowOutput();
        FlowInput param = params.get(0);

        // Send the AccessToken request
        String accessToken = AP022_GetEndesaElecPriceController.getAccessToken();

        // Check the response
        if(accessToken != null) {

            // Construct the JSON Body
            Map<String, Object> bodyMap = new Map<String, Object>();
            bodyMap.put('numero_offre', param.quote.Numero_Offre_API_Endesa_Elec__c);
            bodyMap.put('status', 'en_attente_validation');
            bodyMap.put('commentaire', param.commentaire);

            // Price callout
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();

            // Setup Request
            req.setEndpoint('callout:Endesa_Elec/api/api-changer-status/1.0/');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + accessToken);
            req.setTimeout((Integer)config.Timeout__c);
            req.setBody(JSON.serialize(bodyMap));

            try {
                // Send the Valid Offer request
                res = http.send(req);
            
                // Check the response
                if (res.getStatusCode() == 200) {
                    // Request was successful
                    wrapperChangeStatusOffer response = (wrapperChangeStatusOffer)JSON.deserialize(res.getBody(), wrapperChangeStatusOffer.class);
                    output.StatusCode = res.getStatusCode();
                    output.response = updateStatusEndesaOffer(response, param);
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
    private static String updateStatusEndesaOffer(wrapperChangeStatusOffer apiResponse, FlowInput param) {
        
        Quote quoteToUpdate = new Quote();
        quoteToUpdate.Id = param.quote.Id;
        quoteToUpdate.Status_Offre_API_Endesa_Elec__c = apiResponse.status;

        // Update Quote
        Database.SaveResult srQuote = Database.update(quoteToUpdate);
        if (!srQuote.isSuccess()) {
            for(Database.Error err : srQuote.getErrors()){
                System.debug(err);
            }
            return 'Erreur Update Status Offre Endesa';
        }

        return 'Statut de l\'offre mis à jour avec succes !';
    }
    /*
    * Wrappers
    */
    private class wrapperChangeStatusOffer {
        public String numero_offre;
        public String status;
    }

    public class FlowInput {
        @invocableVariable public Quote quote;
        @invocableVariable public String status;
        @invocableVariable public String commentaire;
    }

    public class FlowOutput {
        @InvocableVariable public Integer StatusCode;
        @InvocableVariable public String response;
    }
}