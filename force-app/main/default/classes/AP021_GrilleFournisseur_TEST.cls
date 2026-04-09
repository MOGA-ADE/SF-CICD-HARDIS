@IsTest
private class AP021_GrilleFournisseur_TEST {
    
    @TestSetup
    static void makeData(){
        TestDataFactory.createPriceBooks();
        //Création de deux opportunités, une gaz et une ELEC avec tous les fournisseurs grilles inclu
        // Create Account
        Id EntiteJuridiquePrincipaleRecordTypeId = [ SELECT Id FROM RecordType WHERE DeveloperName = 'Account_EntiteJuridiquePrincipale'].get(0).Id;
        Account a = new Account(Name = 'TestAccountGaz', Industry = 'Résidentiel', Siren__c = '12345678', Siret__c = '1234567890122', RecordTypeId = EntiteJuridiquePrincipaleRecordTypeId);
        insert a;

        // Create Opp
        Id oppRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_C5'].get(0).Id;
        Opportunity opp = new Opportunity(AccountId= a.Id, Name = a.Name + ' Opportunity ', StageName = 'Conditionné', CloseDate = System.today().addMonths(1), TemplateCotation__c = 'C5', SectionSituationActuelle__c = true, responsableCotation__c = UserInfo.getUserId(), RecordTypeId = oppRecordTypeId);
        insert opp;

        // Create PDEs
        Id c1c2RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Elec_C1C2'].get(0).Id;
        Id c4RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Elec_C3_C4'].get(0).Id;
        Id c5RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_ElecC5'].get(0).Id;
        Id gazRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'PDE_Gaz'].get(0).Id;

        List<PDE__c> pdes = new List<PDE__c>();
        pdes.add(new PDE__c(Name = a.Name + ' PDEC1', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678900', ReferencePointEnergie_Refonte__c = '12345678900', EntiteJuridique__c = a.Id, RecordTypeId = c1c2RecordTypeId, FTA__c = 'HTA - PF - CU', X12_mois_consommation_SGE__c = true,Segment__c = 'C1'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC2', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678901', ReferencePointEnergie_Refonte__c = '12345678900', EntiteJuridique__c = a.Id, RecordTypeId = c1c2RecordTypeId, FTA__c = 'HTA - PF - CU', X12_mois_consommation_SGE__c = true,Segment__c = 'C2'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC4', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678911', ReferencePointEnergie_Refonte__c = '12345678911', EntiteJuridique__c = a.Id, RecordTypeId = c4RecordTypeId, FTA__c = 'BT > 36 kVA - CU', X12_mois_consommation_SGE__c = true,Segment__c = 'C4'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC4', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678911', ReferencePointEnergie_Refonte__c = '12345678912', EntiteJuridique__c = a.Id, RecordTypeId = c4RecordTypeId, FTA__c = 'BT > 36 kVA - LU', X12_mois_consommation_SGE__c = true,Segment__c = 'C4'));  
        pdes.add(new PDE__c(Name = a.Name + ' PDEC5Base', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678922', ReferencePointEnergie_Refonte__c = '12345678922', EntiteJuridique__c = a.Id, RecordTypeId = c5RecordTypeId, FTA__c = 'BT <= 36 kVA - MU', X12_mois_consommation_SGE__c = true,Segment__c = 'C5'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC5HPHC', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678987', ReferencePointEnergie_Refonte__c = '12345678922', EntiteJuridique__c = a.Id, RecordTypeId = c5RecordTypeId, FTA__c = 'BT <= 36 kVA - MU', X12_mois_consommation_SGE__c = true,Segment__c = 'C5',Calendrier_fournisseur__c = 'HP/HC'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEC54Postes', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '12345678933', ReferencePointEnergie_Refonte__c = '12345678933', EntiteJuridique__c = a.Id, RecordTypeId = c5RecordTypeId, FTA__c = 'BT <= 36Kva - CU 4 postes', X12_mois_consommation_SGE__c = true,Segment__c = 'C5'));
        pdes.add(new PDE__c(Name = a.Name + ' PDEGaz', SiteConsommation__c = 'TEST ', NumeroVoie__c = '90', voie__c = 'Rue de la Villette', Code_Postal__c = '69003', Ville__c = 'Lyon', CARGaz__c = 1234, DateEcheance__c = System.today().addMonths(1), PCE_Refonte__c = '1234567893', ReferencePointEnergie_Refonte__c = '1234567893', EntiteJuridique__c = a.Id, RecordTypeId = gazRecordTypeId, Tarif__c = 'T4', Profil__c = 'P011'));
        insert pdes;
        
        List<OpportunityPDERelation__c> listOPR = new List<OpportunityPDERelation__c>();
        for (PDE__c pde : pdes) {
        listOPR.add(new OpportunityPDERelation__c(Opportunity__c = opp.Id, PDE__c = pde.Id));
        }
        insert listOPR;

        opp.Liste_fournisseurs__c= 'TotalEnergies;Vattenfall;Dyneff;EDF Entreprises;Ekwateur;Engie;Ilek;GEG;Hellio;';
        update opp;
    }

    @IsTest
    static void caculatePriceTotal(){
        
        Quote quote = [SELECT Id From Quote WHERE Fournisseur__c = 'TotalEnergies'];
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();

        input.recordId = quote.Id;
        input.fournisseur = 'TotalEnergies';
        input.dureeOffre = '12';

        inputs.add(input);
        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);

        // Upodate Opp
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id oppGazRecordId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_Gaz'].get(0).Id;
        opp.RecordTypeId = oppGazRecordId;
        update opp;

        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest();   
    }

    @IsTest
    static void caculatePriceVattenfall(){
        
        Quote quote = [SELECT Id From Quote WHERE Fournisseur__c = 'Vattenfall']; 
        Grille_Vattenfall__mdt prixGrille = null;
        String labelCode;
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();

        for(QuoteLineItem qli : [SELECT Id,
                                        DebutDeFourniture__c,
                                        Nouvelle_Echeance__c,
                                        Puissance_souscrite__c,
                                        TECH_Segment__c,
                                        TECH_FTA__c,
                                        TECH_Tarif__c,
                                        TECH_CalendrierFournisseur__c
                                    FROM QuoteLineItem 
                                    WHERE QuoteId =: quote.Id
                                    AND TECH_Segment__c = 'C5']){
            
            if(qli.TECH_CalendrierFournisseur__c.contains('Base')){
                labelCode = 'Base_12_24';
            } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){
                labelCode = 'HPHC_12_24';
            } else {
                labelCode = '';
            }

            prixGrille = Grille_Vattenfall__mdt.getInstance(labelCode);

            if(prixGrille != null) {
                qli.DebutDeFourniture__c = prixGrille.Date_debut_maximale__c;
                qli.Nouvelle_Echeance__c = prixGrille.Date_fin_maximale__c;
                qli.Puissance_souscrite__c = 12;
                listQLI.add(qli);
            }
        }


        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();

        input.recordId = quote.Id;
        input.fournisseur = 'Vattenfall';
        input.dureeOffre = '24';

        inputs.add(input);

        update listQLI;
        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest(); 
    }

    @IsTest
    static void caculatePriceDyneff(){
        
        Quote quote = [SELECT Id From Quote WHERE Fournisseur__c = 'Dyneff'];
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();
        String labelCode;
        Grille_Dyneff__mdt prixGrille = null;
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();

        for(QuoteLineItem qli : [SELECT Id,
                                        DebutDeFourniture__c,
                                        Nouvelle_Echeance__c,
                                        Puissance_souscrite__c,
                                        TECH_Segment__c,
                                        TECH_FTA__c,
                                        TECH_Tarif__c,
                                        TECH_CalendrierFournisseur__c
                                    FROM QuoteLineItem 
                                    WHERE QuoteId =: quote.Id
                                    AND TECH_Segment__c = 'C5']){
            
            if(qli.TECH_CalendrierFournisseur__c.contains('Base')){
                labelCode = 'Base_12';
            } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){
                labelCode = 'HPHC_12';
            } else {
                labelCode = '';
            }

            prixGrille = Grille_Dyneff__mdt.getInstance(labelCode);

            if(prixGrille != null) {
                qli.Nouvelle_Echeance__c = prixGrille.Date_fin_maximale__c;
                qli.Puissance_souscrite__c = 12;
                listQLI.add(qli);
            }
        }



        input.recordId = quote.Id;
        input.fournisseur = 'Dyneff';
        input.dureeOffre = '12';

        inputs.add(input);

        update listQLI;
        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest();
    }

    @IsTest
    static void caculatePriceEDFEntreprises(){
        
        Quote quote = [SELECT Id From Quote WHERE Fournisseur__c = 'EDF Entreprises'];
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();


        for(QuoteLineItem qli : [SELECT Id, Puissance_souscrite__c FROM QuoteLineItem WHERE Quote.Id = :quote.Id AND TECH_Segment__c = 'C5' ]){
            qli.Puissance_souscrite__c = 12;
            listQLI.add(qli);
        }

        input.recordId = quote.Id;
        input.fournisseur = 'EDF Entreprises';
        input.dureeOffre = '12';

        inputs.add(input);

        update listQLI;
        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest();  
    }
    
    @IsTest
    static void calculatePriceIlek() {
        Quote quote = [SELECT Id From Quote WHERE Fournisseur__c = 'Ilek'];
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();

        for(QuoteLineItem qli : [SELECT Id, Puissance_souscrite__c FROM QuoteLineItem WHERE Quote.Id = :quote.Id AND TECH_Segment__c = 'C5' ]){
            qli.Puissance_souscrite__c = 12;
            listQLI.add(qli);
        }


        input.recordId = quote.Id;
        input.fournisseur = 'Ilek';
        input.dureeOffre = '12';

        inputs.add(input);

        update listQLI;
        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest();  
    }
    
    @IsTest
    static void calculatePriceGEG() {
        Quote quote = [SELECT Id From Quote WHERE Fournisseur__c = 'GEG'];
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();

        for(Quotelineitem qli : [SELECT Id, DebutDeFourniture__c, Nouvelle_Echeance__c, Puissance_souscrite__c,
                   TECH_Segment__c, TECH_FTA__c, TECH_Tarif__c, TECH_CalendrierFournisseur__c,
                   CAR_New__c,CARGaz__c, PDE__r.X12_mois_consommation_SGE__c
            FROM QuoteLineItem
            WHERE QuoteId = :quote.Id
        ]){

            qli.Puissance_souscrite__c = 12;
            qli.CAR_New__c = 100;
            listQLI.add(qli);
        }

        input.recordId = quote.Id;
        input.fournisseur = 'GEG';
        input.dureeOffre = '12';
        input.margeMwh = 5;

        inputs.add(input);

        update listQLI;
        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest();  
    }

    @IsTest
    static void calculatePriceEkwateur() {
        Quote quote = [SELECT Id,OpportunityId From Quote WHERE Fournisseur__c = 'Ekwateur'];
        //Suppression des QLI autre que C4, C5 et T4
        delete [SELECT Id FROM QuoteLineItem WHERE quote.Id =:quote.ID AND TECH_Segment__c not in ('C4','C5')];
        String labelCode = 'C5';
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        Grille_Ekwateur__mdt dateMinMaxGrille = [SELECT Id, Date_debut_min1__c,Date_fin__c,Date_debut_max1__c,Date_debut_min2__c, Date_debut_max2__c FROM Grille_Ekwateur__mdt WHERE DeveloperName like :labelCode+'%' LIMIT 1];

        for(QuoteLineItem qli : [SELECT Id FROM QuoteLineItem WHERE quote.Id =: quote.Id]){
            qli.DebutDeFourniture__c = dateMinMaxGrille.Date_debut_min1__c;
            qli.DebutDeFourniture__c = dateMinMaxGrille.Date_debut_max1__c;
            qli.Nouvelle_Echeance__c = dateMinMaxGrille.Date_fin__c;
            listQLI.add(qli);
        }
        

        update listQLI;
        
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();

        input.recordId = quote.Id;
        input.fournisseur = 'Ekwateur';
        input.dureeOffre = '12';
        input.margeMwh = 15;

        inputs.add(input);
        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);

        // Upodate Opp
        Id oppC4RecordId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_C1C2C3C4'].get(0).Id;
        Opportunity opp  = [SELECT Id from Opportunity LIMIT 1];
        opp.RecordTypeId = oppC4RecordId;
        update opp;

        AP021_GrilleFournisseur.GET_Prix(inputs);

        // Upodate Opp
        Id oppGazRecordId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Simple_Gaz'].get(0).Id;
        opp.RecordTypeId = oppGazRecordId;
        delete [SELECT Id FROM QuoteLineItem WHERE quote.Id =:quote.ID AND TECH_Profil__c <> ''];
        update opp;

        AP021_GrilleFournisseur.GET_Prix(inputs);

        Test.stopTest();
    }

    @IsTest
    static void calculatePriceEngiePro() {
        Quote quote = [SELECT Id From Quote WHERE Fournisseur__c = 'Engie'];
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();


        for(QuoteLineItem qli : [SELECT Id FROM QuoteLineItem WHERE Quote.Id =: quote.Id]){
            qli.DebutDeFourniture__c = DatE.today();
            qli.CARGaz__c = 20;
            qli.puissance_souscrite__c = 12;
            quote.Date_Validite_Offre__c = Date.today().addMonths(1);
            listQLI.add(qli);
        }


        input.recordId = quote.Id;
        input.fournisseur = 'Engie';
        input.dureeOffre = '12_fixe';

        inputs.add(input);

        update listQLI;        
        update quote;
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest();
    }

    @isTest
    static void calculatePriceHellio(){
        Quote quote = [SELECT Id From Quote WHERE Fournisseur__c = 'Hellio'];
        List<QuoteLineItem> listQLI = new List<QuoteLineItem>();
        
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();

        for (QuoteLineItem qli : [SELECT Id, DebutDeFourniture__c, Nouvelle_Echeance__c, Puissance_souscrite__c,
                   TECH_Segment__c, TECH_FTA__c, TECH_Tarif__c, TECH_CalendrierFournisseur__c,
                   CAR_New__c,CARGaz__c, PDE__r.X12_mois_consommation_SGE__c
            FROM QuoteLineItem
            WHERE QuoteId = :quote.Id
              AND TECH_Segment__c IN ('C4', 'C2')]) {
            qli.CAR_New__c = 55;
            qli.Puissance_souscrite__c = 12;
            qli.DebutDeFourniture__c = Date.today();
            qli.Nouvelle_Echeance__c = Date.today().addYears(1);

            listQLI.add(qli);
        }

        input.recordId = quote.Id;
        input.fournisseur = 'Hellio';
        input.dureeOffre = '12';
        input.margeMwh = 5;

        inputs.add(input);

        update listQLI;        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest();
    }

    @IsTest
    static void caculatePriceError(){
        
        Quote quote = [SELECT Id From Quote LIMIT 1];
        List<AP021_GrilleFournisseur.FlowInput> inputs = new List<AP021_GrilleFournisseur.FlowInput>();
        AP021_GrilleFournisseur.FlowInput input = new AP021_GrilleFournisseur.FlowInput();

        input.recordId = quote.Id;
        input.fournisseur = 'Error';
        input.dureeOffre = '12';

        inputs.add(input);
        
        Test.startTest();
        AP021_GrilleFournisseur.GET_Prix(inputs);
        Test.stopTest(); 
    }
}