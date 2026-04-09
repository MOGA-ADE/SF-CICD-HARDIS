@isTest
public class csv_pdeLoader_Controller_Test {
  static testMethod void testfileupload() {
    Account acc = new Account(Name = 'testAccount', Siren__c = '123456789');

    insert acc;

    String strElec = JSON.serialize(
      '12345657898555;1234565555;COPRO ABC;COLLEGE DE VARADES;Engie;C4;12/12/2012;31/12/2024\n'
    );
    String dataElec = JSON.deserializeUntyped(strElec).toString();
    list<String> csvFileLinesElec = dataElec.split('\n');
    for (String s : csvFileLinesElec) {
      System.debug('value : ' + csvFileLinesElec);
    }



    String strHeaderElec = 'SIRET PAYEUR;RAE;NOM DU SITE OU DE LA COPROPRIETE;SITE DE CONSOMMATION;FOURNISSEUR ACTUEL;SEGMENT;DATE ECHEANCE CONTRAT;DATE SIGNATURE ACD';
    strElec = JSON.serialize(
      '12345657898764;1234565476;COPRO ABC;COLLEGE DE VARADES;Engie;C4;12/12/2012;31/12/2024\n'+
      '12345657898764;1234565475;COPRO ABC;TEST;Engie;C1;12/12/2012;31/12/2024\n'+
      '12345657898764;1234565477;COPRO ABC;TEST;Engie;C5;12/12/2012;31/12/2024'
    );
    dataElec = JSON.deserializeUntyped(strElec).toString();
    list<String> csvFileLinesElec2 = dataElec.split('\n');

    for (String s : csvFileLinesElec) {
      System.debug('value : ' + csvFileLinesElec);
    }

    String strHeaderGaz = 'SIRET PAYEUR;PCE;NOM DU SITE OU DE LA COPROPRIETE;SITE DE CONSOMMATION;NUMERO VOIE;VOIE;CODE POSTAL;COMMUNE;FOURNISSEUR ACTUEL;TARIF;PROFIL;CAR;DATE ECHEANCE CONTRAT';
    String strGaz = JSON.serialize(
      '97350271900147;19183646664896;DOMAINE DU PARC EQUILIBRE;TEST;37;RUE DE LA REPUBLIQUE;69330;MEYZIEU;Engie;T2;P014;487.86;31/12/2022'
    );
    
    String dataGaz = JSON.deserializeUntyped(strGaz).toString();
    list<String> csvFileLinesGaz = dataGaz.split('\n');

    Test.startTest();

    try {
      csv_pdeLoader_Controller.insertPdeElec(
          strHeaderElec,
          csvFileLinesElec,
          acc.id,
          false
      );
      csv_pdeLoader_Controller.insertPdeElec(
          strHeaderElec,
          csvFileLinesElec2,
          acc.id,
          false
      );
  } catch (AuraHandledException e) {
      System.debug('Exception dans le test : ' + e.getMessage());
      System.debug('Stack trace: ' + e.getStackTraceString());
  }
    csv_pdeLoader_Controller.insertPdeGaz(
      strHeaderGaz,
      csvFileLinesGaz,
      acc.id,
      false
    );

    PDE__c pdeGaz = [
      SELECT SiteConsommation__c, RecordType.Name
      FROM PDE__c
      WHERE EntiteJuridique__c = :acc.id AND TypePDE__c = 'Gaz'
      LIMIT 1
    ];
    PDE__c pdeElec = [
      SELECT SiteConsommation__c, RecordType.Name
      FROM PDE__c
      WHERE EntiteJuridique__c = :acc.id AND TypePDE__c = 'C4'
      LIMIT 1
    ];

    System.assertEquals(csv_pdeLoader_Controller.getPDEList(acc.Id).size(), 5);
    System.assertEquals(pdeGaz.SiteConsommation__c, 'TEST');
    System.assertEquals(pdeElec.SiteConsommation__c, 'COLLEGE DE VARADES');

    pdeElec.SiteConsommation__c = 'NEW VALUE';
    List<PDE__c> listPDEToUpdate = new List<PDE__c>();
    listPDEToUpdate.add(pdeElec);
    System.assertEquals(csv_pdeLoader_Controller.updatePDE(listPDEToUpdate),true);
    pdeElec = [
      SELECT SiteConsommation__c
      FROM PDE__c
      WHERE EntiteJuridique__c = :acc.id AND TypePDE__c = 'C4'
      LIMIT 1];
      System.assertEquals(pdeElec.SiteConsommation__c, 'NEW VALUE');
    List<RecordType> listPDERT = new List<RecordType>([SELECT Id FROM RecordType WHERE sObjectType='PDE__c']);   
    System.assertEquals(listPDERT.size(), csv_pdeLoader_Controller.getPDERecodTypeIds().values().size());
    Test.stopTest();
  }

  static testMethod void testfileElecEnergisme(){
    TestDataFactory.createAccountsWithOppsAndPointDenergie(1,1,1,1,1);
    Account acc = [SELECT Id,Name from Account LIMIT 1];
    Set<String> expected = new Set<String>();
    expected.add(acc.Name);
    Map<String,String> result = csv_pdeLoader_Controller.getPDEElecForEnergisme(acc.Id, false);
    Assert.areEqual(expected, result.keySet());
  }

  static testMethod void testfileGazEnergisme(){
    TestDataFactory.createAccountsWithOppsAndPointDenergie(1,1,1,1,1);
    Account acc = [SELECT Id,Name from Account LIMIT 1];
    Set<String> expected = new Set<String>();
    expected.add(acc.Name);
    Map<String,String> result = csv_pdeLoader_Controller.getPDEGazForEnergisme(acc.Id);
    Assert.areEqual(expected, result.keySet());
  }


  static testMethod void testfileElecEnergismeExcel(){
    TestDataFactory.createAccountsWithOppsAndPointDenergie(1,1,1,1,1);
    Account acc = [SELECT Id,Name from Account LIMIT 1];
    Set<String> expected = new Set<String>();
    expected.add(acc.Name);
    Map<String,String> result = csv_pdeLoader_Controller.getPDEElecForEnergismeExcel(acc.Id, 'AFGJGFFJH', 'bak', 'dev', 'mr' ,'deve@gmail.com', false);
    Assert.areEqual(expected, result.keySet());
  }

  static testMethod void testfileGazEnergismeExcel(){
    TestDataFactory.createAccountsWithOppsAndPointDenergie(1,1,1,1,1);
    Account acc = [SELECT Id,Name from Account LIMIT 1];
    Set<String> expected = new Set<String>();
    expected.add(acc.Name);
    Map<String,String> result = csv_pdeLoader_Controller.getPDEGazForEnergismeExcel(acc.Id,'bak deve', 'deve@gmail.com');
    Assert.areEqual(expected, result.keySet());
  }

  static testMethod void testgetSignataire(){
    TestDataFactory.createAccountsWithOppsAndPointDenergie(1,1,1,1,1);
    Account acc = [SELECT Id,Name from Account LIMIT 1];
    Set<String> expected = new Set<String>();
    expected.add(acc.Name);
    List<Contact> result = csv_pdeLoader_Controller.getSignataire(acc.Id);
    Assert.areNotEqual(null, result);
  }
    @isTest
    static void testValidDate() {
      String validDate = '01/01/2024';
      Boolean result = csv_pdeLoader_Controller.isValidDate(validDate);
      System.assertEquals(true, result, 'La date 01/01/2024 devrait être valide');
    }

    @isTest
    static void testInvalidDateFormat() {
      String invalidDateFormat = '2024/01/01';
      Boolean result = csv_pdeLoader_Controller.isValidDate(invalidDateFormat);
      System.assertEquals(false, result, 'Le format 2024/01/01 devrait être invalide');
    }

    @isTest
    static void testInvalidDate() {
        // Tester une date techniquement invalide (par exemple, 30/02/2024)
        String invalidDate = '30/02/2024';
        Boolean result = csv_pdeLoader_Controller.isValidDate(invalidDate);
        System.assertEquals(false, result, 'La date 30/02/2024 devrait être invalide');
    }


}