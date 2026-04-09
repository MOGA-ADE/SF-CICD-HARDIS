@isTest
private class AP028_CheckNbDemandeCotation_TEST {

    @testSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1,1,1,1,1);
        String uniqueString = String.valueOf(Datetime.now()).right(5).replace(':','');

        User user = new User(
            Alias = 'mgr2',
            Email='manager2221154785'+uniqueString+'@example.com',
            EmailEncodingKey='UTF-8',
            LastName='Manager2',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            ProfileId=UserInfo.getProfileId(),
            TimeZoneSidKey='Europe/Paris',
            Username='manager2221154785'+uniqueString+'@example.com',
            CompanyName = 'notADE',
            Phone = '06 41 23 56 87'
        );
        insert user;
    }

    @isTest
    static void testLimitDemandeCotationOnNonADEAccountKO() {
        User nonADEOwner = [SELECT Id FROM User WHERE Alias = 'mgr2' LIMIT 1];
        Account acc = new Account(Name = 'TestAccount_KO', OwnerId = nonADEOwner.Id);
        insert acc;

        DateTime rdvDate = DateTime.newInstance(2099, 1, 1, 10, 0, 0);
        Contact c = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id);
        insert c;

        Limite_Defaut_DDC__c config = Limite_Defaut_DDC__c.getInstance();
        if (config == null) config = new Limite_Defaut_DDC__c(Name='Default');
        config.max_dossier_defaut__c = 0;
        upsert config;

        insert new Demande_Cotation__c(
            Account__c = acc.Id,
            Date_RDV_Client__c = rdvDate,
            Statut__c = 'En attente de traitement',
            Date_demande_cotation__c = Date.today(),
            Duree_offre__c = '12 mois',
            Charge_affaire__c = UserInfo.getUserId(),
            Signataire__c = c.Id
        );

        AP028_CheckNbDemandeCotationFromFlow.FlowInputs input = new AP028_CheckNbDemandeCotationFromFlow.FlowInputs();
        input.DateRDVClient = rdvDate;
        input.UserCompany = 'notADE';

        Test.startTest();
        List<AP028_CheckNbDemandeCotationFromFlow.FlowOutput> result =
            AP028_CheckNbDemandeCotationFromFlow.checkNbDossier(
                new List<AP028_CheckNbDemandeCotationFromFlow.FlowInputs>{input}
            );
        Test.stopTest();

        System.assertEquals(false, result[0].DMLSuccess,
            'Le DML doit échouer car le nombre de DC dépasse la limite');
        System.assertEquals(
            'Notre planning est complet, Veuillez choisir une autre date pour le rendez-vous client',
            result[0].ErrorMessage
        );
    }

    @isTest
    static void testDemandeCotationOnNonADEAccountOK() {
        User nonADEOwner = [SELECT Id FROM User WHERE Alias = 'mgr2' LIMIT 1];
        Account acc = new Account(Name = 'TestAccount_OK', OwnerId = nonADEOwner.Id);
        insert acc;

        DateTime rdvDate = DateTime.newInstance(2099, 1, 1, 10, 0, 0);
        Contact c = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id);
        insert c;

        Limite_Defaut_DDC__c config = Limite_Defaut_DDC__c.getInstance();
        if (config == null) config = new Limite_Defaut_DDC__c(Name='Default');
        config.max_dossier_defaut__c = 10;
        upsert config;

        insert new Demande_Cotation__c(
            Account__c = acc.Id,
            Date_RDV_Client__c = rdvDate,
            Statut__c = 'En attente de traitement',
            Date_demande_cotation__c = Date.today(),
            Duree_offre__c = '12 mois',
            Charge_affaire__c = UserInfo.getUserId(),
            Signataire__c = c.Id
        );

        AP028_CheckNbDemandeCotationFromFlow.FlowInputs input = new AP028_CheckNbDemandeCotationFromFlow.FlowInputs();
        input.DateRDVClient = rdvDate;
        input.UserCompany = 'notADE';

        Test.startTest();
        List<AP028_CheckNbDemandeCotationFromFlow.FlowOutput> result =
            AP028_CheckNbDemandeCotationFromFlow.checkNbDossier(
                new List<AP028_CheckNbDemandeCotationFromFlow.FlowInputs>{input}
            );
        Test.stopTest();

        System.assertEquals(true, result[0].DMLSuccess,
            'Le DML doit réussir car le nombre de DC est en dessous de la limite');
        System.assertEquals(null, result[0].ErrorMessage,
            'Aucun message d’erreur attendu');
    }
}