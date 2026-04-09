@isTest
private class SGEManager_Test {
    
    @TestSetup
    static void createPDE(){
        PDE__c site = new PDE__c(ReferencePointEnergie_Refonte__c ='123456789', Date_signature_ACD__c = System.today());
        insert site;
        Config_Enedis__c config = new Config_Enedis__c(CertificateName__c='CertificatComodo6Years', Endpoint_ConsulterDonneeTech__c='test', Endpoint_ConsulterMesure__c='test', Endpoint_M023_Fines__c ='test', timeout__c= 12000);
        insert config;
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
    static void coverageRefreshMethodsTest() {
        Test.setMock(HttpCalloutMock.class, new SGEMultiMock());
        PDE__c site = [SELECT Id, Name, ReferencePointEnergie_Refonte__c FROM PDE__c LIMIT 1];
        update site;

        Test.startTest();
        SGEManager.refreshSiteInFlow(new List<PDE__c>{site});
        try {SGEManager.refreshSiteInformation(site.Id);} catch(Exception e) {}
        SGEManager.refreshSiteInformationFuture(site.Id);
        Test.stopTest();
    }

    @isTest
    static void coverageExceptionPathTest() {
        Test.startTest();
        try { SGEManager.refreshSiteInformation(null); } catch(Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void commandeCourbeDeCharge_Success_Test() {
        // Configuration du Mock en mode succès
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseM023MesuresFines(true));
        
        PDE__c site = [SELECT Id FROM PDE__c LIMIT 1];
        
        Test.startTest();
        String result = SGEManager.commandeCourbeDeCharge(site.Id);
        Test.stopTest();
        
        // Vérifications
        Assert.isTrue(result.contains('M084SNB0'), 'Le message de retour devrait contenir l\'affaireId');
        
        PDE__c updatedSite = [SELECT Numero_Affaire_SGE__c FROM PDE__c WHERE Id = :site.Id];
        Assert.areEqual('M084SNB0', updatedSite.Numero_Affaire_SGE__c, 'L\'affaireId doit être mis à jour sur le PDE');
    }

    @isTest
    static void commandeCourbeDeCharge_Error_Test() {
        // Configuration du Mock en mode erreur (500)
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseM023MesuresFines(false));
        
        PDE__c site = [SELECT Id FROM PDE__c LIMIT 1];
        
        Test.startTest();
        String result = SGEManager.commandeCourbeDeCharge(site.Id);
        Test.stopTest();
        
        // Vérifications sur le parsing de l'erreur
        Assert.isTrue(result.contains('Erreur'), 'Le message devrait indiquer une erreur');
    }
}