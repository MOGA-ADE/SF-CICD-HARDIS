@IsTest
private class GRDFManagerTest {

    // ========================================
    // MÉTHODES TESTS
    // ========================================
    @IsTest
    static void testCreateDroitAcces_Success_And_JSONCleaning() {
        // Body containing BOM and non-breaking spaces that should be cleaned
        String dirtyJson = '\uFEFF' +
            '{\u00A0"code_statut_traitement":"OK",' +
            '"message_retour_traitement":"Créé",' +
            '"id_pce":"PCE123",' +
            '"role_tiers":"AUTORISE_CONTRAT_FOURNITURE",' +
            '"id_droit_acces":"DA-001"\u00A0}  ';

        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, dirtyJson));

        GRDFManager.DroitAccesRequest req = new GRDFManager.DroitAccesRequest();
        req.raison_sociale = 'ADE';
        req.code_postal = '75001';
        req.courriel_titulaire = 'john.doe@example.com';
        req.date_debut_droit_acces = '2025-01-01';
        req.date_fin_droit_acces = '2025-12-31';
        req.perim_donnees_conso_debut = '2024-01-01';
        req.perim_donnees_conso_fin = '2024-12-31';

        Test.startTest();
        GRDFManager.DroitAccesResponse resp = GRDFManager.createDroitAcces('PCE123', req);
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null');
        System.assertEquals('OK', resp.code_statut_traitement, 'Status should be OK');
        System.assertEquals('DA-001', resp.id_droit_acces, 'Id droit accès should be parsed');
        System.assertEquals('PCE123', resp.id_pce, 'PCE should be parsed');
    }

    @IsTest
    static void testCreateDroitAcces_InvalidJson_ReturnsErrorWrapper() {
        // Invalid JSON causing parse exception -> class should return error wrapper
        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, 'this is not json'));

        GRDFManager.DroitAccesRequest req = new GRDFManager.DroitAccesRequest();
        req.raison_sociale = 'Foo Bar';
        req.code_postal = '13001';
        req.courriel_titulaire = 'foo@bar.com';
        req.date_debut_droit_acces = '2025-01-01';
        req.date_fin_droit_acces = '2025-12-31';
        req.perim_donnees_conso_debut = '2024-01-01';
        req.perim_donnees_conso_fin = '2024-12-31';

        Test.startTest();
        GRDFManager.DroitAccesResponse resp = GRDFManager.createDroitAcces('PCEABC', req);
        Test.stopTest();

        System.assertNotEquals(null, resp, 'Response should not be null even on parse error');
        System.assertEquals('JSON_PARSE_ERROR', resp.code_statut_traitement, 'Should mark parse error');
        System.assertEquals(null, resp.id_droit_acces, 'Id should be null on error wrapper');
        System.assertEquals('this is not json', resp.message_retour_traitement, 'Raw body should be in message');
    }

    @IsTest
    static void testPostDroitsAcces_Success_NDJSON() {
        // NDJSON with two droit records and a final status line
        String ndjson =
            '{"id_droit_acces":"DA-1","id_pce":"PCE1","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"id_droit_acces":"DA-2","id_pce":"PCE2","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"code_statut_traitement":"OK","message_retour_traitement":"Terminé"}';

        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, ndjson));

        List<String> idPces = new List<String>{ 'PCE1', 'PCE2' };

        Test.startTest();
        GRDFManager.DroitsAccesResultat res = GRDFManager.postDroitsAcces(idPces);
        Test.stopTest();

        System.assertNotEquals(null, res, 'Result should not be null');
        System.assertNotEquals(null, res.droitsAcces, 'Should have droitsAcces list');
        System.assertEquals(2, res.droitsAcces.size(), 'Should parse two lines as droits');
        System.assertEquals('DA-1', res.droitsAcces[0].id_droit_acces);
        System.assertEquals('DA-2', res.droitsAcces[1].id_droit_acces);
        System.assertNotEquals(null, res.statutFinal, 'Final status should be parsed');
        System.assertEquals('OK', res.statutFinal.code_statut_traitement);
    }

    @IsTest
    static void testPostDroitsAcces_Failure_Throws() {
        Test.setMock(HttpCalloutMock.class, new SimpleMock(400, '{"error":"Bad request"}'));

        Boolean thrown = false;
        try {
            Test.startTest();
            GRDFManager.postDroitsAcces(new List<String>{ 'PCE1' });
            Test.stopTest();
        } catch (GRDFManager.GRDFException ex) {
            thrown = true;
            System.assert(ex.getMessage().contains('Impossible de récupérer les droits pour les PCEs'), 'Message should indicate failure');
        }
        System.assertEquals(true, thrown, 'Should throw GRDFException on non-200');
    }

    @IsTest
    static void testGetDonneesContractuelles_Success() {
        String body = '{"pce":{"id_pce":"PCE9"},' +
                      '"donnees_contractuelles":{"date_mes":"2025-01-01"},' +
                      '"statut_restitution":{"code":"OK","message":"ok"}}';

        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, body));

        Test.startTest();
        GRDFManager.DonneesContractuellesWrapper res = GRDFManager.getDonneesContractuelles('PCE9');
        Test.stopTest();

        System.assertEquals('PCE9', res.pce.id_pce);
        System.assertEquals('2025-01-01', res.donnees_contractuelles.date_mes);
        System.assertEquals('OK', res.statut_restitution.code);
    }

    @IsTest
    static void testGetDonneesContractuelles_KO() {
        String body = '{"pce":{"id_pce":"PCE9"},' +
                      '"donnees_contractuelles":null,' +
                      '"statut_restitution":{"code":"KO","message":"KO"}}';

        Test.setMock(HttpCalloutMock.class, new SimpleMock(400, body));

        Test.startTest();
        GRDFManager.DonneesContractuellesWrapper res = GRDFManager.getDonneesContractuelles('PCE9');
        Test.stopTest();

        System.assertEquals(null, res.donnees_contractuelles);
        System.assertEquals('HTTP_400', res.statut_restitution.code);
    }

    @IsTest
    static void testGetDonneesContractuelles_CatchException() {
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        Test.startTest();
        GRDFManager.DonneesContractuellesWrapper res = GRDFManager.getDonneesContractuelles('PCE_CRASH');
        Test.stopTest();

        System.assertNotEquals(null, res.statut_restitution, 'Le statut ne devrait pas être null');
        System.assertEquals('DONNEES_CONTRACTUELLES APEX_ERROR', res.statut_restitution.code, 'Le code erreur doit correspondre au catch');
        System.assertEquals('Callout failed: Simulated Callout Error', res.statut_restitution.message, 'Le message doit être celui de l\'exception');
    }

    @IsTest
    static void testGetDonneesTechniques_Success() {
        String body = '{"pce":{"id_pce":"PCE7"},' +
                      '"donnees_techniques":{"situation_compteur":{"numero_rue":"1"}},' +
                      '"statut_restitution":{"code":"OK","message":"ok"}}';

        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, body));

        Test.startTest();
        GRDFManager.DonneesTechniquesWrapper res = GRDFManager.getDonneesTechniques('PCE7');
        Test.stopTest();

        System.assertEquals('PCE7', res.pce.id_pce);
        System.assertEquals('1', res.donnees_techniques.situation_compteur.numero_rue);
        System.assertEquals('OK', res.statut_restitution.code);
    }

    @IsTest
    static void testGetDonneesTechniques_KO() {
        String body = '{"pce":{"id_pce":"PCE7"},' +
                      '"donnees_techniques":null,' +
                      '"statut_restitution":{"code":"KO","message":"KO"}}';

        Test.setMock(HttpCalloutMock.class, new SimpleMock(400, body));

        Test.startTest();
        GRDFManager.DonneesTechniquesWrapper res = GRDFManager.getDonneesTechniques('PCE7');
        Test.stopTest();

        System.assertEquals(null, res.donnees_techniques);
        System.assertEquals('HTTP_400', res.statut_restitution.code);
    }

    @IsTest
    static void testGetDonneesTechniques_CatchException() {
        Test.setMock(HttpCalloutMock.class, new ExceptionMock());

        Test.startTest();
        GRDFManager.DonneesTechniquesWrapper res = GRDFManager.getDonneesTechniques('PCE_CRASH');
        Test.stopTest();

        System.assertNotEquals(null, res.statut_restitution, 'Le statut ne devrait pas être null');
        System.assertEquals('DONNEES_TECHNIQUES APEX_ERROR', res.statut_restitution.code, 'Le code erreur doit correspondre au catch');
        System.assertEquals('Callout failed: Simulated Callout Error', res.statut_restitution.message, 'Le message doit être celui de l\'exception');
    }

    @IsTest
    static void testParseNDJSON_IgnoresInvalidLines() {
        // Mix valid and invalid lines to exercise error handling branch in parseNDJSON
        String ndjson =
            '{"id_droit_acces":"DA-X","id_pce":"PCE-X"}\n' +
            'not a json line\n' +
            '{"code_statut_traitement":"OK","message_retour_traitement":"done"}';

        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, ndjson));

        Test.startTest();
        GRDFManager.DroitsAccesResultat res = GRDFManager.postDroitsAcces(new List<String>{ 'PCE-X' });
        Test.stopTest();

        System.assertEquals(1, res.droitsAcces.size(), 'Only one valid droit should be parsed');
        System.assertEquals('OK', res.statutFinal.code_statut_traitement);
    }

    @IsTest
    static void testBulk_PostDroitsAcces_ManyIds() {
        // Bulk scenario to validate logic under a larger input list (no SOQL/DML performed)
        List<String> ids = new List<String>();
        for (Integer i = 0; i < 50; i++) {
            ids.add('PCE-' + i);
        }
        // Return a single final status line to keep payload small
        String ndjson = '{"code_statut_traitement":"OK","message_retour_traitement":"bulk"}';
        Test.setMock(HttpCalloutMock.class, new SimpleMock(200, ndjson));

        Test.startTest();
        GRDFManager.DroitsAccesResultat res = GRDFManager.postDroitsAcces(ids);
        Test.stopTest();

        System.assertNotEquals(null, res.statutFinal, 'Final status should be present in bulk call');
        System.assertEquals('OK', res.statutFinal.code_statut_traitement);
    }

        // ========================================
    // MÉTHODES HELPERS
    // ========================================
    private class SimpleMock implements HttpCalloutMock {
        Integer statusCode;
        String body;
        Map<String, String> headers = new Map<String, String>();

        SimpleMock(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
            headers.put('Content-Type', 'application/json');
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(body);
            for (String key : headers.keySet()) {
                res.setHeader(key, headers.get(key));
            }
            return res;
        }
    }

    private class ExceptionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            CalloutException e = new CalloutException();
            e.setMessage('Simulated Callout Error');
            throw e;
        }
    }
}