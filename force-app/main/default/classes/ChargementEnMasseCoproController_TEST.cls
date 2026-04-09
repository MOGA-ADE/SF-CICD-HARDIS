@isTest
public with sharing class ChargementEnMasseCoproController_TEST {
  @TestSetup
  static void createTestData() {
    Id syndicRecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Syndic'
      ]
      .get(0)
      .Id;

    Account syndic = new Account(
      Name = 'TestAccount545',
      Industry = 'Résidentiel',
      Siren__c = '123756789',
      Siret__c = '12341678901239',
      RecordTypeId = syndicRecordTypeId
    );
    insert syndic;
  }

  @isTest
  static void insertCoproSuccessTest() {
    Id syndicId = [
      SELECT Id
      FROM Account
      WHERE RecordType.DeveloperName = 'Syndic'
      LIMIT 1
    ]
    .Id;
    Contact contact = new Contact();
    contact.FirstName = 'GestionnaireCopro23131';
    contact.LastName = 'GestionnaireCopro11132';
    contact.Phone = '0711223344';
    contact.Email = 'GestionnaireCopro@activ7.com';
    contact.accountId = syndicId;
    insert contact;
    String strCopro = JSON.serialize('COPRO 1;12345678909871;123456789;22/11/2022;22/11/2022;Non;123;RUE TEST;69008;LYON;'+contact.Id);
    String dataCopro = JSON.deserializeUntyped(strCopro).toString();
    list<String> csvFileLinesCopro = dataCopro.split('\n');
    Test.startTest();
    String strHeaderCopro = 'NOM DE LA COPROPRIETE;SIRET;SIREN;DATE DE RENDEZ-VOUS;DATE DE RECEPTION DE L\'OFFRE;ASAP;NUMERO VOIE;VOIE;CODE POSTAL;COMMUNE;IDENTIFIANT DU CONTACT';
    ChargementEnMasseCoproController.insertCopro(strHeaderCopro,csvFileLinesCopro, syndicId);
    Account insertedCopro = [
      SELECT
        Siret__c,
        Siren__c,
        Numero_voie__c,
        voie__c,
        Code_Postal__c,
        Ville__c
      FROM Account
      WHERE Name = 'COPRO 1'
    ];
    Test.stopTest();
    System.assertEquals('12345678909871', insertedCopro.Siret__c);
    System.assertEquals('123456789', insertedCopro.Siren__c);
    System.assertEquals('123', insertedCopro.Numero_voie__c);
    System.assertEquals('RUE TEST', insertedCopro.voie__c);
    System.assertEquals('69008', insertedCopro.Code_Postal__c);
    System.assertEquals('LYON', insertedCopro.Ville__c);
    System.assertEquals(
      contact.Id,
      [
        SELECT ContactId
        FROM AccountContactRelation
        WHERE AccountId = :insertedCopro.Id
      ][0]
      .ContactId
    );
  }
  
  @isTest
  static void insertCoproFailTest() {
    Id syndicId = [
      SELECT Id
      FROM Account
      WHERE RecordType.DeveloperName = 'Syndic'
      LIMIT 1
    ]
    .Id;
    String strCopro = JSON.serialize(
      'COPRO 1;12345678909876;123456789;;22/11/2022;Non;123;RUE TEST;69008;LYON;' +
      contact.Id
    );
    String dataCopro = JSON.deserializeUntyped(strCopro).toString();
    String strHeaderCopro = 'NOM DE LA COPROPRIETE;SIREN;SIRET;DATE DE RENDEZ-VOUS;DATE DE RECEPTION DE L\'OFFRE;ASAP;NUMERO VOIE;VOIE;CODE POSTAL;COMMUNE;IDENTIFIANT DU CONTACT';
    list<String> csvFileLinesCopro = dataCopro.split('\n');
    Test.startTest();
    try {
      ChargementEnMasseCoproController.insertCopro(strHeaderCopro,csvFileLinesCopro, syndicId);
    } catch (Exception e) {
      System.assertEquals(
        e.getMessage(),
        'Script-thrown exception'
      );
    }
    Test.stopTest();
  }

  @isTest
  static void retrieveCoprosTest(){
    Id coproRecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Copropriete'
        LIMIT 1
      ].Id;

    Id syndicId = [
      SELECT Id
      FROM Account
      WHERE RecordType.DeveloperName = 'Syndic'
      LIMIT 1
    ].Id;

    Account copro = new Account(Name = 'Copro',
    Industry = 'Copro',
    Siren__c = '123758559',
    Siret__c = '12341655901239',
    Syndic__c= syndicId,
    RecordTypeId = coproRecordTypeId);
    insert copro;
    List<Account> listCopro = ChargementEnMasseCoproController.retrieveCopros(syndicId);
    System.assertEquals(listCopro.get(0).Name, copro.Name);
  }
}