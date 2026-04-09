public class ElliDataResult {
  @AuraEnabled @InvocableVariable public Boolean error;
  @AuraEnabled @InvocableVariable public String comment;
  @AuraEnabled @InvocableVariable public String companyname;
  @AuraEnabled @InvocableVariable public String address;
  @AuraEnabled @InvocableVariable public String postcode;
  @AuraEnabled @InvocableVariable public String city;
  @AuraEnabled @InvocableVariable public String country;
  @AuraEnabled @InvocableVariable public List<ElliDataManager> managers;
  @AuraEnabled @InvocableVariable public List<ElliDataScore> scores;
}