public with sharing class ShowQLIOnOpportController {
  @AuraEnabled
  public static List<QuoteLineItem> retrieveQLI(String recordId) {
    return [
      SELECT
        Id,
        LineNumber,
        PDE__r.ReferencePointEnergie_Refonte__c,
        PDE__r.PCE_Refonte__c,
        TECH_TypeOffre__c,
        TECH_fournisseur__c,
        QuoteId,
        Quote.Name,
        TECH_RT__c,
        UnitPrice,
        DebutDeFourniture__c,
        Nouvelle_Echeance__c
      FROM QuoteLineItem
      WHERE TECH_OpportunityId__c = :recordId
    ];
  }
}