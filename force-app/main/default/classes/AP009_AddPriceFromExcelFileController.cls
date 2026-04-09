public with sharing class AP009_AddPriceFromExcelFileController {
    @AuraEnabled(cacheable=true)
    public static List<Quote> retrieveQuote(String recordId) {
        return [
            SELECT
                Id,
                Fournisseur__c,
                TypeOffre__c
            FROM 
                Quote
            WHERE
            OpportunityId = :recordId
          ];
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityPDERelation__c> retrieveOPR(String recordId){
        System.Debug('recordId');
        return [
            SELECT
                PDE__c,
                PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c,
                PDE__r.CARGaz__c,
                PDE__r.Conso_Base__c,
                PDE__r.ConsoHC__c,
                PDE__r.ConsoHP__c,
                PDE__r.Conso_HCE__c,
                PDE__r.Conso_HCH__c,
                PDE__r.Conso_HPE__c,
                PDE__r.Conso_HPH__c,
                PDE__r.Conso_Pointe__c,
                PDE__r.DateEcheance__c,
                PDE__r.Puissance_souscrite__c,
                PDE__r.TECH_num_compteur__c,
                toLabel(PDE__r.Tarif__c),
                PDE__r.Segment__c,
                Opportunity__r.TemplateCotation__c
            FROM
                OpportunityPDERelation__c
            WHERE
                Opportunity__c =: recordId
        ];
    }

@AuraEnabled(cacheable=true)
    public static List<QuoteLineItem> retrievePriceQLI(String recordId){
        System.Debug('recordId');
        return [
            SELECT
                Id,
                AbonnementMois__c,
                CARGaz__c,
                CAR_New__c,
                Capa_Base__c,
                Capa_Pointes__c,
                Capa_HC__c,
                Capa_HCE__c,
                Capa_HCH__c,
                Capa_HP__c,
                Capa_HPE__c,
                Capa_HPH__c,
                CeeMwh__c,

                Conso_Base__c,
                Conso_Pointe__c,
                ConsoHC__c,
                Conso_HCE__c,
                Conso_HCH__c,
                ConsoHP__c,
                Conso_HPE__c,
                Conso_HPH__c,
                CoutDeCapacite__c,

                DebutDeFourniture__c,


                Puissance_souscrite__c,

                TECH_Segment__c,
                TECH_IdentifiantPDE__c,
                TECH_Tarif__c,
                TECH_fournisseur__c,
                TECH_TypeOffre__c,

                Nouvelle_Echeance__c,

                PointesMWh__c,
                PrixBase__c,
                PrixHC__c,
                PrixHceMwh__c,
                PrixHchMwh__c,
                PrixHP__c,
                PrixHpeMwh__c,
                PrixHphMwh__c,
                PrixMolecule__c,

                QuoteId,
                Quote.Name, 
                Quote.OpportunityId,
                Quote.Opportunity.Name,
                Quote.Opportunity.TemplateCotation__c,

                PDE__c,
                PDE__r.DateEcheance__c

            FROM
                QuoteLineItem
            WHERE
                Quote.OpportunityId =: recordId
        ];
    }


    @AuraEnabled
    public static Boolean insertListQLI(List<QuoteLineItem> qlis,String oppId){
        Boolean allSuccess = true;
        delete [SELECT Id from QuoteLineItem where TECH_OpportunityId__c=: oppId];
        // Insérer les nouvelles QLI
        Database.SaveResult[] srList = Database.insert(qlis, true);
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {
                allSuccess = false;
                return allSuccess;
            }
        }
        return allSuccess;
    }

    @AuraEnabled
    public static PricebookEntry getPriceBookEntryGaz(){
        Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
        return [SELECT Product2Id FROM PricebookEntry WHERE Name = 'GAZ' AND Pricebook2Id = :pb.Id LIMIT 1];
    }

    @AuraEnabled
    public static PricebookEntry getPriceBookEntryElec(){
        Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
        return [SELECT Product2Id FROM PricebookEntry WHERE Name = 'ELEC' AND Pricebook2Id = :pb.Id LIMIT 1];
    }
}