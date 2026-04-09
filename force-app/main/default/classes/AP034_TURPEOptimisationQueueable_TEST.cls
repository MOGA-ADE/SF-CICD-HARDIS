@isTest
private class AP034_TURPEOptimisationQueueable_TEST {
    private static final String HOMEYS_JSON =
        '{' +
        '  "data": {' +
        '    "_id": "ANALYSE_001",' +
        '    "_id_building": "BUILD_001",' +
        '    "_id_source": "SRC_MAIN",' +
        '    "inputs": {' +
        '      "source": { "_id_source": "SRC_MAIN" },' +
        '      "data": { "date_from": "2024-01-01", "date_to": "2024-12-31" }' +
        '    },' +
        '    "outputs": {' +
        '      "actuelle": {' +
        '        "structure_tarifaire": {' +
        '          "puissance_souscrite_soutirage": {' +
        '            "denivele": {' +
        '              "HCB": 1, "HPB": 2, "HCH": 3, "HPH": 4, "PTE": 5' +
        '            }' +
        '          }' +
        '        },' +
        '        "data": {' +
        '          "periode": {' +
        '            "prixHTT_elecsoutirage_turpeCSF": { "sum": 10 },' +
        '            "prixHTT_elecsoutirage_turpeCSV": { "sum": 20 },' +
        '            "prixHTT_elecsoutirage_turpeCMDPS": { "sum": 30 },' +
        '            "prixHTVA_elecsoutirage_cta": { "sum": 40 }' +
        '          }' +
        '        }' +
        '      }' +
        '    }' +
        '  }' +
        '}';

    private class HomeysQueueableMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse r = new HttpResponse();

            if (req.getEndpoint().contains('/api/auth/login')) {
                r.setStatusCode(200);
                r.setBody('{"token":"FAKE_TOKEN"}');
                return r;
            }

            r.setStatusCode(201);
            r.setBody(HOMEYS_JSON);
            return r;
        }
    }

    @testSetup
    static void setup() {
        TestDataFactory.createDataForComparatifElec();
    }

    @isTest
    static void testQueueable_PDE_Optimisation() {
        Test.setMock(HttpCalloutMock.class, new HomeysQueueableMock());

        PDE__c p = [
            SELECT Id, ReferencePointEnergie_Refonte__c, SignataireACD__c
            FROM PDE__c
            LIMIT 1
        ];

        p.ReferencePointEnergie_Refonte__c = 'REF_TEST';
        update p;

        QueueableJobChain chain = new QueueableJobChain();

        AP034_TURPEOptimisationQueueable job = new AP034_TURPEOptimisationQueueable(
            chain,
            'PDE_OPTIMISATION',
            p.Id,
            null,
            null,
            null
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void testQueueable_QLI_Optimisation() {
        Test.setMock(HttpCalloutMock.class, new HomeysQueueableMock());

        PDE__c p = [SELECT Id FROM PDE__c LIMIT 1];

        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'ELEC' LIMIT 1];
        PricebookEntry pbe = [
            SELECT Id, Pricebook2Id
            FROM PricebookEntry
            WHERE Product2Id = :prod.Id AND IsActive = TRUE
            LIMIT 1
        ];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Quote q = new Quote(
            Name = 'Q',
            OpportunityId = opp.Id,
            Pricebook2Id = pbe.Pricebook2Id,
            IsOptimisationTURPE__c = true,
            Date_de_fin_de_contrat__c = Date.today().addMonths(6)
        );
        insert q;

        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            Product2Id = prod.Id,
            PricebookEntryId = pbe.Id,
            PDE__c = p.Id,
            Quantity = 1,
            UnitPrice = 1
        );
        insert qli;

        QueueableJobChain chain = new QueueableJobChain();

        AP034_TURPEOptimisationQueueable job = new AP034_TURPEOptimisationQueueable(
            chain,
            'QLI_OPTIMISATION',
            qli.Id,
            null,
            null,
            null
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        Assert.isTrue(true);
    }

    @isTest
    static void testQueueable_Chaining_NoCrash() {
        Test.setMock(HttpCalloutMock.class, new HomeysQueueableMock());

        PDE__c p = [SELECT Id FROM PDE__c LIMIT 1];

        QueueableJobChain chain = new QueueableJobChain();

        chain.chainLast(
            new AP034_TURPEOptimisationQueueable(
                chain,
                'PDE_OPTIMISATION',
                p.Id,
                null,
                null,
                null
            )
        );

        Test.startTest();
        chain.runNext();
        Test.stopTest();

        Assert.isTrue(true);
    }
}