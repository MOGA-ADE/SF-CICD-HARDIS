@isTest
public class TestDataFactory {
  public static List<Account> createAccountsWithOppsAndPointDenergie(Integer numAccts, Integer numOppsPerAcct, Integer numPdesGazPerAcct, Integer numPdesElec1PerAcct, Integer numPdesElec2PerAcct) {
    Id EntiteJuridiquePrincipaleRecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Account_EntiteJuridiquePrincipale'
      ]
      .get(0)
      .Id;
    List<Account> accts = new List<Account>();

    for (Integer i = 0; i < numAccts; i++) {
      Account a = new Account(
        Name = 'TestAccount' + i,
        Industry = 'Résidentiel',
        Siren__c = '12345678' + i,
        Siret__c = '1234567890123' + i,
        RecordTypeId = EntiteJuridiquePrincipaleRecordTypeId
      );
      accts.add(a);
    }
    insert accts;

    Pricebook2 priceBook = new Pricebook2(
      Name = 'AllianceDesEnergies',
      IsActive = true
    );
    insert priceBook;

    List<Product2> products = new List<Product2>();
    Product2 p1 = new Product2(Name = 'ELEC', IsActive = true);
    Product2 p2 = new Product2(Name = 'GAZ', IsActive = true);
    products.add(p1);
    products.add(p2);
    insert products;

    Id standardPricebookId = Test.getStandardPricebookId();
    List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
    priceBookEntries.add(
      new PricebookEntry(
        IsActive = true,
        UnitPrice = 1.00,
        Product2Id = p1.Id,
        Pricebook2Id = standardPricebookId
      )
    );
    priceBookEntries.add(
      new PricebookEntry(
        IsActive = true,
        UnitPrice = 1.00,
        Product2Id = p2.Id,
        Pricebook2Id = standardPricebookId
      )
    );
    priceBookEntries.add(
      new PricebookEntry(
        IsActive = true,
        UnitPrice = 1.00,
        Product2Id = p1.Id,
        Pricebook2Id = priceBook.Id
      )
    );
    priceBookEntries.add(
      new PricebookEntry(
        IsActive = true,
        UnitPrice = 1.00,
        Product2Id = p2.Id,
        Pricebook2Id = priceBook.Id
      )
    );
    insert priceBookEntries;

    Id salesRecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Opportunity_Sales'
      ]
      .get(0)
      .Id;
    List<Opportunity> opps = new List<Opportunity>();
    for (Integer j = 0; j < numAccts; j++) {
      Account acct = accts[j];
      // For each account just inserted, add opportunities
      for (Integer k = 0; k < numOppsPerAcct; k++) {
        opps.add(
          new Opportunity(
            Name = acct.Name + ' Opportunity ' + k,
            StageName = 'Conditionné',
            CloseDate = System.today().addMonths(1),
            Liste_Fournisseurs__c = 'Alterna;Antargaz',
            TemplateCotation__c = 'C5',
            SectionSituationActuelle__c = true,
            AccountId = acct.Id,
            responsableCotation__c = UserInfo.getUserId(),
            RecordTypeId = salesRecordTypeId
          )
        );
      }
    }
    // Insert all opportunities for all accounts.
    insert opps;

    Map<Id, Opportunity> mapAccountOpportunity = new Map<Id, Opportunity>();

    for (Opportunity opp : opps) {
      mapAccountOpportunity.put(opp.AccountId, opp);
    }

    Id gazRecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'PDE_Gaz'
      ]
      .get(0)
      .Id;
    Id elec1RecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Elec_C1C2'
      ]
      .get(0)
      .Id;
    Id elec2RecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'PDE_ElecC5'
      ]
      .get(0)
      .Id;
    List<PDE__c> pdes = new List<PDE__c>();
    for (Integer l = 0; l < numAccts; l++) {
      Account acct = accts[l];
      // For each account just inserted, add point d'energies
      for (Integer m = 0; m < numPdesGazPerAcct; m++) {
        pdes.add(
          new PDE__c(
            Name = acct.Name + ' PDEGaz ' + m,
            SiteConsommation__c = 'TEST ',
            NumeroVoie__c = '90',
            voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            CARGaz__c = 1234,
            DateEcheance__c = System.today().addMonths(1),
            PCE_Refonte__c = '123456789' + m,
            ReferencePointEnergie_Refonte__c = '123456789' + m,
            EntiteJuridique__c = acct.Id,
            RecordTypeId = gazRecordTypeId,
            FTA__c = 'HTA - PF - CU',
            Calendrier_fournisseur__c = 'Base'
          )
        );
      }
      for (Integer n = 0; n < numPdesElec1PerAcct; n++) {
        pdes.add(
          new PDE__c(
            Name = acct.Name + ' PDEElec1 ' + n,
            SiteConsommation__c = 'TEST ',
            NumeroVoie__c = '91',
            voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            Consommation_Annuelle_de_R_f_rence_Elec__c = 1234,
            DateEcheance__c = System.today().addMonths(1),
            Segment__c = 'C1',
            ReferencePointEnergie_Refonte__c = '12345678' + n,
            EntiteJuridique__c = acct.Id,
            RecordTypeId = elec1RecordTypeId,
            FTA__c = 'BT <= 36 kVA - CU',
            Calendrier_fournisseur__c = 'Base'
          )
        );
      }
      for (Integer o = 0; o < numPdesElec2PerAcct; o++) {
        pdes.add(
          new PDE__c(
            Name = acct.Name + ' PDEElec2 ' + o,
            SiteConsommation__c = 'TEST ',
            NumeroVoie__c = '84',
            voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            Consommation_Annuelle_de_R_f_rence_Elec__c = 1234,
            DateEcheance__c = System.today().addMonths(1),
            Segment__c = 'C5',
            ReferencePointEnergie_Refonte__c = '1234567' + o,
            EntiteJuridique__c = acct.Id,
            RecordTypeId = elec2RecordTypeId,
            FTA__c = 'BT <= 36Kva - CU 4 postes',
            Calendrier_fournisseur__c = 'Base'
          )
        );
      }
    }
    // Insert all point d'energie for all accounts.
    insert pdes;
    //Insert All pde to all opportunities
    List<OpportunityPDERelation__c> listOPR = new List<OpportunityPDERelation__c>();
    for (PDE__c pde : pdes) {
      listOPR.add(
        new OpportunityPDERelation__c(
          Opportunity__c = mapAccountOpportunity.get(pde.EntiteJuridique__c).Id,
          PDE__c = pde.Id
        )
      );
    }

    insert listOPR;
    List<Quote> quotes = new List<Quote>();
    Quote q1 = new Quote(
      Name = 'QUOTE 1',
      Pricebook2Id = priceBook.Id,
      OpportunityId = opps.get(0).Id,
      Date_de_fin_de_contrat__c = Date.today()
    );
    Quote q2 = new Quote(
      Name = 'QUOTE 2',
      Pricebook2Id = priceBook.Id,
      OpportunityId = opps.get(0).Id,
      Date_de_fin_de_contrat__c = Date.today()
    );
    quotes.add(q1);
    quotes.add(q2);
    insert quotes;

    List<QuoteLineItem> qlis = new List<QuoteLineItem>();
    QuoteLineItem qli1 = new QuoteLineItem(
      Product2Id = products.get(0).Id,
      PDE__c = pdes.get(1).Id,
      QuoteId = quotes.get(0).Id,
      PricebookEntryId = priceBookEntries.get(2).Id,
      Quantity = 1,
      UnitPrice = 1,
      DebutDeFourniture__c = Date.today(),
      Nouvelle_Echeance__c = Date.today(),
      DureeEngagement__c = 24,
      Budget_TTC__c = 2,
      CARGaz__c = 1234,
      CAR_New__c = 1234,
      TECH_CalendrierFournisseur__c = pdes.get(1).Calendrier_fournisseur__c
    );
    QuoteLineItem qli2 = new QuoteLineItem(
      Product2Id = products.get(1).Id,
      PDE__c = pdes.get(0).Id,
      QuoteId = quotes.get(1).Id,
      PricebookEntryId = priceBookEntries.get(3).Id,
      Quantity = 1,
      UnitPrice = 1,
      DebutDeFourniture__c = Date.today(),
      Nouvelle_Echeance__c = Date.today(),
      DureeEngagement__c = 24,
      Budget_TTC__c = 2,
      CARGaz__c = 1234,
      CAR_New__c = 1234,
      TECH_CalendrierFournisseur__c = pdes.get(0).Calendrier_fournisseur__c
    );
    QuoteLineItem qli3 = new QuoteLineItem(
      Product2Id = products.get(0).Id,
      PDE__c = pdes.get(2).Id,
      QuoteId = quotes.get(0).Id,
      PricebookEntryId = priceBookEntries.get(2).Id,
      Quantity = 1,
      UnitPrice = 1,
      DebutDeFourniture__c = Date.today(),
      Nouvelle_Echeance__c = Date.today(),
      DureeEngagement__c = 24,
      Budget_TTC__c = 2,
      CARGaz__c = 1234,
      CAR_New__c = 1234,
      TECH_CalendrierFournisseur__c = pdes.get(2).Calendrier_fournisseur__c
    );
    qlis.add(qli1);
    qlis.add(qli2);
    qlis.add(qli3);
    insert qlis;

    List<Contact> cons = new List<Contact>();
    for (Integer j = 0; j < numAccts; j++) {
      Account acct = accts[j];
      Contact con1 = new Contact(
        LastName = 'Signataire1',
        FirstName = 'Opportunity',
        Phone = '0611223344',
        Email = 'contact1@test.com',
        accountId = acct.id
      );

      Contact con2 = new Contact(
        LastName = 'Signataire2',
        FirstName = 'Opportunity',
        Phone = '0711223344',
        Email = 'contact2@test.com',
        accountId = acct.id
      );
      cons.add(con1);
      cons.add(con2);
    }
    insert cons;

    List<OpportunityContactRole> oppCTs = new List<OpportunityContactRole>();
    OpportunityContactRole oppCT1 = new OpportunityContactRole(
      ContactId = cons.get(0).Id,
      OpportunityId = opps.get(0).Id,
      Role = 'Signataire'
    );

    OpportunityContactRole oppCT2 = new OpportunityContactRole(
      ContactId = cons.get(0).Id,
      OpportunityId = opps.get(0).Id,
      Role = 'Signataire'
    );
    oppCTs.add(oppCT1);
    oppCTs.add(oppCT2);
    insert oppCTs;

    return accts;
  }

  public static List<Account> createSyndicsWithCoprosAndPointDenergie(Integer numSyndics, Integer numCoproPerSyndic, Integer numPdesGazPerCopro, Integer numPdesElecPerCopro) {
    Id syndicRecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Syndic'
      ]
      .get(0)
      .Id;
    Id CoproprieteRecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Copropriete'
      ]
      .get(0)
      .Id;

    List<Account> listAccount = new List<Account>();

    for (Integer i = 0; i < numSyndics; i++) {
      Account a = new Account(
        Name = 'TestAccount' + i,
        Industry = 'Résidentiel',
        Siren__c = '12345678' + i,
        Siret__c = '1234567890123' + i,
        RecordTypeId = syndicRecordTypeId
      );
      listAccount.add(a);
    }
    insert listAccount;

    List<Account> listCopro = new List<Account>();
    for (Integer j = 0; j < numSyndics; j++) {
      Account acct = listAccount[j];
      // For each Syndic insert copro
      for (Integer k = 0; k < numCoproPerSyndic; k++) {
        listCopro.add(
          new Account(
            Name = 'TestAccount' + k,
            Industry = 'Résidentiel',
            Siren__c = '12345674' + k,
            Siret__c = '1234567890125' + k,
            syndic__c = acct.Id,
            RecordTypeId = CoproprieteRecordTypeId
          )
        );
      }
    }
    insert listCopro;

    Id gazRecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'PDE_Gaz'
      ]
      .get(0)
      .Id;
    Id elec1RecordTypeId = [
        SELECT Id
        FROM RecordType
        WHERE DeveloperName = 'Elec_C1C2'
      ]
      .get(0)
      .Id;
    List<PDE__c> pdes = new List<PDE__c>();
    for (Integer l = 0; l < listCopro.size(); l++) {
      // For each copro just inserted, add point d'energies
      for (Integer m = 0; m < numPdesGazPerCopro; m++) {
        pdes.add(
          new PDE__c(
            Name = listCopro.get(0).Name + ' PDEGaz ' + m,
            SiteConsommation__c = 'TEST ',
            NumeroVoie__c = '90',
            voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            DateEcheance__c = System.today().addMonths(1),
            PCE_Refonte__c = '123457789' + m,
            ReferencePointEnergie_Refonte__c = '123456789' + m,
            EntiteJuridique__c = listCopro.get(l).Id,
            RecordTypeId = gazRecordTypeId
          )
        );
      }
      for (Integer n = 0; n < numPdesElecPerCopro; n++) {
        pdes.add(
          new PDE__c(
            Name = listCopro.get(0).Name + ' PDEElec1 ' + n,
            SiteConsommation__c = 'TEST ',
            NumeroVoie__c = '91',
            voie__c = 'Rue de la Villette',
            Code_Postal__c = '69003',
            Ville__c = 'Lyon',
            DateEcheance__c = System.today().addMonths(1),
            Segment__c = 'C1',
            ReferencePointEnergie_Refonte__c = '12345678' + n,
            EntiteJuridique__c = listCopro.get(l).Id,
            RecordTypeId = elec1RecordTypeId
          )
        );
      }
    }
    // Insert all point d'energie for all copros.
    insert pdes;
    return listAccount;
  }

  public static void createPriceBooks(){
    Pricebook2 priceBook = new Pricebook2(Name = 'AllianceDesEnergies',IsActive = true);
    insert priceBook;

    List<Product2> products = new List<Product2>();
    Product2 p1 = new Product2(Name = 'ELEC', IsActive = true);
    Product2 p2 = new Product2(Name = 'GAZ', IsActive = true);
    products.add(p1);
    products.add(p2);
    insert products;

    Id standardPricebookId = Test.getStandardPricebookId();
    List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
    priceBookEntries.add(
      new PricebookEntry(
        IsActive = true,
        UnitPrice = 1.00,
        Product2Id = p1.Id,
        Pricebook2Id = standardPricebookId
      )
    );
    priceBookEntries.add(
      new PricebookEntry(
        IsActive = true,
        UnitPrice = 1.00,
        Product2Id = p2.Id,
        Pricebook2Id = standardPricebookId
      )
    );
    priceBookEntries.add(
      new PricebookEntry(
        IsActive = true,
        UnitPrice = 1.00,
        Product2Id = p1.Id,
        Pricebook2Id = priceBook.Id
      )
    );
    priceBookEntries.add(
      new PricebookEntry(
        IsActive = true,
        UnitPrice = 1.00,
        Product2Id = p2.Id,
        Pricebook2Id = priceBook.Id
      )
    );
    insert priceBookEntries;
  }

  public static Account createDataForComparatifGaz() {

    // Create Account
    Id EntiteJuridiquePrincipaleRecordTypeId = [ SELECT Id FROM RecordType WHERE DeveloperName = 'Account_EntiteJuridiquePrincipale'].get(0).Id;
    Account a = new Account(Name = 'TestAccountGaz', Industry = 'Résidentiel', Siren__c = '12345678', Siret__c = '1234567890122', RecordTypeId = EntiteJuridiquePrincipaleRecordTypeId);
    insert a;

    // Create PriceBook
    Pricebook2 priceBook = new Pricebook2(Name = 'AllianceDesEnergies', IsActive = true);
    insert priceBook;

    // Create Product Gaz
    Product2 p2 = new Product2(Name = 'GAZ', IsActive = true);
    insert p2;

    // Create priceBookEntries
    Id standardPricebookId = Test.getStandardPricebookId();
    List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
    priceBookEntries.add(new PricebookEntry(IsActive = true, UnitPrice = 1.00, Product2Id = p2.Id, Pricebook2Id = standardPricebookId));
    priceBookEntries.add(new PricebookEntry(IsActive = true, UnitPrice = 1.00, Product2Id = p2.Id, Pricebook2Id = priceBook.Id));
    insert priceBookEntries;

    // Create Contact
    Contact contact = new Contact(LastName = 'Signataire1', FirstName = 'Opportunity', Phone = '0611223344', Email = 'contact1@test.com', AccountId = a.id);
    insert contact;

    // Create Demande de cotation
    Demande_Cotation__c dc = new Demande_Cotation__c();
    dc.Name = a.Name;
    dc.Account__c = a.Id;
    dc.Date_RDV_Client__c = null;
    dc.Signataire__c = contact.Id;
    dc.Charge_affaire__c = UserInfo.getUserId();
    dc.Infos_complementaires__c = '';
    dc.Statut__c = 'En attente de traitement';
    dc.Date_demande_cotation__c = Datetime.now();
    insert dc;

    // Create Opp
    Id oppRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_Gaz'].get(0).Id;
    Opportunity opp = new Opportunity(AccountId= a.Id, Name = a.Name + ' Opportunity ', StageName = 'Conditionné', CloseDate = System.today().addMonths(1), Liste_Fournisseurs__c = 'Alterna;Antargaz', TemplateCotation__c = 'GAZ', SectionSituationActuelle__c = true, responsableCotation__c = UserInfo.getUserId(), RecordTypeId = oppRecordTypeId,Demande_Cotation__c = dc.Id);
    insert opp;

    // Create PDEs
    Id gazRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_Gaz'].get(0).Id;
    List<PDE__c> pdes = new List<PDE__c>();
    pdes.add(new PDE__c(Name = a.Name + ' PDEGaz', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '1234567890', ReferencePointEnergie_Refonte__c = '1234567890', EntiteJuridique__c = a.Id, RecordTypeId = gazRecordTypeId, Tarif__c = 'T1', Profil__c = 'P011'));
    pdes.add(new PDE__c(Name = a.Name + ' PDEGaz', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '1234567891', ReferencePointEnergie_Refonte__c = '1234567891', EntiteJuridique__c = a.Id, RecordTypeId = gazRecordTypeId, Tarif__c = 'T2', Profil__c = 'P011'));
    pdes.add(new PDE__c(Name = a.Name + ' PDEGaz', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '1234567892', ReferencePointEnergie_Refonte__c = '1234567892', EntiteJuridique__c = a.Id, RecordTypeId = gazRecordTypeId, Tarif__c = 'T3', Profil__c = 'P011'));
    pdes.add(new PDE__c(Name = a.Name + ' PDEGaz', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '1234567893', ReferencePointEnergie_Refonte__c = '1234567893', EntiteJuridique__c = a.Id, RecordTypeId = gazRecordTypeId, Tarif__c = 'T4', Profil__c = 'P011'));
    insert pdes;

    // Create OPRs
    List<OpportunityPDERelation__c> listOPR = new List<OpportunityPDERelation__c>();
    for (PDE__c pde : pdes) {
      listOPR.add(new OpportunityPDERelation__c(Opportunity__c = opp.Id, PDE__c = pde.Id));
    }
    insert listOPR;

    // Create Quotes
    List<Quote> quotes = new List<Quote>();
    quotes.add(new Quote(Name = 'Quote Engie', Fournisseur__c = 'Engie', Pricebook2Id = priceBook.Id, OpportunityId = opp.Id, Date_de_fin_de_contrat__c = Date.today()));
    quotes.add(new Quote(Name = 'Quote Situation Actuelle', Fournisseur__c = 'Situation Actuelle', Pricebook2Id = priceBook.Id, OpportunityId = opp.Id, Date_de_fin_de_contrat__c = Date.today()));
    insert quotes;

    // Create QLIs
    List<QuoteLineItem> qlis = new List<QuoteLineItem>();
    // QLI Engie
    for (PDE__c pde : pdes) {
      qlis.add(new QuoteLineItem(Product2Id = p2.Id, PDE__c = pde.Id, QuoteId = quotes.get(0).Id, Opportunit__c = opp.Id, PricebookEntryId = priceBookEntries.get(1).Id, Quantity = 1, UnitPrice = 1, DebutDeFourniture__c = Date.today(), Nouvelle_Echeance__c = Date.today(), DureeEngagement__c = 24, Budget_TTC__c = 2, CARGaz__c = 1234, CAR_New__c = 1234));
    }
    // QLI Situation Actuelle
    for (PDE__c pde : pdes) {
      qlis.add(new QuoteLineItem(Product2Id = p2.Id, PDE__c = pde.Id, QuoteId = quotes.get(1).Id, Opportunit__c = opp.Id, PricebookEntryId = priceBookEntries.get(1).Id, Quantity = 1, UnitPrice = 1, DebutDeFourniture__c = Date.today(), Nouvelle_Echeance__c = Date.today(), DureeEngagement__c = 24, Budget_TTC__c = 2, CARGaz__c = 1234, CAR_New__c = 1234));
    }
    insert qlis;


    // Create OCR
    OpportunityContactRole ocr = new OpportunityContactRole(ContactId = contact.Id,  OpportunityId = opp.Id, Role = 'Signataire');
    insert ocr;

    return a;
  }

  public static Account createDataForComparatifElec() {

    // Create Account
    Id EntiteJuridiquePrincipaleRecordTypeId = [ SELECT Id FROM RecordType WHERE DeveloperName = 'Account_EntiteJuridiquePrincipale'].get(0).Id;
    Account a = new Account(Name = 'TestAccount', Industry = 'Résidentiel', Siren__c = '12345678', Siret__c = '1234567890123', RecordTypeId = EntiteJuridiquePrincipaleRecordTypeId);
    insert a;

    // Create PriceBook
    Pricebook2 priceBook = new Pricebook2(Name = 'AllianceDesEnergies', IsActive = true);
    insert priceBook;

    // Create Product Elec
    Product2 p2 = new Product2(Name = 'ELEC', IsActive = true);
    insert p2;

    // Create priceBookEntries
    Id standardPricebookId = Test.getStandardPricebookId();
    List<PricebookEntry> priceBookEntries = new List<PricebookEntry>();
    priceBookEntries.add(new PricebookEntry(IsActive = true, UnitPrice = 1.00, Product2Id = p2.Id, Pricebook2Id = standardPricebookId));
    priceBookEntries.add(new PricebookEntry(IsActive = true, UnitPrice = 1.00, Product2Id = p2.Id, Pricebook2Id = priceBook.Id));
    insert priceBookEntries;

    // Create Contact
    Contact contact = new Contact(LastName = 'Signataire2', FirstName = 'Opportunity', Phone = '0711223345', Email = 'contact2@test.com', AccountId = a.id);
    insert contact;

    // Create Demande de cotation
    Demande_Cotation__c dc = new Demande_Cotation__c();
    dc.Name = a.Name;
    dc.Account__c = a.Id;
    dc.Date_RDV_Client__c = null;
    dc.Signataire__c = contact.Id;
    dc.Charge_affaire__c = UserInfo.getUserId();
    dc.Infos_complementaires__c = '';
    dc.Statut__c = 'En attente de traitement';
    dc.Date_demande_cotation__c = Datetime.now();
    insert dc;

    // Create Opp
    Id oppRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_C5'].get(0).Id;
    Opportunity opp = new Opportunity(AccountId= a.Id, Name = a.Name + ' Opportunity ', StageName = 'Conditionné', CloseDate = System.today().addMonths(1), Liste_Fournisseurs__c = 'Engie', TemplateCotation__c = 'C5', SectionSituationActuelle__c = true, responsableCotation__c = UserInfo.getUserId(), RecordTypeId = oppRecordTypeId, Demande_Cotation__c = dc.Id);
    insert opp;

    // Create PDEs
    Id c1c2RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Elec_C1C2'].get(0).Id;
    Id c4RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Elec_C3_C4'].get(0).Id;
    Id c5RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_ElecC5'].get(0).Id;
    List<PDE__c> pdes = new List<PDE__c>();
    pdes.add(new PDE__c(Name = a.Name + ' PDEC1C2', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678900', ReferencePointEnergie_Refonte__c = '12345678900', EntiteJuridique__c = a.Id, RecordTypeId = c1c2RecordTypeId, FTA__c = 'HTA - PF - CU', Segment__c = 'C1'));
    pdes.add(new PDE__c(Name = a.Name + ' PDEC4', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678911', ReferencePointEnergie_Refonte__c = '12345678911', EntiteJuridique__c = a.Id, RecordTypeId = c4RecordTypeId, FTA__c = 'BT > 36 kVA - CU', Segment__c = 'C4'));
    pdes.add(new PDE__c(Name = a.Name + ' PDEC5Base', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678922', ReferencePointEnergie_Refonte__c = '12345678922', EntiteJuridique__c = a.Id, RecordTypeId = c5RecordTypeId, FTA__c = 'BT <= 36 kVA - MU', Segment__c = 'C5'));
    pdes.add(new PDE__c(Name = a.Name + ' PDEC54Postes', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678933', ReferencePointEnergie_Refonte__c = '12345678933', EntiteJuridique__c = a.Id, RecordTypeId = c5RecordTypeId, FTA__c = 'BT <= 36Kva - CU 4 postes', Segment__c = 'C5'));
    insert pdes;

    // Create OPRs
    List<OpportunityPDERelation__c> listOPR = new List<OpportunityPDERelation__c>();
    for (PDE__c pde : pdes) {
      listOPR.add(new OpportunityPDERelation__c(Opportunity__c = opp.Id, PDE__c = pde.Id));
    }
    insert listOPR;

    // Create Quotes
    List<Quote> quotes = new List<Quote>();
    quotes.add(new Quote(Name = 'Quote Engie', Fournisseur__c = 'Engie', Pricebook2Id = priceBook.Id, OpportunityId = opp.Id, Date_de_fin_de_contrat__c = Date.today()));
    quotes.add(new Quote(Name = 'Quote Situation Actuelle', Fournisseur__c = 'Situation Actuelle', Pricebook2Id = priceBook.Id, OpportunityId = opp.Id, Date_de_fin_de_contrat__c = Date.today()));
    insert quotes;

    // Create QLIs
    List<QuoteLineItem> qlis = new List<QuoteLineItem>();
    // QLI Engie
    for (PDE__c pde : pdes) {
      qlis.add(new QuoteLineItem(Product2Id = p2.Id, PDE__c = pde.Id, QuoteId = quotes.get(0).Id, Opportunit__c = opp.Id, PricebookEntryId = priceBookEntries.get(1).Id, Quantity = 1, UnitPrice = 1, DebutDeFourniture__c = Date.today(), Nouvelle_Echeance__c = Date.today(), DureeEngagement__c = 24, Budget_TTC__c = 2, CARGaz__c = 1234, CAR_New__c = 1234));
    }
    // QLI Situation Actuelle
    for (PDE__c pde : pdes) {
      qlis.add(new QuoteLineItem(Product2Id = p2.Id, PDE__c = pde.Id, QuoteId = quotes.get(1).Id, Opportunit__c = opp.Id, PricebookEntryId = priceBookEntries.get(1).Id, Quantity = 1, UnitPrice = 1, DebutDeFourniture__c = Date.today(), Nouvelle_Echeance__c = Date.today(), DureeEngagement__c = 24, Budget_TTC__c = 2, CARGaz__c = 1234, CAR_New__c = 1234));
    }
    insert qlis;

    // Create OCR
    OpportunityContactRole ocr = new OpportunityContactRole(ContactId = contact.Id,  OpportunityId = opp.Id, Role = 'Signataire');
    insert ocr;

    return a;
  }
}