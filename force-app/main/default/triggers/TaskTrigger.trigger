trigger TaskTrigger on Task (after insert, after delete) {
    TaskTriggerHandler handler = new TaskTriggerHandler();

    // Gestion des tâches créées
    if (Trigger.isInsert) {
        handler.handleTaskInsert(Trigger.new);
    }
}