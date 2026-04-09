@isTest
private class VFC004_EtudeComparative_TEST {
  @isTest
  static void TestVFC004_EtudeComparative() {
    // Test data setup
    // Create one account with two opportunities and three point d'énergies by calling a utility method
    Account[] accts = TestDataFactory.createAccountsWithOppsAndPointDenergie(1,2,1,1,1);
    // Perform test
    Opportunity obj = [
        SELECT
          Id,
          AccountId,
          OwnerId,
          SectionSituationActuelle__c
        FROM Opportunity
        WHERE AccountId = :accts.get(0).Id
      ]
      .get(0);
    Id quoteId = [
      SELECT id, opportunity.Name
      FROM Quote
      WHERE OpportunityId = :obj.Id
      LIMIT 1
    ]
    .Id;
    PageReference pageRef = Page.Etude_ComparativeNEW;
    Test.setCurrentPage(pageRef);
    ApexPages.StandardController sc = new ApexPages.StandardController(obj);
    VFC004_EtudeComparative testEtudeComparative_C5 = new VFC004_EtudeComparative(
      sc
    );
    List<WrapPde> listWrapPDE = new List<WrapPde>();
    for (OpportunityPDERelation__c pde : [
      SELECT
        PDE__r.Adresse_de_consommation__c,
        PDE__r.CARGaz__c,
        PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c,
        PDE__r.Code_Postal__c,
        PDE__r.Conso_Base__c,
        PDE__r.Conso_HCE__c,
        PDE__r.Conso_HCH__c,
        PDE__r.Conso_HPE__c,
        PDE__r.Conso_HPH__c,
        PDE__r.Conso_Pointe__c,
        PDE__r.ConsoHC__c,
        PDE__r.ConsoHP__c,
        PDE__r.DateEcheance__c,
        PDE__r.EntiteJuridique__r.Siret__c,
        PDE__r.fournisseur__c,
        PDE__r.FTA__c,
        PDE__r.NumeroVoie__c,
        PDE__r.PCE_Refonte__c,
        PDE__r.Profil__c,
        PDE__r.Puissance_souscrite__c,
        PDE__r.RecordType.DeveloperName,
        PDE__r.ReferencePointEnergie_Refonte__c,
        PDE__r.Segment__c,
        PDE__r.Siret_payeur__c,
        PDE__r.SiteConsommation__c,
        PDE__r.Tarif__c,
        PDE__r.TECH_C5_4Postes__c,
        PDE__r.Ville__c,
        PDE__r.voie__c
      FROM OpportunityPDERelation__c
    ]) {
      listWrapPDE.add(new WrapPde(pde));
    }
    listWrapPDE.sort();
  }
}