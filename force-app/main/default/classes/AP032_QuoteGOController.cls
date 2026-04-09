public without sharing class AP032_QuoteGOController {

    // -------- DTO pour init côté LWC ----------
    public class InitResponse {
        @AuraEnabled public List<Quote> quotes;
        @AuraEnabled public List<String> origineOptions;
        @AuraEnabled public Map<String, List<String>> technologieOptionsByType;
        @AuraEnabled public Decimal consoTotal;
        @AuraEnabled public Date minStartElec;
        @AuraEnabled public Date maxEndElec;
        @AuraEnabled public Date minStartGaz;
        @AuraEnabled public Date maxEndGaz;
        @AuraEnabled public Map<String, Decimal> pricingByKey; 
        @AuraEnabled public Map<String, Decimal> margeByKey;   
        @AuraEnabled public Map<String, Id> recordTypeIds;     
    }

    // --------- PUBLIC API ---------
    @AuraEnabled
    public static InitResponse initGO(Id opportunityId) {
        if (opportunityId == null) {
            throw new AuraHandledException('OpportunityId manquant.');
        }

        InitResponse res = new InitResponse();

        // Quotes GO déjà existantes
        res.quotes = getGOQuotes(opportunityId);

        // Picklist Origine
        res.origineOptions = getPicklistValues('Quote', 'OrigineGarantieOrigine__c');

        // --------- TRI TECHNO ---------
        List<String> allValues = getPicklistValues('Quote', 'TechnologieGarantieOrigine__c');

        // Définir les groupes
        Set<String> elecOnly = new Set<String>{ 'Eolien', 'Hydraulique', 'Photovoltaïque' };
        Set<String> gazOnly  = new Set<String>{ 'BioGAZ', 'Biométhane', 'BioGNV' };
        Set<String> both     = new Set<String>{ 'Cogénération', 'Tout confondu' };

        List<String> elecValues = new List<String>();
        List<String> gazValues  = new List<String>();

        for (String v : allValues) {
            if (elecOnly.contains(v) || both.contains(v)) {
                elecValues.add(v);
            }
            if (gazOnly.contains(v) || both.contains(v)) {
                gazValues.add(v);
            }
        }

        res.technologieOptionsByType = new Map<String, List<String>>();
        res.technologieOptionsByType.put('Quote_Elec', elecValues);
        res.technologieOptionsByType.put('Quote_Gaz', gazValues);

        // Conso totale via OpportunityPDERelation__c
        res.consoTotal = getTotalCAR(opportunityId);

        // Min/Max des dates par type sur quotes NON GO
        Map<String, Date> minByType = new Map<String, Date>();
        Map<String, Date> maxByType = new Map<String, Date>();
        getMinMaxDatesByType(opportunityId, minByType, maxByType);
        res.minStartElec = minByType.get('Quote_Elec');
        res.maxEndElec   = maxByType.get('Quote_Elec');
        res.minStartGaz  = minByType.get('Quote_Gaz');
        res.maxEndGaz    = maxByType.get('Quote_Gaz');

        // Pricing & marge depuis Custom Metadata
        res.pricingByKey = new Map<String, Decimal>();
        res.margeByKey   = new Map<String, Decimal>();
        for (GO_Pricing__mdt m : [
            SELECT Origine__c, Technologie__c, PrixGarantieOrigine__c, MargeMin__c
            FROM GO_Pricing__mdt
        ]) {
            String key = (m.Origine__c != null ? m.Origine__c.trim() : '') + '|' +
                        (m.Technologie__c != null ? m.Technologie__c.trim() : '');
            res.pricingByKey.put(key, m.PrixGarantieOrigine__c);
            res.margeByKey.put(key, m.MargeMin__c);
        }

        res.recordTypeIds = new Map<String, Id>();
        for (RecordType rt : [
            SELECT Id, DeveloperName
            FROM RecordType
            WHERE SObjectType = 'Quote'
            AND DeveloperName IN ('Quote_Elec','Quote_Gaz')
        ]) {
            res.recordTypeIds.put(rt.DeveloperName, rt.Id);
        }

        return res;
    }


    @AuraEnabled
    public static List<Quote> saveGOQuotes(List<Quote> quotes) {
        if (quotes == null || quotes.isEmpty()) return new List<Quote>();

        try {
            Map<String, GO_Pricing__mdt> pricingMap = new Map<String, GO_Pricing__mdt>();
            for (GO_Pricing__mdt m : [
                SELECT Origine__c, Technologie__c, PrixGarantieOrigine__c, MargeMin__c
                FROM GO_Pricing__mdt
            ]) {
                String key = (m.Origine__c != null ? m.Origine__c.trim() : '') + '|' +
                             (m.Technologie__c != null ? m.Technologie__c.trim() : '');
                pricingMap.put(key, m);
            }
            for (Quote q : quotes) {
                q.IsGarantieOrigine__c = true;
                if (String.isBlank(q.Name)) {
                    q.Name = 'Garantie Origine ' + DateTime.now().format('dd/MM/yyyy HH:mm');
                }
                if (q.Date_de_fin_de_contrat__c == null && q.FinCouvertureGarantieOrigine__c != null) {
                    q.Date_de_fin_de_contrat__c = q.FinCouvertureGarantieOrigine__c;
                }
                // Fallback Prix / Marge si vide
                if (q.OrigineGarantieOrigine__c != null && q.TechnologieGarantieOrigine__c != null) {
                    String key = q.OrigineGarantieOrigine__c.trim() + '|' + q.TechnologieGarantieOrigine__c.trim();
                    if (pricingMap.containsKey(key)) {
                        GO_Pricing__mdt meta = pricingMap.get(key);
                        if (q.PrixGarantieOrigine__c == null) q.PrixGarantieOrigine__c = meta.PrixGarantieOrigine__c;
                        if (q.MargeGarantieOrigine__c == null) q.MargeGarantieOrigine__c = meta.MargeMin__c;
                    }
                }
            }

            upsert quotes;

            return [
                SELECT Id, QuoteNumber, OpportunityId, IsGarantieOrigine__c,
                       Name, Date_de_fin_de_contrat__c,
                       OrigineGarantieOrigine__c, TechnologieGarantieOrigine__c,
                       DebutCouvertureGarantieOrigine__c, FinCouvertureGarantieOrigine__c,
                       ConsoAnnuelleGarantieOrigine__c, PrixGarantieOrigine__c, MargeGarantieOrigine__c, BudgetGarantieOrigine__c,
                       RecordTypeId, RecordType.Name, RecordType.DeveloperName
                FROM Quote
                WHERE Id IN :quotes
            ];

        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de l\'enregistrement : ' + e.getMessage());
        }
    }

    // --------- PRIVATE HELPERS ----------

    @AuraEnabled(cacheable=true)
    public static List<Quote> getGOQuotes(Id opportunityId) {
        return [
            SELECT Id, QuoteNumber, OpportunityId, IsGarantieOrigine__c,
                   Name, Date_de_fin_de_contrat__c,
                   OrigineGarantieOrigine__c, TechnologieGarantieOrigine__c,
                   DebutCouvertureGarantieOrigine__c, FinCouvertureGarantieOrigine__c,
                   ConsoAnnuelleGarantieOrigine__c, PrixGarantieOrigine__c, MargeGarantieOrigine__c, BudgetGarantieOrigine__c,
                   RecordType.Name, RecordType.DeveloperName, RecordTypeId
            FROM Quote
            WHERE OpportunityId = :opportunityId
            AND IsGarantieOrigine__c = true
            ORDER BY LastModifiedDate DESC
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getPicklistValues(String objectApiName, String fieldApiName) {
        List<String> values = new List<String>();
        try {
            Schema.SObjectType targetType = Schema.getGlobalDescribe().get(objectApiName);
            if (targetType == null) return values;

            Schema.DescribeFieldResult fieldDescribe =
                targetType.getDescribe().fields.getMap().get(fieldApiName).getDescribe();

            for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                values.add(entry.getLabel());
            }
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la récupération des picklist : ' + e.getMessage());
        }
        return values;
    }

    private static Decimal getTotalCAR(Id opportunityId) {
        List<AggregateResult> agg = [
            SELECT SUM(PDE__r.TECH_CAR__c) total
            FROM OpportunityPDERelation__c
            WHERE Opportunity__c = :opportunityId
        ];
        if (!agg.isEmpty() && agg[0].get('total') != null) {
            return (Decimal)agg[0].get('total');
        }
        return 0;
    }

    private static void getMinMaxDatesByType(
        Id opportunityId,
        Map<String, Date> minByType,
        Map<String, Date> maxByType
    ) {
        List<AggregateResult> rows = [
            SELECT RecordType.DeveloperName dev,
                   MIN(Minimum_date_de_debut__c) minStart,
                   MAX(Maximum_date_de_fin__c)   maxEnd
            FROM Quote
            WHERE OpportunityId = :opportunityId
              AND IsGarantieOrigine__c = false
            GROUP BY RecordType.DeveloperName
        ];

        for (AggregateResult r : rows) {
            String dev = (String)r.get('dev');
            minByType.put(dev, (Date)r.get('minStart'));
            maxByType.put(dev, (Date)r.get('maxEnd'));
        }
    }

    @AuraEnabled
    public static void deleteGOQuote(Id quoteId) {
        if (quoteId == null) {throw new AuraHandledException('Id manquant pour suppression.');}
        try {
            delete [SELECT Id FROM Quote WHERE Id = :quoteId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Erreur lors de la suppression : ' + e.getMessage());
        }
    }
}