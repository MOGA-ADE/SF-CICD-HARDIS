@isTest
global class API_EndesaCalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"numero_offre":"202310273305","date_fin_validite":"04/10/2023","sites":{"GI010111":{"atrt":3477.16,"atrd_fix":982.92,"atrd_variable":6.42,"stockage":1750.78,"prix_molecule":80.85,"cee":0,"cta":243.11,"car":628.165}}}');
        res.setStatusCode(200);
        return res;
    }
}