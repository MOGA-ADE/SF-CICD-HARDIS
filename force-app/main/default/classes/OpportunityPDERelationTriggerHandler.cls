public with sharing class OpportunityPDERelationTriggerHandler extends TriggerHandler {
  private static final String CLASS_NAME = OpportunityPDERelationTriggerHandler.class
    .getName();

  public override void afterInsert() {
    //On ne garde que les opportunités qui ont au moins un devis
    Map<Id, OpportunityPDERelation__c> mapOPRLigneDevis = new Map<Id, OpportunityPDERelation__c>(
      [
        SELECT
          Opportunity__c,
          Opportunity__r.SectionPrixConstates__c,
          Opportunity__r.SectionPropositionRenouvellement__c,
          Opportunity__r.SectionSituationActuelle__c,
          Pde__c,
          Pde__r.DateEcheance__c,
          Pde__r.TypePDE__c,
          Pde__r.ConsoHC__c,
          Pde__r.ConsoHP__c,
          Pde__r.Conso_Base__c,
          Pde__r.Conso_HCE__c,
          Pde__r.Conso_HCH__c,
          Pde__r.Conso_HPE__c,
          Pde__r.Conso_HPH__c,
          Pde__r.Conso_Pointe__c,
          Pde__r.Puissance_souscrite__c,
          Pde__r.CARGaz__c,
          Pde__r.Tarif__c,
          Pde__r.Calendrier_fournisseur__c,
          PDE__r.Segment__c
        FROM OpportunityPDERelation__c
        WHERE
          Id IN :Trigger.New
          AND Opportunity__c IN (SELECT OpportunityId FROM Quote)
      ]
    );
    
    if (!mapOPRLigneDevis.isEmpty()) {
      SM001_GestionDevis.addLigneDevis(mapOPRLigneDevis);
    }
  }

  public override void beforeDelete() {
    Map<Id, OpportunityPDERelation__c> mapOPRLigneDeDevisToDelete = new Map<Id, OpportunityPDERelation__c>(
      [
        SELECT PDE__c, Opportunity__c
        FROM OpportunityPDERelation__c
        WHERE
          Id IN :Trigger.old
          AND Opportunity__c IN (SELECT OpportunityId FROM Quote)
      ]
    );
    if (!mapOPRLigneDeDevisToDelete.isEmpty()) {
      SM001_GestionDevis.deleteLigneDevis(mapOPRLigneDeDevisToDelete);
    }
  }
}