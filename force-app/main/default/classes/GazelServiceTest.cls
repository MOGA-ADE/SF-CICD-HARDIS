@IsTest
private class GazelServiceTest {

    // --------------------------------
    // Helpers
    // --------------------------------
    
    /**
     * Crée les données nécessaires pour matcher le JSON du Webhook
     * @param gazelOffreId : L'ID de l'offre renvoyé par Gazel (ex: 69949424b44f233c7e9d9b4a)
     * @param pdeNum : Le numéro de compteur (ex: GI038755)
     * @param isElec : Type d'offre
     */
    private static Quote createDataForWebhook(String gazelOffreId, String pdeNum, Boolean isElec) {
        // 1. Account & Opp
        Account acc = new Account(Name = 'Test Account', Siren__c = '527635718');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert opp;

        // 2. Quote avec l'ID Gazel spécifique
        Id pricebookId = Test.getStandardPricebookId();
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = pricebookId,
            API_Offre_ID__c = gazelOffreId, // CLÉ DE MAPPING
            CEE__c = 'Soumis',
            Date_de_fin_de_contrat__c = Date.today().addMonths(12)
        );
        insert q;

        // 3. Product & PBE
        Product2 prod = new Product2(Name = isElec ? 'Electricity' : 'Gas', IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // 4. PDE avec le Numéro de compteur spécifique
        PDE__c pde = new PDE__c(
            Name = 'PDE Test',
            EntiteJuridique__c = acc.Id,
            ReferencePointEnergie_Refonte__c = isElec ? pdeNum : null,
            PCE_Refonte__c = !isElec ? pdeNum : null
        );
        insert pde;

        // 5. QuoteLineItem
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 0, // Sera mis à jour par la commission
            PDE__c = pde.Id,
            DebutDeFourniture__c = Date.today().addDays(1),
            Nouvelle_Echeance__c = Date.today().addMonths(12)
        );
        insert qli;

        return q;
    }

    // --------------------------------
    // Tests
    // --------------------------------

    @IsTest
    static void testProcessWebhook_Gas_Success() {
        // Setup Data matching the Gas JSON
        String gazelId = '69949424b44f233c7e9d9b4a';
        String pdeNum = 'GI038755';
        createDataForWebhook(gazelId, pdeNum, false);

        // JSON Payload (Gaz)
        String jsonPayload = '{"Offre":{"Compteurs":[{"Adresse":{"libAdresse":"41 AVENUE PIERRE GRENIER","ville":"BOULOGNE BILLANCOURT","codePostal":"92100","codeInsee":"92012","stationId":"75114001"},"PrixMolecule":48.5788,"TermeVariableDistribution":8.19,"AbonnementTransport":3252.65,"AbonnementDistribution":1231.08,"Abonnement":373.64,"EstimationCTA":304.49,"CoutMoyenTotal":78.65957319587628,"CarUtilisee":388605,"ConsommationTotalePrevisionnelle":391069.4450394893,"VolumeEte":103406.20712839524,"VolumeHiver":287663.2379110941,"CapaciteTransportNomalisee":5.13,"Profil":"P017","TarifDistribution":"T3","CarActuelle":456960,"CarFuture":388605,"Num":"GI038755","PrixCee":9.55,"PrixDonCaritatif":0,"IsEligibleCee":true,"Siret":"52763571800044","Debut":"2028-01-01T01:00:00+01:00","Fin":"2028-12-31T23:59:59+01:00"}],"Id":"69949424b44f233c7e9d9b4a","Commodite":2,"Debut":"2028-01-01T01:00:00+01:00","DateValidite":"2026-02-19T12:00:00+01:00","Duree":12,"Fin":"2028-12-31T23:59:59","FormulePrixId":100,"FormulePrix":"CdcPrixFixe","Marge":5,"VolumeEstime":391069.4450394893,"CommissionEstimee":977.6736125987225,"BudgetAnnuel":37328.05106995652,"Status":{"Code":140,"Commentaire":"Contenu de l\'offre validé, en attente de publipostage","Date":"2026-02-17T17:15:51.3414232+01:00"}},"DossierClient":{"Id":"698dcbf3af6024bf15c4e248","Siren":"527635718","RaisonSociale":"VIANOVA GESTION","Adresse":{"Value":"4B RUE JULES SIMON 92100 BOULOGNE-BILLANCOURT","Ville":"BOULOGNE-BILLANCOURT","CodePostal":"92100","CodeInsee":null},"Capital":15000,"NumTva":"FR56527635718","Rcs":"RCS Nanterre","Naf":"6831Z","Sdc":null}}';

        // Deserialize to DTO
        GazelWebhookDTO.Payload payload = (GazelWebhookDTO.Payload) JSON.deserialize(jsonPayload, GazelWebhookDTO.Payload.class);

        Test.startTest();
        GazelService.processWebhookUpdate(payload);
        Test.stopTest();

        // Assertions Quote
        Quote qAfter = [SELECT Api_status__c, Date_Validite_Offre__c FROM Quote WHERE API_Offre_ID__c = :gazelId];
        System.assertEquals('Demande de prix validée par le fournisseur', qAfter.Api_status__c);
        // Vérif date validité (2026-02-19)
        System.assertEquals(Date.newInstance(2026, 02, 19), qAfter.Date_Validite_Offre__c.date());

        // Assertions QLI
        QuoteLineItem qliAfter = [SELECT PrixMolecule__c, AbonnementMois__c, CeeMwh__c, UnitPrice FROM QuoteLineItem WHERE QuoteId = :qAfter.Id LIMIT 1];
        System.assertEquals(48.58, qliAfter.PrixMolecule__c, 'Prix Molecule incorrect'); // 48.5788 rounded
        System.assertEquals(373.64, qliAfter.AbonnementMois__c, 'Abonnement incorrect');
        System.assertEquals(9.55, qliAfter.CeeMwh__c, 'CEE incorrect');
        System.assertEquals(977.67, qliAfter.UnitPrice, 'Commission incorrecte'); // 977.6736 rounded
    }

    @IsTest
    static void testProcessWebhook_Elec_Success() {
        // Setup Data matching the Elec JSON
        String gazelId = '6994916ab44f233c7e9d9b3b';
        String pdeNum = '30002122620503';
        createDataForWebhook(gazelId, pdeNum, true);

        // JSON Payload (Elec)
        String jsonPayload = '{"Offre":{"IsGarantieOrigine":false,"TauxGarantieOrigine":0,"Compteurs":[{"Adresse":{"libAdresse":"1 RUE DES CHAMPS ODES","ville":"BUCHELAY","codePostal":"78200","codeInsee":"78118","stationId":null,"codePays":"FR"},"CoefCapacite":[{"Nom":"BASE","Coefficient":0.5547846041154051,"MontantTheorique":0}],"PrixElectron":[{"Nom":"PF","FormulePrixEnergieValeur":{"PrixAmont":0,"A":147.6689,"B":0,"C":0,"D":0,"VolumeTotal":13862.956812529519,"VolumeArenh":0,"AdditifPrixFixeMarcheInluantArenh":3.1964367639076006}},{"Nom":"HPH","FormulePrixEnergieValeur":{"PrixAmont":0,"A":120.2889,"B":0,"C":0,"D":0,"VolumeTotal":66148.90534167967,"VolumeArenh":0,"AdditifPrixFixeMarcheInluantArenh":2.399157008520941}},{"Nom":"HCH","FormulePrixEnergieValeur":{"PrixAmont":0,"A":99.7389,"B":0,"C":0,"D":0,"VolumeTotal":36647.80352168644,"VolumeArenh":0,"AdditifPrixFixeMarcheInluantArenh":1.8006031654877117}},{"Nom":"HPE","FormulePrixEnergieValeur":{"PrixAmont":0,"A":72.7189,"B":0,"C":0,"D":0,"VolumeTotal":54929.75826543613,"VolumeArenh":0,"AdditifPrixFixeMarcheInluantArenh":1.0133918472687926}},{"Nom":"HCE","FormulePrixEnergieValeur":{"PrixAmont":0,"A":67.1389,"B":0,"C":0,"D":0,"VolumeTotal":25798.493828582326,"VolumeArenh":0,"AdditifPrixFixeMarcheInluantArenh":0.8510461693411591}}],"Statut":1,"Segment":"C2","Turpe":"HTACU5","ConsoAnnuelle":0,"Num":"30002122620503","PrixCee":0,"PrixDonCaritatif":0,"IsEligibleCee":false,"Siret":"79527951200037","Debut":"2027-01-01T01:00:00+01:00","Fin":"2028-12-31T00:00:00+01:00"}],"Id":"6994916ab44f233c7e9d9b3b","Commodite":1,"Debut":"2027-01-01T01:00:00+01:00","DateValidite":"2026-02-19T12:00:00","Duree":24,"Fin":"2028-12-31T00:00:00","FormulePrixId":100,"FormulePrix":"CdcMarche","Marge":5,"VolumeEstime":197002.3116885549,"CommissionEstimee":492.5057792213875,"BudgetAnnuel":20001.800184139945,"Status":{"Code":140,"Commentaire":"Contenu de l\'offre validé, en attente de publipostage","Date":"2026-02-17T17:05:59.3281242+01:00"}},"DossierClient":{"Id":"698f4fca5747226bd75d9d7f","Siren":"795279512","RaisonSociale":"PREFORMED LINE PRODUCTS (FRANCE)","Adresse":{"Value":"1 RUE DES CHAMPS ODES 78200 BUCHELAY","Ville":"BUCHELAY","CodePostal":"78200","CodeInsee":null},"Capital":2000000,"NumTva":"FR67795279512","Rcs":"RCS Versailles","Naf":"2732Z","Sdc":null}}';

        GazelWebhookDTO.Payload payload = (GazelWebhookDTO.Payload) JSON.deserialize(jsonPayload, GazelWebhookDTO.Payload.class);

        Test.startTest();
        GazelService.processWebhookUpdate(payload);
        Test.stopTest();

        Quote qAfter = [SELECT Api_status__c FROM Quote WHERE API_Offre_ID__c = :gazelId];
        System.assertEquals('Demande de prix validée par le fournisseur', qAfter.Api_status__c);

        QuoteLineItem qliAfter = [SELECT PrixHphMwh__c, PrixHchMwh__c, PrixHpeMwh__c, PrixHceMwh__c, UnitPrice FROM QuoteLineItem WHERE QuoteId = :qAfter.Id LIMIT 1];
        
        // Vérification des prix Electron (Valeur "A" dans le JSON)
        System.assertEquals(120.29, qliAfter.PrixHphMwh__c, 'Prix HPH incorrect'); // 120.2889 rounded
        System.assertEquals(99.74, qliAfter.PrixHchMwh__c, 'Prix HCH incorrect'); // 99.7389 rounded
        System.assertEquals(72.72, qliAfter.PrixHpeMwh__c, 'Prix HPE incorrect'); // 72.7189 rounded
        System.assertEquals(67.14, qliAfter.PrixHceMwh__c, 'Prix HCE incorrect'); // 67.1389 rounded
        System.assertEquals(492.51, qliAfter.UnitPrice, 'Commission incorrecte'); // 492.505... rounded
    }

    @IsTest
    static void testProcessWebhook_Rejection() {
        String gazelId = 'REJECT-123';
        createDataForWebhook(gazelId, 'ANY-NUM', false);

        // JSON simplifié pour simuler un rejet (Code 120)
        // Pas de compteurs, pas de dossier client complet, juste le statut
        String jsonPayload = '{"Offre":{"Id":"REJECT-123","Status":{"Code":120,"Commentaire":"Données invalides"}}}';
        
        GazelWebhookDTO.Payload payload = (GazelWebhookDTO.Payload) JSON.deserialize(jsonPayload, GazelWebhookDTO.Payload.class);

        Test.startTest();
        GazelService.processWebhookUpdate(payload);
        Test.stopTest();

        Quote qAfter = [SELECT Api_status__c, Api_error_message__c FROM Quote WHERE API_Offre_ID__c = :gazelId];
        System.assertEquals('Demande de prix rejetée par le fournisseur', qAfter.Api_status__c);
        System.assert(qAfter.Api_error_message__c.contains('Données invalides'), 'Message erreur attendu');
    }

    @IsTest
    static void testProcessWebhook_ManualAction() {
        String gazelId = 'MANUAL-123';
        createDataForWebhook(gazelId, 'ANY-NUM', false);

        // JSON simplifié pour simuler une action manuelle (Code 20 par exemple)
        String jsonPayload = '{"Offre":{"Id":"MANUAL-123","Status":{"Code":20,"Commentaire":"Vérification requise"}}}';
        
        GazelWebhookDTO.Payload payload = (GazelWebhookDTO.Payload) JSON.deserialize(jsonPayload, GazelWebhookDTO.Payload.class);

        Test.startTest();
        GazelService.processWebhookUpdate(payload);
        Test.stopTest();

        Quote qAfter = [SELECT Api_status__c FROM Quote WHERE API_Offre_ID__c = :gazelId];
        System.assertEquals('Demande de prix en attente d\'action manuelle', qAfter.Api_status__c);
    }
}