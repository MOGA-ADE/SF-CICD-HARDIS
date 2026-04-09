@isTest
private class VFC005_OpportunityFields_TEST {
    @isTest static void TestGetOpportunity() {
        // Test data setup
        // Create one account with two opportunities and three point d'énergies by calling a utility method
        Account[] accts = TestDataFactory.createAccountsWithOppsAndPointDenergie(1,2,1,1,1);
        
        // Perform test
        Opportunity opp = new Opportunity();
        Test.startTest();
        String oppId = [SELECT Id FROM Opportunity WHERE AccountId =: accts.get(0).Id].get(0).Id;
        opp = VFC005_OpportunityFields.getOpportunity(oppId);
        Test.stopTest();
        // Verify that we get the opportunity TemplateCotation__c
        System.assertEquals('C5', opp.TemplateCotation__c);
    }
}