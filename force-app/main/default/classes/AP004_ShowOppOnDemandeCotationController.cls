public without sharing class AP004_ShowOppOnDemandeCotationController {

    @AuraEnabled
    public static List<Opportunity> getOppList(Id demandeCotationId){
        return [SELECT Name, StageName, Liste_Fournisseurs__c, RecordType.DeveloperName FROM Opportunity WHERE Demande_Cotation__c = :demandeCotationId ORDER BY Name];
    }

    @AuraEnabled
    public static List<Quote> getQuoteList(Id demandeCotationId){
        if(Schema.SObjectType.Quote.fields.TotalPrice.isAccessible()) {
            return [SELECT Fournisseur__c, TypeOffre__c, TotalPrice, Opportunity.Name FROM Quote WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE Demande_Cotation__c = :demandeCotationId) ORDER BY Opportunity.Name];
        } else {
            return [SELECT Fournisseur__c, TypeOffre__c, Opportunity.Name FROM Quote WHERE OpportunityId IN (SELECT Id FROM Opportunity WHERE Demande_Cotation__c = :demandeCotationId) ORDER BY Opportunity.Name];
        }
    }
}