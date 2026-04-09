@IsTest
private class AP032_EngieAPIPriceControllerTest {

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

        List<ContentDocumentLink> createAccountFileAndLink(Id accountId) {
            ContentVersion cv = new ContentVersion(
                Title = 'Test File',
                PathOnClient = 'test.txt',
                VersionData = Blob.valueOf('Hello world')
            );
            insert cv;

            cv = [
                SELECT Id, ContentDocumentId, Title
                FROM ContentVersion
                WHERE Id = :cv.Id
                LIMIT 1
            ];

            ContentDocumentLink cdl = new ContentDocumentLink(
                ContentDocumentId = cv.ContentDocumentId,
                LinkedEntityId = accountId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );
            insert cdl;

            return new List<ContentDocumentLink>{ cdl };
        }
    }

    @IsTest
    static void test_getAccountFiles_success() {
        TestDataFactory f = new TestDataFactory();

        // Given: Account - Opp - Quote and a file linked to Account
        Account a = f.createAccount();
        Opportunity o = f.createOpportunity(a.Id);
        Quote q = f.createQuote(o.Id);
        List<ContentDocumentLink> links = f.createAccountFileAndLink(a.Id);

        Test.startTest();
        List<ContentDocumentLink> result = AP032_EngieAPIPriceController.getAccountFiles(q.Id);
        Test.stopTest();

        System.assertNotEquals(0, result.size(), 'Expected at least one file linked via account of quote');
        System.assertNotEquals(null, result[0].ContentDocumentId, 'ContentDocumentId should be set');
        System.assertNotEquals(null, result[0].ContentDocument, 'ContentDocument relationship should be populated');
        System.assertNotEquals(null, result[0].ContentDocument.Title, 'Title should be selected');
    }

    @IsTest
    static void test_getAccountFiles_invalidQuote_returnsEmptyList_noException() {
        Test.startTest();
        // Id de Quote inexistant -> la requête renvoie 0 ligne, pas d’exception
        List<ContentDocumentLink> result = AP032_EngieAPIPriceController.getAccountFiles('0Q0xxxxxxxxxxxx'); 
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Expected empty list for non-existing quote id');
    }

    // ---- Mocks ----
    private class ValidateOfferMock implements HttpCalloutMock {
        Integer statusCode;
        String body;
        ValidateOfferMock(Integer code, String b) { statusCode = code; body = b; }
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod(), 'Expected POST method');
            System.assertEquals('application/json', req.getHeader('Content-Type'), 'Expected JSON header');
            System.assert(req.getEndpoint().contains('/api/engie/validate-offer'), 'Endpoint must be validate-offer');
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            return res;
        }
    }
    private class ThrowingMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simule une erreur bas niveau durant Http.send()
            throw new CalloutException('Simulated failure');
        }
    }

    @IsTest
    static void test_processPriceRequest_success() {
        TestDataFactory f = new TestDataFactory();

        Account a = f.createAccount();
        Opportunity o = f.createOpportunity(a.Id);
        Quote q = f.createQuote(o.Id);
        List<ContentDocumentLink> links = f.createAccountFileAndLink(a.Id);
        Id contentDocumentId = links[0].ContentDocumentId;
        
        AP032_EngieAPIPriceController.PriceRequestWrapper req = new AP032_EngieAPIPriceController.PriceRequestWrapper();
        req.quoteId = q.Id;
        req.margin = 5;
        req.validityDuration = 30;
        req.isGreenEnergy = true;
        req.selectedFileId = contentDocumentId;

        Test.startTest();
        AP032_EngieAPIPriceController.toastWrapper toast = AP032_EngieAPIPriceController.processPriceRequest(req);
        Test.stopTest();
    }

    @IsTest
    static void test_processPriceRequest_update_failure() {
        AP032_EngieAPIPriceController.PriceRequestWrapper req = new AP032_EngieAPIPriceController.PriceRequestWrapper();
        req.quoteId = '0Q0000000000000'; // invalid Id
        req.margin = 1;
        req.validityDuration = 1;
        req.isGreenEnergy = false;

        Test.startTest();
        AP032_EngieAPIPriceController.toastWrapper toast = AP032_EngieAPIPriceController.processPriceRequest(req);
        Test.stopTest();

        System.assertEquals('Erreur interne', toast.title);
        System.assertEquals('error', toast.variant);
        System.assert(toast.message.contains('Impossible de mettre à jour le Quote'), 'Expected update error message');
    }

    @IsTest
    static void test_processValidateOffer_success() {
        TestDataFactory f = new TestDataFactory();

        Account a = f.createAccount();
        Opportunity o = f.createOpportunity(a.Id);
        Quote q = f.createQuote(o.Id);

        String responseJson = JSON.serialize(new Map<String,Object>{
            'idTransaction' => 'T-123',
            'message' => 'OK',
            'idSimulation' => 'S-456',
            'referenceOffrePartenaire' => 'REF-ENGIE-001',
            'urlPlateformePartenaire' => 'https://engie.example/offer/REF-ENGIE-001'
        });

        Test.setMock(HttpCalloutMock.class, new ValidateOfferMock(200, responseJson));

        Test.startTest();
        AP032_EngieAPIPriceController.toastWrapper toast = AP032_EngieAPIPriceController.processValidateOffer(q.Id);
        Test.stopTest();

        System.assertEquals('Succès', toast.title);
        System.assertEquals('success', toast.variant);

        Quote qAfter = [
            SELECT Engie_opp_name__c, Engie_url_plateforme__c
            FROM Quote
            WHERE Id = :q.Id
        ];
        System.assertEquals('REF-ENGIE-001', qAfter.Engie_opp_name__c);
        System.assertEquals('https://engie.example/offer/REF-ENGIE-001', qAfter.Engie_url_plateforme__c);
    }

    @IsTest
    static void test_processValidateOffer_error_code() {
        TestDataFactory f = new TestDataFactory();

        Account a = f.createAccount();
        Opportunity o = f.createOpportunity(a.Id);
        Quote q = f.createQuote(o.Id);

        Test.setMock(HttpCalloutMock.class, new ValidateOfferMock(400, '{"error":"bad request"}'));

        Test.startTest();
        AP032_EngieAPIPriceController.toastWrapper toast = AP032_EngieAPIPriceController.processValidateOffer(q.Id);
        Test.stopTest();

        System.assertEquals(true, toast.title.startsWith('Erreur API code '), 'Should return API error code in title');
        System.assertEquals('error', toast.variant);
        System.assertEquals('{"error":"bad request"}', toast.message);
    }

    @IsTest
    static void test_processValidateOffer_exception() {
        // Mock qui jette une exception pour forcer le catch
        Test.setMock(HttpCalloutMock.class, new ThrowingMock());

        Test.startTest();
        AP032_EngieAPIPriceController.toastWrapper toast = AP032_EngieAPIPriceController.processValidateOffer('0Q0xxxxxx');
        Test.stopTest();

        System.assertEquals('Erreur interne', toast.title);
        System.assertEquals('error', toast.variant);
        System.assert(toast.message.contains('Impossible de lancer le processus de validation d\'offre'), 'Expected exception message path');
    }
}