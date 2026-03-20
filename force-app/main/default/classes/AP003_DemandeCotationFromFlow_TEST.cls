@isTest
private class AP003_DemandeCotationFromFlow_TEST {

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
    static void demandeCotationFromFlowSelectedPDE(){

        Account account = [SELECT Name, Owner.Id, Owner.Name, Owner.CompanyName FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        List<PDE__c> ListPDE = [SELECT Demande_Cotation__c FROM PDE__c];
        List<AP003_DemandeCotationFromFlow.FlowInputs> params = new List<AP003_DemandeCotationFromFlow.FlowInputs>();

        AP003_DemandeCotationFromFlow.FlowInputs inputs = new AP003_DemandeCotationFromFlow.FlowInputs();
        inputs.Account = account;
        inputs.DateRDVClient = null;
        inputs.DateEcheance = 'MES';
        inputs.SignataireId = contact.Id;
        inputs.ChargeAffaireId = UserInfo.getUserId();
        inputs.InfosComplementaires = null;
        inputs.SelectedPDEs = ListPDE;

        params.add(inputs);

        Test.startTest();
        List<AP003_DemandeCotationFromFlow.FlowOutput> success = AP003_DemandeCotationFromFlow.createDemandeCotation(params);
        Test.stopTest();

        Assert.isTrue(success[0].DMLSuccess);
    }

    @isTest
    static void demandeCotationFromFlow() {

        Account account = [SELECT Name, Owner.Id, Owner.Name, Owner.CompanyName FROM Account WHERE Name = 'TestAccount0' LIMIT 1];
        Contact contact = [SELECT Id FROM Contact WHERE AccountId = :account.Id LIMIT 1];
        List<AP003_DemandeCotationFromFlow.FlowInputs> params = new List<AP003_DemandeCotationFromFlow.FlowInputs>();
        List<AP003_DemandeCotationFromFlow.FlowOutput> success = new List<AP003_DemandeCotationFromFlow.FlowOutput>();
        User commercialUser = [SELECT Id FROM User WHERE Alias = 'mgr2' LIMIT 1];
        AP003_DemandeCotationFromFlow.FlowInputs inputs = new AP003_DemandeCotationFromFlow.FlowInputs();
        inputs.Account = account;
        inputs.DateRDVClient = null;
        inputs.DateEcheance = 'MES';
        inputs.SignataireId = contact.Id;
        inputs.ChargeAffaireId = UserInfo.getUserId();
        inputs.InfosComplementaires = null;
        inputs.SelectedPDEs = new List<PDE__c>();

        params.add(inputs);

        Test.startTest();
        System.runas(commercialUser) {
            success = AP003_DemandeCotationFromFlow.createDemandeCotation(params);
        }
        Test.stopTest();

        Assert.isTrue(success[0].DMLSuccess);
    }
}