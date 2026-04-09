@isTest
private class AP017_GeneratePrixContratPDE_TEST {

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
    }

    @isTest
    static void createPrixContractPDE() {

        Id contractId = [SELECT Id FROM Contract LIMIT 1].Id;
        List<QuoteLineItem> listQLI = [ SELECT  PDE__c,
                                                TECH_Siret_Payeur__c,
                                                TECH_RT__c,
                                                TECH_PdeReference__c,
                                                TECH_fournisseur__c,
                                                DebutDeFourniture__c,
                                                Nouvelle_Echeance__c,
                                                Conso_Base__c,
                                                ConsoHC__c,
                                                ConsoHP__c,
                                                Conso_HCE__c,
                                                Conso_HCH__c,
                                                Conso_HPE__c,
                                                Conso_HPH__c,
                                                Conso_Pointe__c,
                                                PrixBase__c,
                                                PrixHC__c,
                                                PrixHP__c,
                                                PrixHceMwh__c,
                                                PrixHchMwh__c,
                                                PrixHpeMwh__c,
                                                PrixHphMwh__c,
                                                PointesMWh__c,
                                                Capa_Base__c,
                                                Capa_HC__c,
                                                Capa_HP__c,
                                                Capa_HCE__c,
                                                Capa_HCH__c,
                                                Capa_HPE__c,
                                                Capa_HPH__c,
                                                Capa_Pointes__c,
                                                AbonnementMois__c,
                                                PrixMolecule__c,
                                                CARGaz__c,
                                                CAR_New__c,
                                                CeeMwh__c,
                                                CSPE__c,
                                                TICGN__c,
                                                CTA__c,
                                                FraisTransportDistributionCapacite__c,
                                                Budget_TTC__c,
                                                BudgetgazNaturelHTVAAn__c,
                                                TECH_Tarif__c,
                                                TECH_Segment__c,
                                                TECH_Profil__c,
                                                TECH_FTA__c 
                                        FROM QuoteLineItem];

        List<AP017_GeneratePrixContratPDE.FlowInputs> params = new List<AP017_GeneratePrixContratPDE.FlowInputs>();
        AP017_GeneratePrixContratPDE.FlowInputs inputs = new AP017_GeneratePrixContratPDE.FlowInputs();
        
        inputs.ContractId = contractId;
        inputs.ListQLIFromFlow = listQLI;
        params.add(inputs);

        Test.startTest();
        List<AP017_GeneratePrixContratPDE.FlowOutput> results = AP017_GeneratePrixContratPDE.createPrixContractPDE(params);
        Test.stopTest();

        Assert.isTrue(results[0].success);
    }
}