@isTest
private class AP006_DeleteOPRFromFlow_TEST {
    @testSetup
    static void makeData(){
        TestDataFactory.createPriceBooks();
        Id rtPDEGaz = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_Gaz'].get(0).Id;
        Id rtOpp = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_Gaz'].get(0).Id;
        List<PDE__c> listPDEToInsert = new List<PDE__c>();
        List<OpportunityPDERelation__c> listOPRToInsert = new List<OpportunityPDERelation__c>();

        Account acc = new Account(Name= 'TEST');
        insert acc;

        Contact con1 = new Contact(
            LastName = 'Signataire1',
            FirstName = 'Opportunity',
            Phone = '0611223344',
            Email = 'contact1@test.com',
            accountId = acc.id
          );
        insert con1;

        Demande_Cotation__c demandeCotation = new Demande_Cotation__c(
            Name = 'XXXXXXXXXXX',
            Account__c = acc.Id,
            Statut__c = 'En cours de traitement',
            Date_demande_cotation__c = Date.today(),
            Signataire__c = con1.Id,
            Charge_affaire__c = UserInfo.getUserId()
            );
        insert demandeCotation;
        
        PDE__c pde = new PDE__c(
            Name = acc.Name + ' PDEGaz ',
            voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            DateEcheance__c = System.today().addMonths(1),
            Demande_Cotation__c = demandeCotation.Id,
            PCE_Refonte__c = '1234567899',
            EntiteJuridique__c = acc.Id,
            RecordTypeId = rtPDEGaz
        );
        listPDEToInsert.add(pde);

        PDE__c pde2 = new PDE__c(
            Name = acc.Name + ' PDEGaz2 ',
            voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            DateEcheance__c = System.today().addMonths(1),
            Demande_Cotation__c = demandeCotation.Id,
            PCE_Refonte__c = '1234567891',
            EntiteJuridique__c = acc.Id,
            RecordTypeId = rtPDEGaz
        );
        listPDEToInsert.add(pde2);

        insert listPDEToInsert;

        Opportunity opp =  new Opportunity(
            Name = acc.Name + ' Opportunity',
            StageName = 'Conditionné',
            CloseDate = System.today().addMonths(1),
            TemplateCotation__c = 'Gaz',
            AccountId = acc.Id,
            responsableCotation__c = UserInfo.getUserId(),
            RecordTypeId = rtOpp
          );
          insert opp;
          
          OpportunityPDERelation__c opr1 = new OpportunityPDERelation__c(Opportunity__c = opp.id,PDE__c = pde.Id);
          OpportunityPDERelation__c opr2 = new OpportunityPDERelation__c(Opportunity__c = opp.id,PDE__c = pde2.Id);
          listOPRToInsert.add(opr1);
          listOPRToInsert.add(opr2);
          insert listOPRToInsert;

    }

    @isTest
    static void creerOpportuniteFromFlow(){

        List<OpportunityPDERelation__c> listOPR = [SELECT Id FROM OpportunityPDERelation__c];
        List<AP006_DeleteOPRFromFlow.FlowInputs> params = new List<AP006_DeleteOPRFromFlow.FlowInputs>();

        AP006_DeleteOPRFromFlow.FlowInputs inputs = new AP006_DeleteOPRFromFlow.FlowInputs();
        inputs.selectedOPR = listOPR;

        params.add(inputs);

        Test.startTest();
        List<AP006_DeleteOPRFromFlow.FlowOutput> success = AP006_DeleteOPRFromFlow.deleteOPR(params);
        Test.stopTest();

        Assert.isTrue(success[0].DMLSuccess);
    }
}