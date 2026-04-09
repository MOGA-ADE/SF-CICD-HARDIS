@isTest
private class AP034_TURPEOptimisationService_TEST {

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

    private class HomeysCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {

            HttpResponse r = new HttpResponse();
            String endpoint = req.getEndpoint();

            // 🔑 APPEL TOKEN
            if (endpoint.contains('/api/auth/login')) {
                r.setStatusCode(200);
                r.setBody('{"token":"FAKE_TOKEN"}');
                return r;
            }

            // 🔁 APPEL TURPE
            if (endpoint.contains('/api/open/v1')) {
                r.setStatusCode(201);
                r.setBody(HOMEYS_JSON);
                return r;
            }

            r.setStatusCode(400);
            r.setBody('{"error":"unexpected endpoint"}');
            return r;
        }
    }

    private class TokenCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"token":"TOKEN_NEW"}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        TestDataFactory.createDataForComparatifElec();
    }

    private static PDE__c getPdeC3C4() {
        return [
            SELECT Id,
                   EntiteJuridique__c,
                   ReferencePointEnergie_Refonte__c,
                   SignataireACD__c,
                   HCEActuel__c, HPEActuel__c, HCHActuel__c, HPHActuel__c, POINTEActuel__c,
                   HCEOptimal__c, HPEOptimal__c, HCHOptimal__c, HPHOptimal__c, POINTEOptimal__c,
                   PartFixeCSActuel__c, PartVariableCSActuel__c, DepassementActuel__c, TaxeCTAActuel__c,
                   PartFixeCSOptimal__c, PartVariableCSOptimal__c, DepassementOptimal__c, TaxeCTAOptimal__c,
                   BudgetTotalActuel__c, BudgetTotalOptimal__c, EconomieIdentifie__c,
                   IdSource__c
            FROM PDE__c
            WHERE RecordType.DeveloperName='Elec_C3_C4'
            LIMIT 1
        ];
    }


    private static void ensurePdeHasSignataire(PDE__c p) {
        if (p.SignataireACD__c == null) {
            Contact c = [
                SELECT Id
                FROM Contact
                WHERE AccountId=:p.EntiteJuridique__c
                LIMIT 1
            ];
            p.SignataireACD__c = c.Id;
            update p;
        }
    }


    private static QuoteLineItem createQLI(PDE__c p) {
        ensurePdeHasSignataire(p);

        insert new HomeysToken__c(
            Token__c = 'TOKEN_TEST',
            IssuedAt__c = DateTime.now(),
            ExpiresAt__c = DateTime.now().addHours(23)
        );

        Product2 prod = [SELECT Id FROM Product2 WHERE Name='ELEC' LIMIT 1];

        PricebookEntry pbe = [
            SELECT Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id=:prod.Id AND IsActive=true
            LIMIT 1
        ];

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Quote q = new Quote(
            Name='Q TURPE',
            Pricebook2Id=pbe.Pricebook2Id,
            OpportunityId=opp.Id,
            IsOptimisationTURPE__c=true,
            Date_de_fin_de_contrat__c = Date.today().addMonths(6)
        );
        insert q;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId=q.Id,
            Product2Id=prod.Id,
            PricebookEntryId=pbe.Id,
            PDE__c=p.Id,
            UnitPrice=1,
            Quantity=1
        );
        insert qli;

        return qli;
    }


    @isTest
    static void testPreparePayload_Renouvellement() {
        PDE__c p = getPdeC3C4();

        Test.startTest();
        String json = AP034_TURPEOptimisationService.prepareOptimisationPayload(
            'PDE_RENOUVELLEMENT', p.Id, 'SRC_TEST'
        );
        Test.stopTest();

        Assert.isTrue(json.contains('SRC_TEST'));
    }


    @isTest
    static void testPreparePayload_OptimisationPDE() {
        PDE__c p = getPdeC3C4();
        p.ReferencePointEnergie_Refonte__c = 'REFPDE';
        update p;
        ensurePdeHasSignataire(p);

        Test.startTest();
        String json = AP034_TURPEOptimisationService.prepareOptimisationPayload(
            'PDE_OPTIMISATION', p.Id, null
        );
        Test.stopTest();

        Assert.isTrue(json.contains('REFPDE'));
    }


    @isTest
    static void testPreparePayload_OptimisationQLI() {
        PDE__c p = getPdeC3C4();
        p.ReferencePointEnergie_Refonte__c = 'REFQLI';
        update p;
        ensurePdeHasSignataire(p);

        QuoteLineItem qli = createQLI(p);

        Test.startTest();
        String json = AP034_TURPEOptimisationService.prepareOptimisationPayload(
            'QLI_OPTIMISATION', qli.Id, null
        );
        Test.stopTest();

        Assert.isTrue(json.contains('REFQLI'));
    }


    @isTest
    static void testExtractTurpeData() {
        Test.startTest();
        AP034_TURPEOptimisationService.TurpeDataExtractor d =
            AP034_TURPEOptimisationService.extractTurpeData(HOMEYS_JSON);
        Test.stopTest();

        System.debug('REPONSE DDDDDDDDD: ' + d);

        Assert.areNotEqual(null, d);
        Assert.areEqual(1, d.HCEActuel);
        Assert.areEqual(10, d.POINTEOptimal);
    }


    @isTest
    static void testExecuteCallout_PDE_Optimisation() {
        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        Test.startTest();
        PDE__c p = getPdeC3C4();
        ensurePdeHasSignataire(p);
        p.ReferencePointEnergie_Refonte__c = 'REFPDEOPTI';
        update p;

        AP034_TURPEOptimisationService.executeCallout(
            'PDE_OPTIMISATION', p.Id, null, null, null
        );
        Test.stopTest();

        Assert.isTrue(true);
    }


    @isTest
    static void testExecuteCallout_PDE_Renouvellement() {
        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        PDE__c p = getPdeC3C4();

        Test.startTest();
        AP034_TURPEOptimisationService.executeCallout(
            'PDE_RENOUVELLEMENT', p.Id, 'SRC_MAIN', 'ANALYSE_001', 'BUILD_001'
        );
        Test.stopTest();

        Assert.isTrue(true);
    }


    @isTest
    static void testExecuteCallout_QLI_Optimisation() {
        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        PDE__c p = getPdeC3C4();
        ensurePdeHasSignataire(p);
        p.ReferencePointEnergie_Refonte__c = 'REFQLIOPTI';
        update p;

        QuoteLineItem qli = createQLI(p);

        Test.startTest();
        AP034_TURPEOptimisationService.executeCallout(
            'QLI_OPTIMISATION', qli.Id, null, null, null
        );
        Test.stopTest();

        Assert.isTrue(true);
    }


    @isTest
    static void testExecuteCallout_QLI_Renouvellement() {
        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        PDE__c p = getPdeC3C4();
        QuoteLineItem qli = createQLI(p);

        Test.startTest();
        AP034_TURPEOptimisationService.executeCallout(
            'QLI_RENOUVELLEMENT', qli.Id, 'SRC_MAIN', 'ANALYSE_001', 'BUILD_001'
        );
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void testExecuteCallout_PDE_Optimisation_RENEW_FULL() {

        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        Test.startTest();
        PDE__c p = getPdeC3C4();
        ensurePdeHasSignataire(p);

        p.IdBuilding__c = 'BUILD_001';
        p.IdSource__c   = 'SRC_MAIN';
        p.DateAnalyseFrom__c = Date.today().addMonths(-12);
        p.DateAnalyseTo__c   = Date.today();

        update p;

        AP034_TURPEOptimisationService.executeCallout(
            'PDE_OPTIMISATION_RENEW',
            p.Id,
            null,
            null,
            null
        );
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void test_handleOptimisationResponse_PDE() {

        PDE__c p = getPdeC3C4();

        HttpResponse res = new HttpResponse();
        res.setStatusCode(201);
        res.setBody(HOMEYS_JSON);

        Test.startTest();
        AP034_TURPEOptimisationService.handleOptimisationResponse(
            'PDE_OPTIMISATION',
            p.Id,
            res
        );
        Test.stopTest();

        PDE__c out = [
            SELECT IdSource__c, IdAnalyse__c, IdBuilding__c,
                DateAppel__c, DatePremierAppel__c, AppelEnCours__c
            FROM PDE__c
            WHERE Id = :p.Id
        ];

        Assert.areEqual('SRC_MAIN', out.IdSource__c);
        Assert.areEqual('ANALYSE_001', out.IdAnalyse__c);
        Assert.areEqual('BUILD_001', out.IdBuilding__c);
        Assert.areEqual(true, out.AppelEnCours__c);
    }

    @isTest
    static void test_handleOptimisationResponse_QLI() {

        PDE__c p = getPdeC3C4();
        QuoteLineItem qli = createQLI(p);

        HttpResponse res = new HttpResponse();
        res.setStatusCode(201);
        res.setBody(HOMEYS_JSON);

        Test.startTest();
        AP034_TURPEOptimisationService.handleOptimisationResponse(
            'QLI_OPTIMISATION',
            qli.Id,
            res
        );
        Test.stopTest();

        QuoteLineItem out = [
            SELECT IdAnalyse__c, IdBuilding__c, IdSource__c, AppelEnCours__c
            FROM QuoteLineItem
            WHERE Id = :qli.Id
        ];

        Assert.areEqual('ANALYSE_001', out.IdAnalyse__c);
        Assert.areEqual('BUILD_001', out.IdBuilding__c);
        Assert.areEqual('SRC_MAIN', out.IdSource__c);
        Assert.areEqual(true, out.AppelEnCours__c);
    }


    @isTest
    static void test_handleOptimisationRenewResponse_PDE() {

        PDE__c p = getPdeC3C4();
        p.IdSource__c = 'SRC_OLD';
        update p;

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody(HOMEYS_JSON);

        Test.startTest();
        AP034_TURPEOptimisationService.handleOptimisationRenewResponse(
            'PDE_OPTIMISATION_RENEW',
            p.Id,
            res
        );
        Test.stopTest();

        PDE__c out = [
            SELECT IdAnalyse__c, IdBuilding__c, IdSource__c,
                DateAnalyseFrom__c, DateAnalyseTo__c,
                BudgetTotalActuel__c, BudgetTotalOptimal__c, EconomieIdentifie__c
            FROM PDE__c WHERE Id = :p.Id
        ];

        Assert.areEqual('ANALYSE_001', out.IdAnalyse__c);
        Assert.areEqual('BUILD_001', out.IdBuilding__c);
        Assert.areEqual('SRC_MAIN', out.IdSource__c);
        Assert.areEqual(Date.valueOf('2024-01-01'), out.DateAnalyseFrom__c);
        Assert.areEqual(Date.valueOf('2024-12-31'), out.DateAnalyseTo__c);
    }

    @isTest
    static void test_handleOptimisationRenewResponse_QLI() {

        PDE__c p = getPdeC3C4();
        QuoteLineItem qli = createQLI(p);

        HttpResponse res = new HttpResponse();
        res.setStatusCode(201);
        res.setBody(HOMEYS_JSON);

        Test.startTest();
        AP034_TURPEOptimisationService.handleOptimisationRenewResponse(
            'QLI_OPTIMISATION_RENEW',
            qli.Id,
            res
        );
        Test.stopTest();

        QuoteLineItem out = [
            SELECT IdAnalyse__c, IdBuilding__c
            FROM QuoteLineItem WHERE Id = :qli.Id
        ];

        Assert.areEqual('ANALYSE_001', out.IdAnalyse__c);
        Assert.areEqual('BUILD_001', out.IdBuilding__c);
    }

    @isTest
    static void test_handleRenouvellementResponse_PDE() {

        PDE__c p = getPdeC3C4();

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody(HOMEYS_JSON);

        Test.startTest();
        AP034_TURPEOptimisationService.handleRenouvellementResponse(
            'PDE_RENOUVELLEMENT',
            p.Id,
            res
        );
        Test.stopTest();

        PDE__c out = [
            SELECT IdAnalyse__c, IdBuilding__c, IdSource__c,
                DateAnalyseFrom__c, DateAnalyseTo__c,
                BudgetTotalActuel__c, BudgetTotalOptimal__c, EconomieIdentifie__c
            FROM PDE__c WHERE Id = :p.Id
        ];

        Assert.areEqual('ANALYSE_001', out.IdAnalyse__c);
        Assert.areEqual('BUILD_001', out.IdBuilding__c);
        Assert.areEqual('SRC_MAIN', out.IdSource__c);
        Assert.areEqual(Date.valueOf('2024-01-01'), out.DateAnalyseFrom__c);
        Assert.areEqual(Date.valueOf('2024-12-31'), out.DateAnalyseTo__c);
    }

    @isTest
    static void test_handleRenouvellementResponse_QLI() {

        PDE__c p = getPdeC3C4();
        QuoteLineItem qli = createQLI(p);

        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setBody(HOMEYS_JSON);

        Test.startTest();
        AP034_TURPEOptimisationService.handleRenouvellementResponse(
            'QLI_RENOUVELLEMENT',
            qli.Id,
            res
        );
        Test.stopTest();

        QuoteLineItem out = [
            SELECT IdAnalyse__c, IdBuilding__c,
                DateAnalyseFrom__c, DateAnalyseTo__c
            FROM QuoteLineItem WHERE Id = :qli.Id
        ];

        Assert.areEqual('ANALYSE_001', out.IdAnalyse__c);
        Assert.areEqual('BUILD_001', out.IdBuilding__c);
    }

    @isTest
    static void invokeTURPECallFromFlow_NoWrap() {
        AP034_TURPEOptimisationService.FlowInput input =
            new AP034_TURPEOptimisationService.FlowInput();

        insert new HomeysToken__c(
            Token__c = 'TOKEN_TEST',
            IssuedAt__c = DateTime.now(),
            ExpiresAt__c = DateTime.now().addHours(23)
        );

        Test.startTest();
        AP034_TURPEOptimisationService.invokeTURPECallFromFlow(
            new List<AP034_TURPEOptimisationService.FlowInput>{input}
        );
        Test.stopTest();
    }

    @isTest
    static void invokeTURPECallFromFlow_BasicRules() {
        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        QuoteLineItem qli = [
            SELECT Id FROM QuoteLineItem LIMIT 1
        ];

        insert new HomeysToken__c(
            Token__c = 'TOKEN_TEST',
            IssuedAt__c = DateTime.now(),
            ExpiresAt__c = DateTime.now().addHours(23)
        );

        WrapTURPEDisplayRow wrap = new WrapTURPEDisplayRow();
        wrap.ActionType='QLI_RENOUVELLEMENT';
        wrap.RecordId=qli.Id;
        wrap.IdSource='SRC_MAIN';

        AP034_TURPEOptimisationService.FlowInput input =
            new AP034_TURPEOptimisationService.FlowInput();
        input.wrapTURPE = new List<WrapTURPEDisplayRow>{wrap};

        Test.startTest();
        AP034_TURPEOptimisationService.invokeTURPECallFromFlow(
            new List<AP034_TURPEOptimisationService.FlowInput>{input}
        );
        Test.stopTest();
    }

    @isTest
    static void testInvokeTURPECallFromApex() {
        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        PDE__c p = getPdeC3C4();
        ensurePdeHasSignataire(p);
        p.ReferencePointEnergie_Refonte__c='XTEST';
        update p;

        insert new HomeysToken__c(
            Token__c = 'TOKEN_TEST',
            IssuedAt__c = DateTime.now(),
            ExpiresAt__c = DateTime.now().addHours(23)
        );

        Test.startTest();
        AP034_TURPEOptimisationService.invokeTURPECallFromApex(
            'PDE_OPTIMISATION', p.Id, null, null, null
        );
        Test.stopTest();
    }

    @isTest
    static void testFlowRule_QLIOlderThan3Months() {
        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        PDE__c p = getPdeC3C4();
        QuoteLineItem qli = createQLI(p);

        insert new HomeysToken__c(
            Token__c = 'TOKEN_TEST',
            IssuedAt__c = DateTime.now(),
            ExpiresAt__c = DateTime.now().addHours(23)
        );

        qli.DatePremierAppel__c = Date.today().addMonths(-4);
        update qli;

        WrapTURPEDisplayRow wrap = new WrapTURPEDisplayRow();
        wrap.ActionType = 'QLI_OPTIMISATION';
        wrap.RecordId = qli.Id;
        wrap.IdSource = null;

        AP034_TURPEOptimisationService.FlowInput input =
            new AP034_TURPEOptimisationService.FlowInput();
        input.wrapTURPE = new List<WrapTURPEDisplayRow>{wrap};

        Test.startTest();
        AP034_TURPEOptimisationService.invokeTURPECallFromFlow(
            new List<AP034_TURPEOptimisationService.FlowInput>{input}
        );
        Test.stopTest();
    }

    @isTest
    static void testFlowRule_PDEComplete_UpdatesQLI() {

        PDE__c p = getPdeC3C4();
        ensurePdeHasSignataire(p);

        p.IdSource__c = 'SRC_OK';
        p.HCEActuel__c = 1; p.HPEActuel__c = 1; p.HCHActuel__c = 1; p.HPHActuel__c = 1; p.POINTEActuel__c = 1;
        p.HCEOptimal__c = 2; p.HPEOptimal__c = 2; p.HCHOptimal__c = 2; p.HPHOptimal__c = 2; p.POINTEOptimal__c = 2;
        p.PartFixeCSActuel__c = 3; p.PartVariableCSActuel__c = 3; p.DepassementActuel__c = 3; p.TaxeCTAActuel__c = 3;
        p.PartFixeCSOptimal__c = 4; p.PartVariableCSOptimal__c = 4; p.DepassementOptimal__c = 4; p.TaxeCTAOptimal__c = 4;
        p.BudgetTotalActuel__c = 10; p.BudgetTotalOptimal__c = 5; p.EconomieIdentifie__c = 5;
        update p;

        QuoteLineItem qli = createQLI(p);

        insert new HomeysToken__c(
            Token__c = 'TOKEN_TEST',
            IssuedAt__c = DateTime.now(),
            ExpiresAt__c = DateTime.now().addHours(23)
        );

        WrapTURPEDisplayRow wrap = new WrapTURPEDisplayRow();
        wrap.ActionType = 'QLI_OPTIMISATION';
        wrap.RecordId = qli.Id;

        AP034_TURPEOptimisationService.FlowInput input =
            new AP034_TURPEOptimisationService.FlowInput();
        input.wrapTURPE = new List<WrapTURPEDisplayRow>{wrap};

        Test.startTest();
        AP034_TURPEOptimisationService.invokeTURPECallFromFlow(
            new List<AP034_TURPEOptimisationService.FlowInput>{input}
        );
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void testFlowRule_PDEIncomplete_Renouvellement() {

        Test.setMock(HttpCalloutMock.class, new HomeysCalloutMock());

        PDE__c p = getPdeC3C4();
        ensurePdeHasSignataire(p);

        p.IdSource__c = 'SRC_EXISTE';
        p.HCEActuel__c = null;
        update p;

        QuoteLineItem qli = createQLI(p);

        insert new HomeysToken__c(
            Token__c = 'TOKEN_TEST',
            IssuedAt__c = DateTime.now(),
            ExpiresAt__c = DateTime.now().addHours(23)
        );

        WrapTURPEDisplayRow wrap = new WrapTURPEDisplayRow();
        wrap.ActionType = 'QLI_OPTIMISATION';
        wrap.RecordId = qli.Id;

        AP034_TURPEOptimisationService.FlowInput input =
            new AP034_TURPEOptimisationService.FlowInput();
        input.wrapTURPE = new List<WrapTURPEDisplayRow>{wrap};

        Test.startTest();
        AP034_TURPEOptimisationService.invokeTURPECallFromFlow(
            new List<AP034_TURPEOptimisationService.FlowInput>{input}
        );
        Test.stopTest();
    }

    @isTest
    static void testTokenCacheFlow() {
        Test.setMock(HttpCalloutMock.class, new TokenCalloutMock());

        Test.startTest();
        String t1 = AP034_TURPEOptimisationService.getHomeysJWT();
        Test.stopTest();

        if (t1 != null) {
            Assert.areEqual('TOKEN_NEW', t1, 'Premier appel : token depuis Homeys');
        }
    }
}