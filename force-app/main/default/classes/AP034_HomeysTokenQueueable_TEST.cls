@isTest
private class AP034_HomeysTokenQueueable_TEST {

    /**
     * Mock HTTP pour l’appel de génération de token Homeys
     */
    private class HomeysTokenCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            HttpResponse res = new HttpResponse();

            // Simule l’endpoint token
            if (req.getMethod() == 'POST') {
                res.setStatusCode(200);
                res.setBody('{"token":"TEST_TOKEN_123"}');
                return res;
            }

            res.setStatusCode(400);
            res.setBody('{"error":"unexpected endpoint"}');
            return res;
        }
    }

    @testSetup
    static void setup() {
        // Données minimales nécessaires à l’org
        TestDataFactory.createDataForComparatifElec();
    }

    @isTest
    static void testTokenQueueable_GeneratesAndStoresToken() {

        // Nettoyage éventuel (sécurité)
        delete [SELECT Id FROM HomeysToken__c];

        // Mock HTTP
        Test.setMock(HttpCalloutMock.class, new HomeysTokenCalloutMock());

        QueueableJobChain chain = new QueueableJobChain();
        AP034_HomeysTokenQueueable job =
            new AP034_HomeysTokenQueueable(chain);

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // 🔍 Vérification du token stocké
        HomeysToken__c token = [
            SELECT Token__c, IssuedAt__c, ExpiresAt__c
            FROM HomeysToken__c
            LIMIT 1
        ];

        Assert.areNotEqual(null, token, 'Le token doit exister');
        Assert.areEqual(
            'TEST_TOKEN_123',
            token.Token__c,
            'Le token doit être celui retourné par le mock'
        );
        Assert.areNotEqual(
            null,
            token.ExpiresAt__c,
            'La date d’expiration doit être renseignée'
        );
    }
}