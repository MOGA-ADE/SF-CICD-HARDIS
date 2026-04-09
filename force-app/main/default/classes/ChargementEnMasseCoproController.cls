public with sharing class ChargementEnMasseCoproController {
  public class FieldMissingException extends Exception {
  }

  @AuraEnabled
  public static void insertCopro(String csvHeader, List<String> csvFileLines, String recordId) {
    //Recup les champs prérempli
    String[] headers = csvHeader.split(';');
    List<Account> listCopro = new List<Account>();
    Integer indexNomCopro = headers.indexOf('NOM DE LA COPROPRIETE');
    Integer indexSiren = headers.indexOf('SIREN');
    Integer indexSiret = headers.indexOf('SIRET');
    Integer indexNumeroVoie = headers.indexOf('NUMERO VOIE');
    Integer indexVoie = headers.indexOf('VOIE');
    Integer indexCodePostal = headers.indexOf('CODE POSTAL');
    Integer indexCommune = headers.indexOf('COMMUNE');
    Integer indexIdentifiantDuContact = headers.indexOf('IDENTIFIANT DU CONTACT');
    List<AccountContactRelation> listACRToInsert = new List<AccountContactRelation>();
    Boolean asap;
    String recordIdCopro = [
      SELECT Id
      FROM RecordType
      WHERE DeveloperName = 'Copropriete'
      LIMIT 1
    ]
    .Id;
    try {
      for (Integer i = 0; i < csvFileLines.size(); i++) {
        String[] csvRecordData = csvFileLines[i].split(';');
        if (
          String.isBlank(csvRecordData[indexNomCopro]) ||
          String.isBlank(csvRecordData[indexSiren]) ||
          String.isBlank(csvRecordData[indexSiret]) ||
          String.isBlank(csvRecordData[indexNumeroVoie]) ||
          String.isBlank(csvRecordData[indexVoie]) ||
          String.isBlank(csvRecordData[indexCodePostal]) ||
          String.isBlank(csvRecordData[indexCommune])
        ) {
          throw new FieldMissingException(
            'Attention, tous les champs sont obligatoires (Hors IDENTIFIANT DU CONTACT).'
          );
        }
        Account copro = new Account();
        copro.Name = csvRecordData[indexNomCopro];
        copro.Siret__c = csvRecordData[indexSiret];
        copro.Siren__c = csvRecordData[indexSiren];
        copro.Numero_voie__c = csvRecordData[indexNumeroVoie];
        copro.voie__c = csvRecordData[indexVoie];
        copro.Code_Postal__c = csvRecordData[indexCodePostal];
        copro.Ville__c = csvRecordData[indexCommune];
        copro.Syndic__c = recordId;
        copro.RecordTypeId = recordIdCopro;
        listCopro.add(copro);
      }
    } catch (Exception e) {
      System.debug('Erreur '+ e.getMessage() + 'ligne '+e.getLineNumber());
      throw new AuraHandledException('Attention, tous les champs sont obligatoires (Hors IDENTIFIANT DU CONTACT).');
    }
    try{
      insert listCopro;
      for (Integer i = 0; i < csvFileLines.size(); i++) {
        String[] csvRecordData = csvFileLines[i].split(';');
        if (csvRecordData.size() == headers.size()) {
          AccountContactRelation acr = new AccountContactRelation();
          acr.AccountId = listCopro.get(i).Id;
          acr.contactId = csvRecordData[indexIdentifiantDuContact];
          acr.roles = 'Gestionnaire de la copropriété';
          listACRToInsert.add(acr);
        }
      }
      insert listACRToInsert;
    }
    catch(Exception dmlException){
        throw new AuraHandledException('Erreur lors de l\'enregistrement '+dmlException.getMessage());
      }
  }

  @AuraEnabled
  public static List<Account> retrieveCopros(String recordId) {
    System.debug('retrieveCopros Id received '+recordId);
    List<Account> listAccount = [
      SELECT Id, Name
      FROM Account
      WHERE RecordType.DeveloperName = 'Copropriete' AND Syndic__c = :recordId
    ];
    System.debug('listAccount '+listAccount);
    return listAccount;
  }
}