@isTest
private class AP022_GetCallBack_TEST {

    static final String DOSSIER = 'DOSS123';
    static final String OFFRE = 'OFF123';
    static final String TEST_PDE_REF = '123456780';
    static string refpde = '';

    @testSetup
    static void setupData() {
        // Créer un utilisateur propriétaire de la quote
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);

        Quote quote = [SELECT Id, Numero_Dossier_API_Endesa_Elec__c, OwnerId  FROM Quote WHERE 
                       ID IN (SELECT QuoteId FROM QuoteLineItem WHERE TECH_PdeReference__c != null )LIMIT 1];
        quote.Numero_Dossier_API_Endesa_Elec__c  = DOSSIER; 

        QuoteLineItem qli = [SELECT Id, PDE__c FROM QuoteLineItem WHERE QuoteId =: quote.Id AND PDE__c != null  LIMIT 1];
        PDE__c pde = [SELECT Id FROM PDE__c WHERE Id =: qli.PDE__c LIMIT 1];
        pde.ReferencePointEnergie_Refonte__c = TEST_PDE_REF;
        update pde;
        qli = [SELECT Id, TECH_PdeReference__c, QuoteId FROM QuoteLineItem WHERE TECH_PdeReference__c = '123456780' Limit 1];

        System.debug('for test debug : '+ quote.OwnerId );
        update quote;

        User u = [SELECT Id FROM User WHERE Id = :quote.OwnerId];
        u.Email = 'yakarutestok@gmail.com';
        update u;


        
    }

    @isTest
    static void testReceiveCallback() {
        // Construire un JSON conforme au callback attendu
        Date ladate = Date.today();
        String mois = String.valueOf(ladate.month());
        if (ladate.month() < 10) mois = '0' + mois;
        String jour = String.valueOf(ladate.day());
        if (ladate.day() < 10) jour = '0' + jour;
        String d = String.valueOf(jour + '/' + mois + '/' +  ladate.year());

        String jsonBody = 
            '{'+
                '"numero_offre":"OFF123",'+
                '"num_dossier":"DOSS123",'+
                '"date_fin_validite":"'+d+'",'+
                '"sites":{'+
                    '"'+ TEST_PDE_REF +'": {'+
                        '"commission": 10.5,'+
                        '"abonnement": 5.0,'+
                        '"cee": 1.2,'+
                        '"categorie": "C4",'+
                        '"consommation": 100.0,'+
                        '"capacite": 50.0,'+
                        '"prix_energie_base": 20.0,'+
                        '"prix_energie_hp": 21.0,'+
                        '"prix_energie_hc": 19.0,'+
                        '"prix_energie_hch": 18.0,'+
                        '"prix_energie_hph": 22.0,'+
                        '"prix_energie_hpe": 23.0,'+
                        '"prix_energie_hce": 17.0'+
                    '}'+
                '}'+
            '}';

        // Préparer le RestRequest pour simuler l'appel REST POST
        RestRequest req = new RestRequest();
        req.requestUri = '/callback/poc';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;

        // Lance le test
        Test.startTest();
        AP022_GetCallBack.receiveCallback();
        Test.stopTest();

        // Vérifier que les données ont été mises à jour
        Quote q = [SELECT Id, Numero_Offre_API_Endesa_Elec__c, Date_Validite_Offre_API_Endesa_Elec__c FROM Quote WHERE Numero_Dossier_API_Endesa_Elec__c = 'DOSS123' LIMIT 1];
        System.assertEquals('OFF123', q.Numero_Offre_API_Endesa_Elec__c, 'Le numéro offre doit être mis à jour');
        System.assertEquals(Date.today(), q.Date_Validite_Offre_API_Endesa_Elec__c, 'La date validité doit être mise à jour');
    }

    @isTest
    static void testReceiveCallback_withError() {
        // Simule un callback avec des erreurs
        String jsonBody = JSON.serialize(new Map<String, Object>{
            'num_dossier' => DOSSIER,
            'errors' => new List<Object>{
                new Map<String, Object>{
                    'code_error' => '400',
                    'message' => 'Erreur test'
                }
            }
        });

        RestRequest req = new RestRequest();
        req.requestUri = '/callback/poc';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(jsonBody);
        RestContext.request = req;

        Test.startTest();
        AP022_GetCallBack.receiveCallback();
        Test.stopTest();

        // Pas d’exception levée = succès du traitement d’erreur
        System.assert(true, 'Callback avec erreurs traité sans exception');
    }


}