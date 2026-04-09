public without sharing class AP016_SendEmailChargeAffaireCreationDDC {
    //Class de test : AP003_DemandeCotationFromFlow_TEST
    @invocableMethod(label='Envoie email chargé d\'affaire')
    public static void sendEmailChargeAffaire(List<FlowInputs> params) {
        FlowInputs param = params[0];
        sendMailFutureMethod(params.get(0).recordId);
    }

    @future(callout=true)
    public static void sendMailFutureMethod(Id recordId){
        // Skip email sending during test execution
        if (Test.isRunningTest()) {
            return;
        }

        String segment,heureRDV,dateRDV;
        Integer numberOfC1 = 0, numberOfC2 = 0, numberOfC3 = 0, numberOfC4 = 0,numberOfC5 = 0, numberOfGaz = 0;
        Demande_Cotation__c dc = [  SELECT 
                                        Account__c,
                                        Account__r.Name,
                                        Account__r.Siret__c,
                                        Account__r.Code_NAF__r.Name,
                                        Charge_affaire__r.email,
                                        Charge_affaire__r.Manager.Email,
                                        Date_RDV_Client__c,
                                        Id,
                                        Infos_complementaires__c,
                                        Name,
                                        Plus_1_Giga__c,
                                        Formula_plus_10_compteurs__c,
                                        Owner.Name,
                                        Signataire__r.LastName,
                                        Signataire__r.FirstName,
                                        Signataire__r.Phone,
                                        Signataire__r.Email,
                                        Signataire__r.Title
                                    FROM Demande_Cotation__c 
                                    WHERE 
                                        Id =: recordId];
        AggregateResult[] listAR = [  SELECT Segment__c,count(Id)
                                FROM 
                                    PDE__c
                                WHERE
                                    Demande_Cotation__c =: recordId
                                GROUP BY
                                    Segment__c];
        System.debug('listAR '+listAR);

        for(AggregateResult ar : listAR){
            segment = String.valueOf(ar.get('Segment__c'));
            switch on segment {
                when 'C1' {
                    numberOfC1 = Integer.valueOf(ar.get('expr0'));
                }
                when 'C2' {
                    numberOfC2 = Integer.valueOf(ar.get('expr0'));
                }
                when 'C3' {
                    numberOfC3 = Integer.valueOf(ar.get('expr0'));
                }
                when 'C4' {
                    numberOfC4 = Integer.valueOf(ar.get('expr0'));
                }
                when 'C5' {
                    numberOfC5 = Integer.valueOf(ar.get('expr0'));
                }
                when null {
                    numberOfGaz = Integer.valueOf(ar.get('expr0'));
                }
            }
        }
        Integer nmbrOfSites = numberOfC1 + numberOfC2 + numberOfC3 + numberOfC4 + numberOfC5 + numberOfGaz;

        String multiOrMono = (numberOfC1 + numberOfC2 + numberOfC3 + numberOfC4 + numberOfC5 + numberOfGaz) > 1 ? 'MULTI' : 'MONO';
        List<ELLISPHERE__Elli_Assessement__c> elliScore = new List<ELLISPHERE__Elli_Assessement__c>([SELECT ELLISPHERE__Elli_Tch_Score__c FROM ELLISPHERE__Elli_Assessement__c WHERE ELLISPHERE__Elli_Score_account__c =: dc.Account__c Order by credit_score_date__c DESC LIMIT 1]);
        String lastCreditScore = elliScore.size() == 0 ? 'NaN' : elliScore.get(0).ELLISPHERE__Elli_Tch_Score__c;
        dateRDV = dc.Date_RDV_Client__c == null ? '' : dc.Date_RDV_Client__c.format();
        Messaging.reserveSingleEmailCapacity(3);
        Messaging.SingleEmailMessage mymail = new Messaging.SingleEmailMessage();
        String[] toaddresses = new String[] {dc.Charge_affaire__r.email == null ? 'nomail@alliancedesenergies.fr' :dc.Charge_affaire__r.email}; 
        System.debug('toaddresses '+toaddresses);
        mymail.setToAddresses(toAddresses);
        mymail.setSenderDisplayName('Nouvelle demande de cotation');
        mymail.setSubject('Nouvelle demande de cotation '+multiOrMono+' de '+dc.Owner.Name+' pour '+dc.Account__r.Name);
        String htmlBody = '<p>'+dc.Owner.Name+' vous a assigné en tant que chargé d\'affaire sur sa demande de cotation <strong>'+dc.Name+'</strong> pour le <strong>'+dateRDV+'</strong> .</p>' +
                          '<p>Pour accéder à cette demande de cotation cliquez&nbsp;<a href="https://alliancedesenergies.lightning.force.com/lightning/r/Demande_Cotation__c/'+dc.Id+'/view">ici</a></p>' +
                          '<p>&nbsp;</p><p>Informations concernant la demande de cotation :&nbsp;</p>'+
                          '<strong>SOCIETE</strong>'+
                          '<ul><li>Raison sociale :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Account__r.Name+'</strong></span></li>'+
                          '<li>SIRET :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Account__r.Siret__c+'</strong></span></li>' +
                          '<li>Code NAF :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Account__r.Code_NAF__r.Name+'</strong></span></li>' +
                          '<li>Dernier avis de crédit :&nbsp;<span style="color: #ff0000;"><strong>'+lastCreditScore+'/10</strong></span></li></ul>' +
                          '<p>&nbsp;</p><strong>SIGNATAIRE</strong>'+//
                          '<ul><li>Nom du signataire :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Signataire__r.LastName+'</strong></span></li>' +
                          '<li>Prénom du signataire :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Signataire__r.FirstName+'</strong></span></li>' +
                          '<li>Tel du signataire :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Signataire__r.Phone+'</strong></span></li>' +
                          '<li>Email du signataire :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Signataire__r.Email+'</strong></span></li>'+
                          '<li>Fonction :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Signataire__r.Title+'</strong></span></li></ul>'+
                          '<p>&nbsp;</p><strong>SITES</strong>'+//
                          '<ul><li>Nombre de site par typologie :<ul>' +
                          '<li>C1 :&nbsp;<span style="color: #ff0000;"><strong>'+numberOfC1+'</strong></span></li>'+
                          '<li>C2 :&nbsp;<span style="color: #ff0000;"><strong>'+numberOfC2+'</strong></span></li>'+
                          '<li>C3 :&nbsp;<span style="color: #ff0000;"><strong>'+numberOfC3+'</strong></span></li>'+
                          '<li>C4 :&nbsp;<span style="color: #ff0000;"><strong>'+numberOfC4+'</strong></span></li>'+
                          '<li>C5 :&nbsp;<span style="color: #ff0000;"><strong>'+numberOfC5+'</strong></span></li>'+
                          '<li>Gaz :&nbsp;<span style="color: #ff0000;"><strong>'+numberOfGaz+'</strong></span></li></ul></li>'+
                          '<li>Nombre total de compteur :&nbsp;<span style="color: #ff0000;"><strong>'+nmbrOfSites+'</strong></span></li></ul>'+
                          '<p>&nbsp;</p> <ul><li>Commentaire :&nbsp;<span style="color: #ff0000;"><strong>'+dc.Infos_complementaires__c+'</strong></span></li></ul>'+
                          '<p>&nbsp;</p><strong>Cahier des charges</strong><ul>';// 
                          if (dc.Plus_1_Giga__c) {
                            htmlBody += '<li>Plus de CAR : +1Gwh ? :&nbsp;<span style="color: #ff0000;"><strong>Attention, le dossier fait plus de 1 GWh </strong></span></li>';
                          }
                         if (dc.Formula_plus_10_compteurs__c) {
                            htmlBody += '<li>Plus de 10 Compteurs ? :&nbsp;<span style="color: #ff0000;"><strong>Attention, le dossier contient plus de 10 compteurs</strong></span></li></ul>';
                         }
                        htmlBody += '</ul>';
                        
        mymail.setHtmlBody(htmlBody);
        
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mymail });
    }

    public class FlowInputs {
        @invocableVariable public Id recordId;
    } 
}