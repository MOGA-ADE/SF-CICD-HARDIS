@isTest
private class SGERefreshSiteQueueable_TEST {

    private class MockSGECallout implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('<ok>Mocked Enedis Response</ok>');
            return res;
        }
    }

    private class MockSGECalloutError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Erreur simulée Enedis');
            return res;
        }
    }

    @TestSetup
    static void setupData() {
        PDE__c site = new PDE__c(ReferencePointEnergie_Refonte__c ='123456789', Date_signature_ACD__c = System.today());
        insert site;
        insert new Config_Enedis__c(
            CertificateName__c = 'CertificatComodo6Years',
            Endpoint_ConsulterDonneeTech__c='test', 
            Endpoint_ConsulterMesure__c='test',
            timeout__c = 12000
        );

        Id gazRt = [
            SELECT Id FROM RecordType
            WHERE SObjectType = 'PDE__c' AND DeveloperName = 'PDE_Gaz'
            LIMIT 1
        ].Id;
    }

    @isTest
    static void testNominalExecution() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseConsulterMesure());
        WrapPDEInfoEnedis info = new WrapPDEInfoEnedis();
        PDE__c site = [SELECT Id, ReferencePointEnergie_Refonte__c FROM PDE__c LIMIT 1];

        Test.startTest();
        System.enqueueJob(new SGERefreshSiteQueueable(new List<Id>{site.Id}));
        Test.stopTest();

        SGEManager.checkReponseStatus(MockHttpResponseConsulterMesure.response);
        SGEManager.getConsoByPoste(info,MockHttpResponseConsulterMesure.response); 
        SGEManager.updateSite(site.id,info);
    }

    @isTest
    static void testCatchExecution() {
        Test.setMock(HttpCalloutMock.class, new MockSGECalloutError());

        PDE__c pde = new PDE__c(
            Name = 'PDE Erreur',
            ReferencePointEnergie_Refonte__c = 'REF-ERR',
            Date_signature_ACD__c = Date.today().addMonths(-6)
        );
        insert pde;

        Test.startTest();
        System.enqueueJob(new SGERefreshSiteQueueable(new List<Id>{pde.Id}));
        Test.stopTest();

        PDE__c after = [
            SELECT ReferencePointEnergie_Refonte__c, PCE_Refonte__c, RecordType.DeveloperName
            FROM PDE__c
            WHERE Id = :pde.Id
        ];
    }
}