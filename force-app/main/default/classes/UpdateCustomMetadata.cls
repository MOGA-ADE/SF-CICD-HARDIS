public without sharing class UpdateCustomMetadata  {

    public static Boolean updateMetadata(String refresh, String access) {
        try {

            Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;

            // Recup des identifiants
            Endesa_API__mdt config = [
                SELECT DeveloperName
                FROM Endesa_API__mdt 
                WHERE Sandboxe__c = :isSandbox 
                LIMIT 1
            ];

            if(config != null)  {
                String fullName = 'Endesa_API.' + config.DeveloperName;
                asyncUpdateMetadata(fullName, refresh, access);
                return true;
            }

        } catch (Exception e) {
            System.debug(e.getMessage());
            return false;
        }

        return false;
    }


    @future
    public static void asyncUpdateMetadata(String fullName, String refresh, String access) {

        List<Metadata.Metadata> metadataretrieve = Metadata.Operations.retrieve(
            Metadata.MetadataType.CustomMetadata,
            new List<String>{ fullName }
        );

        Metadata.CustomMetadata customMetadataRecord = (Metadata.CustomMetadata) metadataretrieve.get(0);

        Metadata.CustomMetadataValue refreshvalue = new Metadata.CustomMetadataValue();
        refreshvalue.field = 'Refresh_token__c';
        refreshvalue.value = refresh;
        customMetadataRecord.values.add(refreshvalue);

        Metadata.CustomMetadataValue accessvalue = new Metadata.CustomMetadataValue();
        accessvalue.field = 'Access_token__c';
        accessvalue.value = access;
        customMetadataRecord.values.add(accessvalue);

        Metadata.DeployContainer myContainer = new Metadata.DeployContainer();
        myContainer.addMetadata(customMetadataRecord);

        CustomMetadataCallback callback = new CustomMetadataCallback();

        Id jobId = Metadata.Operations.enqueueDeployment(myContainer, callback);

        System.debug('JobId: ' + jobId);
    }


    public class CustomMetadataCallback implements Metadata.DeployCallback {
        public void handleResult(Metadata.DeployResult result,
                                Metadata.DeployCallbackContext context) {
                                
            if (result.status == Metadata.DeployStatus.Succeeded) {
                System.debug('success: '+ result);
            } else {
                System.debug('fail: '+ result);
            }
            
        }
    }

}