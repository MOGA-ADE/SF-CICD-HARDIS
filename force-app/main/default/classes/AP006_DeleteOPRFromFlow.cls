public with sharing class AP006_DeleteOPRFromFlow {

    @invocableMethod(label='Supprimer une list OpportunityPDERelation depuis Apex')
    public static List<FlowOutput> deleteOPR(List<FlowInputs> params) {

        FlowInputs param = params[0];
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();
        List<Id> listOPRIdToDelete = new List<Id>();
        for(OpportunityPDERelation__c opr : param.selectedOPR){
            listOPRIdToDelete.add(opr.Id);
        }

        List<Database.DeleteResult> listSR = Database.delete(param.selectedOPR);
        for(Database.DeleteResult dr : listSR){
            if (!dr.isSuccess()) {
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
        @invocableVariable public List<OpportunityPDERelation__c> selectedOPR;
    }
    
    public class FlowOutput {
        @InvocableVariable
        public Boolean DMLSuccess;
    }
}