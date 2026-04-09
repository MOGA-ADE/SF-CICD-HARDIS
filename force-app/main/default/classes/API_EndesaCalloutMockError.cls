@isTest
global class API_EndesaCalloutMockError implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"sites":{"GI071733":{"pce":{"value":"GI071733","errors":[{"message":"Ce site est hors de votre périmètre.","code_error":"12-5-0"}]}}}}');
        res.setStatusCode(400);
        return res;

        
    }
}