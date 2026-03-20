@isTest
private class BatchQuoteLineItem_TEST {
    // Ajouter le cas pour le PDE GAZ et le PDE MU
    //Créer des fonctions de test unitaire (Séparer les cas C5/Gaz/C1C2C3C4)
    @testSetup
    static void setupData() {
        TestDataFactory.createPriceBooks();

        // Récupération des RecordType en une seule requête pour éviter plusieurs SOQL oo
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        for (RecordType rt : [SELECT Id, DeveloperName FROM RecordType WHERE DeveloperName IN ('Elec_C3_C4', 'PDE_ElecC5', 'PDE_Gaz')]) {
            recordTypeMap.put(rt.DeveloperName, rt.Id);
        }

        // Récupération du PriceBook et de l'entrée produit associée
        Pricebook2 pb = [SELECT Id FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
        PricebookEntry priceBookEntry = [SELECT Product2Id FROM PricebookEntry WHERE Name = 'ELEC' AND Pricebook2Id = :pb.Id LIMIT 1];

        // Liste des configurations pour les différents PDE__c
        List<Map<String, Object>> pdeConfigs = new List<Map<String, Object>>{
            new Map<String, Object>{'Segment' => 'C4', 'FTA' => 'BT > 36 kVA - CU', 'RecordTypeId' => recordTypeMap.get('Elec_C3_C4')},
            new Map<String, Object>{'Segment' => 'C5', 'FTA' => 'BT > 36 kVA - MU', 'RecordTypeId' => recordTypeMap.get('PDE_ElecC5')},
            new Map<String, Object>{'Segment' => 'C5', 'FTA' => 'BT <= 36 kVA - LU EP', 'RecordTypeId' => recordTypeMap.get('PDE_ElecC5')},
            new Map<String, Object>{'Segment' => 'C5', 'FTA' => 'BT <= 36Kva - MU 4 postes', 'RecordTypeId' => recordTypeMap.get('PDE_ElecC5')}
        };

        // Initialisation de la liste des PDE à insérer
        List<PDE__c> pdeList = new List<PDE__c>();

        // Création dynamique des PDE__c en fonction de la configuration
        for (Map<String, Object> config : pdeConfigs) {
            pdeList.add(new PDE__c(
                Conso_Pointe__c = 123,
                Conso_HPH__c = 123,
                Conso_HCH__c = 123,
                Conso_HPE__c = 123,
                Conso_HCE__c = 123,
                Conso_Base__c = 123,
                ConsoHP__c = 123,
                ConsoHC__c = 123,
                Puissance_souscrite__c = 123,
                Segment__c = (String) config.get('Segment'),
                FTA__c = (String) config.get('FTA'),
                RecordTypeId = (Id) config.get('RecordTypeId')
            ));
        }

        insert pdeList;

        Opportunity opp = new Opportunity();
        opp.Name = 'test opp';
        opp.StageName = 'Négociation';
        opp.CloseDate = Date.today();
        insert opp;

        Quote quote = new Quote();
        quote.Name = 'test quote';
        quote.OpportunityId = opp.Id;
        quote.Date_de_fin_de_contrat__c = Date.today();
        quote.Pricebook2Id = pb.Id;
        insert quote;

        List<QuoteLineItem> listquote = new List<QuoteLineItem>();

        for (PDE__c p : pdeList) {
            QuoteLineItem qli = new QuoteLineItem();
            qli.QuoteId = quote.Id;
            qli.Product2Id = priceBookEntry.Product2Id;
            qli.PricebookEntryId = priceBookEntry.Id;
            qli.Opportunit__c = opp.Id;
            qli.PDE__c = p.Id;
            qli.Quantity = 1;
            qli.UnitPrice = 0;
            qli.Taxes__c = true;
            qli.Puissance_souscrite__c = 123;
            qli.Conso_Base__c = 123;
            qli.ConsoHC__c = 123;
            qli.Conso_HCE__c = 123;
            qli.Conso_HCH__c = 123;
            qli.ConsoHP__c = 123;
            qli.Conso_HPE__c = 123;
            qli.Conso_HPH__c = 123;
            qli.Conso_Pointe__c = 123;
            qli.AbonnementMois__c = 123;
            qli.CSPE__c = 123;
            qli.CeeMwh__c = 123;
            qli.TDCFE__c = 123;
            qli.TCCFE__c = 123;
            qli.Capa_HP__c = 123;
            qli.Capa_HC__c = 123;
            qli.Capa_HPH__c = 123;
            qli.Capa_HCH__c = 123;
            qli.Capa_HPE__c = 123;
            qli.Capa_HCE__c = 123;
            qli.Capa_Base__c = 123;
            qli.PrixHP__c = 123;
            qli.PrixHC__c = 123;
            qli.PrixHphMwh__c = 123;
            qli.PrixHchMwh__c = 123;
            qli.PrixHpeMwh__c = 123;
            qli.PrixHceMwh__c = 123;
            qli.PrixBase__c = 123;
            qli.PointesMWh__c = 123;
            qli.Capa_Pointes__c = 123;
            qli.PrixMolecule__c = 123;
            qli.CARGaz__c = 123;
            qli.FraisTransportDistributionCapacite__c = 123;
            qli.CTA__c = 123;
    
            listquote.add(qli);
        }
        insert listquote;  
    }

    static testMethod void testBatchExecute() {
        Test.startTest();
        
        // Initialisation du batch avec une condition WHERE factice
        BatchQuoteLineItem batch = new BatchQuoteLineItem();
        batch.WhereQuery = ' WHERE Id != NULL';
        
        Database.executeBatch(batch, 4);
        
        Test.stopTest();

        // Vérifiez que les valeurs sont bien calculées
        QuoteLineItem qliUpdated = [SELECT BudgetFourniture__c FROM QuoteLineItem LIMIT 1];
        System.assert(qliUpdated.BudgetFourniture__c > 0, 'Le budget devrait être calculé.');
    }
}