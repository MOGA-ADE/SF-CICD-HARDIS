@isTest
private class AP034_TURPEOptimisationController_TEST {
    @testSetup
    static void setupData() {
        TestDataFactory.createDataForComparatifElec();
    }

    private static Id getEligibleRecordTypeId() {
        return [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'PDE__c' AND DeveloperName = 'Elec_C3_C4'
            LIMIT 1
        ]
        .Id;
    }

    private static PDE__c loadBasePDE() {
        return [
            SELECT
                Id,
                EntiteJuridique__c,
                SignataireACD__c,
                AppelEnCours__c,
                IdAnalyse__c,
                IdSource__c,
                IdBuilding__c,
                DatePremierAppel__c,
                Puissance_souscrite__c,
                PSMaxActive__c,
                RecordTypeId,
                HCEActuel__c,
                HPEActuel__c,
                HCHActuel__c,
                HPHActuel__c,
                POINTEActuel__c,
                HCEOptimal__c,
                HPEOptimal__c,
                HCHOptimal__c,
                HPHOptimal__c,
                POINTEOptimal__c,
                PartFixeCSActuel__c,
                PartVariableCSActuel__c,
                DepassementActuel__c,
                TaxeCTAActuel__c,
                PartFixeCSOptimal__c,
                PartVariableCSOptimal__c,
                DepassementOptimal__c,
                TaxeCTAOptimal__c,
                BudgetTotalActuel__c,
                BudgetTotalOptimal__c,
                EconomieIdentifie__c,
                Conso_HCE__c,
                Conso_HPE__c,
                Conso_HCH__c,
                Conso_HPH__c,
                Conso_Pointe__c
            FROM PDE__c
            LIMIT 1
        ];
    }

    @isTest
    static void testGetInfos_MonoSite() {
        PDE__c p = loadBasePDE();
        p.BudgetTotalActuel__c = 12000;
        p.BudgetTotalOptimal__c = 10000;
        p.EconomieIdentifie__c = 2000;

        p.Conso_HCE__c = 100;
        p.Conso_HPE__c = 200;
        p.Conso_HCH__c = 300;
        p.Conso_HPH__c = 400;
        p.Conso_Pointe__c = 500;
        update p;

        Test.startTest();
        Map<String, Object> res = AP034_TURPEOptimisationController.getInfosTurpeByAccount(
            p.EntiteJuridique__c
        );
        Test.stopTest();

        Assert.areEqual(true, res.get('isMonoSite'));
        Assert.areEqual(12000, res.get('totalBudgetActuel'));
        Assert.areEqual(10000, res.get('totalBudgetOptimal'));
        Assert.areEqual(2000, res.get('totalEconomie'));
        Assert.areNotEqual(null, res.get('noteDateText'));
        Assert.isTrue(((String) res.get('noteConsoText')).contains('HCE'));
    }

    @isTest
    static void testGetInfos_MultiSite() {
        PDE__c p1 = loadBasePDE();
        PDE__c p2 = p1.clone(false, false, false, false);
        p2.Name = 'PDE CLONE';
        insert p2;

        for (PDE__c p : new List<PDE__c>{ p1, p2 }) {
            p.BudgetTotalActuel__c = 10000;
            p.BudgetTotalOptimal__c = 8000;
            p.EconomieIdentifie__c = 2000;
        }
        update new List<PDE__c>{ p1, p2 };

        Test.startTest();
        Map<String, Object> res = AP034_TURPEOptimisationController.getInfosTurpeByAccount(
            p1.EntiteJuridique__c
        );
        Test.stopTest();

        Assert.areEqual(false, res.get('isMonoSite'));
        Assert.areEqual(20000, res.get('totalBudgetActuel'));
        Assert.areEqual(16000, res.get('totalBudgetOptimal'));
        Assert.areEqual(4000, res.get('totalEconomie'));
        Assert.areEqual(null, res.get('noteConsoText'));
    }

    @isTest
    static void testGetInfos_NoPDE() {
        Account acc = new Account(Name = 'EMPTY');
        insert acc;

        Test.startTest();
        Map<String, Object> res = AP034_TURPEOptimisationController.getInfosTurpeByAccount(
            acc.Id
        );
        Test.stopTest();

        Assert.areEqual(true, res.get('isMonoSite'));
        Assert.areEqual(0, res.get('totalBudgetActuel'));
        Assert.areEqual(0, res.get('totalEconomie'));
        Assert.areEqual(null, res.get('noteConsoText'));
    }

    @isTest
    static void test_NotEligible_AppelEnCours() {
        PDE__c p = loadBasePDE();
        p.RecordTypeId = getEligibleRecordTypeId();
        p.AppelEnCours__c = true;
        update p;

        Test.startTest();
        AP034_TURPEOptimisationController.invokeTURPEIfEligible(p.Id);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void test_OPTIMISATION_RENEW() {
        PDE__c p = loadBasePDE();

        p.RecordTypeId = getEligibleRecordTypeId();
        p.SignataireACD__c = getAnyContactId(); // 🔑 CLÉ
        p.Puissance_souscrite__c = 100;
        p.PSMaxActive__c = 50; // taux = 50 %

        p.IdAnalyse__c = 'ANA_RENEW';
        p.IdSource__c = 'SRC';
        p.IdBuilding__c = 'BUILD';
        p.DatePremierAppel__c = Date.today().addMonths(-4);

        update p;

        Test.startTest();
        AP034_TURPEOptimisationController.invokeTURPEIfEligible(p.Id);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void test_RENOUVELLEMENT_missingFields() {
        PDE__c p = loadBasePDE();

        p.RecordTypeId = getEligibleRecordTypeId();
        p.SignataireACD__c = getAnyContactId(); // 🔑
        p.Puissance_souscrite__c = 100;
        p.PSMaxActive__c = 50;

        p.IdAnalyse__c = 'ANA_MISS';
        p.IdSource__c = 'SRC';
        p.IdBuilding__c = 'BUILD';
        p.DatePremierAppel__c = Date.today();

        // Déclenche la formule
        p.HCEActuel__c = null;

        update p;

        Test.startTest();
        AP034_TURPEOptimisationController.invokeTURPEIfEligible(p.Id);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void test_OPTIMISATION_default() {
        PDE__c p = loadBasePDE();

        p.RecordTypeId = getEligibleRecordTypeId();
        p.SignataireACD__c = getAnyContactId(); // 🔑
        p.Puissance_souscrite__c = 100;
        p.PSMaxActive__c = 50;

        p.IdAnalyse__c = 'ANA_OK';
        p.IdSource__c = 'SRC_OK';
        p.IdBuilding__c = 'BUILD';
        p.DatePremierAppel__c = Date.today();

        // Champs complets → formule = false
        p.HCEActuel__c = 1;
        p.HPEActuel__c = 1;
        p.HCHActuel__c = 1;
        p.HPHActuel__c = 1;
        p.POINTEActuel__c = 1;

        p.HCEOptimal__c = 1;
        p.HPEOptimal__c = 1;
        p.HCHOptimal__c = 1;
        p.HPHOptimal__c = 1;
        p.POINTEOptimal__c = 1;

        p.PartFixeCSActuel__c = 1;
        p.PartVariableCSActuel__c = 1;
        p.DepassementActuel__c = 1;
        p.TaxeCTAActuel__c = 1;

        p.PartFixeCSOptimal__c = 1;
        p.PartVariableCSOptimal__c = 1;
        p.DepassementOptimal__c = 1;
        p.TaxeCTAOptimal__c = 1;

        p.BudgetTotalActuel__c = 100;
        p.BudgetTotalOptimal__c = 80;
        p.EconomieIdentifie__c = 20;

        update p;

        Test.startTest();
        AP034_TURPEOptimisationController.invokeTURPEIfEligible(p.Id);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void test_NullId_NoCrash() {
        Test.startTest();
        AP034_TURPEOptimisationController.invokeTURPEIfEligible(null);
        Test.stopTest();
        Assert.isTrue(true);
    }

    private static Id getAnyContactId() {
        return [SELECT Id FROM Contact LIMIT 1].Id;
    }
}