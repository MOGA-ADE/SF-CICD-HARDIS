@IsTest
private class AP032_EngieAPICalloutQueueableTest {

    private class TestDataFactory {
        Account createAccount() {
            Account a = new Account(Name = 'Test Acc');
            insert a;
            return a;
        }
        Opportunity createOpportunity(Id accountId) {
            Opportunity o = new Opportunity(
                Name = 'Test Opp',
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(10),
                AccountId = accountId
            );
            insert o;
            return o;
        }
        Quote createQuote(Id oppId) {
            Quote q = new Quote(
                Name = 'Q-1',
                OpportunityId = oppId,
                Status = 'Draft',
                Date_de_fin_de_contrat__c = Date.today().addYears(1)
            );
            insert q;
            return q;
        }

        Id createDocumentAndReturnContentDocumentId() {
            ContentVersion cv = new ContentVersion(
                Title = 'Test File',
                PathOnClient = 'test.txt',
                VersionData = Blob.valueOf('Hello world')
            );
            insert cv;

            cv = [
                SELECT Id, ContentDocumentId
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];
            return cv.ContentDocumentId;
        }
    }

    private class PricingMock implements HttpCalloutMock {
        private Integer code;
        private String body;
        PricingMock(Integer code, String body) {
            this.code = code; this.body = body;
        }
        public HttpResponse respond(HttpRequest req) {
            System.assertEquals('POST', req.getMethod(), 'La méthode doit être POST');
            System.assertEquals('application/json', req.getHeader('Content-Type'), 'Le Content-Type doit être JSON');
            System.assert(req.getEndpoint().contains('/api/engie/request-pricing'), 'Endpoint inattendu');

            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }

    @IsTest
    static void test_execute_success_updates_quote_status() {
        TestDataFactory f = new TestDataFactory();
        Account a = f.createAccount();
        Opportunity o = f.createOpportunity(a.Id);
        Quote q = f.createQuote(o.Id);

        Id contentDocumentId = f.createDocumentAndReturnContentDocumentId();

        // Mock 200 OK
        Test.setMock(HttpCalloutMock.class, new PricingMock(200, '{"message" : "Demande en cours...", "idTransaction":"TX12345"}'));

        Test.startTest();
        Id jobId = System.enqueueJob(new AP032_EngieAPICalloutQueueable(q.Id, contentDocumentId));
        Test.stopTest();

        Quote qAfter = [
            SELECT Api_status__c, Api_error_message__c
            FROM Quote WHERE Id = :q.Id
        ];
        System.assertEquals('Demande de prix reçue chez le fournisseur', qAfter.Api_status__c,
            'Le statut doit refléter un succès côté Engie');
        System.assertEquals(null, qAfter.Api_error_message__c,
            'Aucun message d’erreur ne doit être posé en cas de succès');
    }

    @IsTest
    static void test_execute_error_sets_error_fields() {
        TestDataFactory f = new TestDataFactory();
        Account a = f.createAccount();
        Opportunity o = f.createOpportunity(a.Id);
        Quote q = f.createQuote(o.Id);

        Id contentDocumentId = f.createDocumentAndReturnContentDocumentId();

        // Mock 500
        Test.setMock(HttpCalloutMock.class, new PricingMock(500, '{"error":"internal"}'));

        Test.startTest();
        Id jobId = System.enqueueJob(new AP032_EngieAPICalloutQueueable(q.Id, contentDocumentId));
        Test.stopTest();

        Quote qAfter = [
            SELECT Api_status__c, Api_error_message__c
            FROM Quote WHERE Id = :q.Id
        ];
        System.assertEquals('Erreur Process Mulesoft', qAfter.Api_status__c,
            'Le statut doit refléter un échec côté Mulesoft');
        System.assert(qAfter.Api_error_message__c != null
                      && qAfter.Api_error_message__c.contains('500'),
            'Le message d’erreur doit contenir le code renvoyés');
    }

    @IsTest
    static void test_execute_missing_file_returns_without_update() {
        TestDataFactory f = new TestDataFactory();
        Account a = f.createAccount();
        Opportunity o = f.createOpportunity(a.Id);
        Quote q = f.createQuote(o.Id);

        // Id de document inexistant : aucune ContentVersion trouvée -> early return
        String nonexistentContentDocumentId = '069000000000000AAA';

        // Pas de mock nécessaire : le callout n’a pas lieu si le fichier manque
        Test.startTest();
        Id jobId = System.enqueueJob(new AP032_EngieAPICalloutQueueable(q.Id, nonexistentContentDocumentId));
        Test.stopTest();

        Quote qAfter = [
            SELECT Api_status__c, Api_error_message__c
            FROM Quote WHERE Id = :q.Id
        ];
        System.assertEquals(null, qAfter.Api_status__c,
            'Aucune mise à jour ne doit être faite si le fichier est introuvable');
        System.assertEquals(null, qAfter.Api_error_message__c,
            'Aucun message d’erreur ne doit être posé si l’exécution sort tôt');
    }
}