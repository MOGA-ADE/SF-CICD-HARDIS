@isTest
private class AP011_ShowRelatedPDE_Test{

    @TestSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
    }

    @isTest
    static void getRelatedPDEElec(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<PDE__c> listPDE = AP011_ShowRelatedPDEController.getRelatedPDEElec(acc.Id);
        Test.stopTest();
        Assert.areEqual(2,listPDE.size());
    }

    @isTest
    static void getRelatedPDEGaz(){
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.startTest();
        List<PDE__c> listPDE = AP011_ShowRelatedPDEController.getRelatedPDEGaz(acc.Id);
        Test.stopTest();
        Assert.areEqual(1,listPDE.size());
    }
}