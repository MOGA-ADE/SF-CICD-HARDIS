public without sharing class AP008_AddPriceFTAFournisseurController {
    
    @AuraEnabled
    public static PricebookEntry getPriceBookEntry(){
        Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
        return [SELECT Product2Id FROM PricebookEntry WHERE Name = 'ELEC' AND Pricebook2Id = :pb.Id LIMIT 1];
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityPDERelation__c> getOPRDetails(Id oppId){
        return [SELECT  PDE__c, 
                        PDE__r.FTA__c, 
                        PDE__r.Puissance_souscrite__c, 
                        PDE__r.Conso_Base__c,
                        PDE__r.ConsoHC__c,
                        PDE__r.Conso_HCE__c,
                        PDE__r.Conso_HCH__c,
                        PDE__r.ConsoHP__c,
                        PDE__r.Conso_HPE__c,
                        PDE__r.Conso_HPH__c,
                        PDE__r.Conso_Pointe__c,
                        PDE__r.DateEcheance__c,
                        PDE__r.Segment__c,
                        PDE__r.TypePDE__c
                FROM OpportunityPDERelation__c 
                WHERE Opportunity__c = :oppId];
    }

    @AuraEnabled(cacheable=true)
    public static List<QuoteWrapper> getQuoteWrappers(Id oppId){

        List<QuoteWrapper> quoteWrapperList = new List<QuoteWrapper>();
        List<FtaWrapper> ftas = new List<FtaWrapper>();
        Set<String> FtaAlreadyAdded = new Set<String>();
        List<Quote> listQuote = [SELECT Fournisseur__c,
                                        QuoteNumber,(SELECT Id,
                                                            Nouvelle_Echeance__c,
                                                            AbonnementMois__c,
                                                            CeeMwh__c,
                                                            CSPE__c,
                                                            TDCFE__c,
                                                            TCCFE__c,
                                                            Capa_HP__c,
                                                            Capa_HC__c,
                                                            Capa_HPH__c,
                                                            Capa_HCH__c,
                                                            Capa_HPE__c,
                                                            Capa_HCE__c,
                                                            Capa_Base__c,
                                                            PDE__r.FTA__c,
                                                            PrixHP__c,
                                                            PrixHC__c,
                                                            PrixHphMwh__c,
                                                            PrixHchMwh__c,
                                                            PrixHpeMwh__c,
                                                            PrixHceMwh__c,
                                                            PrixBase__c,
                                                            PointesMWh__c,
                                                            Capa_Pointes__c
                                                        FROM QuoteLineItems)
                                    FROM Quote 
                                    WHERE OpportunityId = :oppId];
        List<OpportunityPDERelation__c> oprList = [SELECT PDE__r.FTA__c,PDE__r.Puissance_souscrite__c FROM OpportunityPDERelation__c WHERE Opportunity__c = :oppId];
        List<QuoteLineItem> qliList = [SELECT Id FROM QuoteLineItem WHERE Opportunit__c =:oppId limit 1];
        Map<Quote, List<QuoteLineItem>> mapQuoteListQLI = new Map<Quote, List<QuoteLineItem>>();
        Valeur_Annuelle__mdt valeurCSPE = [SELECT 
                                                CSPE_PuissanceInfOuEgal36Kva__c,
                                                CSPE_PuissanceSup36OuEgal250__c,
                                                CSPE_PuissanceSup250__c 
                                            FROM 
                                                Valeur_Annuelle__mdt
                                            LIMIT 1];


        if(!qliList.isEmpty()){

            for(Quote quote : listQuote) {
                List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
                // Récupérer les QLI associées à chaque Quote
                for(QuoteLineItem qli : quote.QuoteLineItems) {
                    quoteLineItems.add(qli);
                }
                // Stocker les QLI dans la Map, associées à leur Quote respective
                mapQuoteListQLI.put(quote, quoteLineItems);
            }

            for(Quote quote: mapQuoteListQLI.keySet()){
                for (QuoteLineItem qli : quote.QuoteLineItems) {        
                    FtaWrapper ftaw = new FtaWrapper();
                    ftaw.name = qli.PDE__r.FTA__c;
                    if (FtaAlreadyAdded.contains(qli.PDE__r.FTA__c)) continue;

        
                    if (ftaw.name == 'BT <= 36 kVA - CU') {
                        ftaw.hasCapaciteHPH = false;
                        ftaw.hasCapaciteHCH = false;
                        ftaw.hasCapaciteHPE = false;
                        ftaw.hasCapaciteHCE = false;
                        ftaw.hasCapaciteHP = false;
                        ftaw.hasCapaciteHC = false;
                        ftaw.hasPrixHPH = false;
                        ftaw.hasPrixHCH = false;
                        ftaw.hasPrixHPE = false;
                        ftaw.hasPrixHCE = false;
                        ftaw.hasPrixHP = false;
                        ftaw.hasPrixHC = false;
                        ftaw.hasPointe = false;
                        ftaw.hasCapacitePointe = false;
                        ftaw.hasPrixHC = false;
                        ftaw.oldValueAbonnement = qli.AbonnementMois__c;
                        ftaw.oldValueCEE = qli.CeeMwh__c;
                        ftaw.oldValueCapaciteBase = qli.Capa_Base__c;
                        ftaw.oldValuePrixBase = qli.PrixBase__c;
                        ftaw.oldValueCSPE = qli.CSPE__c;
                    } else if (ftaw.name == 'BT <= 36 kVA - MU') {
                        ftaw.hasTDCFE = false;
                        ftaw.hasTCCFE = false;
                        ftaw.hasCapaciteHPH = false;
                        ftaw.hasCapaciteHCH = false;
                        ftaw.hasCapaciteHPE = false;
                        ftaw.hasCapaciteHCE = false;
                        ftaw.hasCapaciteBase = false;
                        ftaw.hasPrixHPH = false;
                        ftaw.hasPrixHCH = false;
                        ftaw.hasPrixHPE = false;
                        ftaw.hasPrixHCE = false;
                        ftaw.hasPrixBase = false;
                        ftaw.hasPointe = false;
                        ftaw.hasCapacitePointe = false;
                        ftaw.oldValueAbonnement = qli.AbonnementMois__c;
                        ftaw.oldValueCEE = qli.CeeMwh__c;
                        ftaw.oldValueCapaciteHP = qli.Capa_HP__c;
                        ftaw.oldValueCapaciteHC = qli.Capa_HC__c;
                        ftaw.oldValuePrixHP = qli.PrixHP__c;
                        ftaw.oldValuePrixHC = qli.PrixHC__c;
                        ftaw.oldValueCSPE = qli.CSPE__c;
                    } else if (ftaw.name == 'BT <= 36Kva - CU 4 postes' || ftaw.name == 'BT <= 36Kva - MU 4 postes') {
                        ftaw.hasPointe = false;
                        ftaw.hasCapacitePointe = false;
                        ftaw.hasCapaciteBase = false;
                        ftaw.hasCapaciteHP = false;
                        ftaw.hasCapaciteHC = false;
                        ftaw.hasPrixBase = false;
                        ftaw.hasPrixHP = false;
                        ftaw.hasPrixHC = false;
                        ftaw.oldValueAbonnement = qli.AbonnementMois__c;
                        ftaw.oldValueCEE = qli.CeeMwh__c;
                        ftaw.oldValueCapaciteHPH = qli.Capa_HPH__c;
                        ftaw.oldValueCapaciteHCH = qli.Capa_HPH__c;
                        ftaw.oldValueCapaciteHPE = qli.Capa_HPE__c;
                        ftaw.oldValueCapaciteHCE = qli.Capa_HCE__c;
                        ftaw.oldValuePrixHPH = qli.PrixHphMwh__c;
                        ftaw.oldValuePrixHCH = qli.PrixHchMwh__c;
                        ftaw.oldValuePrixHPE = qli.PrixHpeMwh__c;
                        ftaw.oldValuePrixHCE = qli.PrixHceMwh__c;
                        ftaw.oldValueCSPE = qli.CSPE__c;
                    } else if ( ftaw.name == 'HTA - PF - CU' || ftaw.name == 'HTA - PF - LU' || 
                                ftaw.name == 'HTA - PM - CU' || ftaw.name == 'HTA - PM - LU' || 
                                ftaw.name == 'BT > 36 kVA - CU' || ftaw.name == 'BT > 36 kVA - LU' ) {
                        ftaw.hasCapaciteBase = false;
                        ftaw.hasCapaciteHP = false;
                        ftaw.hasCapaciteHC = false;
                        ftaw.hasPrixBase = false;
                        ftaw.hasPrixHP = false;
                        ftaw.hasPrixHC = false;
                        ftaw.oldValueAbonnement = qli.AbonnementMois__c;
                        ftaw.oldValueCEE = qli.CeeMwh__c;
                        ftaw.oldValueCapaciteHPH = qli.Capa_HPH__c;
                        ftaw.oldValueCapaciteHCH = qli.Capa_HPH__c;
                        ftaw.oldValueCapaciteHPE = qli.Capa_HPE__c;
                        ftaw.oldValueCapaciteHCE = qli.Capa_HCE__c;
                        ftaw.oldValueCapacitePointe = qli.Capa_Pointes__c;
                        ftaw.oldValuePrixHPH = qli.PrixHphMwh__c;
                        ftaw.oldValuePrixHCH = qli.PrixHchMwh__c;
                        ftaw.oldValuePrixHPE = qli.PrixHpeMwh__c;
                        ftaw.oldValuePrixHCE = qli.PrixHceMwh__c;
                        ftaw.oldValuePointe = qli.PointesMWh__c;
                        ftaw.oldValueCSPE = qli.CSPE__c;
                    }
        
                    ftas.add(ftaw);
                    FtaAlreadyAdded.add(ftaw.name);
                }
                QuoteWrapper qw = new QuoteWrapper();
                qw.name = quote.Fournisseur__c + ' - ' + quote.QuoteNumber;
                qw.id = quote.Id;
                qw.ftas = ftas;
                quoteWrapperList.add(qw);
                ftas = new List<FtaWrapper>();
                FtaAlreadyAdded = new Set<String>();
            }
        }
        else{
            for (OpportunityPDERelation__c opr : oprList) {

                if (FtaAlreadyAdded.contains(opr.PDE__r.FTA__c)) continue;
    
                FtaWrapper ftaw = new FtaWrapper();
                ftaw.name = opr.PDE__r.FTA__c;
    
                if (ftaw.name == 'BT <= 36 kVA - CU') {
                    ftaw.hasCapaciteHPH = false;
                    ftaw.hasCapaciteHCH = false;
                    ftaw.hasCapaciteHPE = false;
                    ftaw.hasCapaciteHCE = false;
                    ftaw.hasCapaciteHP = false;
                    ftaw.hasCapaciteHC = false;
                    ftaw.hasPrixHPH = false;
                    ftaw.hasPrixHCH = false;
                    ftaw.hasPrixHPE = false;
                    ftaw.hasPrixHCE = false;
                    ftaw.hasPrixHP = false;
                    ftaw.hasPrixHC = false;
                    ftaw.hasPointe = false;
                    ftaw.hasCapacitePointe = false;
                    ftaw.hasPrixHC = false;
                } else if (ftaw.name == 'BT <= 36 kVA - MU') {
                    ftaw.hasTDCFE = false;
                    ftaw.hasTCCFE = false;
                    ftaw.hasCapaciteHPH = false;
                    ftaw.hasCapaciteHCH = false;
                    ftaw.hasCapaciteHPE = false;
                    ftaw.hasCapaciteHCE = false;
                    ftaw.hasCapaciteBase = false;
                    ftaw.hasPrixHPH = false;
                    ftaw.hasPrixHCH = false;
                    ftaw.hasPrixHPE = false;
                    ftaw.hasPrixHCE = false;
                    ftaw.hasPrixBase = false;
                    ftaw.hasPointe = false;
                    ftaw.hasCapacitePointe = false;
                } else if (ftaw.name == 'BT <= 36Kva - CU 4 postes' || ftaw.name == 'BT <= 36Kva - MU 4 postes') {
                    ftaw.hasPointe = false;
                    ftaw.hasCapacitePointe = false;
                    ftaw.hasCapaciteBase = false;
                    ftaw.hasCapaciteHP = false;
                    ftaw.hasCapaciteHC = false;
                    ftaw.hasPrixBase = false;
                    ftaw.hasPrixHP = false;
                    ftaw.hasPrixHC = false;
                } else if ( ftaw.name == 'HTA - PF - CU' || ftaw.name == 'HTA - PF - LU' || 
                            ftaw.name == 'HTA - PM - CU' || ftaw.name == 'HTA - PM - LU' || 
                            ftaw.name == 'BT > 36 kVA - CU' || ftaw.name == 'BT > 36 kVA - LU' ) {
                    ftaw.hasCapaciteBase = false;
                    ftaw.hasCapaciteHP = false;
                    ftaw.hasCapaciteHC = false;
                    ftaw.hasPrixBase = false;
                    ftaw.hasPrixHP = false;
                    ftaw.hasPrixHC = false;
                }

                

                if(opr.PDE__r.Puissance_souscrite__c <= 36){
                    ftaw.oldValueCSPE = valeurCSPE.CSPE_PuissanceInfOuEgal36Kva__c;
                  }
                  else if (opr.PDE__r.Puissance_souscrite__c > 36 && opr.PDE__r.Puissance_souscrite__c <= 250 ){
                    ftaw.oldValueCSPE = valeurCSPE.CSPE_PuissanceSup36OuEgal250__c;
                  }
                  else {
                    ftaw.oldValueCSPE = valeurCSPE.CSPE_PuissanceSup250__c;
                  }
    
                ftas.add(ftaw);
                FtaAlreadyAdded.add(ftaw.name);
            }
            for (Quote quote : listQuote) {
                QuoteWrapper qw = new QuoteWrapper();
                qw.name = quote.Fournisseur__c + ' - ' + quote.QuoteNumber;
                qw.id = quote.Id;
                qw.ftas = ftas;
                quoteWrapperList.add(qw);
            }
        }
        return quoteWrapperList.isEmpty() ? null : quoteWrapperList;
    }

    @AuraEnabled
    public static Boolean insertListQLI(List<QuoteLineItem> qlis){

        // Supprimer les anciennes QLI des quotes associés aux nouvelles QLI
        Set<Id> quoteIds = new Set<Id>();

        for (QuoteLineItem qli : qlis) {
            quoteIds.add(qli.QuoteId);
        }

        List<QuoteLineItem> qliToDelete = [SELECT Id FROM QuoteLineItem WHERE QuoteId IN :quoteIds];

        if (!qliToDelete.isEmpty()) {
            delete qliToDelete;
        }

        // Insérer les nouvelles QLI
        Boolean allSuccess = true;
        Database.SaveResult[] srList = Database.insert(qlis, true);
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                allSuccess = false;
                return allSuccess;
            }
        }
        return allSuccess;
    }

    @AuraEnabled(cacheable=true)
    public static Valeur_Annuelle__mdt getValeurCSPE() {
        return [SELECT  CTA_T1__c,
                        CTA_T2__c,
                        CTA_T3__c,
                        CTA_T4__c,
                        CSPE_PuissanceInfOuEgal36Kva__c,
                        CSPE_PuissanceSup36OuEgal250__c,
                        CSPE_PuissanceSup250__c,
                        Frais_Transport_Distribution_Capacite_T1__c,
                        Frais_Transport_Distribution_Capacite_T2__c,
                        Frais_Transport_Distribution_Capacite_T3__c,
                        Frais_Transport_Distribution_Capacite_T4__c
                FROM 
                    Valeur_Annuelle__mdt
                LIMIT 1];
    }

    public class QuoteWrapper {
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public Id id {get; set;}
        @AuraEnabled public List<FtaWrapper> ftas {get; set;}
    }

    public class FtaWrapper {
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public Boolean hasAbonnement = true;
        @AuraEnabled public Boolean hasCSPE = true;
        @AuraEnabled public Boolean hasCEE = true;
        @AuraEnabled public Boolean hasTDCFE = true;
        @AuraEnabled public Boolean hasTCCFE = true;
        @AuraEnabled public Boolean hasCapaciteHP = true;
        @AuraEnabled public Boolean hasCapaciteHC = true;
        @AuraEnabled public Boolean hasCapaciteHPH = true;
        @AuraEnabled public Boolean hasCapaciteHCH = true;
        @AuraEnabled public Boolean hasCapaciteHPE = true;
        @AuraEnabled public Boolean hasCapaciteHCE = true;
        @AuraEnabled public Boolean hasCapaciteBase = true;
        @AuraEnabled public Boolean hasPrixHP = true;
        @AuraEnabled public Boolean hasPrixHC = true;
        @AuraEnabled public Boolean hasPrixHPH = true;
        @AuraEnabled public Boolean hasPrixHCH = true;
        @AuraEnabled public Boolean hasPrixHPE = true;
        @AuraEnabled public Boolean hasPrixHCE = true;
        @AuraEnabled public Boolean hasPrixBase = true;
        @AuraEnabled public Boolean hasPointe = true;
        @AuraEnabled public Boolean hasCapacitePointe = true;
        @auraEnabled public Double oldValueAbonnement = 0;
        @auraEnabled public Double oldValueCSPE = 0;
        @auraEnabled public Double oldValueCEE = 0;
        @auraEnabled public Double oldValueTDCFE = 0;
        @auraEnabled public Double oldValueTCCFE = 0;
        @auraEnabled public Double oldValueCapaciteHP = 0;
        @auraEnabled public Double oldValueCapaciteHC = 0;
        @auraEnabled public Double oldValueCapaciteHPH = 0;
        @auraEnabled public Double oldValueCapaciteHCH = 0;
        @auraEnabled public Double oldValueCapaciteHPE = 0;
        @auraEnabled public Double oldValueCapaciteHCE = 0;
        @auraEnabled public Double oldValueCapaciteBase = 0;
        @auraEnabled public Double oldValuePrixHP = 0;
        @auraEnabled public Double oldValuePrixHC = 0;
        @auraEnabled public Double oldValuePrixHPH = 0;
        @auraEnabled public Double oldValuePrixHCH = 0;
        @auraEnabled public Double oldValuePrixHPE = 0;
        @auraEnabled public Double oldValuePrixHCE = 0;
        @auraEnabled public Double oldValuePrixBase = 0;
        @auraEnabled public Double oldValuePointe = 0;
        @auraEnabled public Double oldValueCapacitePointe = 0;
    }
}