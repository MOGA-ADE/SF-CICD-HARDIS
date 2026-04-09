public with sharing class ElliDataScore {
    @AuraEnabled @InvocableVariable public Date dateScore;
    @AuraEnabled @InvocableVariable public String score;
    @AuraEnabled @InvocableVariable public String riskClass;
}