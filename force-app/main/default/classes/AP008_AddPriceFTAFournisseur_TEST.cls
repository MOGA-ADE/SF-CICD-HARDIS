@isTest
private class AP008_AddPriceFTAFournisseur_TEST {
    
    @testSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
    }

    @isTest
    static void getPriceBookEntry() {

        Test.startTest();
        PricebookEntry pbEntrey = AP008_AddPriceFTAFournisseurController.getPriceBookEntry();
        Test.stopTest();

        Assert.isTrue(pbEntrey != null);
    }

    @isTest
    static void getOPRDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<OpportunityPDERelation__c> oprList = AP008_AddPriceFTAFournisseurController.getOPRDetails(opp.Id);
        Test.stopTest();

        Assert.isTrue(oprList.size() != 0);
    }

    @isTest
    static void getQuoteWrappers() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        List<AP008_AddPriceFTAFournisseurController.QuoteWrapper> quoteList = AP008_AddPriceFTAFournisseurController.getQuoteWrappers(opp.Id);
        Test.stopTest();

        Assert.isTrue(quoteList.size() != 0);
    }

    @isTest
    static void insertListQLI() {
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        PricebookEntry pbEntrey = AP008_AddPriceFTAFournisseurController.getPriceBookEntry();
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        for (OpportunityPDERelation__c opr  : AP008_AddPriceFTAFournisseurController.getOPRDetails(opp.Id)) {
            QuoteLineItem qli = new QuoteLineItem();
            qli.Product2Id = pbEntrey.Product2Id;
            qli.QuoteId = quote.Id;
            qli.PriceBookEntryId = pbEntrey.Id;
            qli.Quantity = 1;
            qli.UnitPrice = 0;
            qli.PDE__c = opr.pde__r.Id;
            qli.DureeEngagement__c = 34;
            qli.DebutdeFourniture__c = Date.today();
            qli.Opportunit__c = opp.Id;
            listQLI.add(qli);
        }

        Test.startTest();
        Boolean success = AP008_AddPriceFTAFournisseurController.insertListQLI(ListQLI);
        Test.stopTest();

        Assert.isTrue(success);
    }
    @isTest
    static void updateListQLI() {
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        PricebookEntry pbEntrey = AP008_AddPriceFTAFournisseurController.getPriceBookEntry();
        Quote quote = [SELECT Id FROM Quote LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        for (OpportunityPDERelation__c opr  : AP008_AddPriceFTAFournisseurController.getOPRDetails(opp.Id)) {
            QuoteLineItem qli = new QuoteLineItem();
            qli.Product2Id = pbEntrey.Product2Id;
            qli.QuoteId = quote.Id;
            qli.PriceBookEntryId = pbEntrey.Id;
            qli.Quantity = 1;
            qli.UnitPrice = 0;
            qli.PDE__c = opr.pde__r.Id;
            qli.DureeEngagement__c = 34;
            qli.DebutdeFourniture__c = Date.today();
            qli.Opportunit__c = opp.Id;
            listQLI.add(qli);
        }
        AP008_AddPriceFTAFournisseurController.insertListQLI(ListQLI);
        Test.startTest();
        List<AP008_AddPriceFTAFournisseurController.QuoteWrapper> quoteList = AP008_AddPriceFTAFournisseurController.getQuoteWrappers(opp.Id);
        Test.stopTest();

        Assert.isTrue(quoteList.size() != 0);
    }
}