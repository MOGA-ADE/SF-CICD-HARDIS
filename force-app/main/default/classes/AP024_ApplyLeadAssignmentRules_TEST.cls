@isTest
private class AP024_ApplyLeadAssignmentRules_TEST {

    @isTest
    static void testReassignLeads() {
        // Create a Lead
        Lead testLead = new Lead(LastName = 'Test Lead', Company = 'Test Company', PostalCode = '44200');
        insert testLead;

        // Call the method to reassign the Lead
        AP024_ApplyLeadAssignmentRules.reassignLeads(new List<Id>{testLead.Id});
    }
}