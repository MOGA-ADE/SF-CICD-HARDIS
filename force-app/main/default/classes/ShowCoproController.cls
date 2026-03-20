public with sharing class ShowCoproController {
  @AuraEnabled
  public static List<Account> retrieveCopro(String syndicId) {
    return [
      SELECT
        Id,
        Name,
        Adresse__c,
        Statut__c,
        (
          SELECT Id,ContactId, Roles, Numero_de_telephone__c, ContactName__c
          FROM AccountContactRelations
          WHERE Roles includes ('Gestionnaire de la copropriété')
        )
      FROM Account
      WHERE Syndic__c = :syndicId
    ];
  }

  @AuraEnabled
  public static Boolean deleteCoproRowAction(List<String> listCoproId) {
    if (listCoproId.size() > 0) {
      Database.DeleteResult[] srList = Database.delete(listCoproId, false);
      for (Database.DeleteResult sr : srList) {
        if (!sr.isSuccess()) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}