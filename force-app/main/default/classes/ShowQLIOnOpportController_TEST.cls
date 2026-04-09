@isTest
public with sharing class ShowQLIOnOpportController_TEST {
  @TestSetup
  static void createTestData() {
    TestDataFactory.createAccountsWithOppsAndPointDenergie(1,2,1,1,1);
  }

  @IsTest
  static void retrieveQLI() {
    Id opportId = [SELECT Id FROM Opportunity LIMIT 1].Id;
    Test.startTest();
    List<QuoteLineItem> listQLI = ShowQLIOnOpportController.retrieveQLI(
      opportId
    );
    System.assertEquals(3, listQLI.size());
    Test.stopTest();
  }
}