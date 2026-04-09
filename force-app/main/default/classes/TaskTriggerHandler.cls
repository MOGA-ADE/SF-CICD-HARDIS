public class TaskTriggerHandler {

    // Méthode pour traiter les Tâches insérées
    public void handleTaskInsert(List<Task> newTasks) {
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();

        // Liste pour récupérer les Leads concernés par les nouvelles tâches
        Set<Id> leadIds = new Set<Id>();
        for (Task t : newTasks) {
            if (t.WhoId != null && t.Type == 'Call' && t.WhoId.getSObjectType() == Lead.SObjectType) {
                leadIds.add(t.WhoId);
            }
        }

        // Récupération des Leads concernés
        Map<Id, Lead> leadMap = new Map<Id, Lead>([SELECT Id, OwnerId, Nombre_appel__c FROM Lead WHERE Id IN :leadIds]);

        // Mise à jour du compteur Nombre_d_Appels pour chaque Lead où le propriétaire correspond
        for (Task t : newTasks) {
            if (t.WhoId != null && t.Type == 'Call' && t.WhoId.getSObjectType() == Lead.SObjectType) {
                Lead lead = leadMap.get(t.WhoId);
                if (lead != null && lead.OwnerId == t.OwnerId) {
                    Lead leadToUpdate = leadsToUpdate.get(t.WhoId);
                    if (leadToUpdate == null) {
                        leadToUpdate = new Lead(Id = t.WhoId);
                        leadToUpdate.Nombre_appel__c = lead.Nombre_appel__c;
                    }
                    leadToUpdate.Nombre_appel__c += 1;
                    leadsToUpdate.put(t.WhoId, leadToUpdate);
                }
            }
        }

        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate.values();
        }
    }
}