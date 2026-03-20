public without sharing class DM000_QueryManager {
  /*** *** QUERY ON OPPORTUNITY OBJECT *** ***/
  public static Opportunity getOpportunityById(String opportunityId) {
    Opportunity opportunityRecord = new Opportunity();
    opportunityRecord = [
      SELECT Id, AccountId, TemplateCotation__c
      FROM Opportunity
      WHERE Id = :opportunityId
    ];
    return opportunityRecord;
  }

  /*** *** QUERY ON QUOTE OBJECT *** ***/
  public static Quote getQuoteById(String quotId) {
    Quote quoteRecord = new Quote();
    quoteRecord = [SELECT Id, OpportunityId FROM Quote WHERE Id = :quotId];
    return quoteRecord;
  }

  public static List<Quote> getQuoteByOpportunity(String opportId) {
    List<Quote> quoteList = new List<Quote>();
    quoteList = [
      SELECT Id, Name, Status, OpportunityId
      FROM Quote
      WHERE OpportunityId = :opportId
    ];
    return quoteList;
  }

  /*** *** QUERY ON QUOTELINEITEM OBJECT *** ***/
  public static QuoteLineItem getQuoteLineItemById(String QuoteLineItemId) {
    QuoteLineItem quoteLineItemRecord = new QuoteLineItem();
    quoteLineItemRecord = [
      SELECT Id, QuoteId
      FROM QuoteLineItem
      WHERE Id = :QuoteLineItemId
    ];
    return quoteLineItemRecord;
  }

  public static List<QuoteLineItem> getQuoteLineItemByQuote(
    Set<String> quoteIds
  ) {
    List<QuoteLineItem> quoteLineItemList = new List<QuoteLineItem>();
    quoteLineItemList = [
      SELECT
        Id,
        LineNumber,
        AbonnementMois__c,
        BudgetHTTan__c,
        QuoteId,
        PDE__c,
        PDE__r.ReferencePointEnergie_Refonte__c,
        PDE__r.PCE_Refonte__c,
        PDE__r.TypePDE__c,
        CAR_New__c,
        CARGaz__c,
        BudgetFourniture__c,
        BudgetObligationsMWH__c
      FROM QuoteLineItem
      WHERE QuoteId IN :quoteIds
    ];
    return quoteLineItemList;
  }

  @AuraEnabled
  public static List<CodeNAF__c> getListCodeNaf(){
    return [SELECT Name,Description__c FROM CodeNAF__c ORDER BY Name];
  }

  @AuraEnabled
  public static List<Account> searchAccount(String accountName,String codeNaf){
      if(accountName != ''){
        String name = '%'+accountName+'%';
        return [SELECT Name,
                       Owner.Name,
                       Owner.Email,
                       Owner.Phone,
                       Code_NAF__r.Name 
                FROM Account
                WHERE Name
                LIKE :name
                AND RecordType.DeveloperName != 'Copropriete'];
      } else {
        return [SELECT  Name,
                        Owner.Name,
                        Owner.Email,
                        Owner.Phone,
                        Code_NAF__r.Name 
                FROM Account
                WHERE Code_NAF__r.Name = :codeNaf
                AND RecordType.DeveloperName != 'Copropriete'];
      }
  }
}