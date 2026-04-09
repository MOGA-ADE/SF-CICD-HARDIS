public with sharing class AP012_LeadEllisphereController {

    @AuraEnabled
    public static List<ElliDataResult> getLeadRelatedContacts(String siret) {
        try {
            return ElliData.process(new List<ElliData.Request>{ buildRequest(siret) });
        } catch (Exception e) {
            System.debug('ERROR ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateLeadLastScore(Id leadId, Date latestDate, Decimal latestScore) {
        if (leadId == null || latestDate == null || latestScore == null) return;

        Lead toUpdate = new Lead(
            Id = leadId,
            LastScore__c = latestScore,
            LastScoreDate__c = latestDate
        );
        update toUpdate;
    }

    private static ElliData.Request buildRequest(String siret) {
        ElliData.Request req = new ElliData.Request();
        Ellisphere_API_account__mdt creds = Ellisphere_API_account__mdt.getInstance('Ellisphere');
        req.product   = creds.productId__c;
        req.contract  = creds.contractId__c;
        req.user      = creds.userId__c;
        req.password  = creds.password__c;
        req.companyId = siret;
        return req;
    }
}