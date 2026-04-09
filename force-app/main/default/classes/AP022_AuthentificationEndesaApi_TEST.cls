@isTest
private class AP022_AuthentificationEndesaApi_TEST {

    @testSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1,1,1,1,1);
    }

    @IsTest
    static void testGetEndpoint() {
        Test.startTest();
            String endpoint = AP022_AuthentificationEndesaApi.getEndpoint();
        Test.stopTest();
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (isSandbox) {
            System.assertEquals('Endesa_Elec_Preprod', endpoint, 'Sandbox => endpoint doit être Preprod');
        }
        else {
            System.assertEquals('Endesa_Elec', endpoint, 'Prod => endpoint doit être Prod');
        }
        
    }

    // pas de valeur a verif car le callbackurl n'est pas en mode require dans le custom metadata
    @IsTest
    static void testgetCallBack() {
        Test.startTest();
            String callbackurl = AP022_AuthentificationEndesaApi.getCallBack();
        Test.stopTest();
    }

    @IsTest
    static void testgetToken() {
        Test.startTest();
            AP022_AuthentificationEndesaApi.getToken();
        Test.stopTest();
    }

    @IsTest
    static void testauthentifier() {
        Test.startTest();
            AP022_AuthentificationEndesaApi.authentifier();
        Test.stopTest();
    }


    private class MockHttpResponse implements HttpCalloutMock {
        Integer statusCode;
        String responseBody;

        MockHttpResponse(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.responseBody = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }
}