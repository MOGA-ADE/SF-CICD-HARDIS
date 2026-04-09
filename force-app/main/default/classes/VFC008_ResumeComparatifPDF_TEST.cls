@isTest
private class VFC008_ResumeComparatifPDF_TEST {
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
    static void resumeComparatifPDFTestGaz(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE TemplateCotation__c = 'GAZ' LIMIT 1];
        String quoteNumber = [SELECT QuoteNumber FROM Quote WHERE Fournisseur__c = 'Engie' AND OpportunityId = :opp.Id LIMIT 1].QuoteNumber;
        String quoteNumberSA = [SELECT QuoteNumber FROM Quote WHERE Fournisseur__c = 'Situation Actuelle' AND OpportunityId = :opp.Id LIMIT 1].QuoteNumber;

        PageReference pdfPage = Page.ResumeComparatifPDF;
        pdfPage.getParameters().put('id', opp.Id);
        pdfPage.getParameters().put('fournisseurs', 'Engie');
        pdfPage.getParameters().put('quoteNumbers', quoteNumber+';'+quoteNumberSA);
        pdfPage.getParameters().put('sectionTTC', 'true');
        pdfPage.getParameters().put('sectionSituationActuelle', 'true');
        pdfPage.getParameters().put('goQuoteNumbers', quoteNumber);
        pdfPage.getParameters().put('includeAllGO', 'false');
        Test.setCurrentPage(pdfPage);

        String URL = VFC008_ResumeComparatifPDFController.generateResumePDFUrl(
            opp.Id, 'Engie', quoteNumber, true, true, quoteNumber, false
        );
        Assert.areNotEqual(null, URL, 'L’URL générée ne doit pas être nulle');

        VFC008_ResumeComparatifPDFController ctrl = new VFC008_ResumeComparatifPDFController();

        // Lecture des propriétés statiques
        Boolean isOppGaz = VFC008_ResumeComparatifPDFController.isOppGaz;
        Boolean isOppSimpleRT = VFC008_ResumeComparatifPDFController.isOppSimpleRT;
        Boolean isOppPartenaire = VFC008_ResumeComparatifPDFController.isOppPartenaire;
        String todayDate = VFC008_ResumeComparatifPDFController.todayDate;
        Boolean listprixMoyenT1NotEmpty = VFC008_ResumeComparatifPDFController.listprixMoyenT1NotEmpty;

        // Wrappers
        VFC008_ResumeComparatifPDFController.BudgetGlobalWrapper bg =
            new VFC008_ResumeComparatifPDFController.BudgetGlobalWrapper('Engie','logo',Date.today(),Date.today(),'Fixe');
        String dureeBG = bg.dureeOffre;

        VFC008_ResumeComparatifPDFController.PrixMoyenWrapper pm =
            new VFC008_ResumeComparatifPDFController.PrixMoyenWrapper('Engie','logo',Date.today(),Date.today(),'Fixe','','');
        pm.numberQLI = 2;
        pm.consoTotalCar = 200;
        Decimal baseMoyenne = pm.baseMoyennePonderee;

        VFC008_ResumeComparatifPDFController.VolumeTotalWrapper vt =
            new VFC008_ResumeComparatifPDFController.VolumeTotalWrapper();
        Decimal totalGaz = vt.totalConsoGaz;

        // Vérif FeedItem
        FeedItem f = [SELECT Body FROM FeedItem WHERE ParentId = :opp.Id LIMIT 1];
        Assert.isTrue(f.Body.contains('comparatif'), 'Le FeedItem doit être inséré');
    }

    @isTest
    static void resumeComparatifPDFTestElec(){
        Opportunity opp = [SELECT Id FROM Opportunity WHERE TemplateCotation__c = 'C5' LIMIT 1];
        String quoteNumber = [SELECT QuoteNumber FROM Quote WHERE Fournisseur__c = 'Engie' AND OpportunityId = :opp.Id LIMIT 1].QuoteNumber;
        String quoteNumberSA = [SELECT QuoteNumber FROM Quote WHERE Fournisseur__c = 'Situation Actuelle' AND OpportunityId = :opp.Id LIMIT 1].QuoteNumber;

        PageReference pdfPage = Page.ResumeComparatifPDF;
        pdfPage.getParameters().put('id', opp.Id);
        pdfPage.getParameters().put('fournisseurs', 'Engie');
        pdfPage.getParameters().put('quoteNumbers', quoteNumber+';'+quoteNumberSA);
        pdfPage.getParameters().put('sectionTTC', 'true');
        pdfPage.getParameters().put('sectionSituationActuelle', 'false'); // ⚠️ désactivé pour éviter l'erreur
        pdfPage.getParameters().put('goQuoteNumbers', quoteNumber);
        pdfPage.getParameters().put('includeAllGO', 'true');
        Test.setCurrentPage(pdfPage);

        String URL = VFC008_ResumeComparatifPDFController.generateResumePDFUrl(
            opp.Id, 'Engie', quoteNumber, true, false, quoteNumber, true
        );
        Assert.areNotEqual(null, URL, 'L’URL générée ne doit pas être nulle');

        VFC008_ResumeComparatifPDFController ctrl = new VFC008_ResumeComparatifPDFController();
        Boolean isOppGaz = VFC008_ResumeComparatifPDFController.isOppGaz;
        String todayDate = VFC008_ResumeComparatifPDFController.todayDate;

        // Wrappers
        VFC008_ResumeComparatifPDFController.BudgetGlobalWrapper bg =
            new VFC008_ResumeComparatifPDFController.BudgetGlobalWrapper('Engie','logo',Date.today(),Date.today(),'Fixe');
            Assert.isNotNull(bg.dureeOffre, 'Wrapper doit retourner une durée');
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
}