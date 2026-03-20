@isTest
private class SGEManager_Test {
    
    @TestSetup
    static void createPDE(){
        PDE__c site = new PDE__c(ReferencePointEnergie_Refonte__c ='123456789', Date_signature_ACD__c = System.today());
        insert site;
        Config_Enedis__c config = new Config_Enedis__c(CertificateName__c='CertificatComodo6Years', Endpoint_ConsulterDonneeTech__c='test', Endpoint_ConsulterMesure__c='test', timeout__c= 12000);
        insert config;
        //Mapping_FTA__mdt fta = new Mapping_FTA__mdt(Masterlabel = 'BTINFCUST',label = 'BTINFCUST', SF_FTA__c= 'BT <= 36Kva - CU 4 postes');
        //insert fta;
    }

    @isTest
    static void callConsulterMesureTest() {
            Test.setMock(HttpCalloutMock.class, new MockHttpResponseConsulterMesure());
            WrapPDEInfoEnedis info = new WrapPDEInfoEnedis();
            PDE__c site = [SELECT id, ReferencePointEnergie_Refonte__c From PDE__c Limit 1];
            Test.startTest();
            SGEManager.callConsulterMesure(site.ReferencePointEnergie_Refonte__c, info);
            Test.stopTest();
            SGEManager.checkReponseStatus(MockHttpResponseConsulterMesure.response);
            SGEManager.getConsoByPoste(info,MockHttpResponseConsulterMesure.response); 
            SGEManager.updateSite(site.id,info);
    }

    @isTest
    static void callConsulterPointTest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseConsulterPoint());
        WrapPDEInfoEnedis info = new WrapPDEInfoEnedis();
        PDE__c site = [SELECT id, ReferencePointEnergie_Refonte__c From PDE__c Limit 1];
        Test.startTest();
        SGEManager.consulterPoint(site.ReferencePointEnergie_Refonte__c, info);
        Test.stopTest();
        SGEManager.checkReponseStatus(MockHttpResponseConsulterPoint.response);
        SGEManager.readTechnicalInfo(info,MockHttpResponseConsulterPoint.response); 
        SGEManager.updateSite(site.id,info);
        
    }
    
    @isTest
    static void batchPsMaxTest() {
    	Test.setMock(HttpCalloutMock.class, new MockHttpResponseConsulterMesureDetaillee());
        BatchCalculatePsMax b = new BatchCalculatePsMax();
        PDE__c site = [SELECT Id, ReferencePointEnergie_Refonte__c from PDE__c where ReferencePointEnergie_Refonte__c ='123456789'];
        Test.startTest();
        Database.executeBatch (b,1);
        Test.stopTest();
        SGEManager.calculatePsMaxForAYear(site);
        site = [SELECT Id, PSMaxInductive__c from PDE__c where ReferencePointEnergie_Refonte__c ='123456789'];
        //system.assertEquals (35,site.PSMaxInductive__c);
    }
}