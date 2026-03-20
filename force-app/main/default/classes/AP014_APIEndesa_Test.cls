@isTest
public class AP014_APIEndesa_Test {

    @TestSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1,1,1,1,1);
    }

	@isTest
    static void getPrixGazEndesaEntiteJuridiquePrincipale(){
        Test.setMock(HttpCalloutMock.class, new API_EndesaCalloutMock());
        Account acc = [SELECT Id,Name FROM Account];
        RecordType rt = [SELECT Id from RecordType WHERE DeveloperName = 'Simple_C1C2C3C4'];

        //Demande de cotation avec signataire
        Contact con  = [SELECT Id from Contact WHERE AccountId=: acc.Id limit 1];
        Demande_Cotation__c DDC = new Demande_Cotation__c();
        DDC.Name = acc.Name;
        DDC.Account__c = acc.Id;
        DDC.Date_RDV_Client__c = Date.today();
        DDC.Signataire__c = con.Id;
        DDC.Charge_affaire__c = UserInfo.getUserId()    ;
        DDC.Statut__c = 'Gagnée';
        DDC.Date_demande_cotation__c = Datetime.now();

        Database.SaveResult sr = Database.insert(ddc);

        //opp
        Opportunity opp = [SELECT Id FROM Opportunity];
        opp.RecordTypeId = rt.Id;
        opp.Liste_Fournisseurs__c = 'Endesa';
        opp.Demande_Cotation__c = DDC.ID;
        update opp;

        
        //listOPR
        List<OpportunityPDERelation__c> listOPR = [SELECT Id FROM OpportunityPDERelation__c WHERE Opportunity__c =: opp.Id];
        
        //listSites
        List<PDE__c> listPDE = [SELECT Id,TECH_num_compteur__c FROM PDE__c WHERE EntiteJuridique__c =:acc.Id AND TypePDE__c ='Gaz'];
        for(PDE__c pde: listPDE){
            pde.DateEcheance__c = Date.today().addYears(1);
            pde.PCE_Refonte__c = 'GI010111';
        }
        update listPDE;

        List<WrapSitesAPIEndesa> listPDEInput = new List<WrapSitesAPIEndesa>();
        for(PDE__c pde: listPDE){
            WrapSitesAPIEndesa tmp = new WrapSitesAPIEndesa();
            tmp.pce = pde.PCE_Refonte__c;
            tmp.mandat_grdf = true;
            tmp.commission = 1;
            listPDEInput.add(tmp);
        }

        System.debug('listPDEInput '+ listPDEInput);
        //quote
        Quote quoteEndesa = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id AND Fournisseur__c = 'Endesa'];
        List<QuoteLineItem> listQLIToUpdate = new List<QuoteLineItem>([SELECT Id FROM QuoteLineItem WHERE QuoteId=:quoteEndesa.Id]); 
        for(QuoteLineItem qli : listQLIToUpdate){
            qli.DureeEngagement__c = 12;
            qli.Nouvelle_Echeance__c =  Date.today().addYears(1);
        }
        update listQLIToUpdate;
        //typeOffre
        String typeOffre = 'A1';


        List<AP014_APIEndesa.FlowInput> flowInputs = new list<AP014_APIEndesa.FlowInput>();
        AP014_APIEndesa.FlowInput flowInput = new AP014_APIEndesa.FlowInput();
        flowInput.quote = quoteEndesa;
        flowInput.acc = acc;
        flowInput.opp = opp;
        flowInput.listOPR = listOPR;
        flowInput.listSites = listPDEInput;
        flowInput.type_offre = typeOffre;
        flowInput.duree_offre = string.valueOf(Date.today());
        flowInput.type_paiement = 1;
        flowInput.recordId = quoteEndesa.Id;
        flowInputs.add(flowInput);
        Test.startTest();
        List<AP014_APIEndesa.FlowOutput> outputs = AP014_APIEndesa.GET_PrixGaz(flowInputs);
        Test.stopTest();
    }

    @isTest
    static void getPrixGazEndesaSyndic(){
        Test.setMock(HttpCalloutMock.class, new API_EndesaCalloutMock());
        RecordType rtSyndic,rtCopro;
        rtSyndic = [SELECT Id FROM RecordType WHERE DeveloperName = 'Syndic'];
        rtCopro = [SELECT Id FROM RecordType WHERE DeveloperName = 'Copropriete'];

        Account syndic = new Account(Name='Syndic');
        syndic.RecordTypeId = rtSyndic.Id;
        insert syndic;

        Account acc = [SELECT Id,Name FROM Account WHERE Name <> 'Syndic'];
        acc.RecordTypeId = rtCopro.Id;
        acc.Syndic__c = syndic.Id;
        update acc;

        RecordType rt = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_C1C2C3C4'];

        //Demande de cotation avec signataire
        Contact con  = [SELECT Id from Contact WHERE AccountId=: acc.Id limit 1];
        Demande_Cotation__c DDC = new Demande_Cotation__c();
        DDC.Name = acc.Name;
        DDC.Account__c = acc.Id;
        DDC.Date_RDV_Client__c = Date.today();
        DDC.Signataire__c = con.Id;
        DDC.Charge_affaire__c = UserInfo.getUserId()    ;
        DDC.Statut__c = 'Gagnée';
        DDC.Date_demande_cotation__c = Datetime.now();

        Database.SaveResult sr = Database.insert(ddc);

        //opp
        Opportunity opp = [SELECT Id FROM Opportunity];
        opp.RecordTypeId = rt.Id;
        opp.Liste_Fournisseurs__c = 'Endesa';
        opp.Demande_Cotation__c = DDC.ID;
        update opp;

        //listOPR
        List<OpportunityPDERelation__c> listOPR = [SELECT Id FROM OpportunityPDERelation__c WHERE Opportunity__c =: opp.Id];
        
        //listSites
        List<PDE__c> listPDE = [SELECT Id,TECH_num_compteur__c FROM PDE__c WHERE EntiteJuridique__c =:acc.Id AND TypePDE__c ='Gaz'];
        for(PDE__c pde: listPDE){
            pde.DateEcheance__c = Date.today().addYears(1);
            pde.PCE_Refonte__c = 'GI010111';
        }
        update listPDE;

        List<WrapSitesAPIEndesa> listPDEInput = new List<WrapSitesAPIEndesa>();
        for(PDE__c pde: listPDE){
            WrapSitesAPIEndesa tmp = new WrapSitesAPIEndesa();
            tmp.pce = pde.PCE_Refonte__c;
            tmp.mandat_grdf = true;
            tmp.commission = 1;
            listPDEInput.add(tmp);
        }

        System.debug('listPDEInput '+ listPDEInput);
        //quote
        Quote quoteEndesa = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id AND Fournisseur__c = 'Endesa'];
        List<QuoteLineItem> listQLIToUpdate = new List<QuoteLineItem>([SELECT Id FROM QuoteLineItem WHERE QuoteId=:quoteEndesa.Id]); 
        for(QuoteLineItem qli : listQLIToUpdate){
            qli.DureeEngagement__c = 12;
            qli.Nouvelle_Echeance__c =  Date.today().addYears(1);
        }
        update listQLIToUpdate;
        //typeOffre
        String typeOffre = 'A1';


        List<AP014_APIEndesa.FlowInput> flowInputs = new list<AP014_APIEndesa.FlowInput>();
        AP014_APIEndesa.FlowInput flowInput = new AP014_APIEndesa.FlowInput();
        flowInput.quote = quoteEndesa;
        flowInput.acc = acc;
        flowInput.opp = opp;
        flowInput.listOPR = listOPR;
        flowInput.listSites = listPDEInput;
        flowInput.type_offre = typeOffre;
        flowInput.duree_offre = string.valueOf(Date.today());
        flowInput.type_paiement = 1;
        flowInput.recordId = quoteEndesa.Id;
        flowInputs.add(flowInput);
        Test.startTest();
        List<AP014_APIEndesa.FlowOutput> outputs = AP014_APIEndesa.GET_PrixGaz(flowInputs);
        Test.stopTest();
    }

    @isTest
    static void getPrixGazEndesaError(){
        Test.setMock(HttpCalloutMock.class, new API_EndesaCalloutMockError());
        Account acc = [SELECT Id,Name FROM Account];
        RecordType rt = [SELECT Id from RecordType WHERE DeveloperName = 'Simple_C1C2C3C4'];

        //Demande de cotation avec signataire
        Contact con  = [SELECT Id from Contact WHERE AccountId=: acc.Id limit 1];
        Demande_Cotation__c DDC = new Demande_Cotation__c();
        DDC.Name = acc.Name;
        DDC.Account__c = acc.Id;
        DDC.Date_RDV_Client__c = Date.today();
        DDC.Signataire__c = con.Id;
        DDC.Charge_affaire__c = UserInfo.getUserId()    ;
        DDC.Statut__c = 'Gagnée';
        DDC.Date_demande_cotation__c = Datetime.now();

        Database.SaveResult sr = Database.insert(ddc);

        //opp
        Opportunity opp = [SELECT Id FROM Opportunity];
        opp.RecordTypeId = rt.Id;
        opp.Liste_Fournisseurs__c = 'Endesa';
        opp.Demande_Cotation__c = DDC.ID;
        update opp;

        
        //listOPR
        List<OpportunityPDERelation__c> listOPR = [SELECT Id FROM OpportunityPDERelation__c WHERE Opportunity__c =: opp.Id];
        
        //listSites
        List<PDE__c> listPDE = [SELECT Id,TECH_num_compteur__c FROM PDE__c WHERE EntiteJuridique__c =:acc.Id AND TypePDE__c ='Gaz'];
        for(PDE__c pde: listPDE){
            pde.DateEcheance__c = Date.today().addYears(1);
            pde.PCE_Refonte__c = 'GI010111';
        }
        update listPDE;

        List<WrapSitesAPIEndesa> listPDEInput = new List<WrapSitesAPIEndesa>();
        for(PDE__c pde: listPDE){
            WrapSitesAPIEndesa tmp = new WrapSitesAPIEndesa();
            tmp.pce = pde.PCE_Refonte__c;
            tmp.mandat_grdf = true;
            tmp.commission = 1;
            listPDEInput.add(tmp);
        }

        System.debug('listPDEInput '+ listPDEInput);
        //quote
        Quote quoteEndesa = [SELECT Id FROM Quote WHERE OpportunityId =: opp.Id AND Fournisseur__c = 'Endesa'];
        List<QuoteLineItem> listQLIToUpdate = new List<QuoteLineItem>([SELECT Id FROM QuoteLineItem WHERE QuoteId=:quoteEndesa.Id]); 
        for(QuoteLineItem qli : listQLIToUpdate){
            qli.DureeEngagement__c = 12;
            qli.Nouvelle_Echeance__c =  Date.today().addYears(1);
        }
        update listQLIToUpdate;
        //typeOffre
        String typeOffre = 'A1';


        List<AP014_APIEndesa.FlowInput> flowInputs = new list<AP014_APIEndesa.FlowInput>();
        AP014_APIEndesa.FlowInput flowInput = new AP014_APIEndesa.FlowInput();
        flowInput.quote = quoteEndesa;
        flowInput.acc = acc;
        flowInput.opp = opp;
        flowInput.listOPR = listOPR;
        flowInput.listSites = listPDEInput;
        flowInput.type_offre = typeOffre;
        flowInput.duree_offre = string.valueOf(Date.today());
        flowInput.type_paiement = 1;
        flowInput.recordId = quoteEndesa.Id;
        flowInputs.add(flowInput);
        Test.startTest();
        List<AP014_APIEndesa.FlowOutput> outputs = AP014_APIEndesa.GET_PrixGaz(flowInputs);
        Test.stopTest();
    }
}