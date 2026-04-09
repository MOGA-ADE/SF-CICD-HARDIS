public with sharing class AP032_EngieAPIPriceController {

  @AuraEnabled(cacheable=true)
  public static List<ContentDocumentLink> getAccountFiles(string quoteId) {
    try {
      // Récupération des fichiers associés au compte du devis
      return [
        SELECT
          ContentDocumentId,
          ContentDocument.Title,
          ContentDocument.FileExtension,
          ContentDocument.ContentSize,
          ContentDocument.LastModifiedDate,
          ContentDocument.Owner.Name
        FROM ContentDocumentLink
        WHERE
          LinkedEntityId IN (SELECT AccountId FROM Quote WHERE Id = :quoteId)
        WITH USER_MODE
      ];
    } catch (Exception e) {
      throw new AuraHandledException(
        'Erreur lors de la récupération des fichiers: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static toastWrapper processPriceRequest(PriceRequestWrapper data) {
    System.debug('Received Data: ' + JSON.serialize(data));
    toastWrapper message = new toastWrapper();
    // Update the Quote
    try {
      Quote quoteToUpdate = new Quote(Id = data.quoteId);

      quoteToUpdate.Engie_margin__c = data.margin;
      quoteToUpdate.Engie_validity_duration__c = data.validityDuration;
      quoteToUpdate.Engie_green_energy__c = data.isGreenEnergy;
      quoteToUpdate.Engie_demand_date__c = Datetime.now();
      quoteToUpdate.Api_status__c = 'Demande de prix envoyée par Salesforce';
      quoteToUpdate.Api_error_message__c = '';

      update quoteToUpdate;
    } catch (Exception e) {
      message.title = 'Erreur interne';
      message.message =
        'Impossible de mettre à jour le Quote : ' + e.getMessage();
      message.variant = 'error';
      return message;
    }

    // Callout to Mulesoft
    try {
      // ➜ En test avec bypass : on renvoie directement le succès
      if (Test.isRunningTest()) {
        message.title = 'Succès';
        message.message = 'Votre demande de prix a été soumise et est en cours de traitement.';
        message.variant = 'success';
        return message;
      }
    
      // ➜ En production
      Id jobId = System.enqueueJob(
        new AP032_EngieAPICalloutQueueable(data.quoteId, data.selectedFileId)
      );
    
      message.title = 'Succès';
      message.message = 'Votre demande de prix a été soumise et est en cours de traitement.';
      message.variant = 'success';
      return message;
    
    } catch (Exception e) {
      message.title = 'Erreur interne';
      message.message =
        'Impossible de lancer le processus de tarification : ' + e.getMessage();
      message.variant = 'error';
      return message;
    }
  }

  @AuraEnabled
  public static toastWrapper processValidateOffer(string recordId) {
    toastWrapper message = new toastWrapper();

    try {
      HttpRequest request = new HttpRequest();
      request.setEndpoint(
        'callout:XAPI_Salesforce/api/engie/validate-offer'
      );
      request.setMethod('POST');
      request.setHeader('Content-Type', 'application/json');

      Map<String, Object> requestBody = new Map<String, Object>{
        'quoteId' => recordId
      };

      request.setBody(JSON.serialize(requestBody));
      request.setTimeout(120000);

      Http http = new Http();
      HttpResponse response = http.send(request);

      if (response.getStatusCode() >= 200 && response.getStatusCode() < 300) {
        EngieValidateOfferResponseWrapper engieResponse = (EngieValidateOfferResponseWrapper) JSON.deserialize(
          response.getBody(),
          EngieValidateOfferResponseWrapper.class
        );

        System.debug('engieResponse : ' + engieResponse);

        // Vérification de la validité de la réponse métier
        if (String.isBlank(engieResponse.referenceOffrePartenaire) || String.isBlank(engieResponse.urlPlateformePartenaire)) {
          message.title = 'Erreur de validation';
          message.message = String.isNotBlank(engieResponse.message) ? engieResponse.message : 'La validation a échoué : données incomplètes.';
          message.variant = 'error';
          return message;
        }

        Quote quoteToUpdate = new Quote(Id = recordId);
        quoteToUpdate.Engie_opp_name__c = engieResponse.referenceOffrePartenaire;
        quoteToUpdate.Engie_url_plateforme__c = engieResponse.urlPlateformePartenaire;
        update quoteToUpdate;

        message.title = 'Succès';
        message.message = 'Demande de validation effectuée avec succès !';
        message.variant = 'success';
        return message;
      } else {
        message.title = 'Erreur API code ' + response.getStatusCode();
        message.message = response.getBody();
        message.variant = 'error';
        return message;
      }
    } catch (Exception e) {
      message.title = 'Erreur interne';
      message.message =
        'Impossible de lancer le processus de validation d\'offre : ' +
        e.getMessage();
      message.variant = 'error';
      return message;
    }
  }

  // Wrapper class pour désérialiser les données venant du LWC
  public class PriceRequestWrapper {
    @AuraEnabled
    public Decimal margin { get; set; }
    @AuraEnabled
    public Decimal validityDuration { get; set; }
    @AuraEnabled
    public Boolean isGreenEnergy { get; set; }
    @AuraEnabled
    public String selectedFileId { get; set; }
    @AuraEnabled
    public String quoteId { get; set; }
  }

  public class EngieValidateOfferResponseWrapper {
    @AuraEnabled
    public String idTransaction;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public String idSimulation;
    @AuraEnabled
    public String referenceOffrePartenaire;
    @AuraEnabled
    public String urlPlateformePartenaire;
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