public with sharing class AP026_SendInvoicesToMulesoft {
  @AuraEnabled
  public static toastWrapper sendFiles(
    Id fileId,
    Id recordId,
    Boolean filesFromAccount
  ) {
    System.debug('FileID ' + fileId);
    System.debug('RecordID ' + recordId);

    try {
      Account linkedAccount = [
        SELECT ELLISPHERE__ELLI_IdRegisterestb2__c, OwnerId, Owner.Email
        FROM Account
        WHERE Id = :recordId
        LIMIT 1
      ];
      System.debug('linkedAccount ' + linkedAccount);
      System.debug('Heap size atteint ' + Limits.getHeapSize());
      ContentVersion cv = [
        SELECT VersionData, Title
        FROM ContentVersion
        WHERE ContentDocumentId = :fileId
      ];
      fileWrapper file = new fileWrapper();
      List<fileWrapper> files = new List<fileWrapper>();
      System.debug('Nom du fichier ' + cv.title);
      System.debug('Heap size atteint ' + Limits.getHeapSize());
      file.accountId = recordId;
      System.debug('recordId; ' + recordId);
      file.ownerId = linkedAccount.OwnerId;
      System.debug('linkedAccount.OwnerId; ' + linkedAccount.OwnerId);
      file.accountSiret = linkedAccount.ELLISPHERE__ELLI_IdRegisterestb2__c;
      System.debug(
        'linkedAccount.ELLISPHERE__ELLI_IdRegisterestb2__c ' +
        linkedAccount.ELLISPHERE__ELLI_IdRegisterestb2__c
      );
      file.ownerEmail = linkedAccount.Owner.Email;
      System.debug('linkedAccount.Owner.Email; ' + linkedAccount.Owner.Email);
      file.contentVersionId = cv.Id;
      System.debug('cv.Id; ' + cv.Id);
      file.name = cv.Title;
      System.debug('cv.Title; ' + cv.Title);
      file.content = EncodingUtil.base64Encode(cv.VersionData);
      file.filesFromAccount = filesFromAccount;
      System.debug(
        'EncodingUtil.base64Encode(cv.VersionData); ' +
        EncodingUtil.base64Encode(cv.VersionData)
      );
      files.add(file);
      // Construire l'appel HTTP pour chaque fichier
      HttpRequest req = new HttpRequest();
      req.setEndpoint(
        'https://poc-production-v1-tnle3x.2ky31l-2.deu-c1.eu1.cloudhub.io/api/document'
      );
      req.setMethod('POST');
      req.setHeader('Content-Type', 'application/json');
      req.setHeader(
        'Authorization',
        'Basic ' +
        EncodingUtil.base64Encode(
          Blob.valueOf('poc-production-v1:Abdeslam1952#')
        )
      );
      req.setBody(JSON.serialize(files));

      Http http = new Http();
      HttpResponse res = http.send(req);

      // Traitement de la réponse HTTP
      System.debug('Success Response Status: ' + res.getStatus());
      System.debug('Success Response Body: ' + res.getBody());

      if (res.getStatusCode() >= 400) {
        System.debug('Erreur HTTP détectée: ' + res.getStatusCode());

        toastWrapper errorMessage = new toastWrapper();
        errorMessage.title = 'Erreur lors de l\'envoi';
        errorMessage.message =
          'Le serveur a retourné une erreur (' +
          res.getStatusCode() +
          '): ' +
          res.getBody();
        errorMessage.variant = 'error';
        return errorMessage;
      }

      // Désérialisation du JSON de la réponse
      Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
        res.getBody()
      );

      // Création du toastWrapper avec les valeurs extraites du JSON
      toastWrapper response = new toastWrapper();
      response.title = (String) responseBody.get('title');
      response.message = (String) responseBody.get('message');
      response.variant = (String) responseBody.get('variant');

      return response;
    } catch (CalloutException e) {
      System.debug('Erreur Callout: ' + e.getMessage());

      toastWrapper errorMessage = new toastWrapper();
      errorMessage.title = 'Problème de connexion avec Mulesoft';
      errorMessage.message = 'Problème de connexion avec Mulesoft';
      errorMessage.variant = 'error';
      return errorMessage;
    } catch (Exception e) {
      System.debug('Erreur inconnue: ' + e.getMessage());

      toastWrapper errorMessage = new toastWrapper();
      errorMessage.title = 'Erreur interne';
      errorMessage.message =
        'Une erreur inattendue est survenue: ' + e.getMessage();
      errorMessage.variant = 'error';
      return errorMessage;
    }
  }

  @future(callout=true)
  public static void sendFilesAsync(String fileId, String accountId) {
    AP026_SendInvoicesToMulesoft.sendFiles(fileId, accountId, false);
  }

  /*
   * Wrapper
   */
  private class fileWrapper {
    public Id accountId;
    public Id ownerId;
    public String accountSiret;
    public String ownerEmail;
    public String contentVersionId;
    public String name;
    public String content;
    public Boolean filesFromAccount;
  }

  public class toastWrapper {
    @AuraEnabled
    public String title { get; set; }
    @AuraEnabled
    public String message { get; set; }
    @AuraEnabled
    public String variant { get; set; }
  }
}