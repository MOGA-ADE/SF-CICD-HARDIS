public without sharing class AP013_EspaceApporteurAffairesController {
    
    @AuraEnabled
    public static Account verifyCodePartenaire(String codePartenaire){
        return [SELECT OwnerId, Responsable_Leads__c FROM Account WHERE Code_partenaire__c = :codePartenaire AND Convention_inactive__c = false LIMIT 1];
    }

    @AuraEnabled
    public static Boolean insertLead(Lead lead, String contentVersionId){
        Id recordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Apporteur Affaires').getRecordTypeId();
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.duplicateRuleHeader.allowSave = true;
        
        lead.RecordTypeId = recordTypeId;
        Database.SaveResult srLead = Database.insert(lead, dmlOptions);
        
        if (srLead.isSuccess()){
            // Attach the file to the iserted Lead
            ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = lead.Id;

            Database.SaveResult srCDL = Database.insert(cdl);
            return srCDL.isSuccess();
        } else {
            return false;
        }
    }
}