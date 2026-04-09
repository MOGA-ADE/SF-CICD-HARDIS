@isTest
private class AP031_GetDateIndispo_TEST {

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

        Account acc = new Account(Name = 'TestAccount_KO', OwnerId = user.Id);
        insert acc;

        DateTime rdvDate = DateTime.now();
        Date targetDate = rdvDate.date();
        Contact c = new Contact(FirstName='Test', LastName='Contact', AccountId=acc.Id);
        insert c;

        Integer limite = AP028_CheckNbDemandeCotationFromFlow.getLimiteNbDossier(targetDate);

        System.debug('limite '+limite);

        List<Demande_Cotation__c> demandes = new List<Demande_Cotation__c>();
        for (Integer i = 0; i < limite + 1; i++) {
            demandes.add(new Demande_Cotation__c(
                Account__c = acc.Id,
                Date_RDV_Client__c = rdvDate,
                Statut__c = 'En attente de traitement',
                Date_demande_cotation__c = Date.today(),
                Duree_offre__c = '12 mois',
                Charge_affaire__c = UserInfo.getUserId(),
                Signataire__c = c.Id
            ));
        }
        insert demandes;
    }

    @isTest
    static void testGetDatesIndisponiblesKO() {

        AP031_GetDateIndispo.FlowInputs input = new AP031_GetDateIndispo.FlowInputs();
        input.UserCompany = 'notADE';

        Test.startTest();
        List<AP031_GetDateIndispo.FlowOutput> result = AP031_GetDateIndispo.GetDatesIndisponibles(new List<AP031_GetDateIndispo.FlowInputs>{input});
        Test.stopTest();

        //System.assertEquals(true, result[0].DMLSuccess, 'Le DML doit échouer car le nombre de DC dépasse la limite');
    }

    @isTest
    static void testGetDatesIndisponiblesOK() {

        List<Demande_Cotation__c> ddc = [Select Id, Name From Demande_Cotation__c Limit 3];

        AP031_GetDateIndispo.FlowInputs input = new AP031_GetDateIndispo.FlowInputs();
        input.UserCompany = 'notADE';

        Test.startTest();
        delete ddc;
        List<AP031_GetDateIndispo.FlowOutput> result = AP031_GetDateIndispo.GetDatesIndisponibles(new List<AP031_GetDateIndispo.FlowInputs>{input});
        Test.stopTest();

        System.assertEquals(false, result[0].DMLSuccess, 'Le DML doit réussir car le nombre de DC ne dépasse pas la limite');
    }


}