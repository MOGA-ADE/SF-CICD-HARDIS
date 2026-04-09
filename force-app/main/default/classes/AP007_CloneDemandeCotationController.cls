public without sharing class AP007_CloneDemandeCotationController {
    
    @AuraEnabled(cacheable=true)
    public static Demande_Cotation__c getDemandeCotation(Id demandeCotationId){
        // list<Demande_Cotation__c> demandeCotations = [SELECT Name FROM Demande_Cotation__c WHERE Id = :demandeCotationId];
        // return demandeCotations.size() > 0 ? demandeCotations : null;
        return [SELECT Name,Date_RDV_reactualisation__c FROM Demande_Cotation__c WHERE Id = :demandeCotationId][0];
    }

    @AuraEnabled
    public static Demande_Cotation__c cloneDemandeCotation(Id demandeCotationId, String newName, Datetime newDateRDV){
        try {
            System.debug('newRDV '+newDateRDV);
            List<PDE__c> listPDEs = [SELECT Id FROM PDE__c WHERE Demande_Cotation__c = :demandeCotationId];
            List<Opportunity> listOpps = [SELECT Id FROM Opportunity WHERE Demande_Cotation__c = :demandeCotationId];

            Demande_Cotation__c dcPerimee = [SELECT OwnerId, 
                                                    Name, 
                                                    RecordTypeId, 
                                                    CreatedDate, 
                                                    CreatedById,
                                                    Concurrence_identifiee__c,
                                                    Duree_offre__c,
                                                    Date_RDV_Client__c,
                                                    LastModifiedDate, 
                                                    LastModifiedById, 
                                                    LastActivityDate, 
                                                    Charge_affaire__c, 
                                                    Infos_complementaires__c,
                                                    Infos_reactualisation__c,
                                                    Statut__c, 
                                                    Account__c, 
                                                    Date_demande_cotation__c, 
                                                    Marge__c,
                                                    Marge_souhaitee__c,
                                                    Offre_Renouvellement__c,
                                                    Specificite_offre__c, 
                                                    Signataire__c,
                                                    TECH_Owner_Manger_Mail__c
                                            FROM Demande_Cotation__c 
                                            WHERE Id = :demandeCotationId][0];
            
            Demande_Cotation__c dcClone = dcPerimee.clone(false, true, true, true);
            dcClone.Name= newName;
            dcClone.Statut__c = 'En cours de traitement';
            dcClone.Date_demande_cotation__c = Datetime.now();
            dcClone.Date_RDV_Client__c = newDateRDV;

            Database.SaveResult sr = Database.insert(dcClone, true);

            if(sr.isSuccess()) {
                if (!listOpps.isEmpty()) {
                    for (Opportunity opp : listOpps) {
                        opp.Demande_Cotation__c = dcClone.Id;
                    }
                    update listOpps;
                }
                
                if (!listPDEs.isEmpty()) {
                    for (PDE__c pde : listPDEs) {
                        pde.Demande_Cotation__c = dcClone.Id;
                    }
                    update listPDEs;
                }

                dcPerimee.Statut__c = 'Clonée';
                update dcPerimee;
            }


            return dcClone;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}