@IsTest
private class GazelActionGetContractTest {

    // --------------------------------
    // Mocks
    // --------------------------------
    private class GazelApiMock implements HttpCalloutMock {
        private Boolean isSuccess;
        
        public GazelApiMock(Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (this.isSuccess) {
                res.setStatusCode(200);
                // La classe GazelActionGetContract vérifie si la réponse contient "succes"
                res.setBody('{"status": "succes", "message": "Contrat généré", "pdf_content": "..."}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"status": "error", "message": "Echec génération"}');
            }
            return res;
        }
    }

    // --------------------------------
    // Helpers (Data Creation)
    // --------------------------------
    private static Quote createQuoteWithData() {
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
            Date_de_fin_de_contrat__c = Date.today().addMonths(12),
            API_Offre_ID__c = 'GAZEL-TEST-123'
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
        PDE__c pde = new PDE__c(
            Name = 'PDE Test',
            EntiteJuridique__c = acc.Id,
            ReferencePointEnergie_Refonte__c = '12345678901234'
        );
        insert pde;

        // 6. QuoteLineItem
        // Initialisation des dates pour déclencher les Roll-Up Summary sur le Devis
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

        return q;
    }

    // --------------------------------
    // Tests
    // --------------------------------

    @IsTest
    static void testExecute_Success() {
        Quote q = createQuoteWithData();

        GazelActionGetContract.Input input = new GazelActionGetContract.Input();
        input.quoteId = q.Id;

        // Mock API répondant avec "succes" dans le body
        Test.setMock(HttpCalloutMock.class, new GazelApiMock(true));

        Test.startTest();
        List<GazelActionGetContract.Output> results = GazelActionGetContract.execute(new List<GazelActionGetContract.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, results.size());
    }

    @IsTest
    static void testExecute_ApiFailure() {
        Quote q = createQuoteWithData();

        GazelActionGetContract.Input input = new GazelActionGetContract.Input();
        input.quoteId = q.Id;

        // Mock API répondant sans "succes" (erreur 400)
        Test.setMock(HttpCalloutMock.class, new GazelApiMock(false));

        Test.startTest();
        List<GazelActionGetContract.Output> results = GazelActionGetContract.execute(new List<GazelActionGetContract.Input>{ input });
        Test.stopTest();

        System.assertEquals(1, results.size());
        // La classe GazelActionGetContract met isSuccess à false si la string retournée ne contient pas "succes"
        // ou si GazelAPI gère l'erreur et retourne un message d'erreur simple.
        System.assertEquals(false, results[0].isSuccess, 'Le flag isSuccess devrait être faux en cas d\'erreur API');
    }

    // Note: Le bloc catch(Exception) est difficile à tester sans voir le code de GazelAPI, 
    // mais il serait déclenché si GazelAPI lançait une CalloutException non gérée.
}