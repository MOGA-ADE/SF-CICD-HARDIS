@isTest
public class AP035_FacturationGazEuroCSVCtrl_TEST {
    @testSetup
    static void setupData() {
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        PDE__c pde = [SELECT Id FROM PDE__c LIMIT 1];

        Contract contract = new Contract(
            Name = 'CTR-GAZ-TEST',
            AccountId = acc.Id,
            Opportunity__c = opp.Id,
            FournisseurPicklist__c = 'Gaz Européen',
            Type_offre__c = 'PRIX FIXE',
            StartDate = Date.today(),
            ContractTerm = 12,
            Date_echeance__c = Date.today().addYears(1),
            Budget_TTC_annee__c = 1000,
            Budget_HTVA_annee__c = 1000,
            Commission_ADE__c = 1000,
            Commission_globale__c = 1000,
            Marge_Mwh_T1__c = 10,
            Marge_Mwh_T2__c = 20,
            Marge_Mwh_T3__c = 30,
            Marge_Mwh_T4__c = 40
        );
        insert contract;

        Appel_facturation__c AF = new Appel_facturation__c(
            Contrat__c = contract.Id,
            Montant__c = 1000,
            paye__c = 'ADE',
            Statut__c = 'En attente de validation ADV',
            Mois_facturation_concerne__c = Date.newInstance(2024, 6, 1)
        );
        insert AF;

        Prix_contrat_PDE__c pdePriceContract = new Prix_contrat_PDE__c(
            Contract__c = contract.Id,
            Numero_compteur__c = '1234567890',
            CAR__c = 0,
            Date_debut_fourniture__c = Date.newInstance(2024, 1, 1),
            Date_echeance__c = Date.newInstance(2024, 12, 31),
            Point_energie__c = pde.Id
        );
        insert pdePriceContract;
    }

    @isTest
    static void testNoData() {
        Test.startTest();
        AP035_FacturationGazEuroCSVController.CsvResult res = AP035_FacturationGazEuroCSVController.generateCSV(
            1,
            2030
        );
        Test.stopTest();

        Assert.isFalse(res.hasData, 'Aucune donnée ne doit être retournée');
        Assert.isTrue(
            res.csv.startsWith('Entité de facturation;'),
            'Le CSV doit commencer par le header'
        );
    }

    @isTest
    static void testCsvForMonth() {
        Test.startTest();
        AP035_FacturationGazEuroCSVController.CsvResult res = AP035_FacturationGazEuroCSVController.generateCSV(
            6,
            2024
        );
        Test.stopTest();

        Assert.isTrue(res.hasData, 'Des données doivent être retournées');
        Assert.isTrue(res.csv.contains('1234567890;'), 'Numéro PDE manquant');
        Assert.isTrue(res.csv.contains('5.00;'), 'Marge T1 incorrecte');
        Assert.isTrue(res.csv.contains('10.00;'), 'Marge T2 incorrecte');
        Assert.isTrue(res.csv.contains('15.00;'), 'Marge T3 incorrecte');
        Assert.isTrue(res.csv.contains('20.00;'), 'Marge T4 incorrecte');
        Assert.isTrue(res.csv.contains('1000.00;'), 'Montant incorrect');
        Assert.isTrue(
            res.csv.contains('CTR-GAZ-TEST'),
            'Nom du contrat absent'
        );
    }

    @isTest
    static void testCsvForYear() {
        Test.startTest();
        AP035_FacturationGazEuroCSVController.CsvResult res = AP035_FacturationGazEuroCSVController.generateCSV(
            0,
            2024
        );
        Test.stopTest();

        Assert.isTrue(res.hasData, 'L\'année doit retourner des données');
        Assert.isTrue(
            res.csv.contains('CTR-GAZ-TEST'),
            'Le CSV annuel doit contenir le contrat Gaz Européen'
        );
    }
}