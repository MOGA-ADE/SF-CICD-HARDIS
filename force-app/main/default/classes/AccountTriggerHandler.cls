public with sharing class AccountTriggerHandler {
    
    public void handleTrigger(List<Account> newRecordsList, System.TriggerOperation triggerEvent) {

        switch on triggerEvent {
            when BEFORE_INSERT {
                // Check recordType : Apporteur Affaires
                List<Account> accApporteurAffairesList = new List<Account>();
                Id rTypeIdAA = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Apporteur Affaires').getRecordTypeId();

                for (Account account : newRecordsList) {
                    if (account.recordTypeId == rTypeIdAA) {
                        accApporteurAffairesList.add(account);
                    }
                }

                if (!accApporteurAffairesList.isEmpty()) {  
                    for (Account acc : accApporteurAffairesList) {
                        acc.Code_partenaire__c = Utils.generateCodePartenaire();
                    }
                }
            }
        }
    }
}