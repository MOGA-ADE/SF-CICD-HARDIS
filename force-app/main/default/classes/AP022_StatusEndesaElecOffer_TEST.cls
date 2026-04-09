@isTest
private class AP022_StatusEndesaElecOffer_TEST {
    
    @TestSetup
    static void makeData(){
        Config_Endesa_API_Elec__c config = new Config_Endesa_API_Elec__c(Timeout__c=12000, Username__c='test', Password__c='test', URL_callback__c='https://test.com');
        insert config;

        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);

        Quote quote = [SELECT Id, Numero_Offre_API_Endesa_Elec__c FROM Quote LIMIT 1];
        quote.Numero_Offre_API_Endesa_Elec__c = '202404273814'; 
        update quote;
    }

    @isTest
    static void testChangeStatus() {
        List<AP022_StatusEndesaElecOfferController.FlowInput> inputs = new List<AP022_StatusEndesaElecOfferController.FlowInput>();
        AP022_StatusEndesaElecOfferController.FlowInput input = new AP022_StatusEndesaElecOfferController.FlowInput();

        input.quote = [SELECT Id, Numero_Offre_API_Endesa_Elec__c FROM Quote LIMIT 1];
        input.commentaire = 'Commentaire Test';
        input.status = 'En attente de validation';

        inputs.add(input);

        // Créez un mock pour simuler la réponse HTTP de validOffer
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAPIEndesaElec());

        Test.startTest();
        List<AP022_StatusEndesaElecOfferController.FlowOutput> result = AP022_StatusEndesaElecOfferController.changeStatus(inputs);
        Test.stopTest();

        System.debug('result ' + result);

        // Effectuez des assertions pour vérifier le comportement attendu
        System.assertNotEquals(null, result);
    
    }
}