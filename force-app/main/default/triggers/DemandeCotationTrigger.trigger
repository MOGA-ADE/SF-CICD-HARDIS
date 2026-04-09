trigger DemandeCotationTrigger on Demande_Cotation__c (after insert, after update, after delete) {
    if (Trigger.isInsert) {
        DemandeCotationTriggerHandler.createEvents(Trigger.new);
    }
    if (Trigger.isUpdate) {
        DemandeCotationTriggerHandler.updateEvents(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isDelete) {
        DemandeCotationTriggerHandler.deleteEvents(Trigger.old);
    }
}