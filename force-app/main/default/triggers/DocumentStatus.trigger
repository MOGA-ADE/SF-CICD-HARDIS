trigger DocumentStatus on ContentDocumentLink (before insert) {
    
    if(Trigger.isBefore) {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'Utilisateur Partenaire Communauté' LIMIT 1].Id;
        Map<Id, Account> syndic = new map<Id, Account>([SELECT Id FROM Account WHERE RecordType.Name = 'Syndic']);

        if (System.UserInfo.getProfileId() == profileId) { return; }
        // Default Visibility for uploaded files from Internal Users is 'InternalUsers'
        // If linkedEntityId is not a Syndic we need to share to 'AllUsers'
        for(ContentDocumentLink cdl : Trigger.new) {
            if (!syndic.containsKey(cdl.LinkedEntityId)) {
                cdl.Visibility = 'AllUsers';
            }
        }
    }
}