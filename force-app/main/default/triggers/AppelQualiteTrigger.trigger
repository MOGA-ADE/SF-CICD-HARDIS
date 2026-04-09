trigger AppelQualiteTrigger on Appel_qualite__c (before insert, before update) {
    new AppelQualiteTriggerHandler().run();
}