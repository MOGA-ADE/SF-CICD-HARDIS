@isTest
private class SM002_GestionDevisMasse_TEST {
   
    @TestSetup
    static void makeData() {
        TestDataFactory.createPriceBooks();
        Id rtPDEGaz = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_Gaz'].get(0).Id;
        Id rtOppSimpleGaz = [SELECT Id FROM RecordType WHERE DeveloperName = 'Masse_Gaz'].get(0).Id;
        List<PDE__c> listPDEToInsert = new List<PDE__c>();
        List<OpportunityPDERelation__c> listOPRToInsert = new List<OpportunityPDERelation__c>();

        Account acc = new Account(Name= 'TEST');
        insert acc;
        
        PDE__c pde = new PDE__c(
            Name = acc.Name + ' PDEGaz ',
            voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            DateEcheance__c = System.today().addMonths(1),
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
            RecordTypeId = rtOppSimpleGaz
          );
          insert opp;

          OpportunityPDERelation__c opr1 = new OpportunityPDERelation__c(Opportunity__c = opp.id,PDE__c = pde.Id);
          OpportunityPDERelation__c opr2 = new OpportunityPDERelation__c(Opportunity__c = opp.id,PDE__c = pde2.Id);
          listOPRToInsert.add(opr1);
          listOPRToInsert.add(opr2);
          insert listOPRToInsert;
    }

    @isTest
    static void createThreeFournisseur(){
        Assert.areEqual(0, (Integer)[SELECT count(id) FROM Quote][0].get('expr0'));
        Opportunity opp = [Select Id from Opportunity][0];
        opp.Liste_Fournisseurs__c = 'Antargaz;Alpiq;Engie';
        Test.startTest();
        update opp;
        Test.stopTest();
        Assert.areEqual(3, (Integer)[SELECT count(id) FROM Quote][0].get('expr0'));
        Assert.areEqual(0, (Integer)[SELECT count(id) FROM QuoteLineItem][0].get('expr0'));

    }

    @isTest
    static void deleteAllFournisseur(){
        Opportunity opp = [Select Id from Opportunity][0];
        opp.Liste_Fournisseurs__c = 'Alterna;Antargaz;Engie';

        Test.startTest();
        update opp;
        Assert.areEqual(3, (Integer)[SELECT count(id) FROM Quote][0].get('expr0'));

        opp.Liste_Fournisseurs__c = '';

        update opp;
        Test.stopTest();
        Assert.areEqual(0, (Integer)[SELECT count(id) FROM Quote][0].get('expr0'));
    }

    @isTest
    static void addOneFournisseur(){
        Opportunity opp = [Select Id from Opportunity][0];
        opp.Liste_Fournisseurs__c = 'Alterna;Antargaz;Engie';
        Test.startTest();
        update opp;
        opp.Liste_Fournisseurs__c = 'Alterna;Antargaz;Engie;Alpiq';
        update opp;
        Test.stopTest();
        Assert.areEqual(4, (Integer)[SELECT count(id) FROM Quote][0].get('expr0'));
        Assert.areEqual(0, (Integer)[SELECT count(id) FROM QuoteLineItem][0].get('expr0'));
    }

    @isTest
    static void addOneAndDeleteOneFournisseur(){
        Opportunity opp = [Select Id from Opportunity][0];
        opp.Liste_Fournisseurs__c = 'Alterna;Antargaz;Engie';
        Test.startTest();
        update opp;
        opp.Liste_Fournisseurs__c = 'Alterna;Antargaz;Alpiq';
        update opp;
        Test.stopTest();
        Assert.areEqual(3, (Integer)[SELECT count(id) FROM Quote][0].get('expr0'));
        Assert.areEqual(0, (Integer)[SELECT count(id) FROM QuoteLineItem][0].get('expr0'));
    }

    @isTest
    static void addSpecialQuote(){
        Opportunity opp = [Select Id from Opportunity][0];
        opp.SectionPropositionRenouvellement__c = true;
        opp.SectionSituationActuelle__c = true;
        Test.startTest();
        update opp;
        Test.stopTest();
        Assert.areEqual(2, (Integer)[SELECT count(id) FROM Quote][0].get('expr0'));
        Assert.areEqual(0, (Integer)[SELECT count(id) FROM QuoteLineItem][0].get('expr0'));
    }

    @isTest
    static void deleteSpecialQuote(){
        Opportunity opp = [Select Id from Opportunity][0];
        opp.SectionPropositionRenouvellement__c = true;
        opp.SectionSituationActuelle__c = true;
        Test.startTest();
        update opp;
        opp.SectionPropositionRenouvellement__c = false;
        opp.SectionSituationActuelle__c = false;
        update opp;
        Test.stopTest();
        Assert.areEqual(0, (Integer)[SELECT count(id) FROM Quote][0].get('expr0'));
    }
}