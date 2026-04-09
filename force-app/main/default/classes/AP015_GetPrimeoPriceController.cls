public without sharing class AP015_GetPrimeoPriceController {
    private static Boolean isSandox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    private static Enchere_de_capacite__mdt edc = Enchere_de_capacite__mdt.getInstance('Enchere_de_capacite');
    private static Primeo_API__mdt primeoAPI;

    @AuraEnabled
    public static QuoteLineItem checkQLIValidity(Id recordId){
        return [SELECT  Id, 
                        DebutDeFourniture__c, 
                        Nouvelle_Echeance__c, 
                        TECH_TypeOffre__c,
                        PrimeoApiCurrentOppURL__c,
                        PrimeoApiPriceDate__c,
                        PrimeoApiCurrentMarkup__c,
                        PrimeoApiCurrentGreenEnergy__c,
                        PrimeoApiCurrentOppDate__c
                FROM QuoteLineItem 
                WHERE Id = :recordId 
                LIMIT 1];
    }
    
    @AuraEnabled
    public static Map<String,String> getPrices(Id recordId, Boolean greenEnergy, Decimal marge) {
        
        // Get the QLI
        QuoteLineItem qliToPrice = [SELECT  Id,
                                            PrixHceMwh__c,
                                            PrixHpeMwh__c,
                                            PrixHchMwh__c,
                                            PrixHphMwh__c,
                                            PointesMWh__c,
                                            Capa_HCE__c,
                                            Capa_HCH__c,
                                            Capa_HPE__c,
                                            Capa_HPH__c,
                                            Capa_Pointes__c,
                                            CeeMwh__c,
                                            UnitPrice,
                                            DebutDeFourniture__c,
                                            Nouvelle_Echeance__c,
                                            TECH_PdeReference__c,
                                            TECH_Siret_Payeur__c,
                                            TECH_TypeOffre__c,
                                            TECH_Segment__c,
                                            PrimeoApiPriceDate__c,
                                            PrimeoApiCurrentOfferId__c,
                                            PrimeoApiCurrentTransactionId__c,
                                            PrimeoApiCurrentMarkup__c,
                                            PrimeoApiCurrentGreenEnergy__c
                                    FROM QuoteLineItem
                                    WHERE Id = :recordId
                                    LIMIT 1];

        // Send the AccessToken request
        String accessToken = getAccessToken();
    
        // Check the response
        if (accessToken != null) {
            // Callout
            HttpRequest reqOffer = new HttpRequest();
            HttpResponse resOffer = new HttpResponse();
            Http httpOffer = new Http();
            // Generate a boundary for the second callout
            String boundaryOffer = '----' + String.valueOf(System.currentTimeMillis());
            // Date format because DebutDeFourniture__c and Nouvelle_Echeance__c have the value of yyyy-mm-dd hh:mm:ss
            String startingDate = String.valueOf(Date.valueOf(qliToPrice.DebutDeFourniture__c));
            String endingDate = String.valueOf(Date.valueOf(qliToPrice.Nouvelle_Echeance__c));
            // Generate form body
            String offerBody =  '--' + boundaryOffer + '\r\n' +
                                'Content-Disposition: form-data; name="prm"\r\n\r\n' + qliToPrice.TECH_PdeReference__c + '\r\n' +
                                '--' + boundaryOffer + '\r\n' +
                                'Content-Disposition: form-data; name="siret"\r\n\r\n' + qliToPrice.TECH_Siret_Payeur__c + '\r\n' +
                                '--' + boundaryOffer + '\r\n' +
                                'Content-Disposition: form-data; name="autorisationClient"\r\n\r\n' + 'true' + '\r\n' +
                                '--' + boundaryOffer + '\r\n' +
                                'Content-Disposition: form-data; name="demandeur"\r\n\r\n' +  accessToken + '\r\n' +
                                '--' + boundaryOffer + '\r\n' +
                                'Content-Disposition: form-data; name="greenEnergy"\r\n\r\n' + String.valueOf(greenEnergy) + '\r\n' +
                                '--' + boundaryOffer + '\r\n' +
                                'Content-Disposition: form-data; name="markup"\r\n\r\n' + String.valueOf(marge) + '\r\n' +
                                '--' + boundaryOffer + '\r\n' +
                                'Content-Disposition: form-data; name="startingDate"\r\n\r\n' + startingDate + '\r\n' +
                                '--' + boundaryOffer + '\r\n' +
                                'Content-Disposition: form-data; name="endingDate"\r\n\r\n' + endingDate + '\r\n' +
                                '--' + boundaryOffer + '--';
            // Set the request
            reqOffer.setEndpoint(primeoAPI.URL__c+primeoAPI.Get_Offer_Endpoint__c);
            reqOffer.setMethod('POST');
            reqOffer.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundaryOffer);
            reqOffer.setHeader('Connection', 'keep-alive');
            reqOffer.setTimeout(120000);
            reqOffer.setBody(offerBody);
            // Send the second request
            resOffer = httpOffer.send(reqOffer);
            // Check the response for the second callout
            if (resOffer.getStatusCode() == 200) {
                // Second request was successful
                API_Primeo_Offer primeoOfferWrapper = (API_Primeo_Offer)JSON.deserialize(resOffer.getBody(), API_Primeo_Offer.class);
                
                // Check for error
                if (primeoOfferWrapper.error) {
                    return generateReturnMessage('error', 'Erreur API', primeoOfferWrapper.message);
                }
                
                Offer offer;
                // Check TECH_TypeOffre__c for getting the right offer
                if (qliToPrice.TECH_TypeOffre__c == 'ARENH AVEC ÉCRÊTEMENT') {
                    // Check if the offer still exist
                    if(!primeoOfferWrapper.offers.containsKey('4')) { return generateReturnMessage('error','Erreur Offre API', 'L\'offre Prix Arenh par postes (id : 4) n\'est plus active, contactez votre admin Salesforce.');}
                    offer = primeoOfferWrapper.offers.get('4');
                } else {
                    // Check if the offer still exist
                    if(!primeoOfferWrapper.offers.containsKey('2')) { return generateReturnMessage('error', 'Erreur Offre API', 'L\'offre Prix fixe par postes (id : 2) n\'est plus active, contactez votre admin Salesforce.');} 
                    offer = primeoOfferWrapper.offers.get('2');
                }
                // Calculate the average capa for the offer
                Integer numberOfYear = offer.capa.size();
                Double obligationCapaKwMwh = 0;
                for (capa cp : offer.capa) {
                    obligationCapaKwMwh += cp.obligationCapaKwMwh;
                }
                // Multiply the average result by the "Enchère de capacité"
                Decimal finalCapa = (obligationCapaKwMwh / numberOfYear) * edc.Montant__c;
                finalCapa = finalCapa.setScale(2);
                // Ajout greenEnergy montant
                Decimal greenEnergyMontant = offer.greenEnergy != null ? offer.greenEnergy : 0.0;
                // Check for CEE
                Decimal ceeAmount = 0;
                if (offer.cee != null) {
                    for (cee cee : offer.cee) {
                        if (cee.value != null) {
                            ceeAmount = cee.value;
                            break;
                        }
                    }
                }
                
                // Update QLI
                if (offer.finalPrices[0].PTE != null) {
                    qliToPrice.PointesMWh__c = offer.finalPrices[0].PTE + greenEnergyMontant;
                    qliToPrice.Capa_Pointes__c = finalCapa;
                }
                if (offer.finalPrices[0].HPH != null) {
                    
                    if (qliToPrice.TECH_Segment__c == 'C4') {
                        qliToPrice.PointesMWh__c = offer.finalPrices[0].HPH + greenEnergyMontant;
                        qliToPrice.Capa_Pointes__c = finalCapa;
                    }

                    qliToPrice.PrixHphMwh__c = offer.finalPrices[0].HPH + greenEnergyMontant;
                    qliToPrice.Capa_HPH__c = finalCapa;
                }
                if (offer.finalPrices[0].HCH != null) {
                    qliToPrice.PrixHchMwh__c = offer.finalPrices[0].HCH + greenEnergyMontant;
                    qliToPrice.Capa_HCH__c = finalCapa;
                }
                if (offer.finalPrices[0].HPE != null) {
                    qliToPrice.PrixHpeMwh__c = offer.finalPrices[0].HPE + greenEnergyMontant;
                    qliToPrice.Capa_HPE__c = finalCapa;
                }
                if (offer.finalPrices[0].HCE!= null) {
                    qliToPrice.PrixHceMwh__c = offer.finalPrices[0].HCE + greenEnergyMontant;
                    qliToPrice.Capa_HCE__c = finalCapa;
                }
                
                // Rém globale
                Decimal margeADE =  marge / 2;
                Decimal salesPrice = primeoOfferWrapper.contractConsumptionMwh * margeADE;
                salesPrice = salesPrice.setScale(2);

                qliToPrice.CeeMwh__c = ceeAmount;
                qliToPrice.UnitPrice = salesPrice;
                qliToPrice.PrimeoApiPriceDate__c = Datetime.now();
                qliToPrice.PrimeoApiCurrentMarkup__c = primeoOfferWrapper.markup;
                qliToPrice.PrimeoApiCurrentOfferId__c = offer.id;
                qliToPrice.PrimeoApiCurrentTransactionId__c = primeoOfferWrapper.transactionId;
                qliToPrice.PrimeoApiCurrentGreenEnergy__c = primeoOfferWrapper.greenEnergy == 1 ? true: false;
                update qliToPrice;
                
                // Success return
                return generateReturnMessage('success', 'Prix récupérés avec succès!', 'La page va se rafraîchir automatiquement dans 3 secondes.');
                
            } else {
                // Offer request failed
                return generateReturnMessage('error', 'Offer HTTP Request failed with status code: ' + resOffer.getStatusCode() + '.','Response Body: ' + resOffer.getBody());
            }
        } else {
            // GetToken failed
            return generateReturnMessage('error', 'GetToken HTTP Request failed.', 'Contactez votre admin Salesforce.');
        }
    }

    @AuraEnabled
    public static Map<String,String> validOffer(Id recordId) {

        // Get the QLI
        QuoteLineItem qliToPrice = [SELECT  PrimeoApiCurrentOppURL__c,
                                            PrimeoApiCurrentOfferId__c,
                                            PrimeoApiCurrentTransactionId__c,
                                            PrimeoApiCurrentOppDate__c,
                                            Quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName, 
                                            Quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName, 
                                            Quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone, 
                                            Quote.Opportunity.Demande_Cotation__r.Signataire__r.Email
                                    FROM QuoteLineItem
                                    WHERE Id = :recordId
                                    LIMIT 1];

        // Send the AccessToken request
        String accessToken = getAccessToken();
        // Check the response
        if (accessToken != null) {
            // Callout
            HttpRequest reqValidOffer = new HttpRequest();
            HttpResponse resValidOffer = new HttpResponse();
            Http httpValidOffer = new Http();
            // Generate a boundary for the second callout
            String boundaryValidOffer = '----' + String.valueOf(System.currentTimeMillis());
            // Generate form body
            String validOfferBody = '--' + boundaryValidOffer + '\r\n' +
                                    'Content-Disposition: form-data; name="transactionId"\r\n\r\n' + qliToPrice.PrimeoApiCurrentTransactionId__c + '\r\n' +
                                    '--' + boundaryValidOffer + '\r\n' +
                                    'Content-Disposition: form-data; name="offerId"\r\n\r\n' + qliToPrice.PrimeoApiCurrentOfferId__c + '\r\n' +
                                    '--' + boundaryValidOffer + '\r\n' +
                                    'Content-Disposition: form-data; name="demandeur"\r\n\r\n' +  accessToken + '\r\n' +
                                    '--' + boundaryValidOffer + '\r\n' +
                                    'Content-Disposition: form-data; name="contact"\r\n\r\n' + '{"firstName":"' + qliToPrice.Quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName +'","lastName":"' + qliToPrice.Quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName +'","phone":"' + qliToPrice.Quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone +'","email":"' + qliToPrice.Quote.Opportunity.Demande_Cotation__r.Signataire__r.Email +'"}' + '\r\n' +
                                    '--' + boundaryValidOffer + '--';
            // Set the request
            reqValidOffer.setEndpoint(primeoAPI.URL__c+primeoAPI.Valid_Offer_Endpoint__c);
            reqValidOffer.setMethod('POST');
            reqValidOffer.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundaryValidOffer);
            reqValidOffer.setHeader('Connection', 'keep-alive');
            reqValidOffer.setTimeout(120000);
            reqValidOffer.setBody(validOfferBody);
            // Send the second request
            resValidOffer = httpValidOffer.send(reqValidOffer);
            // Check the response for the second callout
            if (resValidOffer.getStatusCode() == 200) {
                // Second request was successful
                API_Primeo_ValidOffer primeoValidOfferWrapper = (API_Primeo_ValidOffer)JSON.deserialize(resValidOffer.getBody(), API_Primeo_ValidOffer.class);
            
                // Check for error
                if (primeoValidOfferWrapper.error) {
                    return generateReturnMessage('error', 'Erreur API', primeoValidOfferWrapper.message);
                }
            
                // Upodate QLI
                qliToPrice.PrimeoApiCurrentOppURL__c = primeoValidOfferWrapper.url;
                qliToPrice.PrimeoApiCurrentOppDate__c = Date.today();
            
                update qliToPrice;
            
                // Success return
                return generateReturnMessage('success', 'Offre validée avec succès!', 'La page va se rafraîchir automatiquement dans 3 secondes.');
            
            } else {
                // ValidOffer request failed
                return generateReturnMessage('error', 'ValidOffer HTTP Request failed with status code: ' + resValidOffer.getStatusCode() + '.', 'Response Body: ' + resValidOffer.getBody());
            }
        } else {
            // GetToken failed
            return generateReturnMessage('error', 'GetToken HTTP Request failed.', 'Contactez votre admin Salesforce');
        }
    }

    /* 
    * Helpers
    */
    private static String getAccessToken() {
        primeoAPI = isSandox ? Primeo_API__mdt.getInstance('Primeo_API_Preprod_Infos'): Primeo_API__mdt.getInstance('Primeo_API_Prod_Infos');

        // AccessToken callout
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

        // Generate a random boundary string
        String boundary = '----' + String.valueOf(System.currentTimeMillis());

        // Generate form body
        String body =   '--' + boundary + '\r\n' +
                        'Content-Disposition: form-data; name="key"\r\n\r\n' + primeoAPI.Key__c + '\r\n' +
                        '--' + boundary + '\r\n' +
                        'Content-Disposition: form-data; name="secret"\r\n\r\n' + primeoAPI.Secret__c + '\r\n' +
                        '--' + boundary + '--';

        // Set the request
        req.setEndpoint(primeoAPI.URL__c+primeoAPI.Get_Token_Endpoint__c);
        req.setMethod('POST');
        req.setHeader('Content-Type','multipart/form-data; boundary=' + boundary);
        req.setHeader('Connection', 'keep-alive');
        req.setTimeout(120000);
        req.setBody(body);

        try {
            // Send the AccessToken request
            res = http.send(req);
        
            // Check the response
            if (res.getStatusCode() == 200) {
                // Request was successful
                API_Primeo_Token resToken = (API_Primeo_Token)JSON.deserialize(res.getBody(), API_Primeo_Token.class);
                return resToken.el_temporary_id;
            } else {
                return null;
            }
        } catch (Exception e) {
            return null;
        }
    }

    private static Map<String,String> generateReturnMessage(String type, String title, String message) {
        Map<String,String> returnMessage = new Map<String,String>();
        returnMessage.put('type', type);
        returnMessage.put('title', title);
        returnMessage.put('message', message);
        return returnMessage;
    }

    /* 
    * Wrappers
    */
    public class API_Primeo_Token {
        public String el_temporary_id;
        public String el_expiration_id;
    }

    public class API_Primeo_Offer {
        public Boolean error;
        public String message;
        public String transactionId;
        public String prm;
        public String subscribedRate;
        public String siret;
        public Boolean cee;
        public Date startingDate;
        public Date endingDate;
        public Decimal markup;
        public Integer greenEnergy;
        public Decimal annualConsumptionMwh;
        public Decimal contractConsumptionMwh;
        public Decimal pointeMwh;
        public Decimal hphMwh;
        public Decimal hchMwh;
        public Decimal hpeMwh;
        public Decimal hceMwh;
        public Map<String, Offer> offers;
    }
    
    public class Offer {
        public Integer id;
        public String name;
        public String description;
        public List<FinalPrice> finalPrices;
        public List<Cee> cee;
        public List<Capa> capa;
        public List<Arenh> arenh;
        public Decimal greenEnergy;
    }
    
    public class FinalPrice {
        public Integer year;
        public Decimal PTE;
        public Decimal HPH;
        public Decimal HCH;
        public Decimal HPE;
        public Decimal HCE;
        public Decimal UNIQUE;
    }

    public class Cee {
        public Integer year;
        public Decimal value;
    }
    
    public class Capa {
        public Integer year;
        public Decimal obligationCapaKwMwh;
    }
    
    public class Arenh {
        public Integer year;
        public Decimal droitArenh;
        public Decimal droitArenhOctroye;
        public Decimal puissanceArenh;
        public Decimal volumeArenh;
    }

    public class API_Primeo_ValidOffer {
        public Boolean error;
        public String message;
        public String url;
        public String oppid;
    }
}