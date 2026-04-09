@isTest
global class MockHttpResponseAPIEndesaElec implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        // Simulez la réponse JSON en fonction de la requête
        if (req.getEndpoint().contains('login')) {
            res.setBody('{"last_name":"Test","first_name":"Toto","email":"toto.test@test.fr","login":{"access_token":"12345","client_id":"12345","client_secret":"12345","refresh_token":"12345"}}');
        } else if (req.getEndpoint().contains('api-offre-elec')) {
            res.setBody('{"num_dossier":"202404273821","message":"Prix calculé avec succès","code":"200","sites":{"123456780":{"commission":1232.12,"abonnement":28.33,"cee":6.4,"categorie":"C5","consommation":70.808,"capacite":3.96,"prix_energie_base":183.61,"prix_energie_hp":183.61,"prix_energie_hc":122.74,"prix_energie_hch":183.61,"prix_energie_hph":183.61,"prix_energie_hpe":183.61,"prix_energie_hce":183.61}}}');
        } else if (req.getEndpoint().contains('api-fichiers-offre-elec')) {
            res.setBody('{"numero_offre":"202404273814","conditions_generales":{"base64":"azerty64","filename":"cg.pdf"},"conditions_particulieres":{"base64":"azerty64","filename":"cp.pdf"}}');
        } else if (req.getEndpoint().contains('api-changer-status')) {
            res.setBody('{"numero_offre": "202306214289","status":""}');
        }
        res.setStatusCode(200);
        return res;
    }
}