@IsTest
private class AP032_QuoteGOController_TEST {

    @TestSetup
    static void setup() {
        // Jeu de données de base
        TestDataFactory.createDataForComparatifGaz();
        TestDataFactory.createDataForComparatifElec();

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id rtElecId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Quote_Elec' LIMIT 1].Id;
        Id rtGazId  = [SELECT Id FROM RecordType WHERE DeveloperName = 'Quote_Gaz' LIMIT 1].Id;

        // Quote NON-GO (sert pour getMinMaxDatesByType)
        insert new Quote(
            Name = 'Quote Non-GO Gaz',
            OpportunityId = opp.Id,
            RecordTypeId = rtGazId,
            IsGarantieOrigine__c = false,
            DebutCouvertureGarantieOrigine__c = Date.today(),
            FinCouvertureGarantieOrigine__c = Date.today().addMonths(12),
            Date_de_fin_de_contrat__c = Date.today().addMonths(12)
        );

        // Quote GO Elec
        insert new Quote(
            Name = 'Quote GO Elec',
            OpportunityId = opp.Id,
            RecordTypeId = rtElecId,
            IsGarantieOrigine__c = true,
            OrigineGarantieOrigine__c = 'Française',
            TechnologieGarantieOrigine__c = 'Photovoltaïque',
            DebutCouvertureGarantieOrigine__c = Date.today(),
            FinCouvertureGarantieOrigine__c = Date.today().addMonths(6),
            ConsoAnnuelleGarantieOrigine__c = 10,
            PrixGarantieOrigine__c = 2,
            MargeGarantieOrigine__c = 1,
            Date_de_fin_de_contrat__c = Date.today().addMonths(6)
        );
    }

    @IsTest
    static void testInitGO_full() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        AP032_QuoteGOController.InitResponse res = AP032_QuoteGOController.initGO(opp.Id);
        Test.stopTest();

        Assert.isNotNull(res, 'La réponse ne doit pas être null');
        Assert.isTrue(res.quotes.size() > 0, 'Il doit y avoir au moins une GO Quote');
        Assert.isTrue(res.consoTotal >= 0, 'La conso totale doit être positive');
        Assert.isTrue(res.recordTypeIds.containsKey('Quote_Elec'), 'Le recordType Quote_Elec doit exister');
        Assert.isTrue(res.technologieOptionsByType.get('Quote_Elec').size() > 0, 'Des technos Elec doivent être proposées');
    }

    @IsTest
    static void testSaveGOQuotes_withFallback() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Id rtElecId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Quote_Elec' LIMIT 1].Id;

        Quote q = new Quote(
            OpportunityId = opp.Id,
            RecordTypeId = rtElecId,
            OrigineGarantieOrigine__c = 'Française',
            TechnologieGarantieOrigine__c = 'Photovoltaïque',
            DebutCouvertureGarantieOrigine__c = Date.today(),
            FinCouvertureGarantieOrigine__c = Date.today().addMonths(1),
            Date_de_fin_de_contrat__c = Date.today().addMonths(1)
        );

        Test.startTest();
        List<Quote> saved = AP032_QuoteGOController.saveGOQuotes(new List<Quote>{q});
        Test.stopTest();

        Assert.areEqual(1, saved.size(), 'Une quote doit être sauvegardée');
        Assert.isTrue(saved[0].IsGarantieOrigine__c, 'Le flag GO doit être vrai');
        Assert.isNotNull(saved[0].Name, 'Le nom doit être renseigné');
    }

    @IsTest
    static void testSaveGOQuotes_empty() {
        Test.startTest();
        List<Quote> saved = AP032_QuoteGOController.saveGOQuotes(new List<Quote>());
        Test.stopTest();
        Assert.areEqual(0, saved.size(), 'La liste doit être vide');
    }

    @IsTest
    static void testDeleteGOQuote() {
        Quote q = [SELECT Id FROM Quote WHERE IsGarantieOrigine__c = true LIMIT 1];
        Test.startTest();
        AP032_QuoteGOController.deleteGOQuote(q.Id);
        Test.stopTest();

        Assert.areEqual(0, [SELECT Count() FROM Quote WHERE Id = :q.Id], 'La quote doit être supprimée');
    }

    @IsTest
    static void testGetPicklistValues() {
        Test.startTest();
        List<String> origineVals = AP032_QuoteGOController.getPicklistValues('Quote','OrigineGarantieOrigine__c');
        Test.stopTest();

        Assert.isTrue(origineVals.size() > 0, 'La liste de picklist Origine doit contenir des valeurs');
    }
}