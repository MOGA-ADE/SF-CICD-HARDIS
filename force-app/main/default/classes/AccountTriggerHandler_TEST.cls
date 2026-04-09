@isTest
private class AccountTriggerHandler_TEST {

    @IsTest
    static void testCodePartenaire(){
        
        Account acc = new Account();
        acc.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Apporteur Affaires').getRecordTypeId();
        acc.Name = 'Test';
        acc.ELLISPHERE__Elli_CompanyEmail__c = 't@t.fr';

        Test.startTest();
        insert Acc;
        Test.stopTest();
        
        Account savedAccount = [SELECT Code_partenaire__c FROM ACCOUNT LIMIT 1];
        Assert.isNotNull(savedAccount.Code_partenaire__c, 'Code partenaire généré');
    }
}