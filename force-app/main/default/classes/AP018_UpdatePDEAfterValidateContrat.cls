public with sharing class AP018_UpdatePDEAfterValidateContrat {
    
    @invocableMethod(label='Mise à jour des PDE')
    public static List<FlowOutput> updatePDE(List<FlowInputs> params) {
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();
        List<PDE__c> listPDEToUpdate = new List<PDE__c>();
        List<Id> listPDEIds = new List<Id>();
        Map<Id, Date> mapPDEWithContract = new Map<Id, Date>();
        String fournisseur = [SELECT fournisseurPicklist__c FROM Contract WHERE Id = :params[0].ContractId].fournisseurPicklist__c;

        //On extrait les  Ids des PDE à partir des Prix_contrat_PDE__c
        for (Prix_contrat_PDE__c pcpde : params[0].listPCPDEFromFlow) {
            listPDEIds.add(pcpde.Point_energie__c);
        }

        //On récupère les PDE qui sont déjà liés à un contrat différent de celui en cours
        for(PDE__c pde : [SELECT Id, DateEcheance__c FROM PDE__c WHERE Id IN (SELECT Point_energie__c FROM Prix_contrat_PDE__c WHERE Contract__c <> :params[0].ContractId AND Point_energie__c IN :listPDEIds)]) {
            mapPDEWithContract.put(pde.Id, pde.DateEcheance__c);
        }
        
        for (Prix_contrat_PDE__c pcpde : params[0].listPCPDEFromFlow) {

            PDE__c pde = new PDE__c();
            pde.Id = pcpde.Point_energie__c;
            //Si le PDE est déjà lié à un contrat, on enregistre l'ancienne date d'échéance pour le calcul du taux de renouvellment
            if(mapPDEWithContract.containsKey(pcpde.Point_energie__c)) {
                pde.ancienne_date_echeance__c = mapPDEWithContract.get(pcpde.Point_energie__c);
                System.debug('PDE déjà lié à un contrat, ancienne date d\'échéance: ' + pde.ancienne_date_echeance__c);
            }
            pde.DateEcheance__c = pcpde.Date_echeance__c;
            pde.DateEcheanceContract__c = pcpde.Date_echeance__c;
            pde.fournisseur__c = fournisseur;

            listPDEToUpdate.add(pde);
        }

        List<Database.SaveResult> listSRPDE = Database.update(listPDEToUpdate);
        for(Database.SaveResult sr : listSRPDE){
            if (!sr.isSuccess()) {
                System.debug(sr.getErrors());
                output.success = false;
                output.message = 'Erreur Update Date échéance sur PDE';
                outputs.add(output);
                return outputs;
            }
        }

        output.success = true;
        outputs.add(output);
        return outputs;
    }


    public class FlowInputs {
        @invocableVariable public Id ContractId;
        @invocableVariable public List<Prix_contrat_PDE__c> listPCPDEFromFlow;
    }
    
    public class FlowOutput {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }
}