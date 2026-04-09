public with sharing class AP005_CreateOPRFromFlow {

    @invocableMethod(label='Créer list OpportunityPDERelation depuis Apex')
    public static List<FlowOutput> createOPR(List<FlowInputs> params) {

        FlowInputs param = params[0];
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();
        List<OpportunityPDERelation__c> listOPR = new List<OpportunityPDERelation__c>();
        for(PDE__c pde : param.SelectedPDEs){
            listOPR.add(
                new OpportunityPDERelation__c(
                    PDE__c = pde.Id,
                    Opportunity__c = param.OpportunityId
                )
            );
        }

        List<Database.SaveResult> listSR = Database.insert(listOPR);
        for(Database.SaveResult sr : listSR){
            if (!sr.isSuccess()) {
                output.DMLSuccess = false;
                outputs.add(output);
                return outputs;
            }
        }
        output.DMLSuccess = true;
        outputs.add(output);
        return outputs;
    }

    public class FlowInputs {
        @invocableVariable public String OpportunityId;
        @invocableVariable public List<PDE__c> SelectedPDEs;
    }
    
    public class FlowOutput {
        @InvocableVariable
        public Boolean DMLSuccess;
    }
}