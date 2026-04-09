@isTest
private class AP026_SendInvoicesToMulesoft_TEST {

    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Siret__c = '123456789'
        );
        insert testAccount;

        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test File',
            VersionData = Blob.valueOf('Test Content'),
            PathOnClient = 'TestFile.txt'
        );
        insert testContentVersion;
    }

    // Mock réponse HTTP 200 (succès)
    private class MockHttpResponseSuccess implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"title": "Envoi réussi", "message": "Traitement en cours de vos factures...", "variant": "success"}');
            return res;
        }
    }

    // Mock réponse HTTP 500 (erreur)
    private class MockHttpResponseError implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"error": "Internal Server Error"}');
            return res;
        }
    }

    // Mock pour simuler une erreur CalloutException
    private class MockHttpCalloutFailure implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Problème de connexion au serveur');
        }
    }

    @isTest
    static void testSendFiles_Success() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseSuccess());

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Test.startTest();
        AP026_SendInvoicesToMulesoft.toastWrapper response = AP026_SendInvoicesToMulesoft.sendFiles(cv.ContentDocumentId, acc.Id, true);
        Test.stopTest();

        // Vérifications
        System.assertEquals('Envoi réussi', response.title, 'Le titre doit être "Envoi réussi"');
        System.assertEquals('Traitement en cours de vos factures...', response.message);
        System.assertEquals('success', response.variant);
    }

    @isTest
    static void testSendFiles_HttpError() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseError());

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Test.startTest();
        AP026_SendInvoicesToMulesoft.toastWrapper response = AP026_SendInvoicesToMulesoft.sendFiles(cv.ContentDocumentId, acc.Id, true);
        Test.stopTest();

        // Vérifications
        System.assert(response.title.contains('Erreur'), 'Le titre doit indiquer une erreur');
        System.assert(response.message.contains('500'), 'Le message doit inclure le code 500');
        System.assertEquals('error', response.variant);
    }

    @isTest
    static void testSendFiles_CalloutException() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutFailure());

        Account acc = [SELECT Id FROM Account LIMIT 1];
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Test.startTest();
        AP026_SendInvoicesToMulesoft.toastWrapper response = AP026_SendInvoicesToMulesoft.sendFiles(cv.ContentDocumentId, acc.Id, true);
        Test.stopTest();

        // Vérifications
        System.assertEquals('Problème de connexion avec Mulesoft', response.title);
        System.assert(response.message.equals('Problème de connexion avec Mulesoft'), 'Le message doit indiquer une erreur de connexion');
    }
}