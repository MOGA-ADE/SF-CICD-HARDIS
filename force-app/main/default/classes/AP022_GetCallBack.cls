@RestResource(urlMapping='/callback/endesa')
global without sharing class AP022_GetCallBack {

@HttpPost
    global static void receiveCallback() {
        System.debug('receiveCallback');
        try {
            RestRequest req = RestContext.request;
            String body = req.requestBody.toString();
            System.debug('Body reçu : ' + body);

            // Test rapide si la réponse contient des erreurs
            if (body.containsIgnoreCase('"errors"')) {
                System.debug('errors found');
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(body);
                handleErrorCallback(parsed); //Revoir le parsing des erreurs ne pas utiliser chatgpt + Envoyer un mail pour demander si un JSON type pour les erreurs existes
                                             // Si pas de moyen simple de parser les messages d'erreur on l'affiche directement dans le mail
            }
            else {
                CallbackResponse response = (CallbackResponse) JSON.deserialize(body, CallbackResponse.class);
                //Inclure le code de handleSuuccessCallBack dans le if
                //String quoteUrl = 'https://alliancedesenergies--devbb.sandbox.lightning.force.com/lightning/r/Quote/' + quote.Id + '/view';
                Quote quote = updateQuoteLineItems(response, response.num_dossier);

                // Get the Id for our custom notification type
                CustomNotificationType notificationType = 
                    [SELECT Id, DeveloperName 
                    FROM CustomNotificationType 
                    WHERE DeveloperName='Endesa_Elec_Prix'];
                
                // Create a new custom notification
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                // Set the contents for the notification
                notification.setTitle('API ENDESA / Prix Endesa Elec récupérés pour la Quote : ' + quote.Name);

                body = 'Les prix ont été récupérés avec succès pour la Quote ' + quote.Name;
                notification.setBody(body);
                // Set the notification type and target
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(quote.Id);
                
                // Actually send the notification
                try {
                    Set<String> recipients = new Set<String>();
                    recipients.add(quote.Owner.Id);
                    notification.send(recipients);
                }
                catch (Exception e) {
                    System.debug('Problem sending notification: ' + e.getMessage());
                }
            }     

        } catch (Exception e) {
            System.debug('Exception dans receiveCallback: ' + e.getMessage());
            throw new CalloutException('Exception REST Callback : ' + e.getMessage());
        }
    }

    public static Quote updateQuoteLineItems(CallbackResponse response, String numero_dossier) {

        System.debug('response in updateQuoteLineItems : ' + response);
        System.debug('num_dossier in updateQuoteLineItems : ' + numero_dossier);

        List<Quote> quotes = [Select Id From Quote Where Numero_Dossier_API_Endesa_Elec__c =: numero_dossier];
        
        List<QuoteLineItem> qlis = [
            SELECT Id, TECH_PdeReference__c, QuoteId, Quote.Owner.Email, PDE__r.Segment__c,
                    PDE__r.FTA__c, PDE__r.Calendrier_fournisseur__c, Quote.CEE__c
            FROM QuoteLineItem
            WHERE Quote.Numero_Dossier_API_Endesa_Elec__c =: numero_dossier
        ];

        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();

        for (QuoteLineItem qli : qlis) {
            SiteResponse site = response.sites.get(qli.TECH_PdeReference__c);
            if (site == null) continue;

            String segment = qli.PDE__r.Segment__c;
            Boolean is4Postes = qli.PDE__r.FTA__c != null && qli.PDE__r.FTA__c.contains('4 postes');
            String calendrierFournisseur = qli.PDE__r.Calendrier_fournisseur__c;

            QuoteLineItem newQLI = new QuoteLineItem();
            newQLI.Id = qli.Id;
            if (site.commission != null) {
                newQLI.UnitPrice = Decimal.valueOf(site.commission).setScale(2);
            }

            newQLI.AbonnementMois__c = site.abonnement;
            newQLI.PrixBase__c = site.prix_energie_base ?? 0;
            newQLI.PrixHP__c = site.prix_energie_hp ?? 0;
            newQLI.PrixHC__c = site.prix_energie_hc ?? 0;

            if (segment == 'C5' && is4Postes) {
                if (calendrierFournisseur == 'Heures Pleines/Creuses' || calendrierFournisseur == 'HP/HC') {
                    newQLI.PrixHchMwh__c = site.prix_energie_hc ?? 0;
                    newQLI.PrixHceMwh__c = site.prix_energie_hc ?? 0;
                    newQLI.PrixHphMwh__c = site.prix_energie_hp ?? 0;
                    newQLI.PrixHpeMwh__c = site.prix_energie_hp ?? 0;
                } else {
                    newQLI.PrixHchMwh__c = site.prix_energie_base ?? 0;
                    newQLI.PrixHceMwh__c = site.prix_energie_base ?? 0;
                    newQLI.PrixHphMwh__c = site.prix_energie_base ?? 0;
                    newQLI.PrixHpeMwh__c = site.prix_energie_base ?? 0;
                }
            } else {
                newQLI.PrixHchMwh__c = site.prix_energie_hch ?? 0;
                newQLI.PrixHceMwh__c = site.prix_energie_hce ?? 0;
                newQLI.PrixHphMwh__c = site.prix_energie_hph ?? 0;
                newQLI.PrixHpeMwh__c = site.prix_energie_hpe ?? 0;
            }

            newQLI.PointesMWh__c = site.categorie == 'C4' ? site.prix_energie_hph : 0;
            newQLI.CeeMwh__c = qli.Quote.CEE__c == 'Soumis' ? Decimal.valueOf(site.cee).setScale(2, RoundingMode.DOWN) : 0;

            newQLI.Capa_Base__c = site.capacite ?? 0;
            newQLI.Capa_HP__c = site.capacite ?? 0;
            newQLI.Capa_HC__c = site.capacite ?? 0;
            newQLI.Capa_HCH__c = site.capacite ?? 0;
            newQLI.Capa_HPH__c = site.capacite ?? 0;
            newQLI.Capa_HPE__c = site.capacite ?? 0;
            newQLI.Capa_HCE__c = site.capacite ?? 0;
            newQLI.Capa_Pointes__c = site.capacite ?? 0;

            qliToUpdate.add(newQLI);
        }

        Quote quoteToUpdate = [SELECT Id, Name, Owner.Email, Owner.Id From Quote WHERE Id =: qlis[0].QuoteId];
        

        quoteToUpdate.Date_Validite_Offre_API_Endesa_Elec__c = Date.parse(response.date_fin_validite);
        quoteToUpdate.Numero_Offre_API_Endesa_Elec__c = response.numero_offre;

        // Update QLI
        List<Database.SaveResult> listSRQLI = Database.update(qliToUpdate, false);
        for (Database.SaveResult sr : listSRQLI) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(err);
                }
                throw new CalloutException('Erreur Update QLI');
            }
        }

        // Update Quote
        Database.SaveResult srQuote = Database.update(quoteToUpdate);
        if (!srQuote.isSuccess()) {
            for(Database.Error err : srQuote.getErrors()){
                System.debug(err);
            }
            throw new CalloutException('Erreur Update Quote');
        }

        return quoteToUpdate;

    }

    private static void sendEmail(String subject, List<String> toAddresses, String bodyHtml) {
        OrgWideEmailAddress[] owea = [
            SELECT Id FROM OrgWideEmailAddress 
            WHERE Address = 'tech@alliancedesenergies.fr' 
            LIMIT 1
        ];

        if (owea.isEmpty()) {
            System.debug('Aucune adresse OrgWideEmailAddress trouvée.');
            return;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setOrgWideEmailAddressId(owea[0].Id);
        mail.setSubject(subject);
        mail.setHtmlBody(bodyHtml);

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        System.debug('E-mail envoyé avec sujet : ' + subject);
    }

    private static void handleErrorCallback(Map<String, Object> parsed) {
        System.debug('handleErrorCallback');
        String parsedString = String.valueOf(parsed);
        String numdossier = '';
        if (parsed.containsKey('num_dossier')) {
                numdossier = String.valueOf(parsed.get('num_dossier'));
                List<Quote> quotes = [
                    SELECT Id, Name, Numero_Dossier_API_Endesa_Elec__c, Owner.Email, Owner.Id
                    FROM Quote
                    WHERE Numero_Dossier_API_Endesa_Elec__c =: numdossier
                    Limit 1
                ];

                if(!quotes.isEmpty())   {


                    // Get the Id for our custom notification type
                    CustomNotificationType notificationType = 
                        [SELECT Id, DeveloperName 
                        FROM CustomNotificationType 
                        WHERE DeveloperName='Endesa_Elec_Prix'];
                    
                    // Create a new custom notification
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();

                    // Set the contents for the notification
                    notification.setTitle('API ENDESA / Prix Endesa Elec, erreurs survenue pour la Quote : ' + quotes[0].Name);
                    String body = 'Erreurs survenue lors de la récupération des prix : ' + parsedString;
                    notification.setBody(body);

                    // Set the notification type and target
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetId(quotes[0].Id);
                    
                    // Actually send the notification
                    try {
                        Set<String> recipients = new Set<String>();
                        recipients.add(quotes[0].Owner.Id);
                        notification.send(recipients);
                    }
                    catch (Exception e) {
                        System.debug('Problem sending notification: ' + e.getMessage());
                    }
                }
                else {
                    System.debug('No Quote found for dossier number : ' + numdossier);
                    System.debug('quote : ' + quotes);
                }

        }
    }

    private class ErrorItem {
        public String code_error;
        public String message;
        public String num_dossier;

        public ErrorItem(String code, String msg, String dossier) {
            this.code_error = code;
            this.message = msg;
            this.num_dossier = dossier;
        }
    }

    private class CallbackResponse {
        public String numero_offre;
        public String num_dossier;
        public String date_fin_validite;
        public Map<String, SiteResponse> sites;
    }

    private class SiteResponse  {
        public Double commission;
        public Double abonnement;
        public Double cee;
        public String categorie;
        public Double consommation;
        public Double capacite;
        public Double prix_energie_base;
        public Double prix_energie_hp;
        public Double prix_energie_hc;
        public Double prix_energie_hch;
        public Double prix_energie_hph;
        public Double prix_energie_hpe;
        public Double prix_energie_hce;
    }

}