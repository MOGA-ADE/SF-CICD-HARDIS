@isTest
private class AP022_ValidEndesaEllecOffer_TEST {
    
    @TestSetup
    static void makeData(){
        Config_Endesa_API_Elec__c config = new Config_Endesa_API_Elec__c(Timeout__c=12000, Username__c='test', Password__c='test', URL_Callback__c='https://test.com');
        insert config;

        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);

        Quote quote = [SELECT Id, Numero_Offre_API_Endesa_Elec__c FROM Quote LIMIT 1];
        quote.Numero_Offre_API_Endesa_Elec__c = '202404273814'; 
        update quote;
    }

    @isTest
    static void testValidOffer() {

        // Créez un mock pour simuler la réponse HTTP de validOffer
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseAPIEndesaElec());

        Test.startTest();
        List<AP022_ValidEndesaElecOfferController.FlowOutput> result = AP022_ValidEndesaElecOfferController.validOffer(new List<String>{'202404273821'});
        Test.stopTest();

        System.debug('result ' + result);

        // Effectuez des assertions pour vérifier le comportement attendu
        System.assertNotEquals(null, result);
    
    }
}