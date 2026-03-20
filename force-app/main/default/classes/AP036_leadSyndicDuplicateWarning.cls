public with sharing class AP036_leadSyndicDuplicateWarning {

    @AuraEnabled(cacheable=true)
    public static Boolean hasSyndicDuplicate(Id leadId) {

        // Récupérer le Lead
        Lead ld = [
            SELECT Id, PostalCode, SIRET__c
            FROM Lead
            WHERE Id = :leadId
            LIMIT 1
        ];

        // Sécurité : champs obligatoires
        if (String.isBlank(ld.SIRET__c) || String.isBlank(ld.PostalCode)) {
            return false;
        }

        // Récupération des départements depuis Custom Settings
        Map<String, Departement_syndic__c> mcs = Departement_syndic__c.getAll();

        Boolean isValidPostal = false;

        for (Departement_syndic__c dep : mcs.values()) {
            
            if (ld.PostalCode.startsWith(dep.Departement__c)) {
                isValidPostal = true;
                break;
            }
        }

        // Si le code postal n’est pas concerné → pas de vérification
        if (!isValidPostal) {
            return false;
        }

        // Recherche d’un Account Syndic avec le même SIRET
        List<Account> matchingSyndicAccounts = [
            SELECT Id
            FROM Account
            WHERE SIRET__c = :ld.SIRET__c
            AND RecordType.Name = 'Syndic'
            LIMIT 1
        ];

        // TRUE = doublon trouvé
        return !matchingSyndicAccounts.isEmpty();
    }
}