@isTest
private class AP013_EspaceApporteurAffaires_TEST {

    @TestSetup
    static void makeData(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Apporteur Affaires').getRecordTypeId();
        
        Account acc = new Account();
        acc.Name = 'Test AA';
        acc.ELLISPHERE__Elli_CompanyEmail__c = 't@t.fr';
        acc.recordTypeId = recordTypeId;

        insert acc;
    }

    @IsTest
    static void verifyCodePartenaire(){
        Account accInserted = [SELECT Code_partenaire__c FROM Account LIMIT 1];

        Test.startTest();
        Account accTested = AP013_EspaceApporteurAffairesController.verifyCodePartenaire(accInserted.Code_partenaire__c);
        Test.stopTest();

        Assert.isNotNull(accTested, 'accTested is not null');
    }

    @IsTest
    static void insertLead(){
        Lead lead = new Lead();
        lead.LastName = 'Test';
        lead.Company = 'Test Company';

        ContentVersion cv = new Contentversion();
        cv.title = 'ABC';
        cv.PathOnClient = 'test';
        Blob b = Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata = EncodingUtil.base64Decode('Unit Test Attachment Body');
        insert cv;

        Test.startTest();
        Boolean success = AP013_EspaceApporteurAffairesController.insertLead(lead,cv.Id);
        Test.stopTest();

        Assert.isTrue(success, 'Lead inserted successfully');
    }
}