@isTest
private class AP004_ShowOppOnDemandeCotation_TEST {
    
    @testSetup
    static void makeData(){

        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;

        Contact contact = new Contact();
        contact.LastName = 'Test Contact';
        insert contact;

        Demande_Cotation__c dc = new Demande_Cotation__c();
        dc.Name = acc.Name;
        dc.Account__c = acc.Id;
        dc.Date_RDV_Client__c = null;
        dc.Signataire__c = contact.Id;
        dc.Charge_affaire__c = UserInfo.getUserId();
        dc.Infos_complementaires__c = '';
        dc.Statut__c = 'En attente de traitement';
        dc.Date_demande_cotation__c = Datetime.now();
        insert dc;
    }


    @isTest
    static void testGetOppList(){
        Demande_Cotation__c dc = [SELECT Id FROM Demande_Cotation__c];

        Test.startTest();
        List<Opportunity> oppList = AP004_ShowOppOnDemandeCotationController.getOppList(dc.Id);
        Test.stopTest();

        Assert.areEqual(0, oppList.size());
    }

    @isTest
    static void testGetQuoteList(){
        Demande_Cotation__c dc = [SELECT Id FROM Demande_Cotation__c];

        Test.startTest();
        List<Quote> quoteList = AP004_ShowOppOnDemandeCotationController.getQuoteList(dc.Id);
        Test.stopTest();

        Assert.areEqual(0, quoteList.size());
    }
}