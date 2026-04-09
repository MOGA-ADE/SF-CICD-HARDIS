trigger ApiLogEventTrigger on ApiLogEvent__e (after insert) {
    List<Log__c> logsToInsert = new List<Log__c>();
    for (ApiLogEvent__e event : Trigger.new) {
        logsToInsert.add(new Log__c(
            Name = 'API Log ' + Datetime.now().format('yyyy-MM-dd HH:mm:ss'),
            ApexMethod__c = event.ApexMethod__c,
            CurrentUser__c = event.CurrentUser__c,
            Endpoint__c = event.Endpoint__c,
            RequestBody__c = event.RequestBody__c,
            ResponseBody__c = event.ResponseBody__c,
            StatusCode__c = event.StatusCode__c,
            Type__c = event.Type__c,
            Verb__c = event.Verb__c,
            RecordId__c = event.RecordId__c
        ));
    }
    insert logsToInsert;
}