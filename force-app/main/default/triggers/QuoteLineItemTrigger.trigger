trigger QuoteLineItemTrigger on QuoteLineItem (after insert, after update){

    if(!System.isBatch() && !Test.isRunningTest()){
        launchBatch(Trigger.newMap.keySet());
    }

    private void launchBatch(Set<Id> ids) {
        QuoteLineItemTriggerHandler QLITH = new QuoteLineItemTriggerHandler();
        QLITH.setQLIIds = ids;
        Database.executeBatch(QLITH, 200);
    }
}