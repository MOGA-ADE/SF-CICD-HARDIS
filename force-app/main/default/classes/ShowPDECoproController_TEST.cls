@isTest
public with sharing class ShowPDECoproController_TEST {
    @TestSetup
    static void createTestData() {
      TestDataFactory.createSyndicsWithCoprosAndPointDenergie(1,1,1,1);
    }

    @IsTest
  static void retrievePDECoproTest() {
    Id syndicId = [
      SELECT Id
      FROM Account
      WHERE RecordType.DeveloperName = 'Syndic'
      LIMIT 1
    ]
    .Id;
    Test.startTest();
    List<PDE__c> listPDECopro = ShowPDECoproController.retrievePDE(syndicId);
    System.assertEquals(2, listPDECopro.size());
    Test.stopTest();
  }

  @isTest
  static void deletePDECopro(){
    Id syndicId = [
      SELECT Id
      FROM Account
      WHERE RecordType.DeveloperName = 'Syndic'
      LIMIT 1
    ]
    .Id;
    Test.startTest();
    List<Id> listPDEId= new List<Id>();
    List<PDE__c> listPDECopro = ShowPDECoproController.retrievePDE(syndicId);
    for(PDE__c pde:listPDECopro){
        listPDEId.add(pde.Id);
    }
    System.assertEquals(true,ShowPDECoproController.deletePDERowAction(listPDEId));
    System.assertEquals(0, ShowPDECoproController.retrievePDE(syndicId).size());
    Test.stopTest();

    
  }
}