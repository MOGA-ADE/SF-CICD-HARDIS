@isTest
private class VFC003_ViewQuoteLineItems_TEST {
    @isTest static void testGetQuoteLineItemList() {
        // Test data setup
        // Create one account with related object by calling a utility method
        Account[] accts = TestDataFactory.createAccountsWithOppsAndPointDenergie(1,2,1,1,1);
        
        // Perform test
        List<VFC003_ViewQuoteLineItems.QuoteLineElementsByFournisseur> qlisFromOpport = new List<VFC003_ViewQuoteLineItems.QuoteLineElementsByFournisseur>();
        List<VFC003_ViewQuoteLineItems.QuoteLineElementsByFournisseur> qlisFromQuote = new List<VFC003_ViewQuoteLineItems.QuoteLineElementsByFournisseur>();
        List<VFC003_ViewQuoteLineItems.QuoteLineElementsByFournisseur> qlisFromQli = new List<VFC003_ViewQuoteLineItems.QuoteLineElementsByFournisseur>();
        
        Test.startTest();
        String oppId = [SELECT Id FROM Opportunity WHERE AccountId =: accts.get(0).Id].get(0).Id;
        String devisId = [SELECT Id FROM Quote WHERE OpportunityId =: oppId AND Name='QUOTE 1'].get(0).Id;
        String elmtDevisId = [SELECT Id FROM QuoteLineItem WHERE QuoteId =: devisId].get(0).Id;

        qlisFromOpport = VFC003_ViewQuoteLineItems.getQuoteLineItemList(oppId, 'Opportunity');
        qlisFromQuote = VFC003_ViewQuoteLineItems.getQuoteLineItemList(devisId, 'Quote');
        qlisFromQli = VFC003_ViewQuoteLineItems.getQuoteLineItemList(elmtDevisId, 'QuoteLineItem');
        Test.stopTest();

        // Verify that we get 3 point d'énergies
        //System.assertEquals(2, qlisFromOpport.size());
        //System.assertEquals(2, qlisFromQuote.size());
       // System.assertEquals(2, qlisFromQli.size());
    }
}