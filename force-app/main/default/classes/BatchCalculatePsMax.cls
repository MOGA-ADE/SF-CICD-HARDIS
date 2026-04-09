global class BatchCalculatePsMax implements Database.batchable<sObject>, Database.AllowsCallouts, Schedulable {
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT Id, ReferencePointEnergie_Refonte__c from PDE__c where ACD_valide__c = true AND X12_mois_consommation_SGE__c = true  AND Recordtype.Name != 'Gaz' AND Segment__c != 'C5' and (DateCalculPsMaxSansErreur__c = null OR DateCalculPsMaxSansErreur__c < LAST_N_Days:7)]);
    }
    
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        List<PDE__c> sitesToUpdate = new List<PDE__c>();
        for(sobject s : scope){
            PDE__c site = (PDE__c) s;
            site = SGEManager.calculatePsMaxForAYear(site);
        	sitesToUpdate.add(site);
        }
        update sitesToUpdate;      
    }
    
    public void finish(Database.BatchableContext bc){

    }
    
    global void execute(SchedulableContext SC) {
        BatchCalculatePsMax b = new BatchCalculatePsMax();
        Database.executeBatch (b,1);
    }
    
}