@isTest
global class MockHttpResponseConsulterMesure implements HttpCalloutMock {
    public static HttpResponse response;
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/xml');

        String xmlBody = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' +
            '<soap:Header>' +
                '<ns3:acquittement xmlns:ns3="http://www.enedis.fr/sge/b2b/technique/v1.0">' +
                    '<resultat code="SGT200">Succès</resultat>' +
                    '<infoFonctionnelles><pointId>25957452924301</pointId></infoFonctionnelles>' +
                '</ns3:acquittement>' +
            '</soap:Header>' +
            '<soap:Body>' +
                '<ns4:consulterMesuresResponse xmlns:ns4="http://www.enedis.fr/sge/b2b/services/consultermesures/v1.1">' +
                    '<seriesMesuresDateesGrilleTurpe>' +
                        '<serie>' +
                            '<grandeurPhysique code="EA"><libelle>Energie Active</libelle></grandeurPhysique>' +
                            '<classeTemporelle code="HCE"><libelle>Heures creuses été</libelle></classeTemporelle>' +
                            '<unite>kWh</unite>' +
                            '<mesuresDatees>' +
                                '<mesure>' +
                                    '<valeur>244</valeur>' +
                                    '<dateDebut>2023-04-08</dateDebut>' +
                                    '<dateFin>2023-05-08</dateFin>' +
                                '</mesure>' +
                                '<mesure>' +
                                    '<valeur>81</valeur>' +
                                    '<dateDebut>2023-03-08</dateDebut>' +
                                    '<dateFin>2023-04-08</dateFin>' +
                                '</mesure>' +
                            '</mesuresDatees>' +
                        '</serie>' +
                    '</seriesMesuresDateesGrilleTurpe>' +
                '</ns4:consulterMesuresResponse>' +
            '</soap:Body>' +
        '</soap:Envelope>';

        res.setBody(xmlBody);
        res.setStatusCode(200);
        response = res;
        return res;
    }
}