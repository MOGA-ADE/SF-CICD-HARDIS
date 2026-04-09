public with sharing class VFC008_ResumeComparatifPDFController {

    public static Opportunity opp { get; set; }
    public static Boolean isOppGaz { get { return opp.TECH_IsGaz__c; } set; }
    public static Boolean isOppSimpleRT { get { return opp.RecordType.Name.contains('Simple'); } set; }
    public static Boolean isOppPartenaire { get { return opp.Demande_Cotation__r.TECH_Partner_OwnerName__c != null; } set; }
    public static Boolean showSectionTTC { get; set; }
    public static Boolean showSectionSituationActuelle { get; set; }
    public static String todayDate { get{ return Date.today().format().toString();} set; }
    public static List<String> fournisseursList { get; set; }
    public static List<String> quoteNumberList { get; set; }
    public static List<BudgetGlobalWrapper> listBudgetGlobal { get; set; }
    public static List<PrixMoyenWrapper> listprixMoyenT1 { get; set; }
    public static List<PrixMoyenWrapper> listprixMoyenT2 { get; set; }
    public static List<PrixMoyenWrapper> listprixMoyenT3 { get; set; }
    public static List<PrixMoyenWrapper> listprixMoyenT4 { get; set; }
    public static List<PrixMoyenWrapper> listprixMoyenC54postes { get; set; }
    public static List<PrixMoyenWrapper> listprixMoyenC5Base { get; set; }
    public static List<PrixMoyenWrapper> listprixMoyenC4 { get; set; }
    public static List<PrixMoyenWrapper> listprixMoyenC1C2 { get; set; }
    public static List<VolumeTotalWrapper> listvolumeTotalGaz { get; set; }
    public static List<VolumeTotalWrapper> listvolumeTotalC54postes { get; set; }
    public static List<VolumeTotalWrapper> listvolumeTotalC5Base { get; set; }
    public static List<VolumeTotalWrapper> listvolumeTotalC4 { get; set; }
    public static List<VolumeTotalWrapper> listvolumeTotalC1C2 { get; set; }
    public static Boolean listprixMoyenT1NotEmpty { get { return !listprixMoyenT1.isEmpty(); } set; }
    public static Boolean listprixMoyenT2NotEmpty { get { return !listprixMoyenT2.isEmpty(); } set; }
    public static Boolean listprixMoyenT3NotEmpty { get { return !listprixMoyenT3.isEmpty(); } set; }
    public static Boolean listprixMoyenT4NotEmpty { get { return !listprixMoyenT4.isEmpty(); } set; }
    public static Boolean listprixMoyenC54PostesNotEmpty { get { return !listprixMoyenC54postes.isEmpty(); } set; }
    public static Boolean listprixMoyenC5BaseNotEmpty { get { return !listprixMoyenC5Base.isEmpty(); } set; }
    public static Boolean listprixMoyenC4NotEmpty { get { return !listprixMoyenC4.isEmpty(); } set; }
    public static Boolean listprixMoyenC1C2NotEmpty { get { return !listprixMoyenC1C2.isEmpty(); } set; }
    public static Boolean listvolumeTotalGazNotEmpty { get { return !listvolumeTotalGaz.isEmpty(); } set; }
    public static Boolean listvolumeTotalC54postesNotEmpty { get { return !listvolumeTotalC54postes.isEmpty(); } set; }
    public static Boolean listvolumeTotalC5BaseNotEmpty { get { return !listvolumeTotalC5Base.isEmpty(); } set; }
    public static Boolean listvolumeTotalC4NotEmpty { get { return !listvolumeTotalC4.isEmpty(); } set; }
    public static Boolean listvolumeTotalC1C2NotEmpty { get { return !listvolumeTotalC1C2.isEmpty(); } set; }
    public static Set<String> setFournisseurWithPageInfo { get; set; }
    public static List<String> listFournisseurName { get; set; }
    public static List<Quote> goQuotesElec { get; set; }
    public static List<Quote> goQuotesGaz  { get; set; }
    public static Boolean showGOElec { get; set; }
    public static Boolean showGOGaz  { get; set; }
    public static List<String> goQuoteNumberList { get; set; }

    public static List<QuoteLineItem> lstQLITurpe { get; set; }
    public static Boolean turpeIsMonoSite { get; set; }
    public static Boolean showTurpeMono { get { return (lstQLITurpe != null && !lstQLITurpe.isEmpty() && turpeIsMonoSite); } set; }
    public static Boolean showTurpeMulti { get { return (lstQLITurpe != null && !lstQLITurpe.isEmpty() && !turpeIsMonoSite); } set; }
    public static Decimal totalBudgetActuel   { get; set; }
    public static Decimal totalBudgetOptimal  { get; set; }
    public static Decimal totalEconomie       { get; set; }

    public static String noteDateText { get; set; }
    public static String noteConsoText { get; set; }

    // --- AJOUT : classes CSS dynamiques (monosite) ---
    public static String cssPartFixeCS        { get; set; }
    public static String cssPartVariableCS    { get; set; }
    public static String cssDepassement       { get; set; }
    public static String cssTaxeCTA           { get; set; }
    public static String cssInterventionPEPS  { get; set; }
    public static String cssBudgetTotal       { get; set; }
    public static String cssBudgetTotalMulti  { get; set; }

    // Helper très simple
    private static String cssClass(Decimal optimal, Decimal actuel) {
        if (optimal == null || actuel == null) return '';
        if (optimal >  actuel) return 'turpe-negative';
        if (optimal <  actuel) return 'turpe-positive';
        return '';
    }

    public VFC008_ResumeComparatifPDFController() {
        Id oppId = ApexPages.currentPage().getParameters().get('id');
        String fournisseurs = ApexPages.currentPage().getParameters().get('fournisseurs');
        String quoteNumbers = ApexPages.currentPage().getParameters().get('quoteNumbers');
        String goQuoteNumbers = ApexPages.currentPage().getParameters().get('goQuoteNumbers');
        Boolean includeAllGO = Boolean.valueOf(ApexPages.currentPage().getParameters().get('includeAllGO'));

        showSectionTTC = Boolean.valueOf(ApexPages.currentPage().getParameters().get('sectionTTC'));
        showSectionSituationActuelle = Boolean.valueOf(ApexPages.currentPage().getParameters().get('sectionSituationActuelle'));

        fournisseursList = String.isNotBlank(fournisseurs) ? fournisseurs.split(';') : new List<String>();
        quoteNumberList  = String.isNotBlank(quoteNumbers) ? quoteNumbers.split(';') : new List<String>();
        goQuoteNumberList = String.isNotBlank(goQuoteNumbers) ? goQuoteNumbers.split(';') : new List<String>();

        listBudgetGlobal = new List<BudgetGlobalWrapper>();
        listprixMoyenT1 = new List<PrixMoyenWrapper>();
        listprixMoyenT2 = new List<PrixMoyenWrapper>();
        listprixMoyenT3 = new List<PrixMoyenWrapper>();
        listprixMoyenT4 = new List<PrixMoyenWrapper>();
        listprixMoyenC54postes = new List<PrixMoyenWrapper>();
        listprixMoyenC5Base = new List<PrixMoyenWrapper>();
        listprixMoyenC4 = new List<PrixMoyenWrapper>();
        listprixMoyenC1C2 = new List<PrixMoyenWrapper>();
        listvolumeTotalGaz = new List<VolumeTotalWrapper>();
        listvolumeTotalC54postes = new List<VolumeTotalWrapper>();
        listvolumeTotalC5Base = new List<VolumeTotalWrapper>();
        listvolumeTotalC4 = new List<VolumeTotalWrapper>();
        listvolumeTotalC1C2 = new List<VolumeTotalWrapper>();

        Map<Id, BudgetGlobalWrapper> budgetMap = new Map<Id, BudgetGlobalWrapper>();
        Map<Id, PrixMoyenWrapper> prixMoyenT1Map = new Map<Id, PrixMoyenWrapper>();
        Map<Id, PrixMoyenWrapper> prixMoyenT2Map = new Map<Id, PrixMoyenWrapper>();
        Map<Id, PrixMoyenWrapper> prixMoyenT3Map = new Map<Id, PrixMoyenWrapper>();
        Map<Id, PrixMoyenWrapper> prixMoyenT4Map = new Map<Id, PrixMoyenWrapper>();
        Map<Id, PrixMoyenWrapper> prixMoyenC54postesMap = new Map<Id, PrixMoyenWrapper>();
        Map<Id, PrixMoyenWrapper> prixMoyenC5BaseMap = new Map<Id, PrixMoyenWrapper>();
        Map<Id, PrixMoyenWrapper> prixMoyenC4Map = new Map<Id, PrixMoyenWrapper>();
        Map<Id, PrixMoyenWrapper> prixMoyenC1C2Map = new Map<Id, PrixMoyenWrapper>();
        Map<String, VolumeTotalWrapper> volumeTotalGazMap = new Map<String, VolumeTotalWrapper>();
        Map<String, VolumeTotalWrapper> volumeTotalC54postesMap = new Map<String, VolumeTotalWrapper>();
        Map<String, VolumeTotalWrapper> volumeTotalC5BaseMap = new Map<String, VolumeTotalWrapper>();
        Map<String, VolumeTotalWrapper> volumeTotalC4Map = new Map<String, VolumeTotalWrapper>();
        Map<String, VolumeTotalWrapper> volumeTotalC1C2Map = new Map<String, VolumeTotalWrapper>();
        Set<String> setFournisseurWithPageInfo = new Set<String>();

        List<Fiche_fournisseur__mdt> fournisseurMetadataList = [SELECT ImageName__c FROM Fiche_fournisseur__mdt];
        for (Fiche_fournisseur__mdt metadata : fournisseurMetadataList) {
            setFournisseurWithPageInfo.add(metadata.ImageName__c);
        }

        // Get Opportunity
        opp = [ SELECT Id, 
                    Name, 
                    TECH_IsGaz__c,
                    RecordType.Name,
                    SectionSituationActuelle__c, 
                    Account.Name,
                    Demande_Cotation__r.Owner.Name, 
                    Demande_Cotation__r.Owner.Email, 
                    Demande_Cotation__r.Owner.Phone,
                    Demande_Cotation__r.TECH_Partner_OwnerName__c
                FROM Opportunity 
                WHERE Id = :oppId ];

        // === Get GO Quotes (comme dans VFC007)
        String goSoql =
            'SELECT Id, Name, QuoteNumber, RecordType.DeveloperName,' +
            ' OrigineGarantieOrigine__c, TechnologieGarantieOrigine__c,' +
            ' DebutCouvertureGarantieOrigine__c, FinCouvertureGarantieOrigine__c,' +
            ' ConsoAnnuelleGarantieOrigine__c, PrixGarantieOrigine__c, MargeGarantieOrigine__c, BudgetGarantieOrigine__c' +
            ' FROM Quote' +
            ' WHERE OpportunityId = :oppId' +
            ' AND IsGarantieOrigine__c = true';

        if (!(includeAllGO || goQuoteNumberList.isEmpty())) {
            goSoql += ' AND QuoteNumber IN :goQuoteNumberList';
        }
        goSoql += ' ORDER BY BudgetGarantieOrigine__c ASC';

        List<Quote> goQuotes = Database.query(goSoql);
        goQuotesElec = new List<Quote>();
        goQuotesGaz  = new List<Quote>();

        for (Quote q : goQuotes) {
            if (q.RecordType.DeveloperName == 'Quote_Elec') {
                goQuotesElec.add(q);
            } else if (q.RecordType.DeveloperName == 'Quote_Gaz') {
                goQuotesGaz.add(q);
            }
        }

        showGOElec = !goQuotesElec.isEmpty();
        showGOGaz  = !goQuotesGaz.isEmpty();

        // Get All QLI
        for (QuoteLineItem qli : [  SELECT  TECH_Fournisseur__c,
                                            TECH_TypePDL__c,
                                            TECH_Segment__c,
                                            TECH_FTA__c,
                                            TECH_Tarif__c,
                                            TECH_Profil__c,
                                            T_QuoteCAPA__c,
                                            T_QuoteCEE__c,
                                            LogoCompactLayout__c,
                                            Quote.Id,
                                            Quote.TypeOffre__c,
                                            Quote.Minimum_date_de_debut__c,
                                            Quote.Maximum_date_de_fin__c,
                                            Budget_Energie_Euro_An__c,
                                            Budget_Energie_Gaz__c,
                                            Budget_Acheminement_Annuel_HTT__c,
                                            Budget_Acheminement_Gaz__c,
                                            Budget_Taxes_annuel_HTVA__c,
                                            Budget_Taxes_et_Contribution_Gaz__c,
                                            TECH_Budget__c,
                                            Budget_TTC__c,
                                            AbonnementMois__c,
                                            PointesMWh__c,
                                            PrixHchMwh__c,
                                            PrixHphMwh__c,
                                            PrixHceMwh__c,
                                            PrixHpeMwh__c,
                                            PrixHC__c,
                                            PrixHP__c,
                                            PrixBase__c,
                                            PrixMolecule__c,
                                            FraisTransportDistributionCapacite__c,
                                            CeeMwh__c,
                                            Conso_Pointe__c,
                                            Conso_HCH__c,
                                            Conso_HPH__c,
                                            Conso_HCE__c,
                                            Conso_HPE__c,
                                            ConsoHC__c,
                                            ConsoHP__c,
                                            Conso_Base__c,
                                            CAR_New__c,
                                            CARGaz__c,
                                            Capa_HPE__c,
                                            Capa_HPH__c,
                                            Capa_HCE__c,
                                            Capa_HCH__c,
                                            Capa_Base__c,
                                            Capa_Pointes__c,
                                            Capa_HP__c,
                                            Capa_HC__c
                                    FROM QuoteLineItem 
                                    WHERE Opportunit__c = :oppId 
                                    AND TECH_fournisseur__c IN :fournisseursList
                                    AND Quote.QuoteNumber IN :quoteNumberList]) {

            /*
            * Get Budget Globaux
            */
            Id quoteID = qli.Quote.Id;

            if (!budgetMap.containsKey(quoteID)) {
                budgetMap.put(quoteID, new BudgetGlobalWrapper(qli.TECH_Fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c));
            }

            BudgetGlobalWrapper bg = budgetMap.get(quoteID);

            bg.BudgetEnergieElec += qli.Budget_Energie_Euro_An__c;
            bg.BudgetEnergieGaz += qli.Budget_Energie_Gaz__c;
            bg.BudgetAcheminementElec += qli.Budget_Acheminement_Annuel_HTT__c;
            bg.BudgetAcheminementGaz += qli.Budget_Acheminement_Gaz__c;
            bg.BudgetTaxeElec += qli.Budget_Taxes_annuel_HTVA__c;
            bg.BudgetTaxeGaz += qli.Budget_Taxes_et_Contribution_Gaz__c;
            bg.TotalHTVAElec += qli.TECH_Budget__c != null ? qli.TECH_Budget__c : 0;
            bg.TotalHTVAGaz += qli.TECH_Budget__c != null ? qli.TECH_Budget__c : 0;
            bg.TotalTTC += qli.Budget_TTC__c;

            /*
            * Get Prix Moyen par FTA/Tarifs
            */
            if (isOppGaz) {
                if (qli.TECH_Tarif__c == 'T1') {
                    if (!prixMoyenT1Map.containsKey(quoteID)) {
                        prixMoyenT1Map.put(quoteID, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                    }
    
                    PrixMoyenWrapper pm = prixMoyenT1Map.get(quoteID);
                    pm.cee += (qli.CeeMwh__c * qli.CARGaz__c);
                    pm.molecule += (qli.PrixMolecule__c * qli.CARGaz__c);
                    pm.consoTotalCar += qli.CARGaz__c;
                    pm.fraisDistributionVariable = qli.FraisTransportDistributionCapacite__c;
    
                } else if (qli.TECH_Tarif__c == 'T2') {
                    if (!prixMoyenT2Map.containsKey(quoteID)) {
                        prixMoyenT2Map.put(quoteID, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                    }
    
                    PrixMoyenWrapper pm = prixMoyenT2Map.get(quoteID);
                    pm.cee += (qli.CeeMwh__c * qli.CARGaz__c);
                    pm.molecule += (qli.PrixMolecule__c * qli.CARGaz__c);
                    pm.consoTotalCar += qli.CARGaz__c;
                    pm.fraisDistributionVariable = qli.FraisTransportDistributionCapacite__c;
    
                } else if (qli.TECH_Tarif__c == 'T3') {
                    if (!prixMoyenT3Map.containsKey(quoteID)) {
                        prixMoyenT3Map.put(quoteID, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                    }
    
                    PrixMoyenWrapper pm = prixMoyenT3Map.get(quoteID);
                    pm.cee += (qli.CeeMwh__c * qli.CARGaz__c);
                    pm.molecule += (qli.PrixMolecule__c * qli.CARGaz__c);
                    pm.consoTotalCar += qli.CARGaz__c;
                    pm.fraisDistributionVariable = qli.FraisTransportDistributionCapacite__c;
    
                } else if (qli.TECH_Tarif__c == 'T4') {
                    if (!prixMoyenT4Map.containsKey(quoteID)) {
                        prixMoyenT4Map.put(quoteID, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                    }
    
                    PrixMoyenWrapper pm = prixMoyenT4Map.get(quoteID);
                    pm.cee += (qli.CeeMwh__c * qli.CARGaz__c);
                    pm.molecule += (qli.PrixMolecule__c * qli.CARGaz__c);
                    pm.consoTotalCar += qli.CARGaz__c;
                    pm.fraisDistributionVariable = qli.FraisTransportDistributionCapacite__c;
    
                }
            } else {
                if (qli.TECH_Segment__c == 'C5' && qli.TECH_FTA__c.contains('4 postes')) {
                    if (!prixMoyenC54postesMap.containsKey(quoteID)) {
                        prixMoyenC54postesMap.put(quoteID, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                    }
    
                    PrixMoyenWrapper pm = prixMoyenC54postesMap.get(quoteID);
                    pm.abonnement += qli.AbonnementMois__c;
                    pm.numberQLI++;
    
                    pm.hch += (qli.PrixHchMwh__c * qli.Conso_HCH__c);
                    pm.consoTotalHch += qli.Conso_HCH__c;
    
                    pm.hph += (qli.PrixHphMwh__c * qli.Conso_HPH__c);
                    pm.consoTotalHph += qli.Conso_HPH__c;
    
                    pm.hce += (qli.PrixHceMwh__c * qli.Conso_HCE__c);
                    pm.consoTotalHce += qli.Conso_HCE__c;
    
                    pm.hpe += (qli.PrixHpeMwh__c * qli.Conso_HPE__c);
                    pm.consoTotalHpe += qli.Conso_HPE__c;
    
                    pm.cee += (qli.CeeMwh__c * qli.CAR_New__c);
                    pm.capacite += (qli.Capa_HCH__c * qli.Conso_HCH__c) + (qli.Capa_HCE__c * qli.Conso_HCE__c) + (qli.Capa_HPH__c * qli.Conso_HPH__c) + (qli.Capa_HPE__c * qli.Conso_HPE__c);
                    pm.consoTotalCar += qli.CAR_New__c;
    
                } else if (qli.TECH_Segment__c == 'C5' && !qli.TECH_FTA__c.contains('4 postes')) {
                    if (!prixMoyenC5BaseMap.containsKey(quoteID)) {
                        prixMoyenC5BaseMap.put(quoteID, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                    }
    
                    Decimal consoBase = qli.Conso_Base__c ?? 0;
                    Decimal consoHP = qli.ConsoHP__c ?? 0;
                    Decimal consoHC = qli.ConsoHC__c ?? 0;

                    PrixMoyenWrapper pm = prixMoyenC5BaseMap.get(quoteID);
                    pm.abonnement += qli.AbonnementMois__c;
                    pm.numberQLI++;
    
                    pm.base += (qli.PrixBase__c * consoBase);
                    pm.consoTotalBase += consoBase;
    
                    pm.hp += (qli.PrixHP__c * consoHP);
                    pm.consoTotalHp += consoHP;
    
                    pm.hc += (qli.PrixHC__c * consoHC);
                    pm.consoTotalHc += consoHC;
    
                    pm.cee += (qli.CeeMwh__c * qli.CAR_New__c);
                    pm.capacite += (qli.Capa_Base__c * consoBase) + (qli.Capa_HP__c * consoHP) + (qli.Capa_HC__c * consoHC);
                    pm.consoTotalCar += qli.CAR_New__c;
    
                } else if (qli.TECH_Segment__c == 'C4') {
                    if (!prixMoyenC4Map.containsKey(quoteID)) {
                        prixMoyenC4Map.put(quoteID, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                    }
    
                    PrixMoyenWrapper pm = prixMoyenC4Map.get(quoteID);
                    pm.abonnement += qli.AbonnementMois__c;
                    pm.numberQLI++;
    
                    pm.hch += (qli.PrixHchMwh__c * qli.Conso_HCH__c);
                    pm.consoTotalHch += qli.Conso_HCH__c;
    
                    pm.hph += (qli.PrixHphMwh__c * qli.Conso_HPH__c);
                    pm.consoTotalHph += qli.Conso_HPH__c;
    
                    pm.hce += (qli.PrixHceMwh__c * qli.Conso_HCE__c);
                    pm.consoTotalHce += qli.Conso_HCE__c;
    
                    pm.hpe += (qli.PrixHpeMwh__c * qli.Conso_HPE__c);
                    pm.consoTotalHpe += qli.Conso_HPE__c;
    
                    pm.pointe += (qli.PointesMWh__c * qli.Conso_Pointe__c);
                    pm.consoTotalPointe += qli.Conso_Pointe__c;
    
                    pm.cee += (qli.CeeMwh__c * qli.CAR_New__c);
                    pm.capacite += (qli.Capa_HCH__c * qli.Conso_HCH__c) + (qli.Capa_HCE__c * qli.Conso_HCE__c) + (qli.Capa_HPH__c * qli.Conso_HPH__c) + (qli.Capa_HPE__c * qli.Conso_HPE__c) + (qli.Capa_Pointes__c * qli.Conso_Pointe__c);
                    pm.consoTotalCar += qli.CAR_New__c;

    
                } else if (qli.TECH_Segment__c == 'C2' || qli.TECH_Segment__c == 'C1') {
                    if (!prixMoyenC1C2Map.containsKey(quoteID)) {
                        prixMoyenC1C2Map.put(quoteID, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                    }
    
                    PrixMoyenWrapper pm = prixMoyenC1C2Map.get(quoteID);
                    pm.abonnement += qli.AbonnementMois__c;
                    pm.numberQLI++;
    
                    pm.hch += (qli.PrixHchMwh__c * qli.Conso_HCH__c);
                    pm.consoTotalHch += qli.Conso_HCH__c;
    
                    pm.hph += (qli.PrixHphMwh__c * qli.Conso_HPH__c);
                    pm.consoTotalHph += qli.Conso_HPH__c;
    
                    pm.hce += (qli.PrixHceMwh__c * qli.Conso_HCE__c);
                    pm.consoTotalHce += qli.Conso_HCE__c;
    
                    pm.hpe += (qli.PrixHpeMwh__c * qli.Conso_HPE__c);
                    pm.consoTotalHpe += qli.Conso_HPE__c;
    
                    pm.pointe += (qli.PointesMWh__c * qli.Conso_Pointe__c);
                    pm.consoTotalPointe += qli.Conso_Pointe__c;
    
                    pm.cee += (qli.CeeMwh__c * qli.CAR_New__c);
                    pm.capacite += (qli.Capa_HCH__c * qli.Conso_HCH__c) + (qli.Capa_HCE__c * qli.Conso_HCE__c) + (qli.Capa_HPH__c * qli.Conso_HPH__c) + (qli.Capa_HPE__c * qli.Conso_HPE__c) + (qli.Capa_Pointes__c * qli.Conso_Pointe__c);
                    pm.consoTotalCar += qli.CAR_New__c;
                }
            }
        }

        // Trier par Budget Blobaux par budgetTTC ASC
        listBudgetGlobal = budgetMap.values();
        listBudgetGlobal.sort();

        // Prix Moyen List
        listprixMoyenT1 = prixMoyenT1Map.values();
        if (!listprixMoyenT1.isEmpty()) listprixMoyenT1.sort();

        listprixMoyenT2 = prixMoyenT2Map.values();
        if (!listprixMoyenT2.isEmpty()) listprixMoyenT2.sort();

        listprixMoyenT3 = prixMoyenT3Map.values();
        if (!listprixMoyenT3.isEmpty()) listprixMoyenT3.sort();

        listprixMoyenT4 = prixMoyenT4Map.values();
        if (!listprixMoyenT4.isEmpty()) listprixMoyenT4.sort();

        listprixMoyenC54postes = prixMoyenC54postesMap.values();
        if (!listprixMoyenC54postes.isEmpty()) listprixMoyenC54postes.sort();

        listprixMoyenC5Base = prixMoyenC5BaseMap.values();
        if (!listprixMoyenC5Base.isEmpty()) listprixMoyenC5Base.sort();

        listprixMoyenC4 = prixMoyenC4Map.values();
        if (!listprixMoyenC4.isEmpty()) listprixMoyenC4.sort();

        listprixMoyenC1C2 = prixMoyenC1C2Map.values();
        if (!listprixMoyenC1C2.isEmpty()) listprixMoyenC1C2.sort();


        // Get All PDEs
        for (OpportunityPDERelation__c opr : [  SELECT  PDE__r.Profil__c,
                                                        PDE__r.Segment__c,
                                                        PDE__r.FTA__c,
                                                        PDE__r.Tarif__c,
                                                        PDE__r.CARGaz__c,
                                                        PDE__r.Conso_Base__c,
                                                        PDE__r.ConsoHP__c,
                                                        PDE__r.ConsoHC__c,
                                                        PDE__r.Conso_HPH__c,
                                                        PDE__r.Conso_HCH__c,
                                                        PDE__r.Conso_HPE__c,
                                                        PDE__r.Conso_HCE__c,
                                                        PDE__r.Conso_Pointe__c
                                                FROM OpportunityPDERelation__c 
                                                WHERE Opportunity__c = :oppId]) {

            /*
            * Get Volume Total
            */
            if (isOppGaz) {

                if (!volumeTotalGazMap.containsKey('Gaz')) {
                    volumeTotalGazMap.put('Gaz', new VolumeTotalWrapper());
                }

                VolumeTotalWrapper vt = volumeTotalGazMap.get('Gaz');
                vt.p011 += opr.PDE__r.Profil__c == 'P011' ? opr.PDE__r.CARGaz__c : 0;
                vt.p012 += opr.PDE__r.Profil__c == 'P012' ? opr.PDE__r.CARGaz__c : 0;
                vt.p013 += opr.PDE__r.Profil__c == 'P013' ? opr.PDE__r.CARGaz__c : 0;
                vt.p014 += opr.PDE__r.Profil__c == 'P014' ? opr.PDE__r.CARGaz__c : 0;
                vt.p015 += opr.PDE__r.Profil__c == 'P015' ? opr.PDE__r.CARGaz__c : 0;
                vt.p016 += opr.PDE__r.Profil__c == 'P016' ? opr.PDE__r.CARGaz__c : 0;
                vt.p017 += opr.PDE__r.Profil__c == 'P017' ? opr.PDE__r.CARGaz__c : 0;
                vt.p018 += opr.PDE__r.Profil__c == 'P018' ? opr.PDE__r.CARGaz__c : 0;
                vt.p019 += opr.PDE__r.Profil__c == 'P019' ? opr.PDE__r.CARGaz__c : 0;
            } else {
                if (opr.PDE__r.Segment__c == 'C5' && opr.PDE__r.FTA__c.contains('4 postes')) {
                    
                    if (!volumeTotalC54postesMap.containsKey('C5 4 Postes')) {
                        volumeTotalC54postesMap.put('C5 4 Postes', new VolumeTotalWrapper());
                    }
    
                    VolumeTotalWrapper vt = volumeTotalC54postesMap.get('C5 4 Postes');
                    vt.hch += opr.PDE__r.Conso_HCH__c;
                    vt.hph += opr.PDE__r.Conso_HPH__c;
                    vt.hce += opr.PDE__r.Conso_HCE__c;
                    vt.hpe += opr.PDE__r.Conso_HPE__c;
    
                } else if (opr.PDE__r.Segment__c == 'C5' && !opr.PDE__r.FTA__c.contains('4 postes')) {

                    Decimal consoBase = opr.PDE__r.Conso_Base__c ?? 0;
                    Decimal consoHP = opr.PDE__r.ConsoHP__c ?? 0;
                    Decimal consoHC = opr.PDE__r.ConsoHC__c ?? 0;

                    if (!volumeTotalC5BaseMap.containsKey('C5')) {
                        volumeTotalC5BaseMap.put('C5', new VolumeTotalWrapper());
                    }
    
                    VolumeTotalWrapper vt = volumeTotalC5BaseMap.get('C5');
                    vt.base += consoBase;
                    vt.hp += consoHP;
                    vt.hc += consoHC;
    
                } else if (opr.PDE__r.Segment__c == 'C4') {

                    if (!volumeTotalC4Map.containsKey(opr.PDE__r.FTA__c)) {
                        volumeTotalC4Map.put(opr.PDE__r.FTA__c, new VolumeTotalWrapper());
                    }
    
                    VolumeTotalWrapper vt = volumeTotalC4Map.get(opr.PDE__r.FTA__c);
                    vt.hch += opr.PDE__r.Conso_HCH__c;
                    vt.hph += opr.PDE__r.Conso_HPH__c;
                    vt.hce += opr.PDE__r.Conso_HCE__c;
                    vt.hpe += opr.PDE__r.Conso_HPE__c;
                    vt.pointe += opr.PDE__r.Conso_Pointe__c;
    
                } else if (opr.PDE__r.Segment__c == 'C2' || opr.PDE__r.Segment__c == 'C1') {
                    
                    if (!volumeTotalC1C2Map.containsKey(opr.PDE__r.FTA__c)) {
                        volumeTotalC1C2Map.put(opr.PDE__r.FTA__c, new VolumeTotalWrapper());
                    }
    
                    VolumeTotalWrapper vt = volumeTotalC1C2Map.get(opr.PDE__r.FTA__c);
                    vt.hch += opr.PDE__r.Conso_HCH__c;
                    vt.hph += opr.PDE__r.Conso_HPH__c;
                    vt.hce += opr.PDE__r.Conso_HCE__c;
                    vt.hpe += opr.PDE__r.Conso_HPE__c;
                    vt.pointe += opr.PDE__r.Conso_Pointe__c;

                }
            }
        }

        // Volume Total List
        listvolumeTotalGaz = volumeTotalGazMap.values();
        listvolumeTotalC54postes = volumeTotalC54postesMap.values();
        listvolumeTotalC5Base = volumeTotalC5BaseMap.values();
        listvolumeTotalC4 = volumeTotalC4Map.values();
        listvolumeTotalC1C2 = volumeTotalC1C2Map.values();

        // If Situation Actuelle
        if (showSectionSituationActuelle) {
            Id quoteIDSituationActuelle;
            for (QuoteLineItem qli : [  SELECT  TECH_Fournisseur__c,
                                                TECH_TypePDL__c,
                                                TECH_Segment__c,
                                                TECH_FTA__c,
                                                TECH_Tarif__c,
                                                T_QuoteCAPA__c,
                                                T_QuoteCEE__c,
                                                LogoCompactLayout__c,
                                                Quote.Id,
                                                Quote.TypeOffre__c,
                                                Quote.Minimum_date_de_debut__c,
                                                Quote.Maximum_date_de_fin__c,
                                                Budget_Energie_Euro_An__c,
                                                Budget_Energie_Gaz__c,
                                                Budget_Acheminement_Annuel_HTT__c,
                                                Budget_Acheminement_Gaz__c,
                                                Budget_Taxes_annuel_HTVA__c,
                                                Budget_Taxes_et_Contribution_Gaz__c,
                                                TECH_Budget__c,
                                                TECH_BudgetGaz__c,
                                                Budget_TTC__c,
                                                AbonnementMois__c,
                                                PointesMWh__c,
                                                PrixHchMwh__c,
                                                PrixHphMwh__c,
                                                PrixHceMwh__c,
                                                PrixHpeMwh__c,
                                                PrixHC__c,
                                                PrixHP__c,
                                                PrixBase__c,
                                                PrixMolecule__c,
                                                FraisTransportDistributionCapacite__c,
                                                CeeMwh__c,
                                                Conso_Pointe__c,
                                                Conso_HCH__c,
                                                Conso_HPH__c,
                                                Conso_HCE__c,
                                                Conso_HPE__c,
                                                ConsoHC__c,
                                                ConsoHP__c,
                                                Conso_Base__c,
                                                CAR_New__c,
                                                CARGaz__c,
                                                Capa_HPE__c,
                                                Capa_HPH__c,
                                                Capa_HCE__c,
                                                Capa_HCH__c,
                                                Capa_Base__c,
                                                Capa_Pointes__c,
                                                Capa_HP__c,
                                                Capa_HC__c
                                        FROM QuoteLineItem 
                                        WHERE Opportunit__c = :oppId 
                                        AND TECH_fournisseur__c = 'Situation Actuelle']) {

                /*
                * Get Budget Globaux
                */
                quoteIDSituationActuelle = qli.Quote.Id;

                if (!budgetMap.containsKey(quoteIDSituationActuelle)) {
                    budgetMap.put(quoteIDSituationActuelle, new BudgetGlobalWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c));
                }

                BudgetGlobalWrapper bg = budgetMap.get(quoteIDSituationActuelle);

                bg.BudgetEnergieElec += qli.Budget_Energie_Euro_An__c;
                bg.BudgetEnergieGaz += qli.Budget_Energie_Gaz__c;
                bg.BudgetAcheminementElec += qli.Budget_Acheminement_Annuel_HTT__c;
                bg.BudgetAcheminementGaz += qli.Budget_Acheminement_Gaz__c;
                bg.BudgetTaxeElec += qli.Budget_Taxes_annuel_HTVA__c;
                bg.BudgetTaxeGaz += qli.Budget_Taxes_et_Contribution_Gaz__c;
                bg.TotalHTVAElec += qli.TECH_Budget__c != null ? qli.TECH_Budget__c : 0;
                bg.TotalHTVAGaz += qli.TECH_Budget__c != null ? qli.TECH_Budget__c : 0;
                bg.TotalTTC += qli.Budget_TTC__c;

                /*
                * Get Prix Moyen par FTA/Tarifs
                */
                if (isOppGaz) {
                    if (qli.TECH_Tarif__c == 'T1') {
                        if (!prixMoyenT1Map.containsKey(quoteIDSituationActuelle)) {
                            prixMoyenT1Map.put(quoteIDSituationActuelle, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                        }
    
                        PrixMoyenWrapper pm = prixMoyenT1Map.get(quoteIDSituationActuelle);
                        pm.cee += (qli.CeeMwh__c * qli.CARGaz__c);
                        pm.molecule += (qli.PrixMolecule__c * qli.CARGaz__c);
                        pm.consoTotalCar += qli.CARGaz__c;
    
                    } else if (qli.TECH_Tarif__c == 'T2') {
                        if (!prixMoyenT2Map.containsKey(quoteIDSituationActuelle)) {
                            prixMoyenT2Map.put(quoteIDSituationActuelle, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                        }
    
                        PrixMoyenWrapper pm = prixMoyenT2Map.get(quoteIDSituationActuelle);
                        pm.cee += (qli.CeeMwh__c * qli.CARGaz__c);
                        pm.molecule += (qli.PrixMolecule__c * qli.CARGaz__c);
                        pm.consoTotalCar += qli.CARGaz__c;
                        pm.fraisDistributionVariable = qli.FraisTransportDistributionCapacite__c;
    
                    } else if (qli.TECH_Tarif__c == 'T3') {
                        if (!prixMoyenT3Map.containsKey(quoteIDSituationActuelle)) {
                            prixMoyenT3Map.put(quoteIDSituationActuelle, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                        }
    
                        PrixMoyenWrapper pm = prixMoyenT3Map.get(quoteIDSituationActuelle);
                        pm.cee += (qli.CeeMwh__c * qli.CARGaz__c);
                        pm.molecule += (qli.PrixMolecule__c * qli.CARGaz__c);
                        pm.consoTotalCar += qli.CARGaz__c;
                        pm.fraisDistributionVariable = qli.FraisTransportDistributionCapacite__c;
    
                    } else if (qli.TECH_Tarif__c == 'T4') {
                        if (!prixMoyenT4Map.containsKey(quoteIDSituationActuelle)) {
                            prixMoyenT4Map.put(quoteIDSituationActuelle, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                        }
    
                        PrixMoyenWrapper pm = prixMoyenT4Map.get(quoteIDSituationActuelle);
                        pm.cee += (qli.CeeMwh__c * qli.CARGaz__c);
                        pm.molecule += (qli.PrixMolecule__c * qli.CARGaz__c);
                        pm.consoTotalCar += qli.CARGaz__c;
                        pm.fraisDistributionVariable = qli.FraisTransportDistributionCapacite__c;
    
                    }
                } else {
                    if (qli.TECH_Segment__c == 'C5' && qli.TECH_FTA__c.contains('4 postes')) {
                        if (!prixMoyenC54postesMap.containsKey(quoteIDSituationActuelle)) {
                            prixMoyenC54postesMap.put(quoteIDSituationActuelle, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                        }
    
                        PrixMoyenWrapper pm = prixMoyenC54postesMap.get(quoteIDSituationActuelle);
                        pm.abonnement += qli.AbonnementMois__c;
                        pm.numberQLI++;
    
                        pm.hch += (qli.PrixHchMwh__c * qli.Conso_HCH__c);
                        pm.consoTotalHch += qli.Conso_HCH__c;
    
                        pm.hph += (qli.PrixHphMwh__c * qli.Conso_HPH__c);
                        pm.consoTotalHph += qli.Conso_HPH__c;
    
                        pm.hce += (qli.PrixHceMwh__c * qli.Conso_HCE__c);
                        pm.consoTotalHce += qli.Conso_HCE__c;
    
                        pm.hpe += (qli.PrixHpeMwh__c * qli.Conso_HPE__c);
                        pm.consoTotalHpe += qli.Conso_HPE__c;
    
                        pm.cee += (qli.CeeMwh__c * qli.CAR_New__c);
                        pm.capacite += (qli.Capa_HCH__c * qli.Conso_HCH__c) + (qli.Capa_HCE__c * qli.Conso_HCE__c) + (qli.Capa_HPH__c * qli.Conso_HPH__c) + (qli.Capa_HPE__c * qli.Conso_HPE__c);
                        pm.consoTotalCar += qli.CAR_New__c;
    
                    } else if (qli.TECH_Segment__c == 'C5' && !qli.TECH_FTA__c.contains('4 postes')) {
                        if (!prixMoyenC5BaseMap.containsKey(quoteIDSituationActuelle)) {
                            prixMoyenC5BaseMap.put(quoteIDSituationActuelle, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                        }
    
                        PrixMoyenWrapper pm = prixMoyenC5BaseMap.get(quoteIDSituationActuelle);
                        pm.abonnement += qli.AbonnementMois__c;
                        pm.numberQLI++;
    
                        pm.base += (qli.PrixBase__c * qli.Conso_Base__c);
                        pm.consoTotalBase += qli.Conso_Base__c;
    
                        pm.hp += (qli.PrixHP__c * qli.ConsoHP__c);
                        pm.consoTotalHp += qli.ConsoHP__c;
    
                        pm.hc += (qli.PrixHC__c * qli.ConsoHC__c);
                        pm.consoTotalHc += qli.ConsoHC__c;
    
                        pm.cee += (qli.CeeMwh__c * qli.CAR_New__c);
                        pm.capacite += (qli.Capa_Base__c * qli.Conso_Base__c) + (qli.Capa_HP__c * qli.ConsoHP__c) + (qli.Capa_HC__c * qli.ConsoHC__c);
                        pm.consoTotalCar += qli.CAR_New__c;
    
                    } else if (qli.TECH_Segment__c == 'C4') {
                        if (!prixMoyenC4Map.containsKey(quoteIDSituationActuelle)) {
                            prixMoyenC4Map.put(quoteIDSituationActuelle, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                        }
    
                        PrixMoyenWrapper pm = prixMoyenC4Map.get(quoteIDSituationActuelle);
                        pm.abonnement += qli.AbonnementMois__c;
                        pm.numberQLI++;
    
                        pm.hch += (qli.PrixHchMwh__c * qli.Conso_HCH__c);
                        pm.consoTotalHch += qli.Conso_HCH__c;
    
                        pm.hph += (qli.PrixHphMwh__c * qli.Conso_HPH__c);
                        pm.consoTotalHph += qli.Conso_HPH__c;
    
                        pm.hce += (qli.PrixHceMwh__c * qli.Conso_HCE__c);
                        pm.consoTotalHce += qli.Conso_HCE__c;
    
                        pm.hpe += (qli.PrixHpeMwh__c * qli.Conso_HPE__c);
                        pm.consoTotalHpe += qli.Conso_HPE__c;
    
                        pm.pointe += (qli.PointesMWh__c * qli.Conso_Pointe__c);
                        pm.consoTotalPointe += qli.Conso_Pointe__c;
    
                        pm.cee += (qli.CeeMwh__c * qli.CAR_New__c);
                        pm.capacite += (qli.Capa_HCH__c * qli.Conso_HCH__c) + (qli.Capa_HCE__c * qli.Conso_HCE__c) + (qli.Capa_HPH__c * qli.Conso_HPH__c) + (qli.Capa_HPE__c * qli.Conso_HPE__c) + (qli.Capa_Pointes__c * qli.Conso_Pointe__c);
                        pm.consoTotalCar += qli.CAR_New__c;
    
                    } else if (qli.TECH_Segment__c == 'C2' || qli.TECH_Segment__c == 'C1') {
                        if (!prixMoyenC1C2Map.containsKey(quoteIDSituationActuelle)) {
                            prixMoyenC1C2Map.put(quoteIDSituationActuelle, new PrixMoyenWrapper(qli.TECH_fournisseur__c, qli.LogoCompactLayout__c, qli.Quote.Minimum_date_de_debut__c, qli.Quote.Maximum_date_de_fin__c, qli.Quote.TypeOffre__c, qli.T_QuoteCAPA__c, qli.T_QuoteCEE__c));
                        }
    
                        PrixMoyenWrapper pm = prixMoyenC1C2Map.get(quoteIDSituationActuelle);
                        pm.abonnement += qli.AbonnementMois__c;
                        pm.numberQLI++;
    
                        pm.hch += (qli.PrixHchMwh__c * qli.Conso_HCH__c);
                        pm.consoTotalHch += qli.Conso_HCH__c;
    
                        pm.hph += (qli.PrixHphMwh__c * qli.Conso_HPH__c);
                        pm.consoTotalHph += qli.Conso_HPH__c;
    
                        pm.hce += (qli.PrixHceMwh__c * qli.Conso_HCE__c);
                        pm.consoTotalHce += qli.Conso_HCE__c;
    
                        pm.hpe += (qli.PrixHpeMwh__c * qli.Conso_HPE__c);
                        pm.consoTotalHpe += qli.Conso_HPE__c;
    
                        pm.pointe += (qli.PointesMWh__c * qli.Conso_Pointe__c);
                        pm.consoTotalPointe += qli.Conso_Pointe__c;
    
                        pm.cee += (qli.CeeMwh__c * qli.CAR_New__c);
                        pm.capacite += (qli.Capa_HCH__c * qli.Conso_HCH__c) + (qli.Capa_HCE__c * qli.Conso_HCE__c) + (qli.Capa_HPH__c * qli.Conso_HPH__c) + (qli.Capa_HPE__c * qli.Conso_HPE__c) + (qli.Capa_Pointes__c * qli.Conso_Pointe__c);
                        pm.consoTotalCar += qli.CAR_New__c;
                        
                    }
                }
            }

            // Add Situation Actuelle on top of the list
            listBudgetGlobal.add(0, budgetMap.get(quoteIDSituationActuelle));

            // Prix Moyen List
            if (!listprixMoyenT1.isEmpty()) {
                listprixMoyenT1.add(0, prixMoyenT1Map.get(quoteIDSituationActuelle)); 
            }
            if (!listprixMoyenT2.isEmpty()) {
                listprixMoyenT2.add(0, prixMoyenT2Map.get(quoteIDSituationActuelle));
            }
            if (!listprixMoyenT3.isEmpty()) {
                listprixMoyenT3.add(0, prixMoyenT3Map.get(quoteIDSituationActuelle)); 
            }
            if (!listprixMoyenT4.isEmpty()) {
                listprixMoyenT4.add(0, prixMoyenT4Map.get(quoteIDSituationActuelle)); 
            }
            if (!listprixMoyenC54postes.isEmpty()) {
                listprixMoyenC54postes.add(0, prixMoyenC54postesMap.get(quoteIDSituationActuelle));
            }
            if (!listprixMoyenC5Base.isEmpty()) {
                listprixMoyenC5Base.add(0, prixMoyenC5BaseMap.get(quoteIDSituationActuelle)); 
            }
            if (!listprixMoyenC4.isEmpty()) {
                listprixMoyenC4.add(0, prixMoyenC4Map.get(quoteIDSituationActuelle)); 
            }
            if (!listprixMoyenC1C2.isEmpty()) {
                listprixMoyenC1C2.add(0, prixMoyenC1C2Map.get(quoteIDSituationActuelle)); 
            } 
        }

        // Get page fournisseur
        listFournisseurName = new List<String>();
        for(String name : fournisseursList){
            name = name.replace(' ','_').replace('é','e').replace('è','e') + '.jpg';
            if(setFournisseurWithPageInfo.contains(name)){
                listFournisseurName.add(name);
            }
        }

        loadTurpeData(oppId);

        String filename = 'Comparatif_Resume ' + String.valueOf(DateTime.now().format('dd-mm-yyyy')) + ' ' + opp.Account.Name;
        Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=' + filename + '.pdf');
    }

    /*
    * LWC Methods
    */
    @AuraEnabled
    public static String generateResumePDFUrl(
        Id opportunityId,
        String selectedFournisseurs,
        String selectedQuoteNumber,
        Boolean sectionTTC,
        Boolean sectionSituationActuelle,
        String selectedGOQuoteNumbers,
        Boolean includeAllGO
    ) {
        String baseUrl = Site.getBaseUrl();
        String siteContext = (URL.getCurrentRequestUrl().getPath().contains('/s/')) ? '/s' : '';

        PageReference pdfPage = Page.ResumeComparatifPDF;
        pdfPage.getParameters().put('id', opportunityId);
        pdfPage.getParameters().put('fournisseurs', selectedFournisseurs);
        pdfPage.getParameters().put('quoteNumbers', selectedQuoteNumber);
        pdfPage.getParameters().put('goQuoteNumbers', selectedGOQuoteNumbers); // ajout
        pdfPage.getParameters().put('includeAllGO', String.valueOf(includeAllGO)); // ajout
        pdfPage.getParameters().put('sectionTTC', String.valueOf(sectionTTC));
        pdfPage.getParameters().put('sectionSituationActuelle', String.valueOf(sectionSituationActuelle));

        // Create chatter message
        FeedItem feed = new FeedItem();
        feed.ParentId = opportunityId;

        String fournisseursLabel = String.isNotBlank(selectedFournisseurs) 
            ? selectedFournisseurs.replace(';',' - ') 
            : '(aucune)';

        String goLabel = String.isNotBlank(selectedGOQuoteNumbers) 
            ? selectedGOQuoteNumbers.replace(';',' - ') 
            : 'Toutes';

        feed.Body = 'L\'utilisateur ' + UserInfo.getName()
            + ' a téléchargé le comparatif résumé | Offres: ' + fournisseursLabel
            + ' | Garanties d\'origine: ' + goLabel;

        insert feed;
        
        return baseUrl + siteContext + pdfPage.getUrl();
    }

    /**
    * Chargement des QLI liés à la quote TURPE (IsOptimisationTurpe__c = true)
    * Si 1 QLI => mode monosite, sinon multisite
    */
    private static void loadTurpeData(Id oppId) {
        // Recherche de la quote TURPE
        List<Quote> lstQuoteTurpe = [
            SELECT Id, Name,
                SumBudgetTotalActuel__c,
                SumBudgetTotalOptimal__c,
                SumEconomieIdentifiee__c
            FROM Quote
            WHERE OpportunityId = :oppId
            AND IsOptimisationTurpe__c = true
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (lstQuoteTurpe.isEmpty()) {
            lstQLITurpe = new List<QuoteLineItem>();
            turpeIsMonoSite = true;
            totalBudgetActuel  = 0;
            totalBudgetOptimal = 0;
            totalEconomie      = 0;
            return;
        }

        Quote quoteTurpe = lstQuoteTurpe[0];

        // Récupération des rollups sur la quote
        totalBudgetActuel  = (quoteTurpe.SumBudgetTotalActuel__c  != null) ? quoteTurpe.SumBudgetTotalActuel__c  : 0;
        totalBudgetOptimal = (quoteTurpe.SumBudgetTotalOptimal__c != null) ? quoteTurpe.SumBudgetTotalOptimal__c : 0;
        totalEconomie      = (quoteTurpe.SumEconomieIdentifiee__c != null) ? quoteTurpe.SumEconomieIdentifiee__c : 0;

        // Récupération des QLI de la quote TURPE
        lstQLITurpe = [
            SELECT Id,
                PDE__r.Name,
                BudgetTotalActuel__c, BudgetTotalOptimal__c, EconomieIdentifie__c,
                HCEActuel__c, HPEActuel__c, HCHActuel__c, HPHActuel__c, POINTEActuel__c,
                HCEOptimal__c, HPEOptimal__c, HCHOptimal__c, HPHOptimal__c, POINTEOptimal__c,
                PartFixeCSActuel__c, PartVariableCSActuel__c, DepassementActuel__c, TaxeCTAActuel__c,
                PartFixeCSOptimal__c, PartVariableCSOptimal__c, DepassementOptimal__c, TaxeCTAOptimal__c, InterventionPEPS__c,
                PDE__r.Conso_HCE__c, PDE__r.Conso_HPE__c, PDE__r.Conso_HCH__c, PDE__r.Conso_HPH__c, PDE__r.Conso_Pointe__c
            FROM QuoteLineItem
            WHERE QuoteId = :quoteTurpe.Id
            AND EconomieIdentifie__c > 0
            ORDER BY PDE__r.Name
        ];

        turpeIsMonoSite = (lstQLITurpe.size() == 1);

        // Normaliser les valeurs nulles à 0 pour éviter les cellules vides dans la VF
        for (QuoteLineItem qli : lstQLITurpe) {
            qli.BudgetTotalActuel__c    = (qli.BudgetTotalActuel__c    != null) ? qli.BudgetTotalActuel__c    : 0;
            qli.BudgetTotalOptimal__c   = (qli.BudgetTotalOptimal__c   != null) ? qli.BudgetTotalOptimal__c   : 0;
            qli.EconomieIdentifie__c    = (qli.EconomieIdentifie__c    != null) ? qli.EconomieIdentifie__c    : 0;
            qli.PartFixeCSActuel__c     = (qli.PartFixeCSActuel__c     != null) ? qli.PartFixeCSActuel__c     : 0;
            qli.PartFixeCSOptimal__c    = (qli.PartFixeCSOptimal__c    != null) ? qli.PartFixeCSOptimal__c    : 0;
            qli.PartVariableCSActuel__c = (qli.PartVariableCSActuel__c != null) ? qli.PartVariableCSActuel__c : 0;
            qli.PartVariableCSOptimal__c= (qli.PartVariableCSOptimal__c!= null) ? qli.PartVariableCSOptimal__c: 0;
            qli.DepassementActuel__c    = (qli.DepassementActuel__c    != null) ? qli.DepassementActuel__c    : 0;
            qli.DepassementOptimal__c   = (qli.DepassementOptimal__c   != null) ? qli.DepassementOptimal__c   : 0;
            qli.TaxeCTAActuel__c        = (qli.TaxeCTAActuel__c        != null) ? qli.TaxeCTAActuel__c        : 0;
            qli.TaxeCTAOptimal__c       = (qli.TaxeCTAOptimal__c       != null) ? qli.TaxeCTAOptimal__c       : 0;
            qli.InterventionPEPS__c     = (qli.InterventionPEPS__c     != null) ? qli.InterventionPEPS__c     : 0;
        }

        // Préparation des classes CSS dynamiques (monosite uniquement)
        if (lstQLITurpe != null && !lstQLITurpe.isEmpty()) {
            QuoteLineItem t = lstQLITurpe[0];

            cssPartFixeCS       = cssClass(t.PartFixeCSOptimal__c, t.PartFixeCSActuel__c);
            cssPartVariableCS   = cssClass(t.PartVariableCSOptimal__c, t.PartVariableCSActuel__c);
            cssDepassement      = cssClass(t.DepassementOptimal__c, t.DepassementActuel__c);
            cssTaxeCTA          = cssClass(t.TaxeCTAOptimal__c, t.TaxeCTAActuel__c);
            cssBudgetTotal      = cssClass(t.BudgetTotalOptimal__c, t.BudgetTotalActuel__c);
            cssBudgetTotalMulti = cssClass(totalBudgetOptimal, totalBudgetActuel);

            // Règle spéciale: intervention > 0 => rouge, sinon pas de classe
            cssInterventionPEPS = (t.InterventionPEPS__c != null && t.InterventionPEPS__c > 0)
                ? 'turpe-negative'
                : '';
        }

        // Générer le texte de date dynamique (N-1 à J-1)
        Date endDate   = Date.today().addDays(-1);
        Date startDate = endDate.addYears(-1);
        String startStr = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');
        String endStr   = DateTime.newInstance(endDate,   Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');
        noteDateText = 'Note : l\'optimisation se base sur les consommations ci-après du ' + startStr +
                    ' au ' + endStr + ' et suppose qu\'elles seront similaires à l\'avenir.';

        // Générer le texte de consommation (uniquement si monosite)
        if (turpeIsMonoSite && !lstQLITurpe.isEmpty() && lstQLITurpe[0].PDE__r != null) {
            QuoteLineItem qli = lstQLITurpe[0];
            noteConsoText =
                'HCE : ' + (qli.PDE__r.Conso_HCE__c != null ? qli.PDE__r.Conso_HCE__c.format() : '0') + ' kWh — ' +
                'HPE : ' + (qli.PDE__r.Conso_HPE__c != null ? qli.PDE__r.Conso_HPE__c.format() : '0') + ' kWh — ' +
                'HCH : ' + (qli.PDE__r.Conso_HCH__c != null ? qli.PDE__r.Conso_HCH__c.format() : '0') + ' kWh — ' +
                'HPH : ' + (qli.PDE__r.Conso_HPH__c != null ? qli.PDE__r.Conso_HPH__c.format() : '0') + ' kWh — ' +
                'Pointe : ' + (qli.PDE__r.Conso_Pointe__c != null ? qli.PDE__r.Conso_Pointe__c.format() : '0') + ' kWh';
        }
    }

    /*
    * Wrappers
    */
    public class BudgetGlobalWrapper implements Comparable {
        public String fournisseur { get; set; }
        public String logo { get; set; }
        public Date dateDebut { get; set; }
        public Date dateFin { get; set; }
        public String duree { get; set; }
        public String typeOffre { get; set; }
        public Decimal BudgetEnergieElec { get; set; }
        public Decimal BudgetEnergieGaz { get; set; }
        public Decimal BudgetAcheminementElec { get; set; }
        public Decimal BudgetAcheminementGaz { get; set; }
        public Decimal BudgetTaxeElec { get; set; }
        public Decimal BudgetTaxeGaz { get; set; }
        public Decimal TotalHTVAElec { get; set; }
        public Decimal TotalHTVAGaz { get; set; }
        public Decimal TotalTTC { get; set; }
        public String dureeOffre { get { return calculateDureeEnMois(); }}

        public BudgetGlobalWrapper(String fournisseur, String logo, Date dateDebut, Date dateFin, String typeOffre) {
            this.fournisseur = fournisseur;
            this.logo = logo;
            this.dateDebut = dateDebut;
            this.dateFin = dateFin;
            this.typeOffre = typeOffre;
            this.BudgetEnergieElec = 0;
            this.BudgetEnergieGaz = 0;
            this.BudgetAcheminementElec = 0;
            this.BudgetAcheminementGaz = 0;
            this.BudgetTaxeElec = 0;
            this.BudgetTaxeGaz = 0;
            this.TotalHTVAElec = 0;
            this.TotalHTVAGaz = 0;
            this.TotalTTC = 0;
        }

        private String calculateDureeEnMois() {
            if (dateDebut == null || dateFin == null) {
                return '0';
            }
    
            Integer startYear = dateDebut.year();
            Integer startMonth = dateDebut.month();
            Integer endYear = dateFin.year();
            Integer endMonth = dateFin.month();
            Integer duree = ((endYear - startYear) * 12) + (endMonth - startMonth);
            
            if (dateFin.day() == Date.daysInMonth(endYear, endMonth)) {
                duree++;
            }

            return String.valueOf(duree);
        }

        public Integer compareTo(Object other) {
            BudgetGlobalWrapper otherWrapper = (BudgetGlobalWrapper) other;
            if (this.TotalTTC == otherWrapper.TotalTTC) return 0;
            return this.TotalTTC > otherWrapper.TotalTTC ? 1 : -1;
        }
    }

    public class PrixMoyenWrapper implements Comparable {
        public String fournisseur { get; set; }
        public String logo { get; set; }
        public String typeOffre { get; set; }
        public String tQuoteCapa { get; set; }
        public String tQuoteCee { get; set; }
        public Date dateDebut { get; set; }
        public Date dateFin { get; set; }
        public String duree { get; set; }
        public String dureeOffre { get { return calculateDureeEnMois(); }}
        public Decimal abonnement { get; set; }
        public Decimal abonnementMoyenne { get { return abonnement != 0 ? (abonnement / numberQLI).setScale(2) : 0.00; } }
        public Decimal pointe { get; set; }
        public Decimal consoTotalPointe { get; set; }
        public Decimal pointeMoyennePonderee { get { return consoTotalPointe != 0 ? (pointe / consoTotalPointe).setScale(2) : 0.00; }}
        public Decimal hch { get; set; }
        public Decimal consoTotalHch { get; set; }
        public Decimal hchMoyennePonderee { get { return consoTotalHch != 0 ? (hch / consoTotalHch).setScale(2) : 0.00; }}
        public Decimal hph { get; set; }
        public Decimal consoTotalHph { get; set; }
        public Decimal hphMoyennePonderee { get { return consoTotalHph != 0 ?  (hph / consoTotalHph).setScale(2) : 0.00; }}
        public Decimal hce { get; set; }
        public Decimal consoTotalHce { get; set; }
        public Decimal hceMoyennePonderee { get { return consoTotalHce != 0 ?  (hce / consoTotalHce).setScale(2) : 0.00; }}
        public Decimal hpe { get; set; }
        public Decimal consoTotalHpe { get; set; }
        public Decimal hpeMoyennePonderee { get { return consoTotalHpe != 0 ?  (hpe / consoTotalHpe).setScale(2) : 0.00; }}
        public Decimal hc { get; set; }
        public Decimal consoTotalHc { get; set; }
        public Decimal hcMoyennePonderee { get { return consoTotalHc != 0 ? (hc / consoTotalHc).setScale(2) : 0.00; }}
        public Decimal hp { get; set; }
        public Decimal consoTotalHp { get; set; }
        public Decimal hpMoyennePonderee { get { return consoTotalHp != 0 ? (hp / consoTotalHp).setScale(2) : 0.00; }}
        public Decimal base { get; set; }
        public Decimal consoTotalBase { get; set; }
        public Decimal baseMoyennePonderee { get { return consoTotalBase != 0 ? (base / consoTotalBase).setScale(2) : 0.00; }}
        public Decimal molecule { get; set; }
        public Decimal fraisDistributionVariable { get; set; }
        public Decimal cee { get; set; }
        public Decimal capacite { get; set; }
        public Decimal consoTotalCar { get; set; }
        public Integer numberQLI { get; set; }
        public Decimal moleculeMoyennePonderee { get { return (molecule / consoTotalCar).setScale(2); }}
        public Decimal ceeMoyennePonderee { get { return (cee / consoTotalCar).setScale(2); }}
        public Decimal capaciteMoyennePonderee { get { return (capacite / consoTotalCar).setScale(2); }}
        public Decimal totalConsoPoste { get { return (abonnementMoyenne + moleculeMoyennePonderee + baseMoyennePonderee + hpMoyennePonderee + hcMoyennePonderee + hchMoyennePonderee + hceMoyennePonderee + hphMoyennePonderee + hpeMoyennePonderee + pointeMoyennePonderee + ceeMoyennePonderee + capaciteMoyennePonderee) / 12; }}

        public PrixMoyenWrapper(String fournisseur, String logo, Date dateDebut, Date dateFin, String typeOffre, String tQuoteCapa, String tQuoteCee) {
            this.fournisseur = fournisseur;
            this.logo = logo;
            this.dateDebut = dateDebut;
            this.dateFin = dateFin;
            this.typeOffre = typeOffre;
            this.tQuoteCapa = tQuoteCapa;
            this.tQuoteCee = tQuoteCee;
            this.numberQLI = 0;
            this.abonnement = 0;
            this.pointe = 0;
            this.consoTotalPointe = 0;
            this.hch = 0;
            this.consoTotalHch = 0;
            this.hph = 0;
            this.consoTotalHph = 0;
            this.hce = 0;
            this.consoTotalHce = 0;
            this.hpe = 0;
            this.consoTotalHpe = 0;
            this.hc = 0;
            this.consoTotalHc = 0;
            this.hp = 0;
            this.consoTotalHp = 0;
            this.base = 0;
            this.consoTotalBase = 0;
            this.molecule = 0;
            this.fraisDistributionVariable = 0;
            this.cee = 0;
            this.capacite = 0;
            this.consoTotalCar = 0;
        }

        private String calculateDureeEnMois() {
            if (dateDebut == null || dateFin == null) {
                return '0';
            }
    
            Integer startYear = dateDebut.year();
            Integer startMonth = dateDebut.month();
            Integer endYear = dateFin.year();
            Integer endMonth = dateFin.month();
            Integer duree = ((endYear - startYear) * 12) + (endMonth - startMonth);
            
            if (dateFin.day() == Date.daysInMonth(endYear, endMonth)) {
                duree++;
            }

            return String.valueOf(duree);
        }

        public Integer compareTo(Object other) {
            PrixMoyenWrapper otherWrapper = (PrixMoyenWrapper) other;
            if (this.totalConsoPoste == otherWrapper.totalConsoPoste) return 0;
            return this.totalConsoPoste > otherWrapper.totalConsoPoste ? 1 : -1;
        }
    }

    public class VolumeTotalWrapper {
        public Decimal pointe { get; set; }
        public Decimal hch { get; set; }
        public Decimal hph { get; set; }
        public Decimal hce { get; set; }
        public Decimal hpe { get; set; }
        public Decimal hc { get; set; }
        public Decimal hp { get; set; }
        public Decimal base { get; set; }
        public Decimal p011 { get; set; }
        public Decimal p012 { get; set; }
        public Decimal p013 { get; set; }
        public Decimal p014 { get; set; }
        public Decimal p015 { get; set; }
        public Decimal p016 { get; set; }
        public Decimal p017 { get; set; }
        public Decimal p018 { get; set; }
        public Decimal p019 { get; set; }
        public Decimal totalConsoElec { get{ return pointe + hch + hph + hce + hpe + hc + hp + base; } }
        public Decimal totalConsoGaz { get{ return p011 + p012 + p013 + p014 + p015 + p016 + p017 + p018 + p019; } }

        public VolumeTotalWrapper() {
            this.pointe = 0;
            this.hch = 0;
            this.hph = 0;
            this.hce = 0;
            this.hpe = 0;
            this.hc = 0;
            this.hp = 0;
            this.base = 0;
            this.p011 = 0;
            this.p012 = 0;
            this.p013 = 0;
            this.p014 = 0;
            this.p015 = 0;
            this.p016 = 0;
            this.p017 = 0;
            this.p018 = 0;
            this.p019 = 0;
        }
    }
}