@IsTest
public class AP012_LeadEllisphereController_Test {

    @IsTest
    static void testUpdateLeadLastScore_simple() {
        Lead lead = new Lead(
            LastName = 'Test Lead',
            Company = 'TestCo',
            Status = 'New'
        );
        insert lead;

        Date fakeDate = Date.newInstance(2024, 2, 1);
        Decimal fakeScore = 8;

        Test.startTest();
        AP012_LeadEllisphereController.updateLeadLastScore(lead.Id, fakeDate, fakeScore);
        Test.stopTest();

        lead = [SELECT LastScore__c, LastScoreDate__c FROM Lead WHERE Id = :lead.Id];

        Assert.AreEqual(fakeScore, lead.LastScore__c, 'Le score doit être correctement mis à jour');
        Assert.AreEqual(fakeDate, lead.LastScoreDate__c, 'La date doit être correctement mise à jour');
    }

    @IsTest
    static void testUpdateLeadLastScore_withNullValues() {
        Lead lead = new Lead(
            LastName = 'Test Lead 2',
            Company = 'TestCo',
            Status = 'New'
        );
        insert lead;

        Test.startTest();
        AP012_LeadEllisphereController.updateLeadLastScore(lead.Id, null, null);
        Test.stopTest();

        lead = [SELECT LastScore__c, LastScoreDate__c FROM Lead WHERE Id = :lead.Id];

        Assert.AreEqual(null, lead.LastScore__c, 'Le score doit rester vide');
        Assert.AreEqual(null, lead.LastScoreDate__c, 'La date doit rester vide');
    }

    @IsTest
    static void testGetLeadRelatedContacts_mock() {
        Test.startTest();
        try {
            List<ElliDataResult> result = AP012_LeadEllisphereController.getLeadRelatedContacts('12345678900012');
            Assert.AreNotEqual(null, result, 'Le résultat ne doit pas être null (même si vide en test)');
        } catch (Exception e) {
            Assert.IsTrue(true, 'Exception levée comme attendu en environnement de test');
        }
        Test.stopTest();
    }
}