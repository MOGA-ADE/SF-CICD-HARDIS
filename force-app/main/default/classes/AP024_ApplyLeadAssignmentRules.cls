public with sharing class AP024_ApplyLeadAssignmentRules {

    @InvocableMethod(label='Apply Assignment Rules' description='Applies Lead Assignment Rules to Leads')
    public static void reassignLeads(List<Id> leadIds) {
        System.debug('reassignLeads ' + leadIds);
        reassignLeadsFuture(leadIds);
    }

    @future
    public static void reassignLeadsFuture(List<Id> leadIds) {
        List<Lead> leadsToReassign = [SELECT Id FROM Lead WHERE Id IN :leadIds];
        System.debug('reassignLeadsFuture ' + leadsToReassign);
        if (!leadsToReassign.isEmpty()) {
            Database.DMLOptions dmlOpts = new Database.DMLOptions();
            dmlOpts.assignmentRuleHeader.useDefaultRule = true;

            for(Lead lead : leadsToReassign) {
                lead.setOptions(dmlOpts);
            }

            update leadsToReassign;
        }
    }
}