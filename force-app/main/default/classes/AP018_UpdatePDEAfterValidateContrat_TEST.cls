@isTest
private class AP018_UpdatePDEAfterValidateContrat_TEST {

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
        AP017_GeneratePrixContratPDE.createPrixContractPDE(params);

    }

    @isTest
    static void updatePDE() {

        
        Id contractId = [SELECT Id FROM Contract LIMIT 1].Id;
        List<Prix_contrat_PDE__c> listPCPDE = [SELECT   Id,
                                                        Name,
                                                        RecordTypeId,
                                                        Contract__c,
                                                        Abonnement_Mois__c,
                                                        Budget_TTC__c,
                                                        Budget_gaz_naturel_HTVA_an__c,
                                                        CAR__c,
                                                        CEE_Mwh__c,
                                                        CSPE__c,
                                                        CTA__c,
                                                        Capacit_Base_Mwh__c,
                                                        Capacite_HCE_Mwh__c,
                                                        Capacite_HCH_Mwh__c,
                                                        Capacite_HC_Mwh__c,
                                                        Capacite_HPE_Mwh__c,
                                                        Capacite_HPH_Mwh__c,
                                                        Capacite_HP_Mwh__c,
                                                        Capacite_Pointe_Mwh__c,
                                                        Conso_Base__c,
                                                        Conso_HCE__c,
                                                        Conso_HCH__c,
                                                        Conso_HC__c,
                                                        Conso_HPE__c,
                                                        Conso_HPH__c,
                                                        Conso_HP__c,
                                                        Conso_Pointe__c,
                                                        Date_debut_fourniture__c,
                                                        Date_echeance__c,
                                                        FTA__c,
                                                        Frais_distribution_transport_Mwh__c,
                                                        Numero_compteur__c,
                                                        Point_energie__c,
                                                        Prix_Base__c,
                                                        Prix_HCE__c,
                                                        Prix_HCH__c,
                                                        Prix_HC__c,
                                                        Prix_HPE__c,
                                                        Prix_HPH__c,
                                                        Prix_HP__c,
                                                        Prix_Pointe__c,
                                                        Prix_molecule_Mwh__c,
                                                        Profil__c,
                                                        Segment__c,
                                                        Siret_payeur__c,
                                                        TICGN__c,
                                                        Tarif__c
                                                    FROM Prix_contrat_PDE__c];

        List<AP018_UpdatePDEAfterValidateContrat.FlowInputs> params = new List<AP018_UpdatePDEAfterValidateContrat.FlowInputs>();
        AP018_UpdatePDEAfterValidateContrat.FlowInputs inputs = new AP018_UpdatePDEAfterValidateContrat.FlowInputs();
        
        inputs.ContractId = contractId;
        inputs.listPCPDEFromFlow = listPCPDE;
        params.add(inputs);
        Test.startTest();
        List<AP018_UpdatePDEAfterValidateContrat.FlowOutput> results = AP018_UpdatePDEAfterValidateContrat.updatePDE(params);
        Test.stopTest();
        Assert.isTrue(results[0].success);
    }
}