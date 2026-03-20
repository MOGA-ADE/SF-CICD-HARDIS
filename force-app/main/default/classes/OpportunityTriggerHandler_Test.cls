@isTest
public with sharing class OpportunityTriggerHandler_Test {
  @isTest(SeeAllData=false)
  private static void structureTest() {
    Test.startTest();
    String triggerContext = String.valueOf(
      TriggerHandler.TriggerContext.BEFORE_INSERT
    );
    TriggerHandler.TriggerHandlerException handlerException = new TriggerHandler.TriggerHandlerException();
    OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
    TriggerHandler.LoopCount count = new TriggerHandler.LoopCount();
    count = new TriggerHandler.LoopCount(2);
    count.increment();
    count.exceeded();
    count.getMax();
    count.setMax(3);
    handler.beforeInsert();
    handler.beforeUpdate();
    handler.beforeDelete();
    handler.afterInsert();
    handler.afterDelete();
    handler.afterUndelete();
    OpportunityTriggerHandler.resetBypass();
    handler.setMaxLoopCount(3);
    handler.clearMaxLoopCount();
    OpportunityTriggerHandler.isBypassed('OpportunityTriggerHandler');
    OpportunityTriggerHandler.clearAllBypasses();
    Test.stopTest();
  }

  @isTest(SeeAllData=false)
  private static void afterUpdate() {
    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    //Create Pricebook
    Pricebook2 pricebook = new Pricebook2(
      Name = 'AllianceDesEnergies',
      IsActive = true
    );
    insert pricebook;

    //Create Product
    Product2 productElec = new Product2(
      Name = 'ELEC',
      Family = '',
      IsActive = true
    );
    insert productElec;
    Product2 productGaz = new Product2(
      Name = 'GAZ',
      Family = '',
      IsActive = true
    );
    insert productGaz;

    //Create PricebookEntry
    PricebookEntry pbeElecStandard = new PricebookEntry(
      Pricebook2Id = standardPricebook.Id,
      Product2Id = productElec.Id,
      UnitPrice = 0,
      IsActive = true
    );
    insert pbeElecStandard;
    PricebookEntry pbeElec = new PricebookEntry(
      Pricebook2Id = pricebook.Id,
      Product2Id = productElec.Id,
      UnitPrice = 0,
      IsActive = true
    );
    insert pbeElec;

    PricebookEntry pbeGazStandard = new PricebookEntry(
      Pricebook2Id = standardPricebook.Id,
      Product2Id = productGaz.Id,
      UnitPrice = 0,
      IsActive = true
    );
    insert pbeGazStandard;
    PricebookEntry pbeGaz = new PricebookEntry(
      Pricebook2Id = pricebook.Id,
      Product2Id = productGaz.Id,
      UnitPrice = 0,
      IsActive = true
    );
    insert pbeGaz;

    Account account = new Account();
    account.Name = 'Name';
    account.Siren__c = '123456789';
    account.Siret__c = '12345678912345';
    insert account;

    Contact contact = new Contact();
    contact.AccountId = account.Id;
    contact.FirstName = 'FirstName';
    contact.LastName = 'LastName';
    contact.Email = 'email@activ7.com';
    insert contact;

    Opportunity opportunity = new Opportunity();
    opportunity.Name = 'Opportunity Name';
    opportunity.AccountId = account.Id;
    opportunity.StageName = 'Attente de validation';
    opportunity.CloseDate = Date.today().addDays(30);
    opportunity.TemplateCotation__c = 'C1/C2/C3/C4';
    insert opportunity;

    PDE__c pde = new PDE__c();
    pde.Name = 'PDE1';
    pde.EntiteJuridique__c = account.Id;
    pde.fournisseur__c = 'Engie';
    pde.DateEcheance__c = Date.today();
    insert pde;

    OpportunityPDERelation__c opr = new OpportunityPDERelation__c();
    opr.pde__c = pde.Id;
    opr.opportunity__c = Opportunity.Id;
    insert opr;

    opportunity.Liste_Fournisseurs__c = 'Axpo;Edenkia;EDF Entreprises';
    opportunity.SectionSituationActuelle__c = true;
    opportunity.SectionPrixConstates__c = true;
    opportunity.SectionPropositionRenouvellement__c = true;
    update opportunity;
  }
}