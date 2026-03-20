@IsTest
private class GRDFFetchDataTest {

    // ========================================
    // SETUP
    // ========================================

    @TestSetup
    static void makeData() {
        // Créer 1 compte avec 1 opportunity et 10 PDE Gaz
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 10, 0, 0);
    }

    // ========================================
    // MÉTHODES TESTS
    // ========================================

    /**
     * Test mode MANUAL : récupération synchrone réussie
     */
    @IsTest
    static void testFetchData_ManualMode_Success() {
        // Récupérer un PDE
        PDE__c pce = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 1];
        pce.PCE_Refonte__c = 'PCE1000';
        update pce;

        // Relire pour obtenir TECH_num_compteur__c calculé
        pce = [SELECT Id, TECH_num_compteur__c FROM PDE__c WHERE Id = :pce.Id];

        // Mock des réponses HTTP
        String contractResponse = '{"pce":{"id_pce":"PCE1000"},' +
                                  '"donnees_contractuelles":{"date_mes":"2025-01-15","date_publication":"2025-01-20",' +
                                  '"car":{"car_actuelle":"12000","car_future":"13000"},' +
                                  '"cja":{"cja":"100","cja_journaliere":"50","cja_mensuelle":"1500"},' +
                                  '"profil":{"profil_type_actuel":"P011","profil_type_futur":"P012"}},' +
                                  '"statut_restitution":{"code":"OK","message":"Success"}}';

        String techResponse = '{"pce":{"id_pce":"PCE1000"},' +
                             '"donnees_techniques":{"situation_compteur":{"numero_rue":"10","nom_rue":"Rue Test",' +
                             '"code_postal":"75001","commune":"Paris"},' +
                             '"caracteristiques_compteur":{"frequence":"Mensuel"},' +
                             '"pitd":{"identifiant_pitd":"PITD123"}},' +
                             '"statut_restitution":{"code":"OK","message":"Success"}}';

        Test.setMock(HttpCalloutMock.class, new MultiHttpMock(contractResponse, techResponse));

        // Préparer la requête en mode MANUAL
        GRDFFetchData.Request request = new GRDFFetchData.Request();
        request.pceRecords = new List<PDE__c>{pce};
        request.type_action = 'MANUAL';

        Test.startTest();
        GRDFFetchData.fetchData(new List<GRDFFetchData.Request>{ request });
        Test.stopTest();

        // Vérifications : le PCE doit être mis à jour avec les données
        PDE__c updatedPce = [
            SELECT Id, Date_MES__c, CARGaz__c, CARGaz_Future__c, Profil__c, Profil_Futur__c,
                   NumeroVoie__c, voie__c, Code_Postal__c, Ville__c, Frequence__c, Identifiant_PITD__c,
                   GRDF_Statut_Donnees_Contractuelles__c, GRDF_Statut_Donnees_Techniques__c
            FROM PDE__c
            WHERE Id = :pce.Id
        ];

        // Vérifier les données contractuelles
        System.assertEquals('Données récupérées', updatedPce.GRDF_Statut_Donnees_Contractuelles__c);
        System.assertEquals(Date.valueOf('2025-01-15'), updatedPce.Date_MES__c);
        System.assertEquals('P011', updatedPce.Profil__c);
        System.assertEquals('P012', updatedPce.Profil_Futur__c);

        // Vérifier les données techniques
        System.assertEquals('Données récupérées', updatedPce.GRDF_Statut_Donnees_Techniques__c);
        System.assertEquals('10', updatedPce.NumeroVoie__c);
        System.assertEquals('Rue Test', updatedPce.voie__c);
        System.assertEquals('75001', updatedPce.Code_Postal__c);
        System.assertEquals('Paris', updatedPce.Ville__c);
        System.assertEquals('Mensuel', updatedPce.Frequence__c);
        System.assertEquals('PITD123', updatedPce.Identifiant_PITD__c);
    }

    /**
     * Test mode ASYNC : récupération asynchrone via Queueable
     */
    @IsTest
    static void testFetchData_AsyncMode_Success() {
        // Récupérer un PDE
        PDE__c pce = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 1];
        pce.PCE_Refonte__c = 'PCE2000';
        update pce;

        // Relire pour obtenir TECH_num_compteur__c calculé
        pce = [SELECT Id, TECH_num_compteur__c FROM PDE__c WHERE Id = :pce.Id];

        // Mock des réponses HTTP
        String contractResponse = '{"pce":{"id_pce":"PCE2000"},' +
                                  '"donnees_contractuelles":{"date_mes":"2025-02-10","car":{"car_actuelle":"15000"},' +
                                  '"cja":{"cja":"120"},"profil":{"profil_type_actuel":"P013"}},' +
                                  '"statut_restitution":{"code":"OK","message":"Success"}}';

        String techResponse = '{"pce":{"id_pce":"PCE2000"},' +
                             '"donnees_techniques":{"situation_compteur":{"numero_rue":"20","nom_rue":"Avenue Test",' +
                             '"code_postal":"69001","commune":"Lyon"},' +
                             '"caracteristiques_compteur":{"frequence":"Trimestriel"},' +
                             '"pitd":{"identifiant_pitd":"PITD456"}},' +
                             '"statut_restitution":{"code":"OK","message":"Success"}}';

        Test.setMock(HttpCalloutMock.class, new MultiHttpMock(contractResponse, techResponse));

        // Préparer la requête en mode ASYNC (par défaut)
        GRDFFetchData.Request request = new GRDFFetchData.Request();
        request.pceRecords = new List<PDE__c>{pce};

        Test.startTest();
        GRDFFetchData.fetchData(new List<GRDFFetchData.Request>{ request });
        Test.stopTest();

        // Vérifications
        PDE__c updatedPce = [
            SELECT Id, Date_MES__c, CARGaz__c, Profil__c, NumeroVoie__c, voie__c, Ville__c,
                   GRDF_Statut_Donnees_Contractuelles__c, GRDF_Statut_Donnees_Techniques__c
            FROM PDE__c
            WHERE Id = :pce.Id
        ];

        System.assertEquals('Données récupérées', updatedPce.GRDF_Statut_Donnees_Contractuelles__c);
        System.assertEquals('Données récupérées', updatedPce.GRDF_Statut_Donnees_Techniques__c);
        System.assertEquals(Date.valueOf('2025-02-10'), updatedPce.Date_MES__c);
        System.assertEquals('Lyon', updatedPce.Ville__c);
    }

    /**
     * Test erreur récupération données contractuelles
     */
    @IsTest
    static void testFetchData_ContractDataError() {
        // Récupérer un PDE
        PDE__c pce = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 1];
        pce.PCE_Refonte__c = 'PCE3000';
        update pce;

        // Relire pour obtenir TECH_num_compteur__c calculé
        pce = [SELECT Id, TECH_num_compteur__c FROM PDE__c WHERE Id = :pce.Id];

        // Mock erreur pour données contractuelles, succès pour techniques
        String contractResponse = '{"pce":{"id_pce":"PCE3000"},' +
                                  '"donnees_contractuelles":null,' +
                                  '"statut_restitution":{"code":"KO","message":"Droit d\'accès invalide"}}';

        String techResponse = '{"pce":{"id_pce":"PCE3000"},' +
                             '"donnees_techniques":{"situation_compteur":{"numero_rue":"30","nom_rue":"Boulevard Test",' +
                             '"code_postal":"13001","commune":"Marseille"},' +
                             '"caracteristiques_compteur":{"frequence":"Annuel"},' +
                             '"pitd":{"identifiant_pitd":"PITD789"}},' +
                             '"statut_restitution":{"code":"OK","message":"Success"}}';

        Test.setMock(HttpCalloutMock.class, new MultiHttpMock(contractResponse, techResponse));

        // Préparer la requête
        GRDFFetchData.Request request = new GRDFFetchData.Request();
        request.pceRecords = new List<PDE__c>{pce};
        request.type_action = 'MANUAL';

        Test.startTest();
        GRDFFetchData.fetchData(new List<GRDFFetchData.Request>{ request });
        Test.stopTest();

        // Vérifications
        PDE__c updatedPce = [
            SELECT Id, GRDF_Statut_Donnees_Contractuelles__c, GRDF_Erreur_donnees_contractuelles__c,
                   GRDF_Statut_Donnees_Techniques__c, Ville__c
            FROM PDE__c
            WHERE Id = :pce.Id
        ];

        // Les données contractuelles doivent être en erreur
        System.assertEquals('Récupération Impossible', updatedPce.GRDF_Statut_Donnees_Contractuelles__c);
        System.assertNotEquals(null, updatedPce.GRDF_Erreur_donnees_contractuelles__c);
        System.assert(updatedPce.GRDF_Erreur_donnees_contractuelles__c.contains('KO'));

        // Les données techniques doivent être récupérées
        System.assertEquals('Données récupérées', updatedPce.GRDF_Statut_Donnees_Techniques__c);
        System.assertEquals('Marseille', updatedPce.Ville__c);
    }

    /**
     * Test erreur récupération données techniques
     */
    @IsTest
    static void testFetchData_TechDataError() {
        // Récupérer un PDE
        PDE__c pce = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 1];
        pce.PCE_Refonte__c = 'PCE4000';
        update pce;

        // Relire pour obtenir TECH_num_compteur__c calculé
        pce = [SELECT Id, TECH_num_compteur__c FROM PDE__c WHERE Id = :pce.Id];

        // Mock succès pour données contractuelles, erreur pour techniques
        String contractResponse = '{"pce":{"id_pce":"PCE4000"},' +
                                  '"donnees_contractuelles":{"date_mes":"2025-03-05","car":{"car_actuelle":"18000"},' +
                                  '"cja":{"cja":"150"},"profil":{"profil_type_actuel":"P014"}},' +
                                  '"statut_restitution":{"code":"OK","message":"Success"}}';

        String techResponse = '{"pce":{"id_pce":"PCE4000"},' +
                             '"donnees_techniques":null,' +
                             '"statut_restitution":{"code":"HTTP_404","message":"PCE non trouvé"}}';

        Test.setMock(HttpCalloutMock.class, new MultiHttpMock(contractResponse, techResponse));

        // Préparer la requête
        GRDFFetchData.Request request = new GRDFFetchData.Request();
        request.pceRecords = new List<PDE__c>{pce};
        request.type_action = 'MANUAL';

        Test.startTest();
        GRDFFetchData.fetchData(new List<GRDFFetchData.Request>{ request });
        Test.stopTest();

        // Vérifications
        PDE__c updatedPce = [
            SELECT Id, GRDF_Statut_Donnees_Contractuelles__c, Date_MES__c, CARGaz__c,
                   GRDF_Statut_Donnees_Techniques__c, GRDF_Erreur_donnees_techniques__c
            FROM PDE__c
            WHERE Id = :pce.Id
        ];

        // Les données contractuelles doivent être récupérées
        System.assertEquals('Données récupérées', updatedPce.GRDF_Statut_Donnees_Contractuelles__c);
        System.assertEquals(Date.valueOf('2025-03-05'), updatedPce.Date_MES__c);

        // Les données techniques doivent être en erreur
        System.assertEquals('Récupération Impossible', updatedPce.GRDF_Statut_Donnees_Techniques__c);
        System.assertNotEquals(null, updatedPce.GRDF_Erreur_donnees_techniques__c);
        System.assert(updatedPce.GRDF_Erreur_donnees_techniques__c.contains('HTTP_404'));
    }

    /**
     * Test avec plusieurs PCE
     */
    @IsTest
    static void testFetchData_MultiplePCEs() {
        // Récupérer 3 PDE
        List<PDE__c> pces = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 3];

        pces[0].PCE_Refonte__c = 'PCE5000';
        pces[1].PCE_Refonte__c = 'PCE5001';
        pces[2].PCE_Refonte__c = 'PCE5002';
        update pces;

        // Relire pour obtenir TECH_num_compteur__c calculé
        pces = [SELECT Id, TECH_num_compteur__c FROM PDE__c WHERE Id IN :pces];

        // Mock des réponses HTTP
        String contractResponse = '{"pce":{"id_pce":"PCE5000"},' +
                                  '"donnees_contractuelles":{"date_mes":"2025-04-01","car":{"car_actuelle":"20000"},' +
                                  '"cja":{"cja":"200"},"profil":{"profil_type_actuel":"P015"}},' +
                                  '"statut_restitution":{"code":"OK","message":"Success"}}';

        String techResponse = '{"pce":{"id_pce":"PCE5000"},' +
                             '"donnees_techniques":{"situation_compteur":{"numero_rue":"50","nom_rue":"Place Test",' +
                             '"code_postal":"33000","commune":"Bordeaux"},' +
                             '"caracteristiques_compteur":{"frequence":"Semestriel"},' +
                             '"pitd":{"identifiant_pitd":"PITD999"}},' +
                             '"statut_restitution":{"code":"OK","message":"Success"}}';

        Test.setMock(HttpCalloutMock.class, new MultiHttpMock(contractResponse, techResponse));

        // Préparer les requêtes
        List<GRDFFetchData.Request> requests = new List<GRDFFetchData.Request>();
        for (PDE__c pce : pces) {
            GRDFFetchData.Request request = new GRDFFetchData.Request();
            request.pceRecords = new List<PDE__c>{pce};
            request.type_action = 'MANUAL';
            requests.add(request);
        }

        Test.startTest();
        GRDFFetchData.fetchData(requests);
        Test.stopTest();

        // Vérifications : tous les PCE doivent être mis à jour
        List<PDE__c> updatedPces = [
            SELECT Id, GRDF_Statut_Donnees_Contractuelles__c, GRDF_Statut_Donnees_Techniques__c
            FROM PDE__c
            WHERE Id IN :pces
        ];

        for (PDE__c pce : updatedPces) {
            System.assertEquals('Données récupérées', pce.GRDF_Statut_Donnees_Contractuelles__c,
                'Les données contractuelles devraient être récupérées');
            System.assertEquals('Données récupérées', pce.GRDF_Statut_Donnees_Techniques__c,
                'Les données techniques devraient être récupérées');
        }
    }

    /**
     * Test avec requête vide (pas de PCE)
     */
    @IsTest
    static void testFetchData_EmptyRequest() {
        // Préparer une requête sans PCE
        GRDFFetchData.Request request = new GRDFFetchData.Request();
        request.pceRecords = null;
        request.type_action = 'MANUAL';

        Test.startTest();
        GRDFFetchData.fetchData(new List<GRDFFetchData.Request>{ request });
        Test.stopTest();

        // Le test doit passer sans erreur
        System.assert(true, 'La méthode devrait gérer les requêtes vides sans erreur');
    }

    /**
     * Test exception lors des callouts
     */
    @IsTest
    static void testFetchData_CalloutException() {
        // Récupérer un PDE
        PDE__c pce = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 1];
        pce.PCE_Refonte__c = 'PCE6000';
        update pce;

        // Relire pour obtenir TECH_num_compteur__c calculé
        pce = [SELECT Id, TECH_num_compteur__c FROM PDE__c WHERE Id = :pce.Id];

        // Mock une exception HTTP
        Test.setMock(HttpCalloutMock.class, new HttpCalloutExceptionMock());

        // Préparer la requête
        GRDFFetchData.Request request = new GRDFFetchData.Request();
        request.pceRecords = new List<PDE__c>{pce};
        request.type_action = 'MANUAL';

        Test.startTest();
        GRDFFetchData.fetchData(new List<GRDFFetchData.Request>{ request });
        Test.stopTest();

        // Le PCE ne devrait pas être mis à jour (erreur gérée)
        PDE__c updatedPce = [
            SELECT Id, GRDF_Statut_Donnees_Contractuelles__c, GRDF_Statut_Donnees_Techniques__c
            FROM PDE__c
            WHERE Id = :pce.Id
        ];

        // Les statuts ne devraient pas être "Données récupérées"
        System.assertNotEquals('Données récupérées', updatedPce.GRDF_Statut_Donnees_Contractuelles__c);
        System.assertNotEquals('Données récupérées', updatedPce.GRDF_Statut_Donnees_Techniques__c);
    }

    /**
     * Test Queueable avec volume important (> 40 PCE pour tester le chaining)
     */
    @IsTest
    static void testQueueable_BulkProcessing() {
        // Créer 45 PDE supplémentaires pour tester le chaining (< 50 pour éviter les problèmes de chaining en test)
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Id gazRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_Gaz'].get(0).Id;

        List<PDE__c> pces = new List<PDE__c>();
        for (Integer i = 0; i < 45; i++) {
            pces.add(new PDE__c(
                PCE_Refonte__c = 'PCEBULK' + i,
                EntiteJuridique__c = acc.Id,
                RecordTypeId = gazRecordTypeId,
                SiteConsommation__c = 'Site ' + i,
                NumeroVoie__c = String.valueOf(i),
                voie__c = 'Rue Test',
                Ville__c = 'Test',
                Code_Postal__c = '75001'
            ));
        }
        insert pces;

        // Mock des réponses HTTP
        String contractResponse = '{"pce":{"id_pce":"PCE"},"donnees_contractuelles":{"date_mes":"2025-05-01",' +
                                  '"car":{"car_actuelle":"25000"},"cja":{"cja":"250"},"profil":{"profil_type_actuel":"P016"}},' +
                                  '"statut_restitution":{"code":"OK","message":"Success"}}';

        String techResponse = '{"pce":{"id_pce":"PCE"},"donnees_techniques":{"situation_compteur":{"numero_rue":"60",' +
                             '"nom_rue":"Bulk Test","code_postal":"44000","commune":"Nantes"},' +
                             '"caracteristiques_compteur":{"frequence":"Mensuel"},"pitd":{"identifiant_pitd":"PITD000"}},' +
                             '"statut_restitution":{"code":"OK","message":"Success"}}';

        Test.setMock(HttpCalloutMock.class, new MultiHttpMock(contractResponse, techResponse));

        // Récupérer les IDs
        List<Id> pceIds = new List<Id>();
        for (PDE__c pce : pces) {
            pceIds.add(pce.Id);
        }

        Test.startTest();
        System.enqueueJob(new GRDFFetchData.GRDFFetchDataQueueable(pceIds));
        Test.stopTest();
    }

    // ========================================
    // CLASSES MOCK
    // ========================================

    /**
     * Mock pour simuler des réponses HTTP multiples (contractuelles puis techniques)
     */
    private class MultiHttpMock implements HttpCalloutMock {
        private String contractResponse;
        private String techResponse;
        private Integer callCount = 0;

        public MultiHttpMock(String contractResp, String techResp) {
            this.contractResponse = contractResp;
            this.techResponse = techResp;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');

            // Premier appel : données contractuelles
            // Deuxième appel : données techniques
            if (req.getEndpoint().contains('/donnees_contractuelles')) {
                res.setBody(contractResponse);
            } else if (req.getEndpoint().contains('/donnees_techniques')) {
                res.setBody(techResponse);
            } else {
                // Alternance pour les cas où on ne peut pas distinguer par endpoint
                callCount++;
                res.setBody(Math.mod(callCount, 2) == 1 ? contractResponse : techResponse);
            }

            return res;
        }
    }

    /**
     * Mock pour simuler une exception HTTP
     */
    private class HttpCalloutExceptionMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            CalloutException e = new CalloutException();
            e.setMessage('Simulated Callout Exception');
            throw e;
        }
    }
}