trigger AccountTrigger on Account (before insert) {

    AccountTriggerHandler accTriggerHandler = new AccountTriggerHandler();
    accTriggerHandler.handleTrigger(Trigger.new, Trigger.operationType);
}