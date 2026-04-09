public class AP003_DemandeCotationFromFlow {

    @invocableMethod(label='Créer Demande de Cotation depuis Apex')
    public static List<FlowOutput> createDemandeCotation(List<FlowInputs> params) {
        List<String> listCanauxDeVenteCreationTask = new List<String>{'Vente terrain','Vente terrain Lyon'};

        FlowInputs param = params[0];
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();
        List<User> managerList = [SELECT Email FROM User WHERE Id = :param.ManagerId];
        
        String managerEmail = '';
        if (!managerList.isEmpty()) {
            managerEmail = managerList[0].Email;
        }

        Demande_Cotation__c demandeCotation = new Demande_Cotation__c();
        if(param.Account.Name.length() > 80)    {
            demandeCotation.Name = param.Account.Name.substring(0, 80);
        }
        else {
            demandeCotation.Name = param.Account.Name;
        }
        
        demandeCotation.Account__c = param.Account.Id;
        demandeCotation.Date_RDV_Client__c = param.DateRDVClient;
        demandeCotation.Signataire__c = param.SignataireId;
        demandeCotation.Charge_affaire__c = param.ChargeAffaireId;
        demandeCotation.Infos_complementaires__c = param.InfosComplementaires;
        demandeCotation.Statut__c = 'En attente de traitement';
        demandeCotation.Date_demande_cotation__c = Datetime.now();
        demandeCotation.TECH_Owner_Manger_Mail__c = managerEmail;
        demandeCotation.Marge_souhaitee__c = param.MargeSouhaitee;
        demandeCotation.Duree_offre__c = param.DureeOffre;
        demandeCotation.Offre_Renouvellement__c = param.OffreRenouvellement;
        demandeCotation.Concurrence_identifiee__c = param.ConcurrenceIdentifiee;
        demandeCotation.Specificite_offre__c = param.SpecificiteOffre;
        demandeCotation.Plus_1_Giga__c = param.PlusDe1Giga == null ? false : param.PlusDe1Giga;
        demandeCotation.Souhaite_offre_TURPE__c = param.SouhaiteOffreTURPE == null ? false : param.SouhaiteOffreTURPE;

        Database.SaveResult sr = Database.insert(demandeCotation);

        if (sr.isSuccess()) {
            output.DMLSuccess = true;
            output.ErrorMessage = null;
            outputs.add(output);
        } else {
            output.DMLSuccess = false;
            output.ErrorMessage = sr.getErrors()[0].getMessage();
            outputs.add(output);
            return outputs;
        }

        Id runningFlowUserId = UserInfo.getUserId();
        String companyName = [SELECT CompanyName FROM User WHERE Id = :runningFlowUserId  LIMIT 1][0].CompanyName;
        Demande_Cotation__c insertedDemandeCotation = [SELECT Canal_vente__c FROM Demande_Cotation__c WHERE Id = :demandeCotation.Id LIMIT 1][0];
        if(companyName <> 'ADE'){ // Rendre cette partie dynamique plus tard
            User assistanteVI = [SELECT Id FROM User WHERE Name = 'Elisa Diaz' LIMIT 1]; // Rendre cette partie dynamique plus tard
            Task task = new Task();
            task.WhatId = demandeCotation.Id;
            task.Subject = 'Prélecture de la Demande de Cotation '+demandeCotation.Name+ ' du '+param.DateRDVClient;
            task.OwnerId = assistanteVI.Id;
            task.Priority = 'Haute';
            task.Status = 'Ouverte';
            task.ActivityDate = Date.today();
            insert task;
        }
        else if (listCanauxDeVenteCreationTask.contains(insertedDemandeCotation.Canal_Vente__c)) {
            Task task = new Task();
            task.WhatId = demandeCotation.Id;
            task.Subject = 'Prélecture de la Demande de Cotation '+demandeCotation.Name+ ' du '+param.DateRDVClient;
            task.OwnerId = param.chargeAffaireId;
            task.Priority = 'Haute';
            task.Status = 'Ouverte';
            task.ActivityDate = Date.today();
            insert task;
        }
        
        for (PDE__c pde : param.SelectedPDEs) {
            pde.Demande_Cotation__c = demandeCotation.Id;
        }
        
        Database.update(param.SelectedPDEs);

        return outputs;
    }

    public class FlowInputs {
        @invocableVariable public Account Account;
        @invocableVariable public DateTime DateRDVClient;
        @invocableVariable public String DateEcheance;
        @invocableVariable public String SignataireId;
        @invocableVariable public String ChargeAffaireId;
        @invocableVariable public String ManagerId;
        @invocableVariable public String InfosComplementaires;
        @invocableVariable public List<PDE__c> SelectedPDEs;
        @invocableVariable public String MargeSouhaitee;
        @invocableVariable public String DureeOffre;
        @invocableVariable public String OffreRenouvellement;
        @invocableVariable public String ConcurrenceIdentifiee;
        @invocableVariable public String SpecificiteOffre;
        @invocableVariable public Boolean plusde1Giga;
        @invocableVariable public Boolean souhaiteOffreTURPE;
    }
    
    public class FlowOutput {
        @InvocableVariable
        public Boolean DMLSuccess;
        @InvocableVariable
        public String ErrorMessage;
    }
}