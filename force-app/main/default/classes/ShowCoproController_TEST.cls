@isTest
public with sharing class ShowCoproController_TEST {
  @TestSetup
  static void createTestData() {
    TestDataFactory.createSyndicsWithCoprosAndPointDenergie(1,1,1,1);
  }

  @IsTest
  static void retrieveCoproTest() {
    Id syndicId = [
      SELECT Id
      FROM Account
      WHERE RecordType.DeveloperName = 'Syndic'
      LIMIT 1
    ]
    .Id;
    Test.startTest();
    List<Account> listCopro = ShowCoproController.retrieveCopro(syndicId);
    System.assertEquals(1, listCopro.size());
    Test.stopTest();
  }
  @IsTest
  static void deleteCoproTest() {
    Id syndicId = [
      SELECT Id
      FROM Account
      WHERE RecordType.DeveloperName = 'Syndic'
      LIMIT 1
    ]
    .Id;
    List<Id> listCopros = new List<Id>();
    List<Id> listCoprosEmpty = new List<Id>();
    for(Account acc:[SELECT Id FROM Account WHERE Syndic__c =:syndicId]){
        listCopros.add(acc.Id);
    }
    Test.startTest();
    System.assertEquals(true, ShowCoproController.deleteCoproRowAction(listCopros));
    System.assertEquals(false, ShowCoproController.deleteCoproRowAction(listCoprosEmpty));
    List<Account> listCopro = [SELECT Id FROM Account WHERE Syndic__c =:syndicId];
    System.assertEquals(0, listCopro.size());
    Test.stopTest();
  }
}