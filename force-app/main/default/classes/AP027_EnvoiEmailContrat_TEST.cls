@isTest
private class AP027_EnvoiEmailContrat_TEST {

    // Variable accessible à toute la classe
    static Id contractLecedreId;

    @testSetup
    static void setupTestData() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Account testLECEDRE = new Account(Name = 'LE CEDRE');
        insert testLECEDRE;

        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            Date_echeance__c = Date.today().addMonths(12),
            Envoi_Validation_Email__c = false,
            Commercial__c = testUser.Id,
            Type_offre__c = 'PRIX FIXE',
            Nom_signataire__c = 'Raya', 
            Prenom_signataire__c = 'John',
            Mail_signataire__c = 'johndoe@example.com', 
            FournisseurPicklist__c = 'Engie',
            Source__c = testAccount.Id
        );
        insert testContract;

        Contract contractLecedre = new Contract(
            AccountId = testAccount.Id,
            StartDate = Date.today(),
            Date_echeance__c = Date.today().addMonths(12),
            Envoi_Validation_Email__c = false,
            Commercial__c = testUser.Id,
            Type_offre__c = 'PRIX FIXE',
            Nom_signataire__c = 'Doe', 
            Prenom_signataire__c = 'John',
            Mail_signataire__c = 'johndoe@example.com', 
            FournisseurPicklist__c = 'Engie',
            Source__c = testLECEDRE.Id
        );
        insert contractLecedre;

        contractLecedreId = contractLecedre.Id;
    }

    @isTest
    static void testGetContractsGroupedBySignataire() {
        List<Contract> contracts = [SELECT Id, Mail_signataire__c FROM Contract];
        Map<String, List<Contract>> groupedContracts = AP027_EnvoiEmailContrat.getContractsGroupedBySignataire(contracts);

        System.assertEquals(1, groupedContracts.size());
        System.assert(groupedContracts.containsKey('johndoe@example.com'));
        System.assertEquals(2, groupedContracts.get('johndoe@example.com').size());
    }

    @isTest
    static void testValidationContrat() {
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        List<Id> listContratIds = new List<Id>{ testContract.Id };

        AP027_EnvoiEmailContrat.FlowInputs input = new AP027_EnvoiEmailContrat.FlowInputs();
        input.listContratIds = listContratIds; 

        Test.startTest();
        List<AP027_EnvoiEmailContrat.FlowOutput> outputs = AP027_EnvoiEmailContrat.EnvoiMail(
            new List<AP027_EnvoiEmailContrat.FlowInputs>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assert(outputs[0].message.contains('Email de validation envoyé avec succès'));

        Contract updatedContract = [SELECT Envoi_Validation_Email__c, Date_Envoi_Validation_Email__c FROM Contract WHERE Id = :testContract.Id];
        System.assertEquals(true, updatedContract.Envoi_Validation_Email__c);
        System.assertNotEquals(null, updatedContract.Date_Envoi_Validation_Email__c);
    }

    @isTest
    static void testAccountLECEDRE() {
        List<Contract> contracts = [SELECT Id, Nom_signataire__c FROM Contract];
        List<Id> contractIds = new List<Id>();

        for (Contract c : contracts) {
            contractIds.add(c.Id);
        }

        AP027_EnvoiEmailContrat.FlowInputs input = new AP027_EnvoiEmailContrat.FlowInputs();
        input.listContratIds = contractIds;

        Test.startTest();
        List<AP027_EnvoiEmailContrat.FlowOutput> outputs = AP027_EnvoiEmailContrat.EnvoiMail(
            new List<AP027_EnvoiEmailContrat.FlowInputs>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, outputs.size());
        System.assert(outputs[0].message.contains('Email de validation envoyé avec succès'));

        // Boucle sur tous les contrats retournés
        List<Contract> updatedContracts = [
            SELECT Id, Envoi_Validation_Email__c, Date_Envoi_Validation_Email__c, Nom_signataire__c
            FROM Contract
            WHERE Id IN :contractIds
        ];

        for (Contract c : updatedContracts) {
            if (c.Id == contractLecedreId) {
                System.assertEquals(false, c.Envoi_Validation_Email__c, 'Contrat LECEDRE ne devrait pas être validé');
            } 
        }
    }
}