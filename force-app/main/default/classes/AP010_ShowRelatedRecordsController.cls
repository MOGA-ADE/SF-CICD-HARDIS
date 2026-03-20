public without sharing class AP010_ShowRelatedRecordsController {

    @AuraEnabled
    public static List<Quote> getRelatedQuotes(Id recordId){
        Id oppId = [SELECT OpportunityId FROM Quote WHERE Id =: recordId LIMIT 1].OpportunityId;
        return [SELECT Name, Date_de_fin_de_contrat__c, toLabel(TypeOffre__c), GrandTotal, OpportunityId FROM Quote WHERE OpportunityId =: oppId AND Id != :recordId];
    }

    @AuraEnabled
    public static List<QuoteLineItem> getRelatedQLIs(Id recordId){
        Id oppId = [SELECT Opportunit__c FROM QuoteLineItem WHERE Id =: recordId LIMIT 1].Opportunit__c;
        return [SELECT Opportunit__c, TECH_IdentifiantPDE__c, DebutDeFourniture__c,toLabel(Quote.TypeOffre__c), Nouvelle_Echeance__c, TECH_fournisseur__c, Budget_TTC__c, CAR_New__c,CARGaz__c ,TECH_TypePDL__c,TECH_QLI_Remplie__c FROM QuoteLineItem WHERE Opportunit__c =: oppId AND Id != :recordId];
    }

    @AuraEnabled
    public static List<QuoteLineItem> getRelatedEndesaElecQLIs(Id recordId){
        return [SELECT TECH_PdeReference__c, Abonnement_Endesa_Elec_Souhaitee__c, Commission_Endesa_Elec_Souhaitee__c, Quote.Numero_Offre_API_Endesa_Elec__c FROM QuoteLineItem WHERE QuoteId =: recordId];
    }
}