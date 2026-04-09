@IsTest
private class TaskTriggerHandler_TEST {

    @TestSetup
    static void setup() {
        // Création de Leads de test
        List<Lead> testLeads = new List<Lead>{
            new Lead(FirstName = 'Lead', LastName = 'Test 1', Company = 'Test Company', Nombre_appel__c = 0),
            new Lead(FirstName = 'Lead', LastName = 'Test 2', Company = 'Test Company', Nombre_appel__c = 1)
        };
        insert testLeads;
    }

    @IsTest
    static void testHandleTaskInsert() {
        // Récupération des Leads
        Lead lead1 = [SELECT Id, OwnerId, Nombre_appel__c FROM Lead WHERE LastName = 'Test 1' LIMIT 1];
        Lead lead2 = [SELECT Id, OwnerId, Nombre_appel__c FROM Lead WHERE LastName = 'Test 2' LIMIT 1];

        // Création de Tâches de type 'Call' pour les Leads
        List<Task> tasks = new List<Task>{
            new Task(WhoId = lead1.Id, OwnerId = lead1.OwnerId, Type = 'Call', Status = 'Completed', Subject = 'Test Call 1'),
            new Task(WhoId = lead2.Id, OwnerId = lead2.OwnerId, Type = 'Call', Status = 'Completed', Subject = 'Test Call 2')
        };
        
        // Insertion des Tâches
        insert tasks;

        // Appel de la méthode handleTaskInsert pour simuler l'insertion de tâches
        Test.startTest();
        //TaskTriggerHandler handler = new TaskTriggerHandler();
        //handler.handleTaskInsert(tasks);
        Test.stopTest();

        // Vérification de la mise à jour des Leads
        Lead updatedLead1 = [SELECT Id, Nombre_appel__c FROM Lead WHERE Id = :lead1.Id];
        Lead updatedLead2 = [SELECT Id, Nombre_appel__c FROM Lead WHERE Id = :lead2.Id];

        System.assertEquals(1, updatedLead1.Nombre_appel__c, 'Le champ Nombre_appel__c de lead1 devrait être 1');
        System.assertEquals(2, updatedLead2.Nombre_appel__c, 'Le champ Nombre_appel__c de lead2 devrait être 2');
    }
}