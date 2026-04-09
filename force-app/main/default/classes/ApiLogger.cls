public class ApiLogger {
    public static void publish(String method, String type, String endpoint, String reqBody, String resBody, Integer status, String verb, String recordId) {
        
        EventBus.publish(new ApiLogEvent__e(
            ApexMethod__c = method,
            CurrentUser__c = UserInfo.getUserId(),
            Endpoint__c = endpoint,
            RequestBody__c = reqBody?.left(131072),
            ResponseBody__c = resBody?.left(131072),
            StatusCode__c = status,
            Type__c = type,
            Verb__c = verb,
            RecordId__c = recordId
        ));
    }
}