@isTest
private class VFC009_RenouvellementACDController_TEST {
    
    @isTest
    static void testControllerWithValidParams() {
        // Setup test data via factory
        List<Account> accounts = TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
        Account testAccount = accounts[0];

        // Récupère un contact lié à cet Account
        Contact testContact = [SELECT Id FROM Contact WHERE AccountId = :testAccount.Id LIMIT 1];

        // Marque un PDE comme sélectionné
        PDE__c selectedPDE = [SELECT Id FROM PDE__c WHERE EntiteJuridique__c = :testAccount.Id LIMIT 1];
        selectedPDE.TECH_SelectedPDE__c = true;
        update selectedPDE;

        // Simule les paramètres de la page VF
        Test.setCurrentPageReference(new PageReference('/apex/fakePage'));
        ApexPages.currentPage().getParameters().put('signataireId', testContact.Id);
        ApexPages.currentPage().getParameters().put('accountId', testAccount.Id);

        // Appel du constructeur
        VFC009_RenouvellementACDController ctrl = new VFC009_RenouvellementACDController();

        // Vérifications
        Assert.areNotEqual(null, ctrl.account, 'Le compte doit être initialisé');
        Assert.areEqual(testAccount.Id, ctrl.account.Id, 'L’account chargé doit correspondre à l’ID transmis');
        
        Assert.areNotEqual(null, ctrl.signataire, 'Le signataire doit être initialisé');
        Assert.areEqual(testContact.Id, ctrl.signataire.Id, 'Le signataire chargé doit correspondre à l’ID transmis');

        Assert.areNotEqual(null, ctrl.listPDE, 'La liste des PDE doit être initialisée');
        Assert.IsTrue(ctrl.listPDE.size() >= 1, 'Il doit y avoir au moins un PDE sélectionné');

        Assert.IsTrue(!String.isBlank(ctrl.nomSignataire), 'Le nom du signataire ne doit pas être vide');
    }
}