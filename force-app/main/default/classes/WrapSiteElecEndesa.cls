public class WrapSiteElecEndesa {
    @AuraEnabled @InvocableVariable public String prm;
    @AuraEnabled @InvocableVariable public String nom;
    @AuraEnabled @InvocableVariable public String date_debut;
    @AuraEnabled @InvocableVariable public String date_fin;
    @AuraEnabled @InvocableVariable public String type_service = 'CHF';
    @AuraEnabled @InvocableVariable public Boolean mandat_enedis = true;
    @AuraEnabled @InvocableVariable public Decimal commission;
    @AuraEnabled @InvocableVariable public Decimal abonnement;
}