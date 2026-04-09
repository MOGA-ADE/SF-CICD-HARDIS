public with sharing class AP023_CheckContratsFournisseurController {
    @AuraEnabled
    public static List<Appel_facturation__c> getAppelFacturation(String fournisseur,String mois,String annee){
        Date dateMin = Date.newInstance(Integer.valueOf(annee),Integer.valueOf(mois),1);
        Date dateMax = dateMin.addMonths(1);
        return [SELECT  Id,
                        Contrat__r.Name,
                        Contrat__r.Account.Name,
                        Montant__c,
                        Contrat__r.Charge_affaire__r.Name,
                        Contrat__r.Siret_payeur__c
                    FROM Appel_facturation__c 
                    WHERE Contrat__r.TECH_Fournisseur__c = :fournisseur 
                    AND Mois_facturation_concerne__c >= :dateMin
                    AND Mois_facturation_concerne__c < :dateMax
                    AND recordType.Name = 'Commission'];
    }

    @AuraEnabled
    public static Boolean updateAppelFacturation(String fournisseur,String mois,String annee){
        List<Appel_facturation__c> listAFToUpdate = getAppelFacturation(fournisseur,mois,annee);
        for(Appel_facturation__c af : listAFToUpdate){
            af.Statut__c = 'OK pour facturation';
        }
        List<Database.SaveResult> listSR = Database.update(listAFToUpdate,false);
        for(Database.SaveResult sr : listSR){
            if (!sr.isSuccess()) {
                System.debug(sr.getErrors());
                return false;
            }
        }
        return true;
    }

    
}