trigger OpportunityPDERelationTrigger on OpportunityPDERelation__c(
  after insert,
  before delete
) {
  new OpportunityPDERelationTriggerHandler().run();
}