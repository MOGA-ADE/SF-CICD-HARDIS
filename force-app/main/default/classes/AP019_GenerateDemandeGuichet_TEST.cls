@isTest
private class AP019_GenerateDemandeGuichet_TEST {
    
    @testSetup
    static void makeData() {

        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Contact contact = new Contact();
        contact.Title = 'Test Title';
        contact.LastName = 'Lastname';
        contact.Id = contact.Id;
        insert contact;

        // Demande de cotation
        Demande_Cotation__c ddc = new Demande_Cotation__c();
        ddc.Account__c = acc.Id;
        ddc.Signataire__c = contact.Id;
        ddc.Date_RDV_Client__c = Date.today();
        ddc.Charge_affaire__c = System.UserInfo.getUserId();
        ddc.Date_demande_cotation__c = Date.today();
        ddc.Statut__c = 'En attente de traitement';
        insert ddc;
        
        // ContentVersion 
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = 'a picture';
        contentVersion.PathOnClient = 'Pic.jpg';
        contentVersion.VersionData = Blob.valueOf('Test Content');
        contentVersion.IsMajorVersion = true;
        insert contentVersion;
    }

    @isTest
    static void createDemandeGuichet() {
        
        List<AP019_GenerateDemandeGuichet.FlowInputs> params = new List<AP019_GenerateDemandeGuichet.FlowInputs>();
        AP019_GenerateDemandeGuichet.FlowInputs inputs = new AP019_GenerateDemandeGuichet.FlowInputs();
        List<Id> contentDocumentIds = new List<Id>();

        for (ContentDocument cd : [SELECT Id FROM ContentDocument LIMIT 1]) {
            contentDocumentIds.add(cd.Id);
        }
        
        inputs.ContentDocumentIds = contentDocumentIds;
        inputs.DemandeCotation = [SELECT Id FROM Demande_Cotation__c LIMIT 1];
        inputs.DateRetourSouhaitee = Date.today();
        inputs.DureeFourniture = 'durée de fourniture maximale';
        inputs.DateDureeFourniture = Date.today();
        inputs.TypeDemande = 'demande de captation';
        inputs.TypeOffre = 'fixe';
        inputs.TypeEnergie = 'Elec';
        inputs.MargeSouhaitee = '20€';
        inputs.EmailFournisseur = 'test@test.fr';
        inputs.EmailCC1 = 'cc1@test.fr';
        inputs.EmailCC2 = 'cc2@test.fr';
        inputs.EmailCC3 = 'cc3@test.fr';
        inputs.EmailCC4 = 'cc4@test.fr';
        inputs.EmailCC5 = 'cc5@test.fr';
        inputs.SelectedPDEs = [SELECT Siret_payeur__c, ReferencePointEnergie_Refonte__c, TECH_CAR__c, PCE_Refonte__c, Nom_du_compte__c, Name, NumeroVoie__c, voie__c, Code_Postal__c, Ville__c, fournisseur__c, Segment__c, FTA__c, Puissance_souscrite__c, DateEcheance__c FROM PDE__c];

        params.add(inputs);

        Test.startTest();
        List<AP019_GenerateDemandeGuichet.FlowOutput> outputs = AP019_GenerateDemandeGuichet.createDemandeGuichet(params);
        Test.stopTest();

        Assert.isTrue(outputs[0].Success);
    }
}