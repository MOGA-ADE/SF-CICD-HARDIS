@isTest
private class AP029_UpdateQLIFromOpp_TEST {

        @TestSetup
    static void makeData() {
        
        TestDataFactory.createPriceBooks();
        //Création de deux opportunités, une gaz et une ELEC avec tous les fournisseurs grilles inclu
        // Create Account
        Id EntiteJuridiquePrincipaleRecordTypeId = [ SELECT Id FROM RecordType WHERE DeveloperName = 'Account_EntiteJuridiquePrincipale'].get(0).Id;
        Account a = new Account(Name = 'TestAccountGaz', Industry = 'Résidentiel', Siren__c = '12345678', Siret__c = '1234567890122', RecordTypeId = EntiteJuridiquePrincipaleRecordTypeId);
        insert a;

        // Create Opp
        Id oppRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_C5'].get(0).Id;
        Opportunity opp = new Opportunity(AccountId= a.Id, Name = a.Name + ' Opportunity ', StageName = 'Conditionné', CloseDate = System.today().addMonths(1), TemplateCotation__c = 'C5', SectionSituationActuelle__c = true, responsableCotation__c = UserInfo.getUserId(), RecordTypeId = oppRecordTypeId);
        insert opp;

        // Create PDEs
        Id c1c2RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Elec_C1C2'].get(0).Id;
        Id c4RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Elec_C3_C4'].get(0).Id;
        Id c5RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_ElecC5'].get(0).Id;
        Id gazRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_Gaz'].get(0).Id;

        List<PDE__c> pdes = new List<PDE__c>();
        pdes.add(new PDE__c(Name = a.Name + ' PDEC1', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678900', ReferencePointEnergie_Refonte__c = '12345678900', EntiteJuridique__c = a.Id, RecordTypeId = c1c2RecordTypeId, FTA__c = 'HTA - PF - CU', X12_mois_consommation_SGE__c = true,Segment__c = 'C1'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC2', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678901', ReferencePointEnergie_Refonte__c = '12345678900', EntiteJuridique__c = a.Id, RecordTypeId = c1c2RecordTypeId, FTA__c = 'HTA - PF - CU', X12_mois_consommation_SGE__c = true,Segment__c = 'C2'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC4', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678911', ReferencePointEnergie_Refonte__c = '12345678911', EntiteJuridique__c = a.Id, RecordTypeId = c4RecordTypeId, FTA__c = 'BT > 36 kVA - CU', X12_mois_consommation_SGE__c = true,Segment__c = 'C4'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC4', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678911', ReferencePointEnergie_Refonte__c = '12345678912', EntiteJuridique__c = a.Id, RecordTypeId = c4RecordTypeId, FTA__c = 'BT > 36 kVA - LU', X12_mois_consommation_SGE__c = true,Segment__c = 'C4'));  
        pdes.add(new PDE__c(Name = a.Name + ' PDEC5Base', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678922', ReferencePointEnergie_Refonte__c = '12345678922', EntiteJuridique__c = a.Id, RecordTypeId = c5RecordTypeId, FTA__c = 'BT <= 36 kVA - MU', X12_mois_consommation_SGE__c = true,Segment__c = 'C5'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC5HPHC', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678987', ReferencePointEnergie_Refonte__c = '12345678922', EntiteJuridique__c = a.Id, RecordTypeId = c5RecordTypeId, FTA__c = 'BT <= 36 kVA - MU', X12_mois_consommation_SGE__c = true,Segment__c = 'C5',Calendrier_fournisseur__c = 'HP/HC'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC54Postes', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678933', ReferencePointEnergie_Refonte__c = '12345678933', EntiteJuridique__c = a.Id, RecordTypeId = c5RecordTypeId, FTA__c = 'BT <= 36Kva - CU 4 postes', X12_mois_consommation_SGE__c = true,Segment__c = 'C5'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEGaz', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '1234567893', ReferencePointEnergie_Refonte__c = '1234567893', EntiteJuridique__c = a.Id, RecordTypeId = gazRecordTypeId, Tarif__c = 'T4', Profil__c = 'P011'));
        insert pdes;
        
        List<OpportunityPDERelation__c> listOPR = new List<OpportunityPDERelation__c>();
        for (PDE__c pde : pdes) {
        listOPR.add(new OpportunityPDERelation__c(Opportunity__c = opp.Id, PDE__c = pde.Id));
        }
        insert listOPR;

        opp.Liste_fournisseurs__c= 'TotalEnergies;Vattenfall;Dyneff;EDF Entreprises;Ekwateur;Engie;Ilek;GEG;Hellio;';
        update opp;

        Pricebook2 priceBook = [Select Id From Pricebook2 Limit 1];

        List<Quote> quotes = new List<Quote>();
        quotes.add(new Quote(Name = 'QUOTE 1', Pricebook2Id = priceBook.Id, OpportunityId = opp.Id, Date_de_fin_de_contrat__c = Date.today()));
        quotes.add(new Quote(Name = 'QUOTE 2', Pricebook2Id = priceBook.Id, OpportunityId = opp.Id, Date_de_fin_de_contrat__c = Date.today()));
        insert quotes;

        List<Product2> products = [Select id from Product2];

        List<PricebookEntry> priceBookEntries = [Select id from PriceBookEntry];

        List<QuoteLineItem> qlis = new List<QuoteLineItem>();
        qlis.add(new QuoteLineItem(Product2Id = products.get(0).Id,PDE__c = pdes.get(1).Id, QuoteId = quotes.get(0).Id, PricebookEntryId = priceBookEntries.get(2).Id,
                                    Quantity = 1, UnitPrice = 1, DebutDeFourniture__c = Date.today(), Nouvelle_Echeance__c = Date.today(), DureeEngagement__c = 24, Budget_TTC__c = 2, 
                                    CARGaz__c = 1234, CAR_New__c = 1234, TECH_CalendrierFournisseur__c = pdes.get(1).Calendrier_fournisseur__c));
    
    }

    @isTest
    static void UpdateOppQli() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        QuoteLineItem qliBefore = [SELECT Id, PDE__c, Conso_Base__c, DebutDeFourniture__c, Nouvelle_Echeance__c FROM QuoteLineItem LIMIT 1];

        PDE__c pdeToUpdate = [SELECT Id, Conso_Base__c, Puissance_souscrite__c, DateEcheance__c FROM PDE__c WHERE Id = :qliBefore.PDE__c];
        pdeToUpdate.Conso_Base__c = 555;
        pdeToUpdate.Puissance_souscrite__c = 99.9;
        pdeToUpdate.DateEcheance__c = System.today().addDays(15);
        update pdeToUpdate;

        AP029_UpdateQLIFromOpp.FlowInputs input = new AP029_UpdateQLIFromOpp.FlowInputs();
        input.OppId = opp.Id;

        Test.startTest();
        List<AP029_UpdateQLIFromOpp.FlowOutput> result = AP029_UpdateQLIFromOpp.updateOppQli(new List<AP029_UpdateQLIFromOpp.FlowInputs>{input});
        Test.stopTest();

        QuoteLineItem qliAfter = [SELECT Id, PDE__c, Conso_Base__c, Puissance_souscrite__c, DebutDeFourniture__c, Nouvelle_Echeance__c, DureeEngagement__c FROM QuoteLineItem WHERE Id = :qliBefore.Id];

        System.assertEquals(555, qliAfter.Conso_Base__c, 'Conso_Base__c should be updated from PDE');
        System.assertEquals(99.9, qliAfter.Puissance_souscrite__c, 'Puissance_souscrite__c should be updated');
    }

    // code duplicate because after update pde tarif in the same method i have "System.LimitException: Too many SOQL queries: 101"
    @isTest
    static void UpdateOppQliGazTarifT1() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        QuoteLineItem qliBefore = [SELECT Id, PDE__c, Conso_Base__c, DebutDeFourniture__c, Nouvelle_Echeance__c FROM QuoteLineItem WHERE TECH_TypePDL__c = 'PDE_Gaz' LIMIT 1];

        PDE__c pdeToUpdate = [SELECT Id, Conso_Base__c, Puissance_souscrite__c, DateEcheance__c, Tarif__c FROM PDE__c WHERE Id = :qliBefore.PDE__c];

        AP029_UpdateQLIFromOpp.FlowInputs input = new AP029_UpdateQLIFromOpp.FlowInputs();
        input.OppId = opp.Id;

        Test.startTest();
            pdeToUpdate.Tarif__c = 'T1';
            update pdeToUpdate;
            List<AP029_UpdateQLIFromOpp.FlowOutput> result = AP029_UpdateQLIFromOpp.updateOppQli(new List<AP029_UpdateQLIFromOpp.FlowInputs>{input});
        Test.stopTest();
    }

    @isTest
    static void UpdateOppQliGazTarifT2() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        QuoteLineItem qliBefore = [SELECT Id, PDE__c, Conso_Base__c, DebutDeFourniture__c, Nouvelle_Echeance__c FROM QuoteLineItem WHERE TECH_TypePDL__c = 'PDE_Gaz' LIMIT 1];

        PDE__c pdeToUpdate = [SELECT Id, Conso_Base__c, Puissance_souscrite__c, DateEcheance__c, Tarif__c FROM PDE__c WHERE Id = :qliBefore.PDE__c];

        AP029_UpdateQLIFromOpp.FlowInputs input = new AP029_UpdateQLIFromOpp.FlowInputs();
        input.OppId = opp.Id;

        Test.startTest();
            pdeToUpdate.Tarif__c = 'T2';
            update pdeToUpdate;
            List<AP029_UpdateQLIFromOpp.FlowOutput> result = AP029_UpdateQLIFromOpp.updateOppQli(new List<AP029_UpdateQLIFromOpp.FlowInputs>{input});
        Test.stopTest();
    }

    @isTest
    static void UpdateOppQliGazTarifT3() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        QuoteLineItem qliBefore = [SELECT Id, PDE__c, Conso_Base__c, DebutDeFourniture__c, Nouvelle_Echeance__c FROM QuoteLineItem WHERE TECH_TypePDL__c = 'PDE_Gaz' LIMIT 1];

        PDE__c pdeToUpdate = [SELECT Id, Conso_Base__c, Puissance_souscrite__c, DateEcheance__c, Tarif__c FROM PDE__c WHERE Id = :qliBefore.PDE__c];
        AP029_UpdateQLIFromOpp.FlowInputs input = new AP029_UpdateQLIFromOpp.FlowInputs();
        input.OppId = opp.Id;

        Test.startTest();
            pdeToUpdate.Tarif__c = 'T3';
            update pdeToUpdate;
            List<AP029_UpdateQLIFromOpp.FlowOutput> result = AP029_UpdateQLIFromOpp.updateOppQli(new List<AP029_UpdateQLIFromOpp.FlowInputs>{input});
        Test.stopTest();
    }
}