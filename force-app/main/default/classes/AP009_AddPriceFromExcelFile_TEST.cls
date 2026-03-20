@isTest
private class AP009_AddPriceFromExcelFile_TEST {
    @testSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
    }

    @isTest
    static void getPriceBookEntryGaz_test() {

        Test.startTest();
        PricebookEntry pbEntrey = AP009_AddPriceFromExcelFileController.getPriceBookEntryGaz();
        Test.stopTest();

        Assert.isTrue(pbEntrey != null);
    }

    @isTest
    static void getPriceBookEntryElec_test() {

        Test.startTest();
        PricebookEntry pbEntrey = AP009_AddPriceFromExcelFileController.getPriceBookEntryElec();
        Test.stopTest();

        Assert.isTrue(pbEntrey != null);
    }

    @isTest
    static void retrieveQuote_test(){
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        List<Quote> listQuote = AP009_AddPriceFromExcelFileController.retrieveQuote(oppId);
        Test.stopTest();
        Assert.areNotEqual(listQuote.size(),0);
    }

    @isTest
    static void retrieveOPR_test(){
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        List<OpportunityPDERelation__c> listOPR = AP009_AddPriceFromExcelFileController.retrieveOPR(oppId);
        Test.stopTest();
        Assert.areNotEqual(listOPR.size(),0);
    }

    @isTest
    static void retrievePriceQLI_test(){
        Id oppId = [SELECT Id FROM Opportunity LIMIT 1].Id;
        Test.startTest();
        List<QuoteLineItem> listQLI = AP009_AddPriceFromExcelFileController.retrievePriceQLI(oppId);
        Test.stopTest();
        Assert.areNotEqual(listQLI.size(),0);
    }

    @isTest
    static void insertListQLI_test(){
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        PricebookEntry pbEntrey = AP009_AddPriceFromExcelFileController.getPriceBookEntryGaz();
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
        Boolean success = AP009_AddPriceFromExcelFileController.insertListQLI(ListQLI,opp.Id);
        Test.stopTest();

        Assert.isTrue(success);
    }    

    
}