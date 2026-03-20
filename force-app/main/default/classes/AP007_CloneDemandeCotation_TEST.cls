@isTest
private class AP007_CloneDemandeCotation_TEST {
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

        
        Opportunity opp = new Opportunity();
        opp.Name = 'Opportunity test';
        opp.StageName = 'En cours de traitement';
        opp.CloseDate = Date.today();
        opp.AccountId = acc.Id;
        opp.Demande_Cotation__c = dc.Id;
        insert opp;

        PDE__c pde = new PDE__c();
        pde.Name = 'Pde test';
        pde.Demande_Cotation__c = dc.Id;
        insert pde;
    }

    @isTest
    static void getDemandeCotation(){
        Demande_Cotation__c dc = [SELECT Name FROM Demande_Cotation__c][0];
        
        Test.startTest();
        Demande_Cotation__c dcName = AP007_CloneDemandeCotationController.getDemandeCotation(dc.Id);
        Test.stopTest();

        Assert.areEqual('Test Account', dcName.Name);
    }
    
    @isTest
    static void cloneDemandeCotation(){
        Demande_Cotation__c dc = [SELECT Name FROM Demande_Cotation__c][0];
        
        Test.startTest();
        Demande_Cotation__c dcClone = AP007_CloneDemandeCotationController.cloneDemandeCotation(dc.Id, 'New Demande',Datetime.now());
        Test.stopTest();

        Assert.areEqual('New Demande', dcClone.Name);
    }
}