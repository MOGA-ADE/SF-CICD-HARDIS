/**
 * @description Controller for the Pde_lwc
 */
public with sharing class csv_pdeLoader_Controller {


  // Fonction utilitaire pour valider les dates au format JJ/MM/AAAA
  @TestVisible
  private static Boolean isValidDate(String dateStr) {
      // Vérification du format avec une expression régulière
      String datePattern = '^\\d{2}/\\d{2}/\\d{4}$';
      if (!Pattern.matches(datePattern, dateStr)) {
          return false;
      }

      // Extraction des composants de la date
      String[] dateParts = dateStr.split('/');
      Integer day = Integer.valueOf(dateParts[0]);
      Integer month = Integer.valueOf(dateParts[1]);
      Integer year = Integer.valueOf(dateParts[2]);

      try {
          // Validation de la date avec Date.newInstance
          Date testDate = Date.newInstance(year, month, day);

          // Vérification que le jour et le mois correspondent exactement
          if (testDate.year() == year && testDate.month() == month && testDate.day() == day) {
              return true;
          }
          return false; // Les composants ne correspondent pas
      } catch (Exception e) {
          return false; // Date invalide
      }
  }


  private static String checkReaquireFieldValue(String[] recordData, Integer lineNumber, Integer fieldIndex, String fieldName) {
    System.debug('check : ' + fieldName + ' index : ' + fieldIndex);
    //Vérifie le cas ou la dernière cellule est manquante
    if (fieldIndex >= recordData.size()) {
        System.debug(fieldName + ' index out bound index : ' + fieldIndex + ' record size : ' + recordData.size());
        System.debug('Ligne ' + lineNumber + ': Le champ ' + fieldName + ' est obligatoire');
        return 'Ligne ' + lineNumber + ': Le champ ' + fieldName + ' est obligatoire.';
    }
    
    System.debug('recordData '+recordData);
    System.debug('recordData.szie() '+recordData.size());

    String fieldValue = recordData[fieldIndex];
    //Vérifie le cas ou une cellule est vide 
    if (String.isBlank(fieldValue)) {
        System.debug(fieldValue + ' ligne vide');
        return 'Ligne ' + lineNumber + ': Le champ ' + fieldName + ' est obligatoire.';
    }
    //Vérifie le cas ou la date n'est pas valide
    else if ((fieldName == 'DATE ECHEANCE CONTRAT' || fieldName == 'DATE SIGNATURE ACD') && !isValidDate(fieldValue)){
      return 'Ligne ' + lineNumber + ': Le champ ' + fieldName + ' est incorrect (format attendu : JJ/MM/AAAA).';
    }

    return null ;
    }    

  // remove particular string in string list
  public static List<String> removeValue(List<String> liste, String value) {

    if (liste == null || value == null) {
        return liste; 
    }

    for (Integer i = liste.size() - 1; i >= 0; i--) {
        if (liste[i] != null && liste[i].equals(value)) {
            liste.remove(i); 
        }
    }

    return liste; 
}

  @AuraEnabled
  public static void insertPdeElec(String csvHeader,List<String> csvFileLines,String recordId,Boolean insertCopro) {
    String[] headers = csvHeader.split(';');

    String errorMessageChamps = '';
    List<String> errorMessageValeurs = new List<String>();
    List<String> errorList = new List<String>();
    List<String> listMandatoryFields = new List<String>{'SIRET PAYEUR','RAE','SEGMENT','DATE ECHEANCE CONTRAT','DATE SIGNATURE ACD'};
    
    //Faire une lsite d'elements obligatoires pour les copros
    Integer fieldIndex,fileLine;
    String error;
    Integer indexSiretPayeur = headers.indexOf('SIRET PAYEUR');
    Integer indexRAE = headers.indexOf('RAE');
    Integer indexNomDuSite = headers.indexOf('NOM DU SITE OU DE LA COPROPRIETE');
    Integer indexSiteDeConso = headers.indexOf('SITE DE CONSOMMATION');
    Integer indexFounisseurActuel = headers.indexOf('FOURNISSEUR ACTUEL');
    Integer indexSegment = headers.indexOf('SEGMENT');
    Integer indexDateEchanceContrat = headers.indexOf('DATE ECHEANCE CONTRAT');
    Integer indexIdentifiantDateSignatureACD = headers.indexOf('DATE SIGNATURE ACD');
    Integer indexIdentifiantCopro = headers.indexOf('IDENTIFIANT DE LA COPROPRIETE');
    List<PDE__c> pdelist = new List<PDE__c>();
    List<String> errorPdeList = new List<String>(); 
    Integer numberOfElement;
    List<RecordType> C1C2 = new List<RecordType>([SELECT Id FROM RecordType WHERE SobjectType = 'pde__c' AND developername = 'Elec_C1C2']);
    List<RecordType> C3C4 = new List<RecordType>([SELECT Id FROM RecordType WHERE SobjectType = 'pde__c' AND developername = 'Elec_C3_C4']);
    List<RecordType> C5   = new List<RecordType>([SELECT Id FROM RecordType WHERE SobjectType = 'pde__c' AND developername = 'PDE_ElecC5']);


    if(insertCopro) {
      listMandatoryFields.add('IDENTIFIANT DE LA COPROPRIETE');
    }

    for (Integer i = 0; i < csvFileLines.size(); i++) { // Ne pas utiliser d'index passer par un foreach for(String element...)
      String[] csvRecordData = csvFileLines[i].split(';');
      numberOfElement = csvRecordData.size();
      fileLine = i+2;

      //errorMessageValeurs.clear();
      for (String elementMandatory : listMandatoryFields) {
        System.debug('compare size : ' + csvRecordData.size() + 'indice in list : ' + headers.indexOf(elementMandatory) + ' indice : ' + i + ' ' + elementMandatory);
        fieldIndex = headers.indexOf(elementMandatory);
        error = checkReaquireFieldValue(csvRecordData, fileLine, fieldIndex, elementMandatory);

        if (error != null) {
            errorMessageValeurs.add(error);
        }
      }
      
        //Mettre un IF pour n'insérer dans la liste que si la ligne n'a pas d'erreur
        if(errorMessageValeurs.isEmpty()) {
          try {
            PDE__c pdeObj = new PDE__c();
            numberOfElement = csvRecordData.size();
            pdeObj.Siret_payeur__c = csvRecordData[indexSiretPayeur];
            pdeObj.ReferencePointEnergie_Refonte__c = csvRecordData[indexRAE];
            pdeObj.Name = csvRecordData[indexNomDuSite];
            pdeObj.SiteConsommation__c = csvRecordData[indexSiteDeConso];
            pdeObj.Fournisseur__c = csvRecordData[indexFounisseurActuel];
            Date myDate = date.parse(csvRecordData[indexDateEchanceContrat]);
            Date dateSignatureACD = date.parse(csvRecordData[indexIdentifiantDateSignatureACD]);
            pdeObj.DateEcheance__c = myDate;
            pdeObj.Date_signature_ACD__c = dateSignatureACD;
            pdeObj.EntiteJuridique__c = insertCopro ? csvRecordData[indexIdentifiantCopro] : recordId;
            pdeObj.Segment__c = csvRecordData[indexSegment];
            if (csvRecordData[indexSegment] == 'C1' || csvRecordData[indexSegment] == 'C2') {
              pdeObj.RecordTypeId = C1C2.get(0).id;
            } else if (csvRecordData[indexSegment] == 'C3' || csvRecordData[indexSegment] == 'C4') {
              pdeObj.RecordTypeId = C3C4.get(0).id;
            } else if (csvRecordData[indexSegment] == 'C5') {
              pdeObj.RecordTypeId = C5.get(0).id;
            }
            System.debug(csvRecordData);
            pdelist.add(pdeObj);
          }
          catch (Exception e) {
            System.debug('Erreur ' + e.getMessage() + 'ligne ' + e.getLineNumber());
            throw new AuraHandledException(e.getStackTraceString());
          }
        }/* else {
          errorMessageValeurs = removeValue(errorMessageValeurs, null);
          System.debug('final error message  : ' + errorMessageValeurs);
      
          
        }
          */

    }

    if (!errorMessageValeurs.isEmpty()) {
      String tmperror = 'Erreurs détectées dans le fichier :\n' + String.join(errorMessageValeurs, '\n');
      System.debug(tmperror);
      throw new AuraHandledException('Erreurs détectées dans le fichier :\n' + String.join(errorMessageValeurs, '\n'));
    }
    else if(pdelist.size() > 0) {// Ne tenter une insertion en base de donnée que si aucune ligne n'a d'erreur
        Database.SaveResult[] saveResults = Database.insert(pdelist, false);
        for (Integer i = 0; i < saveResults.size(); i++) {
            if (!saveResults[i].isSuccess()) {
                // Récupération du PDE correspondant et ajout dans la liste des erreurs
                PDE__c failedPde = pdelist[i];
                errorPdeList.add(failedPde.ReferencePointEnergie_Refonte__c);
                for(Database.Error err : saveResults[i].getErrors()) {
                  System.debug('The following error has occurred.');                    
                  System.debug(err.getStatusCode() + ': ' + err.getMessage());
                  System.debug('PDE fields that affected this error: ' + err.getFields());
                } 
            }
        }
        // delete maybe !!!
        if (!errorPdeList.isEmpty()) {
            throw new AuraHandledException(
                'Erreur lors de l\'insertion des PDE suivants : ' + String.join(errorPdeList, ', ')
            );
        }
    }
  }

  @AuraEnabled
  public static void insertPdeGaz(String csvHeader,List<String> csvFileLines,String recordId,Boolean insertCopro) {
    Integer numberOfElement;
    String[] headers = csvHeader.split(';');
    List<String> errorMessageValeurs = new List<String>();
    List<String> errorPdeList = new List<String>(); 
    List<String> listMandatoryFields = new List<String>{'SIRET PAYEUR','PCE','VOIE','CODE POSTAL','COMMUNE','DATE ECHEANCE CONTRAT'};


    Integer fieldIndex,fileLine;
    String error;
    Integer indexSiretPayeur = headers.indexOf('SIRET PAYEUR');
    Integer indexPCE = headers.indexOf('PCE');
    //Fix temporaire a corriger proprement dans le fichier CSV
    Integer indexNomDuSite = headers.indexOf('NOM DU SITE OU DE LA COPROPRIETE');
    indexNomDuSite = indexNomDuSite == -1 ? headers.indexOf('NOM DU SITE OU DE LA COPROPRIETE ') : indexNomDuSite;
    Integer indexSiteDeConso = headers.indexOf('SITE DE CONSOMMATION');
    Integer indexNumeroVoie = headers.indexOf('NUMERO VOIE');
    Integer indexVoie = headers.indexOf('VOIE');
    Integer indexCodePostal = headers.indexOf('CODE POSTAL');
    Integer indexCommune = headers.indexOf('COMMUNE');
    Integer indexFounisseurActuel = headers.indexOf('FOURNISSEUR ACTUEL');
    Integer indexTarif = headers.indexOf('TARIF');
    Integer indexProfil = headers.indexOf('PROFIL');
    Integer indexCar = headers.indexOf('CAR');
    Integer indexDateEchanceContrat = headers.indexOf('DATE ECHEANCE CONTRAT');
    Integer indexIdentifiantCopro = headers.indexOf(
      'IDENTIFIANT DE LA COPROPRIETE'
    );

    List<PDE__c> pdelist = new List<PDE__c>();

    List<RecordType> Gaz = new List<RecordType>(
      [
        SELECT id
        FROM RecordType
        WHERE SobjectType = 'pde__c' AND developername = 'PDE_Gaz'
      ]
    );

    if(insertCopro) {
      listMandatoryFields.add('IDENTIFIANT DE LA COPROPRIETE');
    }

    for (Integer i = 0; i < csvFileLines.size(); i++) {
      String[] csvRecordData = csvFileLines[i].split(';');
      numberOfElement = csvRecordData.size();
      fileLine = i+2;

      for (String elementMandatory : listMandatoryFields) {
        System.debug('compare size : ' + csvRecordData.size() + 'indice in list : ' + headers.indexOf(elementMandatory) + ' indice : ' + i + ' ' + elementMandatory);
        fieldIndex = headers.indexOf(elementMandatory);
        error = checkReaquireFieldValue(csvRecordData, fileLine, fieldIndex, elementMandatory);

        if (error != null) {
            errorMessageValeurs.add(error);
        }
      }

      if(errorMessageValeurs.isEmpty()) {
        try
        {    
          PDE__c pdeObj = new PDE__c();
          pdeObj.Siret_payeur__c = csvRecordData[indexSiretPayeur];
          pdeObj.PCE_Refonte__c = csvRecordData[indexPCE];
          pdeObj.Name = csvRecordData[indexNomDuSite];
          pdeObj.SiteConsommation__c = csvRecordData[indexSiteDeConso];
          pdeObj.NumeroVoie__c = csvRecordData[indexNumeroVoie];
          pdeObj.voie__c = csvRecordData[indexVoie];
          pdeObj.Code_Postal__c = csvRecordData[indexCodePostal];
          pdeObj.Ville__c = csvRecordData[indexCommune];
          pdeObj.Fournisseur__c = csvRecordData[indexFounisseurActuel];
          pdeObj.tarif__c = csvRecordData[indexTarif];
          pdeObj.profil__c = csvRecordData[indexProfil];
          Date myDate = date.parse(csvRecordData[indexDateEchanceContrat]);
          pdeObj.DateEcheance__c = myDate;
          pdeObj.EntiteJuridique__c = insertCopro ? csvRecordData[indexIdentifiantCopro] : recordId;
            pdeObj.CARGaz__c = String.isBlank(csvRecordData[indexCar]) ? null : Decimal.valueOf(csvRecordData[indexCar]).setScale(2);
          pdeObj.RecordTypeId = Gaz.get(0).id;
          pdelist.add(pdeObj);
        } 
        catch (Exception e) {
          System.debug('Erreur ' + e.getMessage() + 'ligne ' + e.getLineNumber());
          throw new AuraHandledException(e.getStackTraceString());
        }         
      }
      
    }

    if (!errorMessageValeurs.isEmpty()) {
      throw new AuraHandledException('Erreurs détectées dans le fichier :\n' + String.join(errorMessageValeurs, '\n'));
    }
    else if(pdelist.size() > 0) {// Ne tenter une insertion en base de donnée que si aucune ligne n'a d'erreur
        Database.SaveResult[] saveResults = Database.insert(pdelist, false);
        for (Integer i = 0; i < saveResults.size(); i++) {
            if (!saveResults[i].isSuccess()) {
                // Récupération du PDE correspondant et ajout dans la liste des erreurs
                PDE__c failedPde = pdelist[i];
                errorPdeList.add(failedPde.PCE_Refonte__c );
                for(Database.Error err : saveResults[i].getErrors()) {
                  System.debug('The following error has occurred.');                    
                  System.debug(err.getStatusCode() + ': ' + err.getMessage());
                  System.debug('PDE fields that affected this error: ' + err.getFields());
                } 
            }
        }
        // delete maybe !!!
        if (!errorPdeList.isEmpty()) {
            throw new AuraHandledException(
                'Erreur lors de l\'insertion des PDE suivants : ' + String.join(errorPdeList, ', ')
            );
        }
    }
  }

  @AuraEnabled
  public static List<PDE__c> getPDEList(Id AccountId){
    return [SELECT  Id,
                    CARGaz__c,
                    Code_Postal__c,
                    Conso_Base__c,
                    Conso_HCE__c,
                    Conso_HCH__c,
                    Conso_HPE__c,
                    Conso_HPH__c,
                    Conso_Pointe__c,
                    ConsoHC__c,
                    ConsoHP__c,
                    DateEcheance__c,
                    EntiteJuridique__c,
                    Fournisseur__c,
                    FTA__c,
                    Name,
                    NumeroVoie__c,
                    PCE_Refonte__c,
                    profil__c,
                    Puissance_souscrite__c,
                    ReferencePointEnergie_Refonte__c,
                    Segment__c,
                    Siret_payeur__c,
                    SiteConsommation__c,
                    tarif__c,
                    Ville__c,
                    voie__c
              FROM PDE__c 
              WHERE EntiteJuridique__c = :AccountId];
  }

  @AuraEnabled
  public static List<PDE__c> getPDESyndicList(Id AccountId){
    return [SELECT  Id,
                    CARGaz__c,
                    Code_Postal__c,
                    Conso_Base__c,
                    Conso_HCE__c,
                    Conso_HCH__c,
                    Conso_HPE__c,
                    Conso_HPH__c,
                    Conso_Pointe__c,
                    ConsoHC__c,
                    ConsoHP__c,
                    DateEcheance__c,
                    Date_signature_ACD__c,
                    EntiteJuridique__c,
                    Fournisseur__c,
                    FTA__c,
                    Name,
                    NumeroVoie__c,
                    OwnerId,
                    Owner.Name,
                    PCE_Refonte__c,
                    profil__c,
                    Puissance_souscrite__c,
                    ReferencePointEnergie_Refonte__c,
                    Segment__c,
                    Siret_payeur__c,
                    SiteConsommation__c,
                    tarif__c,
                    Ville__c,
                    voie__c
              FROM PDE__c 
              WHERE EntiteJuridique__r.Syndic__c = :AccountId
              ];
  }


  @AuraEnabled
  public static Boolean updatePDE(List<PDE__c> pdes){
    System.debug('updatePDE ');
      // MAJ PDEs
      Boolean allSuccess = true;
      Database.SaveResult[] srList = Database.update(pdes, true);
      // Iterate through each returned result
      for (Database.SaveResult sr : srList) {
          if (!sr.isSuccess()) {
              allSuccess = false;
              return allSuccess;
          }
      }
      return allSuccess;
  }

  @AuraEnabled
  public static Map<String,String> getPDERecodTypeIds(){
    try {
      Map<String,String> mapIdRTName = new Map<String,String>();
      List<RecordType> listRT = new List<RecordType>([SELECT Id,Name FROM RecordType WHERE sObjectType='PDE__c']);
      for(RecordType rt : listRT){
        mapIdRTName.put(rt.Name, rt.Id);
      } 
      return mapIdRTName;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }


  @AuraEnabled
  public static Map<String,String> getPDEElecForEnergisme(Id accountId, Boolean includeC5) {
      Map<String, String> response = new Map<String, String>();
      String recordTypeName = [SELECT RecordType.Name FROM Account WHERE Id = :accountId LIMIT 1].RecordType.Name;
      Boolean isSyndic = recordTypeName == 'Syndic'; // Vérification du type d'account
      String adresse = '';
      List<PDE__c> listPDE = new List<PDE__c>();

      if (accountId == null) {
          System.debug('getPDEElecForEnergisme : L\'ID est nul ou invalide.');
          return null;
      }
  
      try {
          // Définir la requête SOQL de manière dynamique
          String query = 'SELECT Name, TECH_num_compteur__c, EntiteJuridique__r.Name, EntiteJuridique__r.Syndic__r.Name, ' +
                         'EntiteJuridique__r.ELLISPHERE__Elli_code_ape08__c, EntiteJuridique__r.SecteurActiviteEllisphere__c, ' +
                         'Adresse_de_consommation__c, Code_Postal__c, Ville__c, NumeroVoie__c, voie__c, Segment__c, FTA__c';
  
          // Conditions spécifiques en fonction du type de record
          if (!isSyndic) {
            //if (!isSyndic) {
              query += ' FROM PDE__c WHERE EntiteJuridique__c = :accountId';
              if (includeC5) {
                  query += ' AND Segment__c <> \'\'';
              } else {
                  query += ' AND Segment__c <> \'C5\' AND Segment__c <> \'\'';
              }
  
              query += ' WITH SECURITY_ENFORCED';
          //}

          } else {
            query += ' FROM PDE__c WHERE EntiteJuridique__r.Syndic__c = :accountId'; 
            if (includeC5) {
              query += ' AND Segment__c <> \'\'';
            } else {
              query += ' AND Segment__c <> \'C5\' AND Segment__c <> \'\'';
            }
              query += ' WITH SECURITY_ENFORCED';
          }

          System.debug('query '+query);
  
          // Exécuter la requête dynamique
          listPDE = Database.query(query);
  
      } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
  
      // Générer la réponse JSON
      JSONGenerator gen = JSON.createGenerator(true);
      gen.writeStartArray();
      for (PDE__c pde : listPDE) {
          adresse = (pde.NumeroVoie__c != null ? pde.NumeroVoie__c : '') + ' ' + (pde.voie__c != null ? pde.voie__c : '');
          gen.writeStartObject();
          gen.writeStringField('point de livraison', pde.TECH_num_compteur__c);
          gen.writeStringField('nom du site', pde.Name);
          gen.writeStringField('niveau d\'organisation1', 'France');
          gen.writeStringField('code orga1', '');
          if(! isSyndic)  {
            gen.writeStringField('niveau d\'organisation2', pde.EntiteJuridique__r.Name);
          }
          else {
            gen.writeStringField('niveau d\'organisation2', pde.EntiteJuridique__r.Syndic__r.Name);
          }
          
          gen.writeStringField('code orga2', '');
          gen.writeStringField('niveau d\'organisation3', 'Elec');
          gen.writeStringField('code orga3', '');
          gen.writeStringField('niveau d\'organisation4', '');
          gen.writeStringField('code orga4', '');
          gen.writeStringField('adresse du site', adresse);
          gen.writeStringField('code postal', pde.Code_Postal__c != null ? pde.Code_Postal__c : '');
          gen.writeStringField('ville', pde.Ville__c != null ? pde.Ville__c : '');
          gen.writeStringField('pays', 'FR');
          gen.writeStringField('typologie', pde.EntiteJuridique__r?.SecteurActiviteEllisphere__c != null ? pde.EntiteJuridique__r?.SecteurActiviteEllisphere__c : '');
          gen.writeStringField('statut', 'true');
          gen.writeStringField('fluide', 'ELEC');
          gen.writeStringField('segment tarifaire', pde.Segment__c != null ? pde.Segment__c : '');
          gen.writeStringField('GRD', 'Enedis');
          gen.writeEndObject();
      }
      gen.writeEndArray();
  
      // Retourner la réponse sous forme de map avec le nom de l'entité juridique comme clé
      if (listPDE.size() > 0) {
          response.put(listPDE.get(0).EntiteJuridique__r.Name, gen.getAsString());
          return response;
      }
      return null;
  }


  @AuraEnabled
  public static Map<String,String> getPDEElecForEnergismeExcel(Id accountId, String contactId, String contactFN, String contactLN, String contactS ,String contactEmail, Boolean includeC5) {
      System.debug('contat : ' + contactFN);
      Map<String, String> response = new Map<String, String>();
      String recordTypeName = [SELECT RecordType.Name FROM Account WHERE Id = :accountId LIMIT 1].RecordType.Name;
      Boolean isSyndic = recordTypeName == 'Syndic'; // Vérification du type d'account
      String adresse = '';
      List<PDE__c> listPDE = new List<PDE__c>();

      if (accountId == null) {
          System.debug('getPDEElecForEnergisme : L\'ID est nul ou invalide.');
          return null;
      }
  
      try {
          // Définir la requête SOQL de manière dynamique
          String query = 'SELECT Name, TECH_num_compteur__c, EntiteJuridique__r.Name, ' +
                         'PCE_Refonte__c, Code_Postal__c, Date_signature_ACD__c, ' +
                         'EntiteJuridique__r.ELLISPHERE__Elli_code_ape08__c, EntiteJuridique__r.SecteurActiviteEllisphere__c, ' +
                         'Adresse_de_consommation__c, Ville__c, NumeroVoie__c, voie__c, Segment__c, FTA__c';
  
          // Conditions spécifiques en fonction du type de record
          if (!isSyndic) {
            query += ' FROM PDE__c WHERE EntiteJuridique__c = :accountId';
            if (includeC5) {
                query += ' AND Segment__c <> \'\'';
            } else {
                query += ' AND Segment__c <> \'C5\' AND Segment__c <> \'\'';
            }

            query += ' WITH SECURITY_ENFORCED';
          } else {
            query += ' FROM PDE__c WHERE EntiteJuridique__r.Syndic__c = :accountId'; 
            if (includeC5) {
              query += ' AND Segment__c <> \'\'';
            } else {
              query += ' AND Segment__c <> \'C5\' AND Segment__c <> \'\'';
            }
              query += ' WITH SECURITY_ENFORCED';
          }

          System.debug('query '+query);
  
          // Exécuter la requête dynamique
          listPDE = Database.query(query);
  
      } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
  
      // Générer la réponse JSON
      JSONGenerator gen = JSON.createGenerator(true);
      gen.writeStartArray();
      for (PDE__c pde : listPDE) {
          adresse = (pde.NumeroVoie__c != null ? pde.NumeroVoie__c : '') + ' ' + (pde.voie__c != null ? pde.voie__c : '');
          gen.writeStartObject();
          gen.writeStringField('id_pdl', pde.TECH_num_compteur__c != null ? pde.TECH_num_compteur__c : '');
          gen.writeStringField('Partner', 'alliancedesenergies');
          gen.writeStringField('Date signature Mandat', pde.Date_signature_ACD__c != null ? pde.Date_signature_ACD__c.format() : '');
          gen.writeStringField('Date Debut Autorisation', pde.Date_signature_ACD__c != null ? pde.Date_signature_ACD__c.format() : '');
          gen.writeStringField('Date Fin Autorisation', pde.Date_signature_ACD__c != null ? pde.Date_signature_ACD__c.addYears(1).format() : '');
          gen.writeStringField('Raison sociale', pde.EntiteJuridique__r.Name);
          gen.writeStringField('Civilite', contactS != null ? contactS : '');
          gen.writeStringField('Nom', contactLN != null ? contactLN : '');
          gen.writeStringField('Prenom', contactFN != null ? contactFN : '');
          gen.writeBooleanField('Injection', false);
          gen.writeBooleanField('Soutirage', true);
          gen.writeEndObject();
      }
      gen.writeEndArray();
  
      // Retourner la réponse sous forme de map avec le nom de l'entité juridique comme clé
      if (listPDE.size() > 0) {
          response.put(listPDE.get(0).EntiteJuridique__r.Name, gen.getAsString());
          return response;
      }
      return null;
  }
  
  @AuraEnabled
  public static Map<String, String> getPDEGazForEnergisme(Id accountId) {
      Map<String, String> response = new Map<String, String>();
      String adresse = '';
      List<PDE__c> listPDE = new List<PDE__c>();
      
      if (accountId == null) {
          System.debug('getPDEGazForEnergisme : L\'ID est nul ou invalide.');
          return null;
      }
      
      try {
          // Récupérer le type de record de l'Account pour déterminer s'il s'agit d'un Syndic
          String recordTypeName = [SELECT RecordType.Name FROM Account WHERE Id = :accountId LIMIT 1].RecordType.Name;
          Boolean isSyndic = recordTypeName == 'Syndic'; // Vérification du type d'account
  
          // Construction de la requête dynamique pour récupérer les PDE Gaz
          String query = 'SELECT Name, TECH_num_compteur__c, EntiteJuridique__r.Name, ' +
                         'EntiteJuridique__r.ELLISPHERE__Elli_code_ape08__c, EntiteJuridique__r.SecteurActiviteEllisphere__c, ' +
                         'Adresse_de_consommation__c, Code_Postal__c, Ville__c, NumeroVoie__c, voie__c, Segment__c, FTA__c ';
  
          if (!isSyndic) {
              // Cas où l'Account n'est pas un Syndic
              query += ' FROM PDE__c WHERE EntiteJuridique__c = :accountId AND TypePDE__c = \'Gaz\' WITH SECURITY_ENFORCED';
          } else {
              // Cas où l'Account est un Syndic
              query += ' FROM PDE__c WHERE EntiteJuridique__r.Syndic__c = :accountId AND TypePDE__c = \'Gaz\' WITH SECURITY_ENFORCED';
          }
  
          // Exécution de la requête dynamique
          listPDE = Database.query(query);
  
      } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
  
      // Génération de la réponse JSON
      JSONGenerator gen = JSON.createGenerator(true);
      gen.writeStartArray();
      for (PDE__c pde : listPDE) {
          adresse = (pde.NumeroVoie__c != null ? pde.NumeroVoie__c : '') + ' ' + (pde.voie__c != null ? pde.voie__c : '');
          gen.writeStartObject();
          gen.writeStringField('point de livraison', pde.TECH_num_compteur__c);
          gen.writeStringField('nom du site', pde.Name);
          gen.writeStringField('niveau d\'organisation1', 'France');
          gen.writeStringField('code orga1', '');
          gen.writeStringField('niveau d\'organisation2', pde.EntiteJuridique__r.Name);
          gen.writeStringField('code orga2', '');
          gen.writeStringField('niveau d\'organisation3', 'Gaz');
          gen.writeStringField('code orga3', '');
          gen.writeStringField('niveau d\'organisation4', '');
          gen.writeStringField('code orga4', '');
          gen.writeStringField('adresse du site', adresse);
          gen.writeStringField('code postal', pde.Code_Postal__c != null ? pde.Code_Postal__c : '');
          gen.writeStringField('ville', pde.Ville__c != null ? pde.Ville__c : '');
          gen.writeStringField('pays', 'FR');
          gen.writeStringField('typologie', pde.EntiteJuridique__r.SecteurActiviteEllisphere__c != null ? pde.EntiteJuridique__r.SecteurActiviteEllisphere__c : '');
          gen.writeStringField('statut', 'true');
          gen.writeStringField('fluide', 'GAS');
          gen.writeStringField('GRD', 'grdf');
          gen.writeEndObject();
      }
      gen.writeEndArray();
  
      // Retourner la réponse sous forme de map avec le nom de l'entité juridique comme clé
      if (listPDE.size() > 0) {
          response.put(listPDE.get(0).EntiteJuridique__r.Name, gen.getAsString());
          return response;
      }
      return null;
  }

  @AuraEnabled
  public static Map<String, String> getPDEGazForEnergismeExcel(Id accountId, String contactName, String contactEmail) {
      Map<String, String> response = new Map<String, String>();
      String adresse = '';
      List<PDE__c> listPDE = new List<PDE__c>();

      System.debug('name : ' + contactName);
      
      if (accountId == null) {
          System.debug('getPDEGazForEnergisme : L\'ID est nul ou invalide.');
          return null;
      }
      
      try {
          // Récupérer le type de record de l'Account pour déterminer s'il s'agit d'un Syndic
          String recordTypeName = [SELECT RecordType.Name FROM Account WHERE Id = :accountId LIMIT 1].RecordType.Name;
          Boolean isSyndic = recordTypeName == 'Syndic'; // Vérification du type d'account
  
          // Construction de la requête dynamique pour récupérer les PDE Gaz
          String query = 'SELECT Name, TECH_num_compteur__c, EntiteJuridique__r.Name, ' +
                         'PCE_Refonte__c, Code_Postal__c, Date_signature_ACD__c, ' +
                         'EntiteJuridique__r.ELLISPHERE__Elli_code_ape08__c, EntiteJuridique__r.SecteurActiviteEllisphere__c, ' +
                         'Adresse_de_consommation__c, Ville__c, NumeroVoie__c, voie__c, Segment__c, FTA__c';
  
          if (!isSyndic) {
              // Cas où l'Account n'est pas un Syndic
              query += ' FROM PDE__c WHERE EntiteJuridique__c = :accountId AND TypePDE__c = \'Gaz\' WITH SECURITY_ENFORCED';
          } else {
              // Cas où l'Account est un Syndic
              query += ' FROM PDE__c WHERE EntiteJuridique__r.Syndic__c = :accountId AND TypePDE__c = \'Gaz\' WITH SECURITY_ENFORCED';
          }
  
          // Exécution de la requête dynamique
          listPDE = Database.query(query);
  
      } catch (Exception e) {
          throw new AuraHandledException(e.getMessage());
      }
  
      // Génération de la réponse JSON
      JSONGenerator gen = JSON.createGenerator(true);
      gen.writeStartArray();
      for (PDE__c pde : listPDE) {
          adresse = (pde.NumeroVoie__c != null ? pde.NumeroVoie__c : '') + ' ' + (pde.voie__c != null ? pde.voie__c : '');
          gen.writeStartObject();
          gen.writeStringField('Partner', 'alliancedesenergies');
          gen.writeStringField('PCE', pde.PCE_Refonte__c != null ? pde.PCE_Refonte__c : '');
          gen.writeStringField('code postal', pde.Code_Postal__c != null ? pde.Code_Postal__c : '');
          gen.writeStringField('Raison sociale', pde.EntiteJuridique__r.Name != null ? pde.EntiteJuridique__r.Name : '');
          gen.writeStringField('Nom du titulaire', contactName != null ? contactName : '');
          gen.writeStringField('Adresse E-mail du titulaire', contactEmail != null ? contactEmail : '');
          gen.writeStringField('Date signature Mandat', pde.Date_signature_ACD__c != null ? pde.Date_signature_ACD__c.format() : '');
          gen.writeStringField('Date Début Mandat', pde.Date_signature_ACD__c != null ? pde.Date_signature_ACD__c.format() : '');
          gen.writeStringField('Date Fin Mandat', pde.Date_signature_ACD__c != null ? pde.Date_signature_ACD__c.addYears(1).format() : '');
          gen.writeStringField('perim_donnees_techniques_et_contractuelles', '');
          gen.writeStringField('perim_historique_de_donnees', '');
          gen.writeStringField('perim_flux_de_donnees', '');
          gen.writeStringField('perim_donnees_informatives', '');
          gen.writeStringField('perim_donnees_publiees', '');
          gen.writeEndObject();
      }
      gen.writeEndArray();
  
      // Retourner la réponse sous forme de map avec le nom de l'entité juridique comme clé
      if (listPDE.size() > 0) {
          response.put(listPDE.get(0).EntiteJuridique__r.Name, gen.getAsString());
          return response;
      }
      return null;
  }

  @AuraEnabled
  public static List<Contact> getSignataire(Id accountId) {
    
      if (accountId == null) {
          System.debug('Account ID is null');
          return new List<Contact>();
      }

      List<Contact> signataires = [
          SELECT Id, Name, Email, Salutation, FirstName, LastName
          FROM Contact
          WHERE Id IN (
              SELECT ContactId
              FROM AccountContactRelation
              WHERE AccountId = :accountId AND Roles INCLUDES ('Signataire')
          )
      ];

      System.debug('Nombre de signataires trouvés : ' + signataires.size());

      return signataires; 
  }
}