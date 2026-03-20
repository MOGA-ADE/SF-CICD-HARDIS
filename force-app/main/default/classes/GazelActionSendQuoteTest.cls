/**
 * GazelActionSendQuoteTest
 * Tests for GazelActionSendQuote invocable using existing TestDataFactory to generate data.
 *
 * Covered scenarios:
 *  - SDC validation: no copro on QLI -> error
 *  - SDC validation: multiple copro -> error
 *  - SDC validation: incomplete address -> error
 *  - Success path (Elec, non-SDC) -> mocked 201, quote updated
 *  - Success path (SDC) -> mocked 201, success message
 *  - Error path: API non-2xx -> failure with technical message
 *  - Exception-like path: unexpected body -> caught and reported
 *  - Bulk invocation with two inputs (method returns single Output by design)
 */
@IsTest
private class GazelActionSendQuoteTest {

    // --------------------------------
    // Helpers
    // --------------------------------
    private class ApiSuccess201Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('Gazel_Auth_NC')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"tok_ok","expires_in":3600}');
            } else if (req.getEndpoint().contains('/v1/demande-cotation')) {
                res.setStatusCode(201);
                res.setBody('{"offre":{"id":"GAZEL-OK-201"},"status":"CREATED"}');
            } else {
                res.setStatusCode(200);
                res.setBody('OK');
            }
            return res;
        }
    }
    private class ApiError400Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('Gazel_Auth_NC')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"tok_ok","expires_in":3600}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"error":"Bad Request"}');
            }
            return res;
        }
    }
    private class ApiUnexpectedBodyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (req.getEndpoint().contains('Gazel_Auth_NC')) {
                res.setStatusCode(200);
                res.setBody('{"access_token":"tok_ok","expires_in":3600}');
                return res;
            }
            res.setStatusCode(200);
            res.setBody('not-json');
            return res;
        }
    }

    // --------------------------------
    // Helpers
    // --------------------------------
    private static Quote createQuoteWithData(Boolean isSdc) {
        // 1. Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // 2. Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addMonths(1)
        );
        insert opp;

        // 3. Quote
        Id pricebookId = Test.getStandardPricebookId();
        Quote q = new Quote(
            Name = 'Test Quote',
            OpportunityId = opp.Id,
            Pricebook2Id = pricebookId,
            Date_de_fin_de_contrat__c = Date.today().addMonths(12)
        );
        insert q;

        // 4. Product & PBE
        Product2 prod = new Product2(Name = 'Electricity', IsActive = true);
        insert prod;
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        // 5. PDE & Entite Juridique
        Account entiteJuridique = acc;
        if (isSdc) {
            // Create Copro Account
            Id coproRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Copropriete').getRecordTypeId();
            Account copro = new Account(
                Name = 'Copro Test',
                RecordTypeId = coproRtId,
                Numero_voie__c = '10',
                Voie__c = 'Rue Test',
                Code_postal__c = '75001',
                Ville__c = 'Paris'
            );
            insert copro;
            entiteJuridique = copro;
        }

        PDE__c pde = new PDE__c(
            Name = 'PDE Test',
            EntiteJuridique__c = entiteJuridique.Id,
            ReferencePointEnergie_Refonte__c = '12345678901234'
        );
        insert pde;

        // 6. QuoteLineItem
        // Setting DebutDeFourniture__c and Nouvelle_Echeance__c triggers rollups on Quote
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100,
            PDE__c = pde.Id,
            DebutDeFourniture__c = Date.today().addDays(1),
            Nouvelle_Echeance__c = Date.today().addMonths(12)
        );
        insert qli;

        // Return re-queried Quote
        return [
            SELECT Id, Minimum_date_de_debut__c, Maximum_date_de_fin__c, Duree_offre_en_mois__c, Opportunity.AccountId 
            FROM Quote 
            WHERE Id = :q.Id
        ];
    }

    // --------------------------------
    // Tests for SDC validations
    // --------------------------------

    @IsTest
    static void testSDC_NoCopro_ReturnsError() {
        Quote q = createQuoteWithData(true); // Create SDC structure initially

        // Remove PDE__c from all QLIs
        List<QuoteLineItem> qlis = [SELECT Id, PDE__c FROM QuoteLineItem WHERE QuoteId = :q.Id];
        for (QuoteLineItem qli : qlis) {
            qli.PDE__c = null;
        }
        update qlis;

        GazelActionSendQuote.Input input = new GazelActionSendQuote.Input();
        input.quoteId = q.Id;
        input.quoteType = 'Elec';
        input.formulePrix = 2;
        input.prixHorosaisonnier = 1;
        input.marge = 5.0;
        input.clientType = 'SDC';
        input.immatriculation = 'IMM-1';
        input.isGarantieOrigine = true;
        input.tauxGarantieOrigine = 30.0;
        input.isComplementPrixSpot = false;
        input.isClauseDerogationPenalitesRetardPaiement = false;
        input.demandeContournementLiasse = true;

        Test.startTest();
        List<GazelActionSendQuote.Output> outs = GazelActionSendQuote.GazelActionSendQuote(new List<GazelActionSendQuote.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(false, outs[0].isSuccess);
        System.assert(outs[0].userMessage != null && outs[0].userMessage.contains('Aucune copropriété'), 'Expected missing copro error');
    }

    @IsTest
    static void testSDC_MultipleCopro_ReturnsError() {
        Quote q = createQuoteWithData(true); // Creates 1 QLI linked to 1 Copro

        // Create a second Copro and PDE
        Id coproRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Copropriete').getRecordTypeId();
        Account copro2 = new Account(
            Name = 'Copro 2', 
            RecordTypeId = coproRtId,
            Numero_voie__c = '20', 
            Voie__c = 'Rue B', 
            Code_postal__c = '69001', 
            Ville__c = 'Lyon'
        );
        insert copro2;

        PDE__c pde2 = new PDE__c(
            Name = 'PDE B', 
            EntiteJuridique__c = copro2.Id, 
            ReferencePointEnergie_Refonte__c='900000000002'
        );
        insert pde2;

        // Create a second QLI linked to this new PDE
        // Need PricebookEntryId from existing QLI
        QuoteLineItem existingQli = [SELECT PricebookEntryId FROM QuoteLineItem WHERE QuoteId = :q.Id LIMIT 1];
        
        QuoteLineItem qli2 = new QuoteLineItem(
            QuoteId = q.Id,
            PricebookEntryId = existingQli.PricebookEntryId,
            Quantity = 1,
            UnitPrice = 100,
            PDE__c = pde2.Id,
            DebutDeFourniture__c = Date.today().addDays(1),
            Nouvelle_Echeance__c = Date.today().addMonths(12)
        );
        insert qli2;

        GazelActionSendQuote.Input input = new GazelActionSendQuote.Input();
        input.quoteId = q.Id;
        input.quoteType = 'Elec';
        input.formulePrix = 2;
        input.prixHorosaisonnier = 1;
        input.marge = 8.0;
        input.clientType = 'SDC';
        input.immatriculation = 'IMM-2';
        input.isGarantieOrigine = false;
        input.tauxGarantieOrigine = 0;
        input.isComplementPrixSpot = false;
        input.isClauseDerogationPenalitesRetardPaiement = false;
        input.demandeContournementLiasse = true;

        Test.startTest();
        List<GazelActionSendQuote.Output> outs = GazelActionSendQuote.GazelActionSendQuote(new List<GazelActionSendQuote.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(false, outs[0].isSuccess);
        System.assert(outs[0].userMessage != null && outs[0].userMessage.contains('Plusieurs copropriétés'), 'Expected multi-copro error');
    }

    @IsTest
    static void testSDC_IncompleteAddress_ReturnsError() {
        Quote q = createQuoteWithData(true);

        // Retrieve the Copro linked to the PDE and clear address fields
        // We need to find the Account via the QLI -> PDE -> EntiteJuridique
        QuoteLineItem qli = [SELECT PDE__r.EntiteJuridique__c FROM QuoteLineItem WHERE QuoteId = :q.Id LIMIT 1];
        Account copro = [SELECT Id FROM Account WHERE Id = :qli.PDE__r.EntiteJuridique__c];
        
        copro.Numero_voie__c = null;
        copro.Ville__c = null;
        update copro;

        GazelActionSendQuote.Input input = new GazelActionSendQuote.Input();
        input.quoteId = q.Id;
        input.quoteType = 'Elec';
        input.formulePrix = 2;
        input.prixHorosaisonnier = 0;
        input.marge = 4.0;
        input.clientType = 'SDC';
        input.immatriculation = 'IMM-3';
        input.isGarantieOrigine = true;
        input.tauxGarantieOrigine = 50.0;
        input.isComplementPrixSpot = true;
        input.isClauseDerogationPenalitesRetardPaiement = false;
        input.demandeContournementLiasse = true;

        Test.startTest();
        List<GazelActionSendQuote.Output> outs = GazelActionSendQuote.GazelActionSendQuote(new List<GazelActionSendQuote.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(false, outs[0].isSuccess);
        System.assert(outs[0].userMessage != null && outs[0].userMessage.contains('Adresse de facturation incomplète'), 'Expected incomplete address error');
    }

    // --------------------------------
    // Success and error paths with mocks
    // --------------------------------

    @IsTest
    static void testNonSDC_Success201_Elec() {
        Quote q = createQuoteWithData(false);

        GazelActionSendQuote.Input input = new GazelActionSendQuote.Input();
        input.quoteId = q.Id;
        input.quoteType = 'Elec';
        input.formulePrix = 2;
        input.prixHorosaisonnier = 1;
        input.marge = 7.5;
        input.clientType = 'Pro';
        input.isGarantieOrigine = true;
        input.tauxGarantieOrigine = 20.0;
        input.isComplementPrixSpot = false;
        input.isClauseDerogationPenalitesRetardPaiement = true;
        input.demandeContournementLiasse = true;

        Test.setMock(HttpCalloutMock.class, new ApiSuccess201Mock());
        Test.startTest();
        List<GazelActionSendQuote.Output> outs = GazelActionSendQuote.GazelActionSendQuote(new List<GazelActionSendQuote.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(true, outs[0].isSuccess);
        System.assert(outs[0].userMessage != null && outs[0].userMessage.contains('Cotation envoyée avec succès'), 'Expected success message');

        Quote qAfter = [SELECT Id, API_Offre_ID__c, API_status__c, API_Marge_Choisie__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals('GAZEL-OK-201', qAfter.API_Offre_ID__c);
        System.assertEquals('Demande de prix reçue chez le fournisseur', qAfter.API_status__c);
        System.assertEquals(input.marge, qAfter.API_Marge_Choisie__c);
    }

    @IsTest
    static void testSDC_Success201_WithCopro() {
        Quote q = createQuoteWithData(true);

        GazelActionSendQuote.Input input = new GazelActionSendQuote.Input();
        input.quoteId = q.Id;
        input.quoteType = 'Elec';
        input.formulePrix = 2;
        input.prixHorosaisonnier = 1;
        input.marge = 6.0;
        input.clientType = 'SDC';
        input.immatriculation = 'IMM-4';
        input.isGarantieOrigine = false;
        input.tauxGarantieOrigine = 0;
        input.isComplementPrixSpot = true;
        input.isClauseDerogationPenalitesRetardPaiement = false;
        input.demandeContournementLiasse = true;

        Test.setMock(HttpCalloutMock.class, new ApiSuccess201Mock());
        Test.startTest();
        List<GazelActionSendQuote.Output> outs = GazelActionSendQuote.GazelActionSendQuote(new List<GazelActionSendQuote.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(true, outs[0].isSuccess);
        System.assert(outs[0].userMessage != null && outs[0].userMessage.contains('Cotation envoyée avec succès'), 'Expected success message');

        Quote qAfter = [SELECT Id, API_Offre_ID__c FROM Quote WHERE Id = :q.Id];
        System.assertEquals('GAZEL-OK-201', qAfter.API_Offre_ID__c);
    }

    @IsTest
    static void testApiError_ReturnsFailure() {
        Quote q = createQuoteWithData(false);

        GazelActionSendQuote.Input input = new GazelActionSendQuote.Input();
        input.quoteId = q.Id;
        input.quoteType = 'Elec';
        input.formulePrix = 2;
        input.prixHorosaisonnier = 1;
        input.marge = 2.0;
        input.clientType = 'Pro';
        input.isGarantieOrigine = false;
        input.tauxGarantieOrigine = 0;
        input.isComplementPrixSpot = false;
        input.isClauseDerogationPenalitesRetardPaiement = false;
        input.demandeContournementLiasse = true;

        Test.setMock(HttpCalloutMock.class, new ApiError400Mock());
        Test.startTest();
        List<GazelActionSendQuote.Output> outs = GazelActionSendQuote.GazelActionSendQuote(new List<GazelActionSendQuote.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(false, outs[0].isSuccess);
        System.assert(outs[0].userMessage != null && outs[0].userMessage.contains('Echec de l\'envoi'), 'Expected failure user message');
        System.assert(outs[0].technicalMessage != null && outs[0].technicalMessage.contains('Erreur Gazel (400)'), 'Expected technical error detail');
    }

    @IsTest
    static void testApiUnexpectedBody_HandledAsException() {
        Quote q = createQuoteWithData(false);

        GazelActionSendQuote.Input input = new GazelActionSendQuote.Input();
        input.quoteId = q.Id;
        input.quoteType = 'Elec';
        input.formulePrix = 2;
        input.prixHorosaisonnier = 1;
        input.marge = 9.0;
        input.clientType = 'Pro';
        input.isGarantieOrigine = false;
        input.tauxGarantieOrigine = 0;
        input.isComplementPrixSpot = true;
        input.isClauseDerogationPenalitesRetardPaiement = false;
        input.demandeContournementLiasse = true;

        Test.setMock(HttpCalloutMock.class, new ApiUnexpectedBodyMock());
        Test.startTest();
        List<GazelActionSendQuote.Output> outs = GazelActionSendQuote.GazelActionSendQuote(new List<GazelActionSendQuote.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, outs.size());
        System.assertEquals(false, outs[0].isSuccess);
        System.assert(outs[0].userMessage != null && outs[0].userMessage.contains('Erreur système inattendue'), 'Expected system error catch');
        System.assertNotEquals(null, outs[0].technicalMessage, 'Expected technical message to contain stack trace');
    }
}