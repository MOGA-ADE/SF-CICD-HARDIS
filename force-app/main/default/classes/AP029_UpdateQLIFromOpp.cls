public with sharing class AP029_UpdateQLIFromOpp {

    @InvocableMethod(label='Maj Opp QLI')
    public static List<FlowOutput> updateOppQli(List<FlowInputs> flowInputs) {

        List<FlowOutput> listOutput = new List<FlowOutput>();
        FlowOutput output = new FlowOutput();

        List<Quote> quotes = [SELECT Id FROM Quote WHERE OpportunityId = :flowInputs[0].OppId];

        List<Id> setQuoteIds = new List<Id>();

        for (Quote q : quotes) {
            setQuoteIds.add(q.Id);
        }
        
        List<QuoteLineItem> listQli = [
            SELECT Id, PDE__c, Puissance_souscrite__c,
                   Conso_Base__c, ConsoHC__c, Conso_HCE__c, Conso_HCH__c,
                   ConsoHP__c, Conso_HPE__c, Conso_HPH__c, Conso_Pointe__c,
                   DureeEngagement__c, DebutDeFourniture__c, Nouvelle_Echeance__c,
                   QuoteId, TECH_CalendrierFournisseur__c, TECH_Tarif__c,TECH_fournisseur__c,
                   CoutDeCapacite__c, T_QuoteCEE__c
            FROM QuoteLineItem
            WHERE QuoteId IN :setQuoteIds
        ];

        Set<Id> setPDEIds = new Set<Id>();
        for (QuoteLineItem qli : listQli) {
            if (qli.PDE__c != null) {
                setPDEIds.add(qli.PDE__c);
            }
        }

        List<PDE__c> pdes = [
            SELECT Id, Puissance_souscrite__c, Conso_Base__c, ConsoHC__c,
                   Conso_HCE__c, Conso_HCH__c, ConsoHP__c,
                   Conso_HPE__c, Conso_HPH__c, Conso_Pointe__c,
                   Consommation_Annuelle_de_R_f_rence_Elec__c, CARGaz__c,
                   DateEcheance__c, Calendrier_fournisseur__c, Tarif__c,
                   TypePDE__c
            FROM PDE__c
            WHERE Id IN :setPDEIds
        ];

        updateqli(listQli, pdes);

        output.message = listQli.size() + ' QLI mis à jour.';
        listOutput.add(output);
        return listOutput;
    }

    public class FlowInputs {
        @InvocableVariable public String OppId;
    }

    public class FlowOutput {
        @InvocableVariable public String message;
    }

    // Méthode utilitaire pour mettre à jour les QuoteLineItems avec les données des PDE
    public static void updateqli(List<QuoteLineItem> qlis, List<PDE__c> pdes) {
        Map<Id, PDE__c> mapPdeById = new Map<Id, PDE__c>();
        for (PDE__c pde : pdes) {
            mapPdeById.put(pde.Id, pde);
        }

        Valeur_Annuelle__mdt customMetadataRecord = [SELECT CTA_T1__c,
                                                    CTA_T2__c,
                                                    CTA_T3__c,
                                                    CTA_T4__c,
                                                    CSPE_PuissanceInfOuEgal36Kva__c,
                                                    CSPE_PuissanceSup36OuEgal250__c,
                                                    CSPE_PuissanceSup250__c,
                                                    TICGN__c,
                                                    Frais_Transport_Distribution_Capacite_T1__c,
                                                    Frais_Transport_Distribution_Capacite_T2__c,
                                                    Frais_Transport_Distribution_Capacite_T3__c,
                                                    Frais_Transport_Distribution_Capacite_T4__c
                                                 FROM 
                                                    Valeur_Annuelle__mdt
                                                 LIMIT 1];
        /*
        Enchere_de_capacite__mdt customMetadataEnchereCapacite = [SELECT Montant__c
                                                    FROM 
                                                        Enchere_de_capacite__mdt
                                                    LIMIT 1   
                                                ];
        */

        Map<String,Double> mapFournisseurCEEGaz = new Map<String,Double>();
        Map<String,Double> mapFournisseurCEEElec =  new Map<String,Double>();
        for(CEE_Fournisseur__mdt CEEFournisseur : [SELECT CEE__c, Fournisseur__c, Type_energie__c FROM CEE_Fournisseur__mdt]){
            if (CEEFournisseur.Type_energie__c == 'Gaz') {
                mapFournisseurCEEGaz.put(CEEFournisseur.Fournisseur__c, CEEFournisseur.CEE__c);
            } else { // For 'Elec' Energy Type
                mapFournisseurCEEElec.put(CEEFournisseur.Fournisseur__c, CEEFournisseur.CEE__c);
            }
        }

        for (QuoteLineItem qli : qlis) {
            PDE__c pde = mapPdeById.get(qli.PDE__c);
            /*
            update dans QuoteLineItemTriggerHandler (Trigger after insert and update)
            qli.CoutDeCapacite__c = customMetadataEnchereCapacite != null ? customMetadataEnchereCapacite.Montant__c : 0;
            */
            if (pde != null) {
                Boolean isTypePDEGaz = (pde.TypePDE__c == 'Gaz');
                Map<String, Double> CEEValByCEEFournisseur = isTypePDEGaz ? mapFournisseurCEEGaz : mapFournisseurCEEElec;
                qli.Puissance_souscrite__c        = pde.Puissance_souscrite__c;
                qli.Conso_Base__c                 = pde.Conso_Base__c;
                qli.ConsoHC__c                    = pde.ConsoHC__c;
                qli.Conso_HCE__c                  = pde.Conso_HCE__c;
                qli.Conso_HCH__c                  = pde.Conso_HCH__c;
                qli.ConsoHP__c                    = pde.ConsoHP__c;
                qli.Conso_HPE__c                  = pde.Conso_HPE__c;
                qli.Conso_HPH__c                  = pde.Conso_HPH__c;
                qli.Conso_Pointe__c               = pde.Conso_Pointe__c;
                qli.DebutDeFourniture__c          = pde.DateEcheance__c != null ? pde.DateEcheance__c  + 1 : null;
                //qli.TECH_CalendrierFournisseur__c = pde.Calendrier_fournisseur__c;
                // version in SM001_GestionDevis
                if(pde.Calendrier_fournisseur__c == 'HP/HC' || pde.Calendrier_fournisseur__c == 'Heures Pleines/Creuses'){
                    qli.TECH_CalendrierFournisseur__c = 'HP/HC';
                }
                else if(pde.Calendrier_fournisseur__c == 'Base' || pde.Calendrier_fournisseur__c != ''){
                    qli.TECH_CalendrierFournisseur__c = 'Base';
                }

                if(isTypePDEGaz) {
                    if(pde.Tarif__c == 'T1'){
                        qli.CTA__c = customMetadataRecord.CTA_T1__c;
                        qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T1__c;
                    } else if(pde.Tarif__c == 'T2'){
                        qli.CTA__c = customMetadataRecord.CTA_T2__c;
                        qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T2__c;
                    } else if(pde.Tarif__c == 'T3'){
                        qli.CTA__c = customMetadataRecord.CTA_T3__c;
                        qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T3__c;
                    } else if(pde.Tarif__c == 'T4'){
                        qli.CTA__c = customMetadataRecord.CTA_T4__c;
                        qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T4__c;
                    } else {
                        qli.CTA__c = 1;
                        qli.FraisTransportDistributionCapacite__c = 1;
                    }
                    qli.CARGaz__c = pde.CARGaz__c;
                    qli.TICGN__c = customMetadataRecord.TICGN__c; 
                }
                else{
                    if(pde.Puissance_souscrite__c <= 36){
                        qli.CSPE__c = customMetadataRecord.CSPE_PuissanceInfOuEgal36Kva__c;
                    }
                    else if (pde.Puissance_souscrite__c > 36 && pde.Puissance_souscrite__c <= 250 ){
                        qli.CSPE__c = customMetadataRecord.CSPE_PuissanceSup36OuEgal250__c;
                    }
                    else {
                        qli.CSPE__c = customMetadataRecord.CSPE_PuissanceSup250__c;
                    }
                    // update dans QuoteLineItemTriggerHandler
                    //qli.CAR_New__c = pde.Consommation_Annuelle_de_R_f_rence_Elec__c;
                }
                
                if (qli.T_QuoteCEE__c != 'Non Soumis' && CEEValByCEEFournisseur.containsKey(qli.TECH_fournisseur__c)) {
                    qli.CeeMwh__c = CEEValByCEEFournisseur.get(qli.TECH_fournisseur__c);
                }

                if(qli.TECH_fournisseur__c.equals('Situation Actuelle')) {
                    qli.Nouvelle_Echeance__c = qli.DebutDeFourniture__c.addDays(-1);
                }
            }
        }
        update qlis;
    }

}