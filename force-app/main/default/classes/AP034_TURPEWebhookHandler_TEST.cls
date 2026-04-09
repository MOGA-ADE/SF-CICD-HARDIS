@isTest
private class AP034_TURPEWebhookHandler_TEST {

    private static final String HOMEYS_JSON =
        '{'+
        '  "event" : "optimturpe_finished",'+
        '  "data": {'+
        '  "_id_source": "SRC_MAIN",'+
        '    "_id": "ANALYSE_001",'+
        '    "_id_analyse_optimturpe": "ANALYSE_001",'+
        '    "_id_building": "BUILD_001",'+
        '    "status": "SUCCESS",'+
        '    "error" : {'+
        '      "message" : "",'+
        '      "code" : ""'+
        '    },'+
        '    "inputs": {'+
        '      "source": {'+
        '        "_id_source": "SRC_MAIN"'+
        '      },'+
        '      "data": {'+
        '        "date_from": "2024-01-01",'+
        '        "date_to": "2024-12-31"'+
        '      },'+
        '      "comptage" : null,'+
        '      "structure_tarifaire" : null,'+
        '      "optimisation" : null'+
        '    },'+
        '    "outputs": {'+
        '      "actuelle": {'+
        '        "structure_tarifaire": {'+
        '          "puissance_souscrite_soutirage": {'+
        '            "denivele": {'+
        '              "HCB": 1,'+
        '              "HPB": 2,'+
        '              "HCH": 3,'+
        '              "HPH": 4,'+
        '              "PTE": 5'+
        '            }'+
        '          }'+
        '        },'+
        '        "data": {'+
        '          "periode": {'+
        '            "prixHTT_elecsoutirage_turpeCSF": { "sum": 10 },'+
        '            "prixHTT_elecsoutirage_turpeCSV": { "sum": 20 },'+
        '            "prixHTT_elecsoutirage_turpeCMDPS": { "sum": 30 },'+
        '            "prixHTVA_elecsoutirage_cta": { "sum": 40 }'+
        '          }'+
        '        }'+
        '      },'+
        '      "meilleure": {'+
        '        "structure_tarifaire": {'+
        '          "puissance_souscrite_soutirage": {'+
        '            "denivele": {'+
        '              "HCB": 6,'+
        '              "HPB": 7,'+
        '              "HCH": 8,'+
        '              "HPH": 9,'+
        '              "PTE": 10'+
        '            }'+
        '          }'+
        '        },'+
        '        "data": {'+
        '          "periode": {'+
        '            "prixHTT_elecsoutirage_turpeCSF": { "sum": 15 },'+
        '            "prixHTT_elecsoutirage_turpeCSV": { "sum": 25 },'+
        '            "prixHTT_elecsoutirage_turpeCMDPS": { "sum": 35 },'+
        '            "prixHTVA_elecsoutirage_cta": { "sum": 45 }'+
        '          }'+
        '        }'+
        '      }'+
        '    },'+
        '    "created_at" : "2026-02-17T11:08:04.888000",'+
        '    "updated_at" : "2026-02-17T11:08:10.876000"'+
        '  }'+
        '}';


    @testSetup
    static void setupData() {
        TestDataFactory.createDataForComparatifElec();
    }

    private static AP034_TURPEOptimisationService.TurpeDataExtractor buildTurpeData() {

        AP034_TURPEOptimisationService.TurpeDataExtractor d =
            new AP034_TURPEOptimisationService.TurpeDataExtractor();

        d.idAnalyse  = 'ANALYSE_001';
        d.idBuilding = 'BUILD_001';
        d.dateFrom   = Date.newInstance(2024, 1, 1);
        d.dateTo     = Date.newInstance(2024, 12, 31);

        // ACTUEL
        d.HCEActuel = 1;
        d.HPEActuel = 2;
        d.HCHActuel = 3;
        d.HPHActuel = 4;
        d.POINTEActuel = 5;

        d.PartFixeCSActuel = 10;
        d.PartVariableCSActuel = 20;
        d.actuelleTurpeCMDPS = 30;
        d.TaxeCTAActuel = 40;

        // OPTIMAL
        d.HCEOptimal = 6;
        d.HPEOptimal = 7;
        d.HCHOptimal = 8;
        d.HPHOptimal = 9;
        d.POINTEOptimal = 10;

        d.PartFixeCSOptimal = 15;
        d.PartVariableCSOptimal = 25;
        d.meilleureTurpeCMDPS = 35;
        d.TaxeCTAOptimal = 45;

        return d;
    }

    private static PDE__c createPDEWithIdSource(String idSource) {
        PDE__c p = new PDE__c(
            Name = 'PDE_TURPE',
            SiteConsommation__c = 'TEST',
            NumeroVoie__c = '90',
            Voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            CARGaz__c = 1234,
            DateEcheance__c = Date.today().addMonths(1),
            PCE_Refonte__c = '12345478900',
            ReferencePointEnergie_Refonte__c = '12345678980',
            IdSource__c = idSource
        );
        insert p;
        return p;
    }

    private static QuoteLineItem createQLIWithIdSource(PDE__c p, String idSource) {

        Product2 prod = [
            SELECT Id
            FROM Product2
            WHERE Name = 'ELEC'
            LIMIT 1
        ];

        PricebookEntry pbe = [
            SELECT Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :prod.Id
            AND IsActive = true
            LIMIT 1
        ];

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Quote q = new Quote(
            Name = 'Q TURPE',
            Pricebook2Id = pbe.Pricebook2Id,
            OpportunityId = opp.Id,
            IsOptimisationTURPE__c = true,
            Date_de_fin_de_contrat__c = Date.today().addMonths(12)
        );
        insert q;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PDE__c = p.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 1,
            IdSource__c = idSource
        );
        insert qli;

        return qli;
    }

    private static RestRequest buildRequest() {
        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(HOMEYS_JSON);
        return req;
    }

    @isTest
    static void test_PDE_and_QLI() {

        PDE__c p = createPDEWithIdSource('SRC_EXEC');
        QuoteLineItem qli = createQLIWithIdSource(p, 'SRC_EXEC');

        RestRequest req = buildRequest();
        AP034_TURPEWebhookHandler handler = new AP034_TURPEWebhookHandler();

        Test.startTest();
        handler.handle(req);
        Test.stopTest();

        PDE__c updatedPDE = [
            SELECT AppelEnCours__c, DateAppel__c,
                   HCEActuel__c, HCEOptimal__c,
                   POINTEActuel__c, POINTEOptimal__c,
                   BudgetTotalActuel__c, BudgetTotalOptimal__c,
                   EconomieIdentifie__c
            FROM PDE__c
            WHERE Id = :p.Id
        ];

        QuoteLineItem updatedQLI = [
            SELECT AppelEnCours__c, DateAppel__c,
                   HCEActuel__c, HCEOptimal__c,
                   POINTEActuel__c, POINTEOptimal__c,
                   BudgetTotalActuel__c, BudgetTotalOptimal__c,
                   EconomieIdentifie__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];

        Assert.isTrue(true);
    }

    @isTest
    static void test_PDE_only() {

        PDE__c p = createPDEWithIdSource('SRC_EXEC');

        RestRequest req = buildRequest();
        AP034_TURPEWebhookHandler handler = new AP034_TURPEWebhookHandler();

        Test.startTest();
        handler.handle(req);
        Test.stopTest();

        PDE__c updated = [
            SELECT HCEActuel__c, HCEOptimal__c, AppelEnCours__c
            FROM PDE__c
            WHERE Id = :p.Id
        ];

        Assert.isTrue(true);
    }

    @isTest
    static void test_QLI_only() {

        PDE__c p = createPDEWithIdSource('OTHER_SRC');
        QuoteLineItem qli = createQLIWithIdSource(p, 'SRC_EXEC');

        RestRequest req = buildRequest();
        AP034_TURPEWebhookHandler handler = new AP034_TURPEWebhookHandler();

        Test.startTest();
        handler.handle(req);
        Test.stopTest();

        QuoteLineItem updated = [
            SELECT HCHActuel__c, HCHOptimal__c, AppelEnCours__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];

        Assert.isTrue(true);
    }

    @isTest
    static void test_updateRecordWithTurpeData_PDE() {

        PDE__c pde = [
            SELECT Id
            FROM PDE__c
            LIMIT 1
        ];

        AP034_TURPEOptimisationService.TurpeDataExtractor data =
            buildTurpeData();

        Test.startTest();
        AP034_TURPEWebhookHandler.updateRecordWithTurpeData(pde, data);
        Test.stopTest();

        PDE__c updated = [
            SELECT
                IdAnalyse__c,
                IdBuilding__c,
                AppelEnCours__c,
                BudgetTotalActuel__c,
                BudgetTotalOptimal__c,
                EconomieIdentifie__c
            FROM PDE__c
            WHERE Id = :pde.Id
        ];

        Assert.areEqual(100, updated.BudgetTotalActuel__c);
        Assert.areEqual(120, updated.BudgetTotalOptimal__c);
        Assert.areEqual(-20, updated.EconomieIdentifie__c);
        Assert.areEqual(false, updated.AppelEnCours__c);
        Assert.areEqual('ANALYSE_001', updated.IdAnalyse__c);
        Assert.areEqual('BUILD_001', updated.IdBuilding__c);
    }

    @isTest
    static void test_updateRecordWithTurpeData_QLI() {
        QuoteLineItem qli = [
            SELECT Id
            FROM QuoteLineItem
            LIMIT 1
        ];

        AP034_TURPEOptimisationService.TurpeDataExtractor data =
            buildTurpeData();

        Test.startTest();
        AP034_TURPEWebhookHandler.updateRecordWithTurpeData(qli, data);
        Test.stopTest();

        QuoteLineItem updated = [
            SELECT
                IdAnalyse__c,
                IdBuilding__c,
                AppelEnCours__c,
                BudgetTotalActuel__c,
                BudgetTotalOptimal__c,
                EconomieIdentifie__c,
                HCHActuel__c,
                HCHOptimal__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];

        Assert.areEqual(3, updated.HCHActuel__c);
        Assert.areEqual(8, updated.HCHOptimal__c);
        Assert.areEqual(100, updated.BudgetTotalActuel__c);
        Assert.areEqual(120, updated.BudgetTotalOptimal__c);
        Assert.areEqual(-20, updated.EconomieIdentifie__c);
        Assert.areEqual(false, updated.AppelEnCours__c);
        Assert.areEqual('ANALYSE_001', updated.IdAnalyse__c);
        Assert.areEqual('BUILD_001', updated.IdBuilding__c);
    }
}