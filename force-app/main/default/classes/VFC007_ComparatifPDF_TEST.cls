@isTest
private class VFC007_ComparatifPDF_TEST {
    @testSetup
    static void makeData(){
        TestDataFactory.createDataForComparatifGaz();
        TestDataFactory.createDataForComparatifElec();

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id rtElecId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Quote_Elec' LIMIT 1].Id;

        insert new Quote(
            Name = 'Quote GO Test',
            OpportunityId = opp.Id,
            RecordTypeId = rtElecId,
            IsGarantieOrigine__c = true,
            OrigineGarantieOrigine__c = 'Française',
            TechnologieGarantieOrigine__c = 'Photovoltaïque',
            DebutCouvertureGarantieOrigine__c = Date.today(),
            FinCouvertureGarantieOrigine__c   = Date.today().addMonths(6),
            Date_de_fin_de_contrat__c = Date.today().addMonths(6) 
        );

        Opportunity oppAny = [SELECT Id FROM Opportunity LIMIT 1];
        Id pbId = Test.getStandardPricebookId();

        Quote qTurpe = new Quote(
            Name = 'Quote TURPE Test',
            OpportunityId = oppAny.Id,
            Pricebook2Id = pbId,
            IsOptimisationTurpe__c = true,
            RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Quote_Elec').getRecordTypeId(),
            Date_de_fin_de_contrat__c = Date.today().addMonths(6)
        );
        insert qTurpe;

        PDE__c pde = [SELECT Id FROM PDE__c LIMIT 1];
        Id pbeId = [
            SELECT Id FROM PricebookEntry
            WHERE Pricebook2Id = :pbId
            LIMIT 1
        ].Id;

        insert new QuoteLineItem(
            QuoteId = qTurpe.Id,
            PDE__c = pde.Id,
            Product2Id = [SELECT Id FROM Product2 LIMIT 1].Id,
            PricebookEntryId = pbeId,
            Quantity = 1,
            UnitPrice = 1,
            EconomieIdentifie__c = 100,
            BudgetTotalActuel__c = 5000,
            BudgetTotalOptimal__c = 4500
        );
    }

    @isTest
    static void comparatifPDFTestGaz(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE TemplateCotation__c = 'GAZ' LIMIT 1];
        String quoteNumber = [SELECT QuoteNumber FROM Quote WHERE Fournisseur__c = 'Engie' AND OpportunityId = :opp.Id LIMIT 1].QuoteNumber;

        PageReference pdfPage = Page.ComparatifPDF;
        pdfPage.getParameters().put('id', opp.Id);
        pdfPage.getParameters().put('fournisseurs', 'Engie');
        pdfPage.getParameters().put('quoteNumbers', quoteNumber);
        pdfPage.getParameters().put('goQuoteNumbers', '');
        pdfPage.getParameters().put('includeAllGO', 'true');
        pdfPage.getParameters().put('sectionTTC', 'true');
        pdfPage.getParameters().put('sectionSituationActuelle', 'true');
        Test.setCurrentPage(pdfPage);

        Test.startTest();
        String url = VFC007_ComparatifPDFController.generatePDFUrl(
            opp.Id, null, 'Engie', quoteNumber, true, true, '', true
        );
        Test.stopTest();

        // Vérif du FeedItem
        FeedItem f = [SELECT Body FROM FeedItem WHERE ParentId = :opp.Id LIMIT 1];
        Assert.isTrue(f.Body.contains('comparatif détaillé'));

        // Instanciation du controller
        VFC007_ComparatifPDFController ctrl = new VFC007_ComparatifPDFController();

        // Lecture de propriétés statiques
        Boolean isGaz = VFC007_ComparatifPDFController.isOppGaz;
        Boolean isSimple = VFC007_ComparatifPDFController.isOppSimpleRT;
        Boolean isPartenaire = VFC007_ComparatifPDFController.isOppPartenaire;
        String  todayDate = VFC007_ComparatifPDFController.todayDate;
        Boolean hasGOElec = VFC007_ComparatifPDFController.listQuoteGOElecNotEmpty;
        Boolean hasGOGaz = VFC007_ComparatifPDFController.listQuoteGOGazNotEmpty;
        Boolean hasC1 = VFC007_ComparatifPDFController.listQLIC1ListNotEmpty;
        Boolean hasC2 = VFC007_ComparatifPDFController.listQLIC2ListNotEmpty;
        Boolean hasC4 = VFC007_ComparatifPDFController.listQLIC4ListNotEmpty;
        Boolean hasC5Base = VFC007_ComparatifPDFController.listQLIC5BaseListNotEmpty;
        Boolean hasC54 = VFC007_ComparatifPDFController.listQLIC54postesListNotEmpty;

        Assert.areNotEqual(null, todayDate, 'todayDate ne doit pas être null');
    }

    @isTest
    static void comparatifPDFTestElec(){
        Opportunity opp = [
            SELECT Id 
            FROM Opportunity 
            WHERE TemplateCotation__c = 'C5' 
            LIMIT 1
        ];
        Quote q = [
            SELECT QuoteNumber 
            FROM Quote 
            WHERE Fournisseur__c = 'Engie' 
            AND OpportunityId = :opp.Id 
            LIMIT 1
        ];

        PageReference pdfPage = Page.ComparatifPDF;
        pdfPage.getParameters().put('id', opp.Id);
        pdfPage.getParameters().put('fournisseurs', 'Engie');
        pdfPage.getParameters().put('quoteNumbers', q.QuoteNumber);
        pdfPage.getParameters().put('goQuoteNumbers', '');
        pdfPage.getParameters().put('includeAllGO', 'true');
        pdfPage.getParameters().put('sectionTTC', 'false');
        pdfPage.getParameters().put('sectionSituationActuelle', 'false');
        Test.setCurrentPage(pdfPage);

        String url = VFC007_ComparatifPDFController.generatePDFUrl(
            opp.Id, null, 'Engie', q.QuoteNumber, false, false, '', true
        );
        Assert.areNotEqual(null, url);

        // Méthodes auxiliaires
        List<Quote> quotes = VFC007_ComparatifPDFController.getInfosComparatif(opp.Id);
        Assert.isTrue(!quotes.isEmpty(), 'Des quotes doivent être retournées');

        List<OpportunityPDERelation__c> oprs = VFC007_ComparatifPDFController.getInfosOpportunity(opp.Id);
        Assert.isTrue(!oprs.isEmpty(), 'Des OPR doivent être retournés');

        // Instanciation
        VFC007_ComparatifPDFController ctrl = new VFC007_ComparatifPDFController();
        Assert.areNotEqual(null, ctrl);
    }

    @isTest
    static void testLoadTurpeData_Elec_TURPE() {
        Opportunity opp = [
            SELECT Id FROM Opportunity 
            WHERE TemplateCotation__c = 'C5'
            LIMIT 1
        ];

        Id pricebookId = [SELECT Id FROM Pricebook2 WHERE IsActive = true LIMIT 1].Id;

        Quote qTurpe = new Quote(
            Name = 'Quote TURPE Elec',
            OpportunityId = opp.Id,
            Pricebook2Id = pricebookId,
            IsOptimisationTurpe__c = true,
            Date_de_fin_de_contrat__c = Date.today().addMonths(6),
            RecordTypeId = Schema.SObjectType.Quote.getRecordTypeInfosByDeveloperName().get('Quote_Elec').getRecordTypeId()
        );
        insert qTurpe;

        PDE__c pde = [SELECT Id FROM PDE__c LIMIT 1];
        Id pbEntryId = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId LIMIT 1].Id;
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qTurpe.Id,
            PDE__c = pde.Id,
            Product2Id = [SELECT Id FROM Product2 LIMIT 1].Id,
            PricebookEntryId = pbEntryId,
            EconomieIdentifie__c = 500,
            EconomieIdentifieNet__c = 500,
            BudgetTotalActuel__c = 12000,
            BudgetTotalOptimal__c = 10000,
            PartFixeCSActuel__c = 100,
            PartFixeCSOptimal__c = 80,
            PartVariableCSActuel__c = 200,
            PartVariableCSOptimal__c = 150,
            DepassementActuel__c = 50,
            DepassementOptimal__c = 30,
            TaxeCTAActuel__c = 40,
            TaxeCTAOptimal__c = 35,
            InterventionPEPS__c = 25,
            Quantity = 1,
            UnitPrice = 1
        );
        insert qli;

        PageReference pdfPage = Page.ResumeComparatifPDF;
        pdfPage.getParameters().put('id', opp.Id);
        pdfPage.getParameters().put('fournisseurs', 'Engie');
        pdfPage.getParameters().put('quoteNumbers', '');
        pdfPage.getParameters().put('includeAllGO', 'false');
        pdfPage.getParameters().put('sectionTTC', 'false');
        pdfPage.getParameters().put('sectionSituationActuelle', 'false');
        Test.setCurrentPage(pdfPage);

        Test.startTest();
        VFC008_ResumeComparatifPDFController ctrl = new VFC008_ResumeComparatifPDFController();
        Test.stopTest();

        Assert.areNotEqual(null, VFC008_ResumeComparatifPDFController.lstQLITurpe, 'Les QLI doivent être chargés');
        Assert.areEqual(1, VFC008_ResumeComparatifPDFController.lstQLITurpe.size(), 'Un QLI TURPE doit être trouvé');
        Assert.areEqual(true, VFC008_ResumeComparatifPDFController.turpeIsMonoSite, 'Le mode monosite doit être activé');
        Assert.areEqual(12000, VFC008_ResumeComparatifPDFController.totalBudgetActuel, 'Le budget actuel doit être 12000');
        Assert.areEqual(10000, VFC008_ResumeComparatifPDFController.totalBudgetOptimal, 'Le budget optimal doit être 10000');
        Assert.areEqual(500, VFC008_ResumeComparatifPDFController.totalEconomie, 'L\'économie doit être 500');
        Assert.isTrue(VFC008_ResumeComparatifPDFController.noteDateText.contains('optimisation'), 'Le texte dynamique de date doit être généré');
    }

    @isTest
    static void testTurpeAndPEPSMethods() {

        Pricebook2 priceBook = new Pricebook2(Name = 'AllianceDesEnergies', IsActive = true);
        insert priceBook;

        // Create Product Gaz
        Product2 p2 = new Product2(Name = 'GAZ', IsActive = true);
        insert p2;

        // Create priceBookEntries
        Id standardPricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
        priceBookEntries.add(new PricebookEntry(IsActive = true, UnitPrice = 1.00, Product2Id = p2.Id, Pricebook2Id = standardPricebookId));
        priceBookEntries.add(new PricebookEntry(IsActive = true, UnitPrice = 1.00, Product2Id = p2.Id, Pricebook2Id = priceBook.Id));
        insert priceBookEntries;

        Opportunity opp = [
            SELECT Id
            FROM Opportunity
            WHERE TemplateCotation__c = 'C5'
            LIMIT 1
        ];

        Id rtElecId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Quote_Elec' LIMIT 1].Id;

        // 2️⃣ Création d'une quote TURPE
        Quote qTurpe = new Quote(
            Name = 'TURPE Quote',
            OpportunityId = opp.Id,
            RecordTypeId = rtElecId,
            IsOptimisationTurpe__c = true,
            MargeInterventionPEPS__c = 0,
            Date_de_fin_de_contrat__c = Date.today().addMonths(6),
            Pricebook2Id = priceBook.Id
        );
        insert qTurpe;

        // 3️⃣ Récupération d’un PDE et création d’un QLI associé
        PDE__c pde = [SELECT Id FROM PDE__c LIMIT 1];
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = qTurpe.Id,
            PDE__c = pde.Id,
            EconomieIdentifie__c = 1000,
            InterventionPEPS__c = 0,
            Product2Id = p2.Id,
            PricebookEntryId = priceBookEntries[1].Id,
            Quantity = 1,
            UnitPrice = 0
        );
        insert qli;

        // 4️⃣ Simulation de la configuration PEPS
        MargePEPS__c conf = new MargePEPS__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            DefaultMargin__c = 10,
            MinMargin__c = 5,
            MaxMargin__c = 20
        );
        insert conf;

        // 5️⃣ Initialisation de la page Visualforce
        PageReference pdfPage = Page.ComparatifPDF;
        pdfPage.getParameters().put('id', opp.Id);
        pdfPage.getParameters().put('fournisseurs', 'Engie');
        pdfPage.getParameters().put('quoteNumbers', '');
        pdfPage.getParameters().put('includeAllGO', 'false');
        pdfPage.getParameters().put('sectionTTC', 'false');
        pdfPage.getParameters().put('sectionSituationActuelle', 'false');
        Test.setCurrentPage(pdfPage);

        // 6️⃣ Test : exécution du contrôleur pour déclencher loadTurpeData()
        Test.startTest();
        VFC007_ComparatifPDFController ctrl = new VFC007_ComparatifPDFController();
        Test.stopTest();

        Assert.areNotEqual(null, ctrl, 'Le contrôleur doit être instancié sans erreur');

        // 7️⃣ Vérification de la méthode getInfosTurpe()
        List<Quote> turpeQuotes = VFC007_ComparatifPDFController.getInfosTurpe(opp.Id);
        Assert.isTrue(!turpeQuotes.isEmpty(), 'Une quote TURPE doit être retournée');

        // 8️⃣ Vérification de la méthode getPEPSConfig()
        Map<String, Decimal> pepsConfig = VFC007_ComparatifPDFController.getPEPSConfig();
        Assert.areEqual(10, pepsConfig.get('defaultMargin'), 'DefaultMargin doit être 10');

        // 9️⃣ Vérification de la méthode applyPEPSMargin()
        VFC007_ComparatifPDFController.applyPEPSMargin(opp.Id, 15);

        QuoteLineItem qliAfter = [
            SELECT InterventionPEPS__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];

        Quote quoteAfter = [
            SELECT MargeInterventionPEPS__c
            FROM Quote
            WHERE Id = :qTurpe.Id
        ];
        Assert.areEqual(150.00, qliAfter.InterventionPEPS__c, 'Intervention PEPS doit être d\'un montant de 150€');
        Assert.areEqual(15, quoteAfter.MargeInterventionPEPS__c, 'Marge appliquée doit être mise à jour');
    }
}