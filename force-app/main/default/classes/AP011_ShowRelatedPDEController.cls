public with sharing class AP011_ShowRelatedPDEController {
    
    @AuraEnabled
    public static List<PDE__c> getRelatedPDEElec(Id recordId){
        return [SELECT Id, Name, Siret_payeur__c,Contrat_actif__c,ReferencePointEnergie_Refonte__c, TypePDE__c, DateEcheance__c, Adresse_de_consommation__c,Consommation_Annuelle_de_R_f_rence_Elec__c,EntiteJuridique__c   FROM PDE__c WHERE EntiteJuridique__c =: recordId AND TypePDE__c <> 'Gaz' LIMIT 11];
    }

    @AuraEnabled
    public static List<PDE__c> getRelatedPDEGaz(Id recordId){
        return [SELECT Id, Name, Siret_payeur__c,Contrat_actif__c,PCE_Refonte__c, TypePDE__c, DateEcheance__c, Adresse_de_consommation__c,CARGaz__c,EntiteJuridique__c   FROM PDE__c WHERE EntiteJuridique__c =: recordId AND TypePDE__c = 'Gaz' LIMIT 11];
    }
}