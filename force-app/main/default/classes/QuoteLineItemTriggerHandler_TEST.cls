@isTest
private class QuoteLineItemTriggerHandler_TEST {

    @testSetup
    static void makeData(){
        TestDataFactory.createPriceBooks();
        Id rtPDEc4 = [SELECT Id FROM RecordType WHERE DeveloperName = 'Elec_C3_C4'].get(0).Id;
        Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
        PricebookEntry priceBookEntry = [SELECT Product2Id FROM PricebookEntry WHERE Name = 'ELEC' AND Pricebook2Id = :pb.Id LIMIT 1];

        PDE__c pde = new PDE__c();
        pde.Conso_Pointe__c = 123;
        pde.Conso_HPH__c = 123;
        pde.Conso_HCH__c = 123;
        pde.Conso_HPE__c = 123;
        pde.Conso_HCE__c = 123;
        pde.Conso_Base__c = 123;
        pde.ConsoHP__c = 123;
        pde.ConsoHC__c = 123;
        pde.Puissance_souscrite__c = 123;
        pde.Segment__c = 'C4';
        pde.FTA__c = 'BT > 36 kVA - CU';
        pde.RecordTypeId = rtPDEc4;
        insert pde;

        Opportunity opp = new Opportunity();
        opp.Name = 'test opp';
        opp.StageName = 'Négociation';
        opp.CloseDate = Date.today();
        insert opp;

        Quote quote = new Quote();
        quote.Name = 'test quote';
        quote.OpportunityId = opp.Id;
        quote.Date_de_fin_de_contrat__c = Date.today();
        quote.Pricebook2Id = pb.Id;
        insert quote;

        QuoteLineItem qli = new QuoteLineItem();
        qli.QuoteId = quote.Id;
        qli.Product2Id = priceBookEntry.Product2Id;
        qli.PricebookEntryId = priceBookEntry.Id;
        qli.Opportunit__c = opp.Id;
        qli.PDE__c = pde.Id;
        qli.Quantity = 1;
        qli.UnitPrice = 0;
        qli.Taxes__c = true;
        qli.Puissance_souscrite__c = 123;
        qli.Conso_Base__c = 123;
        qli.ConsoHC__c = 123;
        qli.Conso_HCE__c = 123;
        qli.Conso_HCH__c = 123;
        qli.ConsoHP__c = 123;
        qli.Conso_HPE__c = 123;
        qli.Conso_HPH__c = 123;
        qli.Conso_Pointe__c = 123;
        qli.AbonnementMois__c = 123;
        qli.CSPE__c = 123;
        qli.CeeMwh__c = 123;
        qli.TDCFE__c = 123;
        qli.TCCFE__c = 123;
        qli.Capa_HP__c = 123;
        qli.Capa_HC__c = 123;
        qli.Capa_HPH__c = 123;
        qli.Capa_HCH__c = 123;
        qli.Capa_HPE__c = 123;
        qli.Capa_HCE__c = 123;
        qli.Capa_Base__c = 123;
        qli.PrixHP__c = 123;
        qli.PrixHC__c = 123;
        qli.PrixHphMwh__c = 123;
        qli.PrixHchMwh__c = 123;
        qli.PrixHpeMwh__c = 123;
        qli.PrixHceMwh__c = 123;
        qli.PrixBase__c = 123;
        qli.PointesMWh__c = 123;
        qli.Capa_Pointes__c = 123;
        qli.PrixMolecule__c = 123;
        qli.CARGaz__c = 123;
        qli.FraisTransportDistributionCapacite__c = 123;
        qli.CTA__c = 123;

        insert qli;
    }

    @isTest
    static void testQLIElecC4(){
        Set<Id> setIds = new Set<Id>();
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        setIds.add(qli.Id);

        Test.startTest();
        QuoteLineItemTriggerHandler triggerHandlerQLI = new QuoteLineItemTriggerHandler();
        triggerHandlerQLI.setQLIIds = setIds;
        Database.executeBatch(triggerHandlerQLI, 200);
        Test.stopTest();
    }

    @isTest
    static void testQLIElecC54CU(){
        Set<Id> setIds = new Set<Id>();
        PDE__c pde = [SELECT FTA__c, Segment__c FROM PDE__c LIMIT 1];
        pde.FTA__c = 'BT <= 36Kva - CU';
        pde.Segment__c = 'C5';
        pde.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_ElecC5'].get(0).Id;
        update pde;

        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        setIds.add(qli.Id);

        Test.startTest();
        QuoteLineItemTriggerHandler triggerHandlerQLI = new QuoteLineItemTriggerHandler();
        triggerHandlerQLI.setQLIIds = setIds;
        Database.executeBatch(triggerHandlerQLI, 200);
        Test.stopTest();
    }

    @isTest
    static void testQLIElecC54LUEP(){
        Set<Id> setIds = new Set<Id>();
        PDE__c pde = [SELECT FTA__c, Segment__c FROM PDE__c LIMIT 1];
        pde.FTA__c = 'BT <= 36 kVA - LU EP';
        pde.Segment__c = 'C5';
        pde.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_ElecC5'].get(0).Id;
        update pde;

        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        setIds.add(qli.Id);

        Test.startTest();
        QuoteLineItemTriggerHandler triggerHandlerQLI = new QuoteLineItemTriggerHandler();
        triggerHandlerQLI.setQLIIds = setIds;
        Database.executeBatch(triggerHandlerQLI, 200);
        Test.stopTest();
    }

    @isTest
    static void testQLIElecC5MU(){
        Set<Id> setIds = new Set<Id>();
        PDE__c pde = [SELECT FTA__c, Segment__c FROM PDE__c LIMIT 1];
        pde.FTA__c = 'BT <= 36Kva - MU';
        pde.Segment__c = 'C5';
        pde.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_ElecC5'].get(0).Id;
        update pde;

        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        setIds.add(qli.Id);

        Test.startTest();
        QuoteLineItemTriggerHandler triggerHandlerQLI = new QuoteLineItemTriggerHandler();
        triggerHandlerQLI.setQLIIds = setIds;
        Database.executeBatch(triggerHandlerQLI, 200);
        Test.stopTest();
    }

    @isTest
    static void testQLIElecC54postes(){
        Set<Id> setIds = new Set<Id>();
        PDE__c pde = [SELECT FTA__c, Segment__c FROM PDE__c LIMIT 1];
        pde.FTA__c = 'BT <= 36Kva - CU 4 postes';
        pde.Segment__c = 'C5';
        pde.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_ElecC5'].get(0).Id;
        update pde;

        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        setIds.add(qli.Id);

        Test.startTest();
        QuoteLineItemTriggerHandler triggerHandlerQLI = new QuoteLineItemTriggerHandler();
        triggerHandlerQLI.setQLIIds = setIds;
        Database.executeBatch(triggerHandlerQLI, 200);
        Test.stopTest();
    }

    @isTest
    static void testQLIGaz(){
        Set<Id> setIds = new Set<Id>();
        PDE__c pde = [SELECT Id FROM PDE__c LIMIT 1];
        pde.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_Gaz'].get(0).Id;
        update pde;

        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];
        setIds.add(qli.Id);

        Test.startTest();
        QuoteLineItemTriggerHandler triggerHandlerQLI = new QuoteLineItemTriggerHandler();
        triggerHandlerQLI.setQLIIds = setIds;
        Database.executeBatch(triggerHandlerQLI, 200);
        Test.stopTest();
    }
}