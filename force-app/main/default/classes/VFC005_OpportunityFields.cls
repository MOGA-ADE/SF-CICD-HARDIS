public without sharing class VFC005_OpportunityFields {

    @AuraEnabled
    public static Opportunity getOpportunity(String oppId){
        Opportunity opp = DM000_QueryManager.getOpportunityById(oppId);
        return opp;
    }
}