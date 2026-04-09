public with sharing class AP032_EngieAPICalloutQueueable implements Queueable, Database.AllowsCallouts {
  private String quoteId;
  private String selectedFileId;

  public AP032_EngieAPICalloutQueueable(String quoteId, String fileId) {
    this.quoteId = quoteId;
    this.selectedFileId = fileId;
  }

  public void execute(QueueableContext context) {
    try {
      String fileContentBase64 = '';
      ContentVersion cv = [
        SELECT VersionData, Title, versionNumber, ContentSize
        FROM ContentVersion
        WHERE ContentDocumentId = :this.selectedFileId
        ORDER BY VersionNumber DESC
        LIMIT 1
      ];

      if (cv != null) {
        fileContentBase64 = EncodingUtil.base64Encode(cv.VersionData);
      } else {
        System.debug(
          'Erreur dans le Queueable : Fichier introuvable pour ContentDocumentId ' +
          this.selectedFileId
        );
        return;
      }

      HttpRequest request = new HttpRequest();
      request.setEndpoint(
        'callout:XAPI_Salesforce/api/engie/request-pricing'
      );
      request.setMethod('POST');
      request.setHeader('Content-Type', 'application/json');

      Map<String, Object> requestBody = new Map<String, Object>{
        'quoteId' => this.quoteId,
        'acdDocumentBase64' => fileContentBase64
      };

      request.setBody(JSON.serialize(requestBody));
      request.setTimeout(120000);

      Http http = new Http();
      HttpResponse response = http.send(request);

      if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
        Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String message = (String) jsonResponse.get('message');
        
        Quote quoteToUpdate = new Quote(Id = this.quoteId);
        
        if (message == 'Demande en cours...') {
            // Succès : la demande est bien reçue
            quoteToUpdate.Api_status__c = 'Demande de prix reçue chez le fournisseur';
            quoteToUpdate.Engie_idTransaction__c = (String) jsonResponse.get('idTransaction');
        } else {
            // Refus : pas d'idTransaction
            quoteToUpdate.Api_status__c = 'Demande de prix rejetée par le fournisseur';
            quoteToUpdate.Api_error_message__c = (String) jsonResponse.get('message');
        }
        update quoteToUpdate;
      } else {
        Quote quoteToUpdate = new Quote(Id = this.quoteId);
        quoteToUpdate.Api_status__c = 'Erreur Process Mulesoft';
        quoteToUpdate.Api_error_message__c = 'Erreur lors du callout : ' + response.getStatusCode();
        update quoteToUpdate;
      }
    } catch (Exception e) {
      System.debug(
        'Exception dans EngieApiCalloutQueueable : ' + e.getMessage()
      );
    }
  }
}