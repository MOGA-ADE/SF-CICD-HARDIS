@isTest
private class AP010_ShowRelatedRecords_TEST {

    @TestSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
    }

    @isTest
    static void getRelatedQuote(){
        Quote quote = [SELECT Id, OpportunityId FROM Quote LIMIT 1];
        Test.startTest();
        List<Quote> listQuote = AP010_ShowRelatedRecordsController.getRelatedQuotes(quote.Id);
        Test.stopTest();
        Assert.isTrue(listQuote.size() == 1);
    }

    @isTest
    static void getRelatedQLI(){
        QuoteLineItem qli = [SELECT Id, Opportunit__c FROM QuoteLineItem LIMIT 1];
        Test.startTest();
        List<QuoteLineItem> listQLI = AP010_ShowRelatedRecordsController.getRelatedQLIs(qli.Id);
        Test.stopTest();
        Assert.isTrue(listQLI.size() == 2);
    }

    @isTest
    static void getRelatedEndesaElecQLI(){
        Quote quote = [SELECT Id, OpportunityId FROM Quote LIMIT 1];
        Test.startTest();
        List<QuoteLineItem> listQLI = AP010_ShowRelatedRecordsController.getRelatedEndesaElecQLIs(quote.Id);
        Test.stopTest();
        Assert.isTrue(listQLI.size() == 2);
    }
}