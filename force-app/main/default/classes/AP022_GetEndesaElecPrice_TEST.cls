@isTest
private class AP022_GetEndesaElecPrice_TEST {
    
    @TestSetup
    static void makeData(){
        Config_Endesa_API_Elec__c config = new Config_Endesa_API_Elec__c(Timeout__c=12000, Username__c='test', Password__c='test',URL_Callback__c='https://test.com');
        insert config;

        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);

        Contact signataire = [SELECT Id FROM Contact LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Demande_Cotation__c dc = new Demande_Cotation__c();
        dc.Account__c = acc.Id;
        dc.Signataire__c = signataire.Id;
        dc.Name = 'Test DC';
        dc.Date_demande_cotation__c = Date.today();
        dc.Statut__c = 'En attente de traitement';
        dc.Charge_affaire__c = UserInfo.getUserId();
        insert dc;

        opp.Demande_Cotation__c = dc.Id;
        update opp;
    }

    @isTest
    static void testGetPricesEntreprise() {
        List<AP022_GetEndesaElecPriceController.FlowInput> inputs = new List<AP022_GetEndesaElecPriceController.FlowInput>();
        
        WrapSiteElecEndesa site = new WrapSiteElecEndesa();
        site.prm = '123456780';
        site.nom = '123456780';
        site.abonnement = 10;
        site.commission = 10;
        site.date_debut = Date.today().format();
        site.date_fin = Date.today().format();
        
        AP022_GetEndesaElecPriceController.FlowInput input = new AP022_GetEndesaElecPriceController.FlowInput();
        input.quote = [SELECT Id FROM Quote LIMIT 1];
        input.sites = new List<WrapSiteElecEndesa>{site};
        input.type_offre = 'Sérénité-1';
        input.date_validite_offre = Date.today().addDays(2);

        inputs.add(input);

        // Créez un mock pour simuler la réponse HTTP de getPrices
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAPIEndesaElec());

        Test.startTest();
        List<AP022_GetEndesaElecPriceController.FlowOutput> result = AP022_GetEndesaElecPriceController.getPrices(inputs);
        Test.stopTest();

        // Effectuez des assertions pour vérifier le comportement attendu
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetPricesCopro() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        RecordType rtSyndic = [SELECT Id FROM RecordType WHERE Name = 'Syndic' LIMIT 1];
        RecordType rtCopro = [SELECT Id FROM RecordType WHERE Name = 'Copropriété' LIMIT 1];
        
        Account syndic = New Account(Name = 'TestSyndic', RecordTypeId = rtSyndic.Id);
        insert syndic;

        acc.RecordTypeId = rtCopro.Id;
        acc.Syndic__c = syndic.Id;
        update acc;

        List<AP022_GetEndesaElecPriceController.FlowInput> inputs = new List<AP022_GetEndesaElecPriceController.FlowInput>();
        
        WrapSiteElecEndesa site = new WrapSiteElecEndesa();
        site.prm = '123456780';
        site.nom = '123456780';
        site.abonnement = 10;
        site.commission = 10;
        site.date_debut = Date.today().format();
        site.date_fin = Date.today().format();
        
        AP022_GetEndesaElecPriceController.FlowInput input = new AP022_GetEndesaElecPriceController.FlowInput();
        input.quote = [SELECT Id FROM Quote LIMIT 1];
        input.sites = new List<WrapSiteElecEndesa>{site};
        input.type_offre = 'Sérénité-1';
        input.date_validite_offre = Date.today().addDays(2);

        inputs.add(input);

        // Créez un mock pour simuler la réponse HTTP de getPrices
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAPIEndesaElec());

        Test.startTest();
        List<AP022_GetEndesaElecPriceController.FlowOutput> result = AP022_GetEndesaElecPriceController.getPrices(inputs);
        Test.stopTest();

        // Effectuez des assertions pour vérifier le comportement attendu
        System.assertNotEquals(null, result);
    }
}