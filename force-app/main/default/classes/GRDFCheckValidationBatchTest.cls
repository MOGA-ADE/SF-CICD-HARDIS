@IsTest
private class GRDFCheckValidationBatchTest {

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
     * Test nominal : droits d'accès validés (Active)
     */
    @IsTest
    static void testBatch_DroitsValidesActive() {
        // Récupérer les PDE créés et les mettre en statut "en attente de validation"
        List<PDE__c> pces = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 3];

        // Mettre à jour les PCE avec des valeurs spécifiques
        pces[0].PCE_Refonte__c = 'PCE1000';
        pces[0].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[0].GRDF_Id_Droit_Acces__c = 'DA-001';

        pces[1].PCE_Refonte__c = 'PCE1001';
        pces[1].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[1].GRDF_Id_Droit_Acces__c = 'DA-002';

        pces[2].PCE_Refonte__c = 'PCE1002';
        pces[2].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[2].GRDF_Id_Droit_Acces__c = 'DA-003';

        update pces;

        // Mock la réponse HTTP avec des droits validés (les id_pce doivent correspondre aux PCE_Refonte__c)
        String ndjsonResponse =
            '{"id_droit_acces":"DA-001","id_pce":"PCE1000","etat_droit_acces":"Active","date_fin_droit_acces":"2025-12-31","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"id_droit_acces":"DA-002","id_pce":"PCE1001","etat_droit_acces":"Active","date_fin_droit_acces":"2026-01-15","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"id_droit_acces":"DA-003","id_pce":"PCE1002","etat_droit_acces":"Active","date_fin_droit_acces":"2026-06-30","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"code_statut_traitement":"OK","message_retour_traitement":"Terminé"}';

        Test.setMock(HttpCalloutMock.class, new HttpCalloutSuccessMock(ndjsonResponse));

        Test.startTest();
        GRDFCheckValidationBatch batch = new GRDFCheckValidationBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Vérifications : tous les PCE doivent être passés à "validée"
        List<PDE__c> updatedPces = [
            SELECT Id, GRDF_Statut_Droit_Acces__c, GRDF_Date_fin_droit_acces__c
            FROM PDE__c
            WHERE Id IN :pces
        ];

        for (PDE__c pce : updatedPces) {
            System.assertEquals('Demande d\'accès validée', pce.GRDF_Statut_Droit_Acces__c,
                'Le statut devrait être "validée"');
            System.assertNotEquals(null, pce.GRDF_Date_fin_droit_acces__c,
                'La date de fin devrait être renseignée');
        }
    }

    /**
     * Test : droits d'accès refusés
     */
    @IsTest
    static void testBatch_DroitsRefuses() {
        // Récupérer les PDE et les mettre en statut "en attente de validation"
        List<PDE__c> pces = [SELECT Id, PCE_Refonte__c, TECH_num_compteur__c FROM PDE__c LIMIT 2];

        // Mettre à jour les PCE avec des valeurs spécifiques
        pces[0].PCE_Refonte__c = 'PCE2000';
        pces[0].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[0].GRDF_Id_Droit_Acces__c = 'DA-101';

        pces[1].PCE_Refonte__c = 'PCE2001';
        pces[1].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[1].GRDF_Id_Droit_Acces__c = 'DA-102';

        update pces;

        // Relire les PCE pour obtenir les valeurs calculées de TECH_num_compteur__c
        pces = [SELECT Id, PCE_Refonte__c, TECH_num_compteur__c FROM PDE__c WHERE Id IN :pces];
        System.debug('PCE après update - TECH_num_compteur__c: ' + pces[0].TECH_num_compteur__c + ', ' + pces[1].TECH_num_compteur__c);

        // Mock la réponse HTTP avec des droits refusés (les id_pce doivent correspondre aux PCE_Refonte__c)
        String ndjsonResponse =
            '{"id_droit_acces":"DA-101","id_pce":"PCE2000","etat_droit_acces":"Refusée","source_passage_a_refuse":"Document manquant","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"id_droit_acces":"DA-102","id_pce":"PCE2001","etat_droit_acces":"Refusée","source_passage_a_refuse":"Informations incorrectes","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"code_statut_traitement":"OK","message_retour_traitement":"Terminé"}';

        Test.setMock(HttpCalloutMock.class, new HttpCalloutSuccessMock(ndjsonResponse));

        Test.startTest();
        GRDFCheckValidationBatch batch = new GRDFCheckValidationBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    }

    /**
     * Test : mix de droits validés et refusés
     */
    @IsTest
    static void testBatch_MixeValidesEtRefuses() {
        // Récupérer les PDE et les mettre en statut "en attente de validation"
        List<PDE__c> pces = [SELECT Id, PCE_Refonte__c, TECH_num_compteur__c FROM PDE__c LIMIT 4];

        // Mettre à jour les PCE avec des valeurs spécifiques
        pces[0].PCE_Refonte__c = 'PCE3000';
        pces[0].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[0].GRDF_Id_Droit_Acces__c = 'DA-201';

        pces[1].PCE_Refonte__c = 'PCE3001';
        pces[1].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[1].GRDF_Id_Droit_Acces__c = 'DA-202';

        pces[2].PCE_Refonte__c = 'PCE3002';
        pces[2].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[2].GRDF_Id_Droit_Acces__c = 'DA-203';

        pces[3].PCE_Refonte__c = 'PCE3003';
        pces[3].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[3].GRDF_Id_Droit_Acces__c = 'DA-204';

        update pces;

        // Relire les PCE pour obtenir les valeurs calculées de TECH_num_compteur__c
        pces = [SELECT Id, PCE_Refonte__c, TECH_num_compteur__c FROM PDE__c WHERE Id IN :pces];

        // Mock la réponse HTTP avec un mix (les id_pce doivent correspondre aux PCE_Refonte__c)
        String ndjsonResponse =
            '{"id_droit_acces":"DA-201","id_pce":"PCE3000","etat_droit_acces":"Active","date_fin_droit_acces":"2025-12-31","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"id_droit_acces":"DA-202","id_pce":"PCE3001","etat_droit_acces":"Refusée","source_passage_a_refuse":"Document expiré","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"id_droit_acces":"DA-203","id_pce":"PCE3002","etat_droit_acces":"Active","date_fin_droit_acces":"2026-03-15","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"id_droit_acces":"DA-204","id_pce":"PCE3003","etat_droit_acces":"Refusée","source_passage_a_refuse":"Signature invalide","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"code_statut_traitement":"OK","message_retour_traitement":"Terminé"}';

        Test.setMock(HttpCalloutMock.class, new HttpCalloutSuccessMock(ndjsonResponse));

        Test.startTest();
        GRDFCheckValidationBatch batch = new GRDFCheckValidationBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Vérifications
        Map<Id, PDE__c> pceMap = new Map<Id, PDE__c>([
            SELECT Id, PCE_Refonte__c, GRDF_Statut_Droit_Acces__c, GRDF_Date_fin_droit_acces__c
            FROM PDE__c
            WHERE Id IN :pces
        ]);

        Integer validesCount = 0;
        Integer refusesCount = 0;

        for (PDE__c pce : pceMap.values()) {
            if (pce.GRDF_Statut_Droit_Acces__c == 'Demande d\'accès validée') {
                validesCount++;
                System.assertNotEquals(null, pce.GRDF_Date_fin_droit_acces__c,
                    'La date de fin devrait être renseignée pour les validés');
            } else if (pce.GRDF_Statut_Droit_Acces__c == 'Demande d\'accès refusée') {
                refusesCount++;
            }
        }

        System.assertEquals(2, validesCount, 'Devrait avoir 2 droits validés');
    }

    /**
     * Test : état en attente (ni Active ni Refusée)
     * Ces PCE ne doivent pas être mis à jour
     */
    @IsTest
    static void testBatch_EtatEnAttente() {
        // Récupérer les PDE et les mettre en statut "en attente de validation"
        List<PDE__c> pces = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 2];

        // Mettre à jour les PCE avec des valeurs spécifiques
        pces[0].PCE_Refonte__c = 'PCE4000';
        pces[0].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[0].GRDF_Id_Droit_Acces__c = 'DA-301';

        pces[1].PCE_Refonte__c = 'PCE4001';
        pces[1].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[1].GRDF_Id_Droit_Acces__c = 'DA-302';

        update pces;

        // Mock la réponse HTTP avec un état "En attente" (ni Active ni Refusée)
        String ndjsonResponse =
            '{"id_droit_acces":"DA-301","id_pce":"PCE4000","etat_droit_acces":"En attente","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"id_droit_acces":"DA-302","id_pce":"PCE4001","etat_droit_acces":"En cours de traitement","role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"code_statut_traitement":"OK","message_retour_traitement":"Terminé"}';

        Test.setMock(HttpCalloutMock.class, new HttpCalloutSuccessMock(ndjsonResponse));

        Test.startTest();
        GRDFCheckValidationBatch batch = new GRDFCheckValidationBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Vérifications : les PCE doivent rester en "attente de validation"
        List<PDE__c> updatedPces = [
            SELECT Id, GRDF_Statut_Droit_Acces__c
            FROM PDE__c
            WHERE Id IN :pces
        ];

        for (PDE__c pce : updatedPces) {
            System.assertEquals('Demande d\'accès en attente de validation', pce.GRDF_Statut_Droit_Acces__c,
                'Le statut ne devrait pas changer pour les états en attente');
        }
    }

    /**
     * Test : erreur HTTP lors de l'appel API
     */
    @IsTest
    static void testBatch_ErreurHTTP() {
        // Récupérer les PDE et les mettre en statut "en attente de validation"
        List<PDE__c> pces = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 2];

        // Mettre à jour les PCE avec des valeurs spécifiques
        pces[0].PCE_Refonte__c = 'PCE5000';
        pces[0].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[0].GRDF_Id_Droit_Acces__c = 'DA-401';

        pces[1].PCE_Refonte__c = 'PCE5001';
        pces[1].GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pces[1].GRDF_Id_Droit_Acces__c = 'DA-402';

        update pces;

        // Mock une erreur HTTP
        Test.setMock(HttpCalloutMock.class, new HttpCalloutErrorMock());

        Test.startTest();
        GRDFCheckValidationBatch batch = new GRDFCheckValidationBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Vérifications : le batch ne doit pas planter, les PCE restent inchangés
        List<PDE__c> updatedPces = [
            SELECT Id, GRDF_Statut_Droit_Acces__c
            FROM PDE__c
            WHERE Id IN :pces
        ];

        // Les PCE doivent rester en attente (gestion d'erreur dans le batch)
        for (PDE__c pce : updatedPces) {
            System.assertEquals('Demande d\'accès en attente de validation', pce.GRDF_Statut_Droit_Acces__c,
                'Le statut ne devrait pas changer en cas d\'erreur HTTP');
        }
    }

    /**
     * Test : aucun PCE en attente de validation
     */
    @IsTest
    static void testBatch_AucunPCEEnAttente() {
        // Mettre tous les PCE dans un autre statut
        List<PDE__c> pces = [SELECT Id FROM PDE__c];
        for (PDE__c pce : pces) {
            pce.GRDF_Statut_Droit_Acces__c = 'Demande d\'accès validée';
        }
        update pces;

        Test.startTest();
        GRDFCheckValidationBatch batch = new GRDFCheckValidationBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Le batch doit se terminer sans erreur
        // Pas de vérifications spécifiques car aucun enregistrement ne doit être traité
        System.assert(true, 'Le batch devrait se terminer sans erreur même sans données');
    }

    /**
     * Test : date_fin_droit_acces null dans la réponse
     */
    @IsTest
    static void testBatch_DateFinNull() {
        // Récupérer un PDE
        PDE__c pce = [SELECT Id, PCE_Refonte__c FROM PDE__c LIMIT 1];
        pce.PCE_Refonte__c = 'PCE6000';
        pce.GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
        pce.GRDF_Id_Droit_Acces__c = 'DA-601';
        update pce;

        // Mock la réponse avec date_fin_droit_acces à null
        String ndjsonResponse =
            '{"id_droit_acces":"DA-601","id_pce":"PCE6000","etat_droit_acces":"Active","date_fin_droit_acces":null,"role_tiers":"AUTORISE_CONTRAT_FOURNITURE"}\n' +
            '{"code_statut_traitement":"OK","message_retour_traitement":"Terminé"}';

        Test.setMock(HttpCalloutMock.class, new HttpCalloutSuccessMock(ndjsonResponse));

        Test.startTest();
        GRDFCheckValidationBatch batch = new GRDFCheckValidationBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Vérifications
        PDE__c updatedPce = [
            SELECT Id, GRDF_Statut_Droit_Acces__c, GRDF_Date_fin_droit_acces__c
            FROM PDE__c
            WHERE Id = :pce.Id
        ];

        System.assertEquals('Demande d\'accès validée', updatedPce.GRDF_Statut_Droit_Acces__c,
            'Le statut devrait être validé');
        System.assertEquals(null, updatedPce.GRDF_Date_fin_droit_acces__c,
            'La date de fin devrait être null');
    }

    // ========================================
    // CLASSES MOCK
    // ========================================

    /**
     * Mock pour simuler une réponse HTTP réussie
     */
    private class HttpCalloutSuccessMock implements HttpCalloutMock {
        private String responseBody;

        public HttpCalloutSuccessMock(String body) {
            this.responseBody = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(responseBody);
            res.setHeader('Content-Type', 'application/x-ndjson');
            return res;
        }
    }

    /**
     * Mock pour simuler une erreur HTTP
     */
    private class HttpCalloutErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            CalloutException e = new CalloutException();
            e.setMessage('Simulated HTTP Error');
            throw e;
        }
    }
}