public with sharing class AP022_ValidEndesaElecOfferController {
    private static Config_Endesa_API_Elec__c config = Config_Endesa_API_Elec__c.getInstance();
    
    @invocableMethod(callout=true label='Valider Offre Elec Endesa')
    public static List<FlowOutput> validOffer(List<String> numerosOffre) {

        List<FlowOutput> outputs = new List<FlowOutput>();
        FlowOutput output = new FlowOutput();
        String numeroOffre = numerosOffre[0];

        // Send the AccessToken request
        String accessToken = AP022_GetEndesaElecPriceController.getAccessToken();

        // Check the response
        if(accessToken != null) {

            // Construct the JSON Body
            Map<String, Object> bodyMap = new Map<String, Object>();
            bodyMap.put('numero_offre', numeroOffre);

            // Price callout
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();

            // Setup Request
            req.setEndpoint('callout:Endesa_Elec/api/api-fichiers-offre-elec/1.0/');
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
                    wrapperValidOffer response = (wrapperValidOffer)JSON.deserialize(res.getBody(), wrapperValidOffer.class);
                    output.StatusCode = res.getStatusCode();
                    output.response = sendMailWithDocuments(response);
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
    private static String sendMailWithDocuments(wrapperValidOffer apiResponse) {

        // Get Infos
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'tech@alliancedesenergies.fr'];
        Quote quote = [SELECT Name, Owner.Email FROM Quote WHERE Numero_Offre_API_Endesa_Elec__c = :apiResponse.numero_offre LIMIT 1];
        String userEmail = UserInfo.getUserEmail();

        // Generate PDFs from base64 string
        Messaging.EmailFileAttachment pdfCG = new Messaging.EmailFileAttachment();
        Blob blobCG = EncodingUtil.base64Decode(apiResponse.conditions_generales.base64);
        pdfCG.setFileName(apiResponse.conditions_generales.filename);
        pdfCG.setBody(blobCG);
        pdfCG.setContentType('application/pdf');

        Messaging.EmailFileAttachment pdfCP = new Messaging.EmailFileAttachment();
        Blob blobCP = EncodingUtil.base64Decode(apiResponse.conditions_particulieres.base64);
        pdfCP.setFileName(apiResponse.conditions_particulieres.filename);
        pdfCP.setBody(blobCP);
        pdfCP.setContentType('application/pdf');

        // Create subject and email body text
        String subject = 'Offre Endesa numéro ' + apiResponse.numero_offre + ' validée !' ;
        String emailBody = 'Bonjour,\n\n';
        emailBody += 'Vous venez de valider l\'offre Endesa numéro ' + apiResponse.numero_offre + '.\n';
        emailBody += 'Cette offre est associée à l\'offre fournisseur Salesforce : ' + quote.Name + '.\n';
        emailBody += 'Vous trouverez en pièces jointes les 2 fichiers PDF à faire signer au client.\n\n';
        emailBody += 'Bien à vous.\n\n';

        // Create email and send it
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{quote.Owner.Email});
        email.setSubject(subject);
        email.setPlainTextBody(emailBody);
        email.setUseSignature(false);
        email.setCharset('utf-8');
        if ( owea.size() > 0 ) {
            email.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{pdfCP, pdfCG});

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

        if (results[0].success) {
            return 'Offre Validée avec succes !';
        } else {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
            return 'Offre validée avec succes mais impossible de vous envoyer le mail contenant les documents à faire signer.\n Merci de vous connectez à la plateforme Endesa pour les récupérer. Numéro offre : ' + apiResponse.numero_offre;
        }
    }

    /*
    * Wrappers
    */
    private class wrapperValidOffer {
        public String numero_offre;
        public conditionsGenerales conditions_generales;
        public conditionsParticulieres conditions_particulieres;
    }

    private class conditionsGenerales {
        public String base64;
        public String filename;	
    }

    private class conditionsParticulieres {
        public String base64;
        public String filename;
    }

    public class FlowOutput {
        @InvocableVariable public Integer StatusCode;
        @InvocableVariable public String response;
    }
}