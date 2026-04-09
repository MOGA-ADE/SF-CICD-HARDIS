public class DemandeCotationTriggerHandler {

    // 🔹 Création des événements
    public static void createEvents(List<Demande_Cotation__c> demandes) {
        List<Event> eventsToInsert = new List<Event>();

        for (Demande_Cotation__c demande : demandes) {
            if (demande.Date_RDV_Client__c != null) {
                eventsToInsert.add(new Event(
                    Subject = 'RDV Cotation: ' + demande.Name,
                    StartDateTime = demande.Date_RDV_Client__c,
                    EndDateTime = demande.Date_RDV_Client__c.addHours(1),
                    WhatId = demande.Id,
                    OwnerId = demande.OwnerId
                ));
            }
        }

        if (!eventsToInsert.isEmpty()) {
            try {
                insert eventsToInsert;
            } catch (DmlException e) {
                System.debug('Erreur lors de la création des événements : ' + e.getMessage());
            }
        }
    }

    // 🔹 Mise à jour des événements
    public static void updateEvents(List<Demande_Cotation__c> newDemandes, Map<Id, Demande_Cotation__c> oldDemandeMap) {
        Set<Id> demandeIds = new Set<Id>();
        // Set<Id> demandesACloner = new Set<Id>();
        List<Event> eventsToUpdate = new List<Event>();

        for (Demande_Cotation__c demande : newDemandes) {
            demandeIds.add(demande.Id);
            // if (demande.Statut__c == 'Clonée') {
            //     demandesACloner.add(demande.Id);
            // }
        }

        // Récupérer tous les événements liés en une seule requête SOQL
        Map<Id, Event> eventsMap = new Map<Id, Event>();
        for (Event ev : [SELECT Id, WhatId, StartDateTime, EndDateTime FROM Event WHERE WhatId IN :demandeIds]) {
            eventsMap.put(ev.WhatId, ev);
        }

        // Mise à jour des événements existants
        for (Demande_Cotation__c newDemande : newDemandes) {
            Demande_Cotation__c oldDemande = oldDemandeMap.get(newDemande.Id);

            if (newDemande.Date_RDV_Client__c != null && newDemande.Date_RDV_Client__c != oldDemande.Date_RDV_Client__c  || (newDemande.OwnerId != oldDemande.OwnerId) ) {
                Event ev = eventsMap.get(newDemande.Id);
                if (ev != null) {
                    ev.StartDateTime = newDemande.Date_RDV_Client__c;
                    ev.EndDateTime = newDemande.Date_RDV_Client__c.addHours(1);
                    ev.OwnerId = newDemande.OwnerId;
                    eventsToUpdate.add(ev);
                }
            }
        }

        // Mise à jour des événements en masse
        if (!eventsToUpdate.isEmpty()) {
            try {
                update eventsToUpdate;
            } catch (DmlException e) {
                System.debug('Erreur lors de la mise à jour des événements : ' + e.getMessage());
            }
        }

        // Suppression des événements pour les demandes clonées
        // if (!demandesACloner.isEmpty()) {
        //     List<Event> eventsToDelete = [SELECT Id FROM Event WHERE WhatId IN :demandesACloner];
        //     if (!eventsToDelete.isEmpty()) {
        //         try {
        //             delete eventsToDelete;
        //         } catch (DmlException e) {
        //             System.debug('Erreur lors de la suppression des événements (demandes clonées) : ' + e.getMessage());
        //         }
        //     }
        // }
    }

    // 🔹 Suppression des événements liés
    public static void deleteEvents(List<Demande_Cotation__c> oldDemandes) {
        Set<Id> demandeIds = new Set<Id>();

        for (Demande_Cotation__c demande : oldDemandes) {
            demandeIds.add(demande.Id);
        }

        if (!demandeIds.isEmpty()) {
            List<Event> eventsToDelete = [SELECT Id FROM Event WHERE WhatId IN :demandeIds];

            if (!eventsToDelete.isEmpty()) {
                try {
                    delete eventsToDelete;
                } catch (DmlException e) {
                    System.debug('Erreur lors de la suppression des événements : ' + e.getMessage());
                }
            }
        }
    }
}