@isTest
public class AppelQualiteTriggerHanlder_TEST {

    @testSetup
    static void setupData() {

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

    // Test pour la méthode beforeInsert
    @isTest
    static void testBeforeInsert() {
        // Création d'un enregistrement Appel_qualite__c avec des valeurs dans elements_conformes__c

        Contract contrat = [SELECT Id FROM CONTRACT LIMIT 1];
        Appel_qualite__c appelQualite = new Appel_qualite__c();
        
        appelQualite.elements_conformes__c = 'Nom et Prénom signataire;Mail signataire;Date de fin';
        appelQualite.Type_vente__c = 'Vente en direct';
        appelQualite.Contract__c = contrat.Id;

        // Insertion de l'enregistrement pour déclencher le trigger
        insert appelQualite;

        // Récupération de l'enregistrement inséré pour vérifier le calcul du score
        Appel_qualite__c insertedAppel = [SELECT TECH_Score_conformite__c FROM Appel_qualite__c WHERE Id = :appelQualite.Id];
        
        // Vérification du score calculé
        System.assertEquals(2, insertedAppel.TECH_Score_conformite__c, 'Le score de conformité doit être 2.');
    }

    // Test pour la méthode beforeUpdate
    @isTest
    static void testBeforeUpdate() {

        Contract contrat = [SELECT Id FROM CONTRACT LIMIT 1];

        // Création et insertion d'un enregistrement Appel_qualite__c initial
        Appel_qualite__c appelQualite = new Appel_qualite__c();
        appelQualite.elements_conformes__c = 'Nom et Prénom signataire;Mail signataire;Date de fin';
        appelQualite.Type_vente__c = 'Vente en direct';
        appelQualite.Contract__c = contrat.Id;
        insert appelQualite;

        // Modification de elements_conformes__c pour déclencher le calcul du score
        appelQualite.elements_conformes__c = 'Nom et Prénom signataire;Mail signataire';
        update appelQualite;

        // Récupération de l'enregistrement mis à jour pour vérifier le nouveau score
        Appel_qualite__c updatedAppel = [SELECT TECH_Score_conformite__c FROM Appel_qualite__c WHERE Id = :appelQualite.Id];
        
        // Vérification que le score a été recalculé
        System.assertEquals(1, updatedAppel.TECH_Score_conformite__c, 'Le score de conformité mis à jour doit être 1.');
    }

    // Test pour vérifier que le score est 0 si elements_conformes__c est null
    @isTest
    static void testNullElementsConformes() {

        Contract contrat = [SELECT Id FROM CONTRACT LIMIT 1];

        // Création d'un enregistrement Appel_qualite__c sans valeur pour elements_conformes__c
        Appel_qualite__c appelQualite = new Appel_qualite__c();
        appelQualite.Type_vente__c = 'Vente en direct';
        appelQualite.Contract__c = contrat.Id;
        insert appelQualite;

        // Récupération de l'enregistrement pour vérifier que le score est bien 0
        Appel_qualite__c insertedAppel = [SELECT TECH_Score_conformite__c FROM Appel_qualite__c WHERE Id = :appelQualite.Id];
        
        // Vérification que le score est bien 0
        System.assertEquals(0, insertedAppel.TECH_Score_conformite__c, 'Le score de conformité doit être 0 lorsque elements_conformes__c est null.');
    }
}