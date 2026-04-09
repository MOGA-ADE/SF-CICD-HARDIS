/*
 * Test Class for AP025_CreateCommission
 */
@isTest
public class AP025_CreateCommission_TEST {


    @testSetup
    static void makeData(){
        TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        List<User> listUserToInsert = new List<User>();
        
        Contract contract = new Contract();
        contract.Name = 'Test';
        contract.AccountId = acc.Id;
        contract.Opportunity__c = opp.Id;
        contract.FournisseurPicklist__c = 'Engie';
        contract.Type_offre__c = 'PRIX FIXE';
        contract.StartDate = Date.today();
        contract.ContractTerm = 12;
        contract.Date_echeance__c = Date.today();
        contract.Budget_TTC_annee__c = 1000;
        contract.Budget_HTVA_annee__c = 1000;
        contract.Commission_ADE__c = 1000;
        contract.Commission_globale__c = 1000;
        insert contract;

        Appel_facturation__c AF = new Appel_facturation__c();
        AF.Contrat__c = contract.Id;
        AF.Montant__c = 1000;
        AF.paye__c = 'ADE';
        AF.Statut__c = 'En attente de validation ADV';
        AF.Mois_facturation_concerne__c = Date.newInstance(2024,6,1);
        insert AF;

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Commercial' LIMIT 1];
        UserRole incubeRole = [SELECT Id FROM UserRole WHERE Name = 'Incubé' LIMIT 1];

        User commercial = new User(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'johndoe@example.com',
            Phone = '06 06 06 06 06',
            Username = 'johndoe' + DateTime.now().getTime() + '@example.com',
            Alias = 'jdoe',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert commercial;

        User currentUser = new User(Id=UserInfo.getUserId());
        System.runAs(currentUser){

    
    
            User incube = new User(
                FirstName = 'Nicole',
                LastName = 'Doe',
                Email = 'johndoe2@example.com',
                Phone = '06 06 06 06 06',
                Username = 'johndoe2' + DateTime.now().getTime() + '@example.com',
                Alias = 'jdoe',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                ProfileId = p.Id,
                UserRoleId = incubeRole.Id,
                companyName = 'TEST NOM ENTREPRISE'
            );
    
            insert incube;
    
            incube.TECH_Responsable_legal_Id__c = commercial.Id;
            update incube;
            
        }

        Id recordTypeId = [SELECT Id FROM RecordType WHERE Name ='Salarié'].Id;

        Convention__c conventionSalarie = new Convention__c(
            Name = 'CONVENTION TEST',
            Date_debut__c = Date.today(),
            Date_fin__c = Date.today().addYears(1),
            Type_de_remuneration__c = '€/Compteur',
            Salarie__c = commercial.Id,
            Remuneration_E_NmbrCompteur__c = 5
        );

        insert conventionSalarie;
    }

    @isTest
    static void testCreateCommissionSalarie() {
        // Step 1: Setup test data


        List<Appel_facturation__c> results = AP023_CheckContratsFournisseurController.getAppelFacturation('Engie','06','2024');

        User commercial = [SELECT Id FROM USER WHERE Email = 'johndoe@example.com' LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        // Simulate commission data
        WrapCommission testCommission = new WrapCommission();
        testCommission.commercial = commercial.Id;
        testCommission.moisPaiement = Date.newInstance(2024, 12, 1);
        testCommission.contrat = contract.Id;
        testCommission.montant = 1000.00;
        testCommission.appelFacturation = results.get(0).Id;
        testCommission.prenomCommercial = 'John';
        testCommission.nomCommercial = 'Doe';

        List<WrapCommission> commissionList = new List<WrapCommission>{testCommission};
        AP025_CreateCommission.FlowInputs flowInput = new AP025_CreateCommission.FlowInputs();
        flowInput.listCommissions = commissionList;

        List<AP025_CreateCommission.FlowInputs> flowInputs = new List<AP025_CreateCommission.FlowInputs>{flowInput};

        // Step 2: Invoke the method
        Test.startTest();
        List<AP025_CreateCommission.FlowOutput> outputs = AP025_CreateCommission.createCommission(flowInputs);
        Test.stopTest();

        // Step 3: Verify results
        AP025_CreateCommission.FlowOutput output = outputs.get(0);
        System.assertEquals(true, output.commissionCreated, 'Le champs commissionCreated doit être à vrai');
        System.assertEquals('Les commissions ont bien été créées', output.message, 'La fonction doit retourner un message de succès');

        // Verify that the Chiffre_affaire__c and Commission__c records are inserted
        List<Chiffre_affaire__c> caList = [SELECT Id, Name FROM Chiffre_affaire__c];
        System.assertEquals(1, caList.size(), 'La fonction doit créer un seul chiffre d\'affaire');
        System.assertEquals('J.DOE - 12/2024', caList[0].Name, 'Le nom du chiffre d\'affaire n\'est pas le bon ');

        List<Commission__c> commissionListDB = [SELECT Id, Name FROM Commission__c];
        System.assertEquals(1, commissionListDB.size(), 'La fonction doit créer une seule commission');
        System.assertEquals('Engie ADE 12-2024 TestAccount0', commissionListDB[0].Name, 'Le nom de la commission n\'est pas bon');
    }

    @isTest
    static void testCreateCommissionIncube() {
        // Step 1: Setup test data
        List<Appel_facturation__c> results = AP023_CheckContratsFournisseurController.getAppelFacturation('Engie','06','2024');        
        User incube = [SELECT Id FROM USER WHERE Email = 'johndoe2@example.com' LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        // Simulate commission data
        WrapCommission testCommission = new WrapCommission();
        testCommission.commercial = incube.Id;
        testCommission.moisPaiement = Date.newInstance(2024, 12, 1);
        testCommission.contrat = contract.Id;
        testCommission.montant = 1000.00;
        testCommission.appelFacturation = results.get(0).Id;
        testCommission.prenomCommercial = 'John';
        testCommission.nomCommercial = 'Doe';

        List<WrapCommission> commissionList = new List<WrapCommission>{testCommission};
        AP025_CreateCommission.FlowInputs flowInput = new AP025_CreateCommission.FlowInputs();
        flowInput.listCommissions = commissionList;

        List<AP025_CreateCommission.FlowInputs> flowInputs = new List<AP025_CreateCommission.FlowInputs>{flowInput};

        // Step 2: Invoke the method
        Test.startTest();
        List<AP025_CreateCommission.FlowOutput> outputs = AP025_CreateCommission.createCommission(flowInputs);
        Test.stopTest();

        // Step 3: Verify results
        AP025_CreateCommission.FlowOutput output = outputs.get(0);
        System.assertEquals(true, output.commissionCreated, 'La fonction créé bien les commissions');
        System.assertEquals('Les commissions ont bien été créées', output.message, 'La fonction retourne un message de succès');

        // Verify that the Chiffre_affaire__c and Commission__c records are inserted
        List<Chiffre_affaire__c> caList = [SELECT Id, Name FROM Chiffre_affaire__c];
        System.assertEquals(1, caList.size(), 'Création d\'un seul chffre d\'affaire');
        System.assertEquals('TEST NOM ENTREPRISE - 12/2024', caList[0].Name, 'Chiffre affaire name should match');

        List<Commission__c> commissionListDB = [SELECT Id, Name FROM Commission__c];
        System.assertEquals(1, commissionListDB.size(), 'Chiffre d\'affaire créé');
        System.assertEquals('Engie ADE 12-2024 TestAccount0', commissionListDB[0].Name, 'Commission créé');
    }

    @isTest
    static void testCreateCommissionSalarieWithoutConvention(){
        // Step 1: Setup test data
        Convention__c[] conventionToDelete = [SELECT Id FROM Convention__c ]; 
        delete conventionToDelete;
        List<Appel_facturation__c> results = AP023_CheckContratsFournisseurController.getAppelFacturation('Engie','06','2024');        
        User incube = [SELECT Id FROM USER WHERE Email = 'johndoe2@example.com' LIMIT 1];
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        // Simulate commission data
        WrapCommission testCommission = new WrapCommission();
        testCommission.commercial = incube.Id;
        testCommission.moisPaiement = Date.newInstance(2024, 12, 1);
        testCommission.contrat = contract.Id;
        testCommission.montant = 1000.00;
        testCommission.appelFacturation = results.get(0).Id;
        testCommission.prenomCommercial = 'John';
        testCommission.nomCommercial = 'Doe';

        List<WrapCommission> commissionList = new List<WrapCommission>{testCommission};
        AP025_CreateCommission.FlowInputs flowInput = new AP025_CreateCommission.FlowInputs();
        flowInput.listCommissions = commissionList;

        List<AP025_CreateCommission.FlowInputs> flowInputs = new List<AP025_CreateCommission.FlowInputs>{flowInput};

        // Step 2: Invoke the method
        Test.startTest();
        List<AP025_CreateCommission.FlowOutput> outputs = AP025_CreateCommission.createCommission(flowInputs);
        Test.stopTest();
        // Step 3: Verify results
        AP025_CreateCommission.FlowOutput output = outputs.get(0);
        System.assertEquals(false, output.commissionCreated, 'Le champs commissionCreated doit être à faux');
        System.assertEquals('Convention inexistante ou inactive', output.message, 'La fonction doit retourner un message d\'erreur');

        // Verify that the Chiffre_affaire__c and Commission__c records are inserted
        List<Chiffre_affaire__c> caList = [SELECT Id, Name FROM Chiffre_affaire__c];
        System.assertEquals(0, caList.size(), 'La fonction ne doit pas créer de chiffre d\'affaire');

        List<Commission__c> commissionListDB = [SELECT Id, Name FROM Commission__c];
        System.assertEquals(0, commissionListDB.size(), 'La fonction ne doit pas créer de commission');
    }
}