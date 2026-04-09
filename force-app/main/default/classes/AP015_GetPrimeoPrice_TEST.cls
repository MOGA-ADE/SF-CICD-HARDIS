@isTest
private class AP015_GetPrimeoPrice_TEST {

    @testSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
    }

    @isTest
    static void testCheckQLIValidity() {
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];

        Test.startTest();
        QuoteLineItem result = AP015_GetPrimeoPriceController.checkQLIValidity(qli.Id);
        Test.stopTest();

        // Effectuez des assertions pour vérifier le comportement attendu
        System.assertNotEquals(null, result);
    }

    @isTest
    static void testGetPrices() {
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];

        // Créez un mock pour simuler la réponse HTTP de getPrices
        Test.setMock(HttpCalloutMock.class, new MockHttpResponsePrimeoGenerator());

        Test.startTest();
        Map<String, String> result = AP015_GetPrimeoPriceController.getPrices(qli.Id, true, 10); // Adapté aux valeurs de test
        Test.stopTest();

        // Effectuez des assertions pour vérifier le comportement attendu
        System.assertNotEquals(null, result);

    }

    @isTest
    static void testValidOffer() {
        QuoteLineItem qli = [SELECT Id FROM QuoteLineItem LIMIT 1];

        // Créez un mock pour simuler la réponse HTTP de validOffer
        Test.setMock(HttpCalloutMock.class, new MockHttpResponsePrimeoGenerator());

        Test.startTest();
        Map<String, String> offerValidation = AP015_GetPrimeoPriceController.validOffer(qli.Id);
        Test.stopTest();

        // Effectuez des assertions pour vérifier le comportement attendu
        System.assertNotEquals(null, offerValidation);
    }


    
    /*
    * Mock
    */
    public class MockHttpResponsePrimeoGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            // Simulez la réponse JSON en fonction de la requête
            if (req.getEndpoint().contains('getofferaccesstoken')) {
                res.setBody('{"el_temporary_id": "AL9.VGjCqrXB6-652f803d303410.35215422", "el_expiration_id": "2023-10-25 06:50:37"}');
            } else if (req.getEndpoint().contains('getoffer4')) {
                res.setBody('{"error":false,"message":null,"markup":"10","greenEnergy":1,"contractConsumptionMwh":152.32916966779,"offers":{"2":{"id":2,"name":"Prix fixe par postes","description":"Ce prix est fixe sur l\u0027ensemble de la p\u00e9riode du contrat","finalPrices":[{"year":2024,"PTE":140,"HPH":242.46,"HCH":167.97,"HPE":147.91,"HCE":123.38},{"year":2025,"HPH":242.46,"HCH":167.97,"HPE":147.91,"HCE":123.38},{"year":2026,"HPH":242.46,"HCH":167.97,"HPE":147.91,"HCE":123.38}],"cee":[{"year":2024, "value":134}],"capa":[{"year":2024,"obligationCapaKwMwh":0.582599},{"year":2025,"obligationCapaKwMwh":0.240143},{"year":2026,"obligationCapaKwMwh":0.240143}],"greenEnergy":8.57},"4":{"id":4,"name":"Prix Arenh par postes","description":"Attention, en cas de r\u00e9vision de l\u0027ARENH ou de rationnement ce prix \u00e9voluera \u00e0 la hausse pendant le contrat.","finalPrices":[{"year":2024,"HPH":217.4,"HCH":150.6,"HPE":132.62,"HCE":110.63},{"year":2025,"HPH":217.4,"HCH":150.6,"HPE":132.62,"HCE":110.63},{"year":2026,"HPH":217.4,"HCH":150.6,"HPE":132.62,"HCE":110.63}],"capa":[{"year":2024,"obligationCapaKwMwh":0.509601},{"year":2025,"obligationCapaKwMwh":0.170975},{"year":2026,"obligationCapaKwMwh":0.240143}],"arenh":[{"year":2024,"droitArenh":25.6456,"droitArenhOctroye":40,"puissanceArenh":0.000760058838727,"volumeArenh":6676.36},{"year":2025,"droitArenh":21.8136,"droitArenhOctroye":36,"puissanceArenh":0.001572474121266,"volumeArenh":13774.87}],"greenEnergy":8.57},"6":{"id":6,"name":"Prix fixes par postes","description":"Ces prix sont fixes sur l\u0027ensemble de la p\u00e9riode du contrat.","finalPrices":[{"year":2024,"HPH":252.32,"HCH":175.63,"HPE":164.02,"HCE":137.23},{"year":2025,"HPH":229.7,"HCH":158.37,"HPE":148.57,"HCE":119.32},{"year":2026,"HPH":252.34,"HCH":175.34,"HPE":139.23,"HCE":121.14}],"capa":[{"year":2024,"obligationCapaKwMwh":0.582599},{"year":2025,"obligationCapaKwMwh":0.240143},{"year":2026,"obligationCapaKwMwh":0.240143}],"greenEnergy":8.57},"8":{"id":8,"name":"Prix Arenh par postes","description":"Attention, en cas de r\u00e9vision de l\u0027ARENH ou de rationnement ces prix \u00e9volueront \u00e0 la hausse pendant le contrat.","finalPrices":[{"year":2024,"HPH":208.94,"HCH":145.43,"HPE":135.81,"HCE":113.63},{"year":2025,"HPH":188.35,"HCH":129.86,"HPE":121.82,"HCE":97.84},{"year":2026,"HPH":252.34,"HCH":175.34,"HPE":139.23,"HCE":121.14}],"capa":[{"year":2024,"obligationCapaKwMwh":0.509601},{"year":2025,"obligationCapaKwMwh":0.170975},{"year":2026,"obligationCapaKwMwh":0.240143}],"arenh":[{"year":2024,"droitArenh":25.6456,"droitArenhOctroye":40,"puissanceArenh":0.000760058838727,"volumeArenh":6676.36},{"year":2025,"droitArenh":21.8136,"droitArenhOctroye":36,"puissanceArenh":0.001572474121266,"volumeArenh":13774.87}],"greenEnergy":8.57}}}');
            } else if (req.getEndpoint().contains('validoffer')) {
                res.setBody('{"error":false,"message":null,"url":"url.com","oppid":"0063G0000076yp0QAA"}');
            }

            res.setStatusCode(200);
            return res;
        }
    }
}