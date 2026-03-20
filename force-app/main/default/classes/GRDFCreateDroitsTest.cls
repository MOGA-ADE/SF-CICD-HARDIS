@IsTest
private class GRDFCreateDroitsTest {

    // ========================================
    // SETUP
    // ========================================

    @TestSetup
    static void makeData() {
        // Créer 1 compte avec 1 opportunity et 5 PDE Gaz
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 5, 0, 0);
    }

    // ========================================
    // MÉTHODES TESTS
    // ========================================

    /**
     * Test nominal : création de droits avec succès
     */
    @IsTest
    static void testCreateDroitsAcces_Success() {
        // Récupérer les PDE créés par le setup
        List<PDE__c> pces = [
            SELECT Id, PCE_Refonte__c, TECH_num_compteur__c, Nom_du_compte__c, Code_Postal__c, Date_signature_ACD__c
            FROM PDE__c
            LIMIT 2
        ];

        // Mettre à jour les champs requis pour GRDF
        for (Integer i = 0; i < pces.size(); i++) {
            pces[i].PCE_Refonte__c = 'PCE' + (100 + i);
            pces[i].Date_signature_ACD__c = Date.today();
        }
        update pces;

        // Préparer la requête
        GRDFCreateDroits.Request request = new GRDFCreateDroits.Request();
        request.pces = pces;
        request.userEmail = 'test@example.com';

        Test.startTest();
        List<GRDFCreateDroits.Result> results = GRDFCreateDroits.createDroitsAcces(
            new List<GRDFCreateDroits.Request>{ request }
        );
        Test.stopTest();

        // Vérifications
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return one result');

        GRDFCreateDroits.Result result = results[0];
        System.assertEquals(true, result.success, 'Operation should succeed');
        System.assertNotEquals(null, result.jobId, 'Job ID should be set');
        System.assert(result.message.contains('2'), 'Message should mention 2 PCEs');
        System.assert(result.message.contains('email'), 'Message should mention email notification');
    }

    /**
     * Test avec un seul PCE
     */
    @IsTest
    static void testCreateDroitsAcces_SinglePCE() {
        // Récupérer un PDE créé par le setup
        PDE__c pce = [
            SELECT Id, PCE_Refonte__c, Nom_du_compte__c, TECH_num_compteur__c, Code_Postal__c, Date_signature_ACD__c
            FROM PDE__c
            LIMIT 1
        ];

        // Mettre à jour les champs requis
        pce.PCE_Refonte__c = 'PCE789';
        pce.Date_signature_ACD__c = Date.today();
        update pce;

        // Préparer la requête
        GRDFCreateDroits.Request request = new GRDFCreateDroits.Request();
        request.pces = new List<PDE__c>{ pce };
        request.userEmail = 'single@example.com';

        Test.startTest();
        List<GRDFCreateDroits.Result> results = GRDFCreateDroits.createDroitsAcces(
            new List<GRDFCreateDroits.Request>{ request }
        );
        Test.stopTest();

        // Vérifications
        System.assertEquals(1, results.size(), 'Should return one result');
        GRDFCreateDroits.Result result = results[0];
        System.assertEquals(true, result.success, 'Operation should succeed');
        System.assert(result.message.contains('1 PCE'), 'Message should mention 1 PCE');
    }

    /**
     * Test avec une liste vide de PCE
     */
    @IsTest
    static void testCreateDroitsAcces_EmptyList() {
        // Préparer la requête avec liste vide
        GRDFCreateDroits.Request request = new GRDFCreateDroits.Request();
        request.pces = new List<PDE__c>();
        request.userEmail = 'empty@example.com';

        Test.startTest();
        List<GRDFCreateDroits.Result> results = GRDFCreateDroits.createDroitsAcces(
            new List<GRDFCreateDroits.Request>{ request }
        );
        Test.stopTest();

        // Vérifications
        System.assertEquals(1, results.size(), 'Should return one result');
        GRDFCreateDroits.Result result = results[0];
        System.assertEquals(true, result.success, 'Operation should succeed even with empty list');
        System.assertNotEquals(null, result.jobId, 'Job ID should still be set');
    }

    /**
     * Test avec un volume de PCE important (50 PCE)
     * Note: On limite à 50 pour éviter les problèmes de chaining Queueable en test
     */
    @IsTest
    static void testCreateDroitsAcces_BulkVolume() {
        // Créer 50 PDE Gaz pour tester le traitement en volume
        // On récupère le compte et le RecordType créé par le setup
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        Id gazRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_Gaz'].get(0).Id;

        List<PDE__c> pces = new List<PDE__c>();
        for (Integer i = 0; i < 50; i++) {
            pces.add(new PDE__c(
                PCE_Refonte__c = 'PCEBULK' + i,
                Code_Postal__c = '13001',
                Date_signature_ACD__c = Date.today(),
                EntiteJuridique__c = acc.Id,
                RecordTypeId = gazRecordTypeId,
                SiteConsommation__c = 'Site ' + i,
                NumeroVoie__c = String.valueOf(i),
                voie__c = 'Rue Test',
                Ville__c = 'Marseille'
            ));
        }
        insert pces;

        // Préparer la requête
        GRDFCreateDroits.Request request = new GRDFCreateDroits.Request();
        request.pces = pces;
        request.userEmail = 'bulk@example.com';

        Test.startTest();
        List<GRDFCreateDroits.Result> results = GRDFCreateDroits.createDroitsAcces(
            new List<GRDFCreateDroits.Request>{ request }
        );
        Test.stopTest();

        // Vérifications
        System.assertEquals(1, results.size(), 'Should return one result');
        GRDFCreateDroits.Result result = results[0];
        System.assertEquals(true, result.success, 'Operation should succeed');
        System.assert(result.message.contains('50'), 'Message should mention 50 PCEs');
    }

    /**
     * Test avec email valide
     */
    @IsTest
    static void testCreateDroitsAcces_ValidEmail() {
        // Récupérer un PDE créé par le setup
        PDE__c pce = [
            SELECT Id, PCE_Refonte__c, Date_signature_ACD__c, TECH_num_compteur__c
            FROM PDE__c
            LIMIT 1
        ];

        // Mettre à jour les champs requis
        pce.PCE_Refonte__c = 'PCE999';
        pce.Date_signature_ACD__c = Date.today();
        update pce;

        // Préparer la requête avec un email valide
        GRDFCreateDroits.Request request = new GRDFCreateDroits.Request();
        request.pces = new List<PDE__c>{ pce };
        request.userEmail = 'valid.email+tag@example.com';

        Test.startTest();
        List<GRDFCreateDroits.Result> results = GRDFCreateDroits.createDroitsAcces(
            new List<GRDFCreateDroits.Request>{ request }
        );
        Test.stopTest();

        // Vérifications
        System.assertEquals(1, results.size(), 'Should return one result');
        GRDFCreateDroits.Result result = results[0];
        System.assertEquals(true, result.success, 'Operation should succeed with valid email');
    }

    /**
     * Test de vérification du format de sortie
     */
    @IsTest
    static void testCreateDroitsAcces_OutputFormat() {
        // Récupérer un PDE créé par le setup
        PDE__c pce = [
            SELECT Id, PCE_Refonte__c, Date_signature_ACD__c, TECH_num_compteur__c
            FROM PDE__c
            LIMIT 1
        ];

        // Mettre à jour les champs requis
        pce.PCE_Refonte__c = 'PCE111';
        pce.Date_signature_ACD__c = Date.today();
        update pce;

        // Préparer la requête
        GRDFCreateDroits.Request request = new GRDFCreateDroits.Request();
        request.pces = new List<PDE__c>{ pce };
        request.userEmail = 'format@example.com';

        Test.startTest();
        List<GRDFCreateDroits.Result> results = GRDFCreateDroits.createDroitsAcces(
            new List<GRDFCreateDroits.Request>{ request }
        );
        Test.stopTest();

        // Vérifications du format de sortie
        System.assertEquals(1, results.size(), 'Should return exactly one result');

        GRDFCreateDroits.Result result = results[0];
        System.assertNotEquals(null, result.success, 'Success flag should be set');
        System.assertNotEquals(null, result.message, 'Message should be set');
        System.assertNotEquals(null, result.jobId, 'Job ID should be set');
    }

    /**
     * Test de la structure de la classe Request
     */
    @IsTest
    static void testRequestClass_Structure() {
        // Récupérer un PDE créé par le setup
        PDE__c pce = [SELECT Id FROM PDE__c LIMIT 1];

        // Tester l'instanciation de Request
        GRDFCreateDroits.Request request = new GRDFCreateDroits.Request();
        request.pces = new List<PDE__c>{ pce };
        request.userEmail = 'structure@example.com';

        // Vérifications
        System.assertNotEquals(null, request, 'Request should be instantiable');
        System.assertEquals(1, request.pces.size(), 'PCE list should be set');
        System.assertEquals('structure@example.com', request.userEmail, 'Email should be set');
    }

    /**
     * Test de la structure de la classe Result
     */
    @IsTest
    static void testResultClass_Structure() {
        // Tester l'instanciation de Result
        GRDFCreateDroits.Result result = new GRDFCreateDroits.Result();
        result.success = true;
        result.message = 'Test message';
        result.jobId = '00000000000000';

        // Vérifications
        System.assertNotEquals(null, result, 'Result should be instantiable');
        System.assertEquals(true, result.success, 'Success should be set');
        System.assertEquals('Test message', result.message, 'Message should be set');
        System.assertEquals('00000000000000', result.jobId, 'Job ID should be set');
    }

    /**
     * Test avec des PCE ayant des données minimales
     */
    @IsTest
    static void testCreateDroitsAcces_MinimalPCEData() {
        // Récupérer un PDE créé par le setup
        PDE__c pce = [SELECT Id, TECH_num_compteur__c FROM PDE__c LIMIT 1];

        // Mettre à jour avec données minimales
        pce.PCE_Refonte__c = 'PCE_MIN';
        pce.Date_signature_ACD__c = Date.today();
        update pce;

        // Préparer la requête
        GRDFCreateDroits.Request request = new GRDFCreateDroits.Request();
        request.pces = new List<PDE__c>{ pce };
        request.userEmail = 'minimal@example.com';

        Test.startTest();
        List<GRDFCreateDroits.Result> results = GRDFCreateDroits.createDroitsAcces(
            new List<GRDFCreateDroits.Request>{ request }
        );
        Test.stopTest();

        // Vérifications
        System.assertEquals(1, results.size(), 'Should return one result');
        GRDFCreateDroits.Result result = results[0];
        System.assertEquals(true, result.success, 'Should succeed even with minimal data');
    }
}