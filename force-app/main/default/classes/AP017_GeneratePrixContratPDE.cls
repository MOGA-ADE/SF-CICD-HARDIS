public with sharing class AP017_GeneratePrixContratPDE {
    
    @invocableMethod(label='Générer prix contrat PDE')
    public static List<FlowOutput> createPrixContractPDE(List<FlowInputs> params) {
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();
        List<Prix_contrat_PDE__c> ListpcPDE = new List<Prix_contrat_PDE__c>();
        // List<PDE__c> ListPDE = new List<PDE__c>();
        Contract contract = [ SELECT  Name FROM Contract WHERE Id = :params[0].ContractId];

        for (QuoteLineItem qli : params[0].ListQLIFromFlow) {
            Boolean isGAZ = qli.TECH_RT__c == 'PDE_Gaz' ? true : false;

            Prix_contrat_PDE__c pcPDE = new Prix_contrat_PDE__c();
            pcPDE.Name = contract.Name + '-PDE-' + qli.TECH_PdeReference__c;
            pcPDE.Point_energie__c = qli.PDE__c;
            
            pcPDE.Contract__c = params[0].ContractId;
            pcPDE.Siret_payeur__c = qli.TECH_Siret_Payeur__c;
            pcPDE.Numero_compteur__c = qli.TECH_PdeReference__c;
            pcPDE.Date_debut_fourniture__c = qli.DebutDeFourniture__c;
            pcPDE.Date_echeance__c = qli.Nouvelle_Echeance__c;
            
            pcPDE.Conso_Base__c = qli.Conso_Base__c;
            pcPDE.Conso_HC__c = qli.ConsoHC__c;
            pcPDE.Conso_HP__c = qli.ConsoHP__c;
            pcPDE.Conso_HCE__c = qli.Conso_HCE__c;
            pcPDE.Conso_HCH__c = qli.Conso_HCH__c;
            pcPDE.Conso_HPE__c = qli.Conso_HPE__c;
            pcPDE.Conso_HPH__c = qli.Conso_HPH__c;
            pcPDE.Conso_Pointe__c = qli.Conso_Pointe__c;

            pcPDE.Prix_Base__c = qli.PrixBase__c;
            pcPDE.Prix_HC__c = qli.PrixHC__c;
            pcPDE.Prix_HP__c = qli.PrixHP__c;
            pcPDE.Prix_HCE__c = qli.PrixHceMwh__c;
            pcPDE.Prix_HCH__c = qli.PrixHchMwh__c;
            pcPDE.Prix_HPE__c = qli.PrixHpeMwh__c;
            pcPDE.Prix_HPH__c = qli.PrixHphMwh__c;
            pcPDE.Prix_Pointe__c = qli.PointesMWh__c;

            pcPDE.Capacit_Base_Mwh__c = qli.Capa_Base__c;
            pcPDE.Capacite_HC_Mwh__c = qli.Capa_HC__c;
            pcPDE.Capacite_HP_Mwh__c = qli.Capa_HP__c;
            pcPDE.Capacite_HCE_Mwh__c = qli.Capa_HCE__c;
            pcPDE.Capacite_HCH_Mwh__c = qli.Capa_HCH__c;
            pcPDE.Capacite_HPE_Mwh__c = qli.Capa_HPE__c;
            pcPDE.Capacite_HPH_Mwh__c = qli.Capa_HPH__c;
            pcPDE.Capacite_Pointe_Mwh__c = qli.Capa_Pointes__c;

            pcPDE.Abonnement_Mois__c = qli.AbonnementMois__c;
            pcPDE.Prix_molecule_Mwh__c = qli.PrixMolecule__c;
            pcPDE.CAR__c = isGAZ ? qli.CARGaz__c : qli.CAR_New__c;
            pcPDE.CEE_Mwh__c = qli.CeeMwh__c;
            pcPDE.CSPE__c = qli.CSPE__c;
            pcPDE.TICGN__c = qli.TICGN__c;
            pcPDE.CTA__c = qli.CTA__c;
            pcPDE.Frais_distribution_transport_Mwh__c = qli.FraisTransportDistributionCapacite__c;
            pcPDE.Budget_TTC__c = qli.Budget_TTC__c;
            pcPDE.Budget_gaz_naturel_HTVA_an__c = qli.BudgetgazNaturelHTVAAn__c;
            
            pcPDE.Tarif__c = qli.TECH_Tarif__c;
            pcPDE.Segment__c = qli.TECH_Segment__c;
            pcPDE.Profil__c = qli.TECH_Profil__c;
            pcPDE.FTA__c = qli.TECH_FTA__c;

            pcPDE.RecordTypeId = getRecordTypeId(isGAZ);

            // PDE__c pde = new PDE__c();
            // pde.Id = qli.PDE__c;
            // pde.DateEcheance__c = qli.Nouvelle_Echeance__c;
            // pde.DateEcheanceContract__c = qli.Nouvelle_Echeance__c;
            // pde.Fournisseur_Actuel__c = qli.TECH_fournisseur__c;

            ListpcPDE.add(pcPDE);
            // ListPDE.add(pde);
        }

        List<Database.SaveResult> listSR = Database.insert(ListpcPDE);
        for(Database.SaveResult sr : listSR){
            if (!sr.isSuccess()) {
                System.debug(sr.getErrors());
                output.success = false;
                output.message = 'Erreur insert Prix contrat PDE';
                outputs.add(output);
                return outputs;
            }
        }

        // List<Database.SaveResult> listSRPDE = Database.update(ListPDE);
        // for(Database.SaveResult sr : listSR){
        //     if (!sr.isSuccess()) {
        //         System.debug(sr.getErrors());
        //         output.success = false;
        //         output.message = 'Erreur Update Date échéance sur PDE';
        //         outputs.add(output);
        //         return outputs;
        //     }
        // }

        output.success = true;
        outputs.add(output);
        return outputs;
    }

    private static Id getRecordTypeId(Boolean isGaz) {
        String devName = isGaz ? 'Gaz' : 'Elec';
        return Schema.SObjectType.Prix_contrat_PDE__c.getRecordTypeInfosByName().get(devName).getRecordTypeId();
    }

    public class FlowInputs {
        @invocableVariable public Id ContractId;
        @invocableVariable public List<QuoteLineItem> ListQLIFromFlow;
    }
    
    public class FlowOutput {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }
}