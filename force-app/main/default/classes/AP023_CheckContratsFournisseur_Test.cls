@isTest
private class AP023_CheckContratsFournisseur_Test {

    @testSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Contract contract = new Contract();
        contract.Name = 'Test';
        contract.AccountId = acc.Id;
        contract.Opportunity__c = opp.Id;
        contract.FournisseurPicklist__c = 'Engie';
        contract.Type_offre__c = 'PRIX FIXE';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Date_echeance__c = Date.today();
        contract.Budget_TTC_annee__c = 1000;
        contract.Budget_HTVA_annee__c = 1000;
        contract.Commission_ADE__c = 1000;
        contract.Commission_globale__c = 1000;
        insert contract;

        Appel_facturation__c AF = new Appel_facturation__c();
        AF.Contrat__c = contract.Id;
        AF.Montant__c = 1000;
        AF.paye__c = 'ADE';
        AF.Statut__c = 'En attente de validation ADV';
        AF.Mois_facturation_concerne__c = Date.newInstance(2024,6,1);
        insert AF;
    }

    @isTest
    static void getAppelFacturation() {
        Test.startTest();
        List<Appel_facturation__c> results = AP023_CheckContratsFournisseurController.getAppelFacturation('Engie','06','2024');
        Test.stopTest();
        Assert.isTrue(results.size() == 1);
    }

    @isTest
    static void updateAppelFacturation() {
        Test.startTest();
        Date moisFacturation = Date.newInstance(2024,6,1);
        Boolean result = AP023_CheckContratsFournisseurController.updateAppelFacturation('Engie','06','2024');
        Appel_facturation__c AF = [SELECT Id,Statut__c FROM Appel_facturation__c WHERE Mois_facturation_concerne__c = :moisFacturation][0];
        Test.stopTest();
        Assert.isTrue(result == true);
        Assert.isTrue(AF.Statut__c == 'OK pour facturation');
    }
}