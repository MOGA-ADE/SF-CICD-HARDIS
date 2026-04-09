@isTest
private class WebhookRouter_TEST {

    private static final String VALID_JSON =
    '{' +
    '  "data": {' +
    '    "_id_source": "SRC_EXEC",' +
    '    "inputs": {"source": {"_id_source": "SRC_EXEC"}},' +
    '    "outputs": {' +
    '      "source": {"idsource": "SRC_SOURCE"},' +
    '      "actuelle": {' +
    '        "structure_tarifaire": {' +
    '          "puissance_souscrite_soutirage": {' +
    '            "denivele": {' +
    '              "HCB": 1, "HPB": 2, "HCH": 3, "HPH": 4, "PTE": 5' +
    '            }' +
    '          }' +
    '        },' +
    '        "data": {"periode": {' +
    '          "prixHTT_elecsoutirage_turpeCSF": {"sum": 10},' +
    '          "prixHTT_elecsoutirage_turpeCSV": {"sum": 20},' +
    '          "prixHTT_elecsoutirage_turpeCMDPS": {"sum": 30},' +
    '          "prixHTVA_elecsoutirage_cta": {"sum": 40}' +
    '        }}' +
    '      },' +
    '      "meilleure": {' +
    '        "structure_tarifaire": {' +
    '          "puissance_souscrite_soutirage": {' +
    '            "denivele": {' +
    '              "HCB": 6, "HPB": 7, "HCH": 8, "HPH": 9, "PTE": 10' +
    '            }' +
    '          }' +
    '        },' +
    '        "data": {"periode": {' +
    '          "prixHTT_elecsoutirage_turpeCSF": {"sum": 15},' +
    '          "prixHTT_elecsoutirage_turpeCSV": {"sum": 25},' +
    '          "prixHTT_elecsoutirage_turpeCMDPS": {"sum": 35},' +
    '          "prixHTVA_elecsoutirage_cta": {"sum": 45}' +
    '        }}' +
    '      }' +
    '    }' +
    '  }' +
    '}';

    @testSetup
    static void setup() {
        TestDataFactory.createDataForComparatifElec();

        PDE__c p = [
            SELECT Id FROM PDE__c
            WHERE RecordType.DeveloperName = 'Elec_C3_C4'
            LIMIT 1
        ];
        p.IdSource__c = 'SRC_EXEC';
        update p;

        QuoteLineItem qli = [
            SELECT Id FROM QuoteLineItem
            LIMIT 1
        ];
        qli.IdSource__c = 'SRC_EXEC';
        update qli;
    }

    @isTest
    static void testWebhookValid() {

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/callback/TURPEWebhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(VALID_JSON);
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        WebhookRouter.handler();
        Test.stopTest();

        Assert.areEqual(
            200,
            res.statusCode,
            'Le webhook valide doit répondre 200'
        );
        Assert.isTrue(
            res.responseBody.toString().contains('"received": true'),
            'La réponse doit confirmer la réception'
        );
    }

    @isTest
    static void testWebhookNotFound() {

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/callback/UNKNOWN';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"ok":true}');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        WebhookRouter.handler();
        Test.stopTest();

        Assert.areEqual(
            404,
            res.statusCode,
            'Un webhook inconnu doit répondre 404'
        );
    }

    @isTest
    static void testWebhookInvalidFormat() {

        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/callback/TURPEWebhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{bad json');
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        WebhookRouter.handler();
        Test.stopTest();

        Assert.areEqual(
            202,
            res.statusCode,
            'Un webhook reçu mais invalide doit répondre 202'
        );
        Assert.isTrue(
            res.responseBody.toString().contains('"warning"'),
            'La réponse doit contenir un warning'
        );
    }

    @isTest
    static void testWebhookTechnicalError() {

        RestRequest req = new RestRequest();
        req.requestURI = null; // force une exception technique
        req.httpMethod = 'POST';
        RestContext.request = req;

        RestResponse res = new RestResponse();
        RestContext.response = res;

        Test.startTest();
        WebhookRouter.handler();
        Test.stopTest();

        Assert.areEqual(
            500,
            res.statusCode,
            'Une erreur technique doit répondre 500'
        );
    }
}