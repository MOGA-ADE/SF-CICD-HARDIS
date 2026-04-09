@isTest
private class VFC006_EtudeComparativeMasse_TEST {

    @testSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
    }

    @isTest
    static void vfc006Test(){
        Opportunity obj = [SELECT Id, AccountId, OwnerId, SectionSituationActuelle__c FROM Opportunity LIMIT 1];

        PageReference pageRef = Page.Etude_ComparativeMasse;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(obj);
        VFC006_EtudeComparativeMasse testEtudeComparativeMasse = new VFC006_EtudeComparativeMasse(sc);

        
    }
}