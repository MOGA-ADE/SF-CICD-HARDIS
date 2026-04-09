global without sharing class WrapTURPEDisplayRow {
    @AuraEnabled public String RecordId { get; set; }
    @AuraEnabled public String PDEName { get; set; }
    @AuraEnabled public String IdSource { get; set; }
    @AuraEnabled public String IdAnalyse { get; set; }
    @AuraEnabled public String IdBuilding { get; set; }
    @AuraEnabled public String MessageStatut { get; set; }
    @AuraEnabled public String ActionType { get; set; }
}