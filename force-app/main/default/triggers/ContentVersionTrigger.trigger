trigger ContentVersionTrigger on ContentVersion (before insert) {

    if(Trigger.isInsert && Trigger.isBefore){
        ContentVersionTriggerHandler.zipFileForbidden(Trigger.new);
    }
    
}