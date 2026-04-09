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
                       Code_NAF__r.Name,
                       Statut__c  
                FROM Account
                WHERE Name
                LIKE :name
                AND RecordType.DeveloperName != 'Copropriete'];
      } else {
        return [SELECT  Name,
                        Owner.Name,
                        Owner.Email,
                        Owner.Phone,
                        Code_NAF__r.Name,
                        Statut__c 
                FROM Account
                WHERE Code_NAF__r.Name = :codeNaf
                AND RecordType.DeveloperName != 'Copropriete'];
      }
  }

  @AuraEnabled(cacheable=true)
  public static Boolean isLeadAlreadyClient(String siret, String postalCode) {
    if (String.isBlank(siret)) {
        return false;
    }

    List<Account> matchingAccounts = [
        SELECT Id, RecordType.Name, Statut__c
        FROM Account
        WHERE SIRET__c = :siret
        AND (RecordType.DeveloperName = 'Syndic' 
        OR Owner.isActive = true)
    ];

    if (matchingAccounts.isEmpty()) {
        return false;
    }

    // Vérifie si le code postal de la piste est dans un département interdit pour les syndics
    Boolean isLeadInForbiddenDept = false;
    if (String.isNotBlank(postalCode)) {
        Map<String, Departement_syndic__c> mcs = Departement_syndic__c.getAll();
        for (Departement_syndic__c dep : mcs.values()) {
            if (postalCode.startsWith(dep.Departement__c)) {
                isLeadInForbiddenDept = true;
                break;
            }
        }
    }

    for (Account acc : matchingAccounts) {
        // Compte Syndic et la piste est dans un département interdit aux doublons
        if (acc.RecordType.Name == 'Syndic' && isLeadInForbiddenDept) {
            return true;
        }

        // Compte avec statut Client
        if (acc.Statut__c == 'Client') {
            return true;
        }
    }

    return false;
  }


}