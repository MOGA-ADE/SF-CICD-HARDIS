@isTest
public with sharing class OpportunityPDERelTriggerHandler_Test {
  @TestSetup
  static void makeData() {
    TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
  }
  @isTest
  private static void AfterCreateTest() {
    Test.startTest();
    Opportunity opp = [
      SELECT Id, Nombre_de_PDE__c
      FROM Opportunity
      LIMIT 1
    ];
    Test.stopTest();
    System.assertEquals(3, opp.Nombre_de_PDE__c);
  }

  @isTest
  private static void testAfterDelete() {
    Test.startTest();
    delete [SELECT Id FROM OpportunityPDERelation__c];
    Test.stopTest();
    System.assertEquals(
      0,
      [SELECT Nombre_de_PDE__c FROM Opportunity].Nombre_de_PDE__c
    );
    System.assertEquals(0, [SELECT COUNT() FROM QuoteLineItem]);
  }
}