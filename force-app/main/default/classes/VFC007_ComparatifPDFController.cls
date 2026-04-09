public without sharing class VFC007_ComparatifPDFController {
    
    public static Opportunity opp { get; set; }
    public static Boolean isOppGaz { get { return opp.TECH_IsGaz__c; } set; }
    public static Boolean isOppSimpleRT { get { return opp.RecordType.Name.contains('Simple'); } set; }
    public static Boolean isOppPartenaire { get { return opp.Demande_Cotation__r.TECH_Partner_OwnerName__c != null; } set; }
    public static Boolean showSectionTTC { get; set; }
    public static Boolean showSectionSituationActuelle { get; set; }
    public static String todayDate { get{ return Date.today().format().toString();} set; }
    public static String accountName { get; set; }
    public static List<String> fournisseursList { get; set; }
    public static List<String> quoteNumberList { get; set; }
    public static List<OpportunityPDERelation__c> listOPR { get; set; }
    public static String PDENumber { get { return listOPR.size() + ' compteur(s)'; } set; }
    public static List<List<QuoteLineItem>> listQLIGazList { get; set; }
    public static List<List<QuoteLineItem>> listQLIC54postesList { get; set; }
    public static List<List<QuoteLineItem>> listQLIC5BaseList { get; set; }
    public static List<List<QuoteLineItem>> listQLIC4List { get; set; }
    public static List<List<QuoteLineItem>> listQLIC2List { get; set; }
    public static List<List<QuoteLineItem>> listQLIC1List { get; set; }
    public static Boolean listQLIC54postesListNotEmpty { get { return !listQLIC54postesList.isEmpty(); } set; }
    public static Boolean listQLIC5BaseListNotEmpty { get { return !listQLIC5BaseList.isEmpty(); } set; }
    public static Boolean listQLIC4ListNotEmpty { get { return !listQLIC4List.isEmpty(); } set; }
    public static Boolean listQLIC2ListNotEmpty { get { return !listQLIC2List.isEmpty(); } set; }
    public static Boolean listQLIC1ListNotEmpty { get { return !listQLIC1List.isEmpty(); } set; }
    public static Set<String> setFournisseurWithPageInfo { get; set; }
    public static List<String> listFournisseurName { get; set; }
    public static String commercialName {get; set;}
    public static String commercialEmail {get; set;}
    public static String commercialPhone {get; set;}

    public static List<Quote> listQuoteGOElec { get; set; }
    public static List<Quote> listQuoteGOGaz  { get; set; }
    public static Boolean listQuoteGOElecNotEmpty { get { return listQuoteGOElec != null && !listQuoteGOElec.isEmpty(); } set; }
    public static Boolean listQuoteGOGazNotEmpty  { get { return listQuoteGOGaz  != null && !listQuoteGOGaz.isEmpty(); } set; }
    public static List<String> goQuoteNumberList { get; set; }
    public static List<Quote> goQuotesElec { get; set; }
    public static List<Quote> goQuotesGaz  { get; set; }
    public static Boolean showGOElec { get; set; }
    public static Boolean showGOGaz  { get; set; }


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


    public VFC007_ComparatifPDFController() {
        Id oppId = ApexPages.currentPage().getParameters().get('id');
        Id coproId = ApexPages.currentPage().getParameters().get('coproId');
        String fournisseurs = ApexPages.currentPage().getParameters().get('fournisseurs');
        String quoteNumbers = ApexPages.currentPage().getParameters().get('quoteNumbers');
        String goQuoteNumbers = ApexPages.currentPage().getParameters().get('goQuoteNumbers');
        Boolean includeAllGO = Boolean.valueOf(ApexPages.currentPage().getParameters().get('includeAllGO'));
        showSectionTTC = Boolean.valueOf(ApexPages.currentPage().getParameters().get('sectionTTC'));
        showSectionSituationActuelle = Boolean.valueOf(ApexPages.currentPage().getParameters().get('sectionSituationActuelle'));
        fournisseursList = String.isBlank(fournisseurs) ? new List<String>() : fournisseurs.split(';');
        quoteNumberList  = String.isBlank(quoteNumbers) ? new List<String>() : quoteNumbers.split(';');
        goQuoteNumberList = String.isBlank(goQuoteNumbers) ? new List<String>() : goQuoteNumbers.split(';');
        listQLIGazList = new List<List<QuoteLineItem>>();
        listQLIC54postesList = new List<List<QuoteLineItem>>();
        listQLIC5BaseList = new List<List<QuoteLineItem>>();
        listQLIC4List = new List<List<QuoteLineItem>>();
        listQLIC2List = new List<List<QuoteLineItem>>();
        listQLIC1List = new List<List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> mapQLIGazByPdeReference = new Map<String, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> mapQLIC54postesByPdeReference = new Map<String, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> mapQLIC5BaseByPdeReference = new Map<String, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> mapQLIC4ByPdeReference = new Map<String, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> mapQLIC2ByPdeReference = new Map<String, List<QuoteLineItem>>();
        Map<String, List<QuoteLineItem>> mapQLIC1ByPdeReference = new Map<String, List<QuoteLineItem>>();
        Set<String> setFournisseurWithPageInfo = new Set<String>();
        List<Fiche_fournisseur__mdt> fournisseurMetadataList = [SELECT ImageName__c FROM Fiche_fournisseur__mdt];
        
        // Get Fiche Fournisseur
        for (Fiche_fournisseur__mdt metadata : fournisseurMetadataList) {
            setFournisseurWithPageInfo.add(metadata.ImageName__c);
        }

        // Get Opp
        opp = [ SELECT  Id, 
                        Name, 
                        TECH_IsGaz__c,
                        RecordType.Name,
                        SectionSituationActuelle__c,
                        Account.Name,
                        Demande_Cotation__r.Owner.Name, 
                        Demande_Cotation__r.Owner.Email, 
                        Demande_Cotation__r.Owner.Phone,
                        Demande_Cotation__r.OwnerId,
                        Demande_Cotation__r.TECH_Partner_OwnerName__c
                FROM Opportunity 
                WHERE Id = :oppId];

        // === Get GO Quotes avec filtrage
        String soql = 
            'SELECT Id, Name, QuoteNumber, RecordType.DeveloperName,' +
            ' OrigineGarantieOrigine__c, TechnologieGarantieOrigine__c,' +
            ' DebutCouvertureGarantieOrigine__c, FinCouvertureGarantieOrigine__c,' +
            ' ConsoAnnuelleGarantieOrigine__c, PrixGarantieOrigine__c, MargeGarantieOrigine__c, BudgetGarantieOrigine__c' +
            ' FROM Quote' +
            ' WHERE OpportunityId = :oppId' +
            ' AND IsGarantieOrigine__c = true';

        if (!(includeAllGO || goQuoteNumberList.isEmpty())) {
            soql += ' AND QuoteNumber IN :goQuoteNumberList';
        }

        soql += ' ORDER BY BudgetGarantieOrigine__c ASC';

        // On exécute avec bind des variables
        List<Quote> goQuotes = Database.query(soql);



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

        // Get Nom du compte à afficher
        if (coproId != null) {
            accountName = [SELECT Name FROM Account WHERE Id = :coproId LIMIT 1].Name;
        } else {
            accountName = opp.Account.Name;
        }

        // Get Périmètre actuel
        String listOPRQuery = ' SELECT  PDE__r.Name,' +
                                        'PDE__r.Adresse_de_consommation__c,' +
                                        'PDE__r.Siret_payeur__c,' +
                                        'PDE__r.TECH_num_compteur__c,' +
                                        'PDE__r.Segment__c,' +
                                        'PDE__r.FTA__c,' +
                                        'PDE__r.TECH_Short_FTA__c,' +
                                        'PDE__r.Tarif__c,' +
                                        'PDE__r.Profil__c,' +
                                        'PDE__r.Fournisseur__c,' +
                                        'PDE__r.DateEcheance__c,' +
                                        'PDE__r.TECH_CAR__c,' +
                                        'PDE__r.Conso_Base__c,' +
                                        'PDE__r.ConsoHP__c,' +
                                        'PDE__r.ConsoHC__c,' +
                                        'PDE__r.Conso_HPE__c,' +
                                        'PDE__r.Conso_HPH__c,' +
                                        'PDE__r.Conso_HCH__c,' +
                                        'PDE__r.Conso_HCE__c,' +
                                        'PDE__r.Conso_Pointe__c' +
                                    ' FROM OpportunityPDERelation__c' +
                                    ' WHERE Opportunity__c = :oppId';
        if (coproId != null) {listOPRQuery += ' AND PDE__r.EntiteJuridique__c = :coproId';}
        listOPRQuery += ' ORDER BY PDE__r.TECH_num_compteur__c';
        
        listOPR = (List<OpportunityPDERelation__c>) Database.query(listOPRQuery);

        // Get lstQLI
        String queryQLI = 'SELECT  TECH_fournisseur__c,' +
                                    'LogoCompactLayout__c, ' +
                                    'TECH_PdeReference__c, ' +
                                    'AbonnementMois__c, ' +
                                    'PrixMolecule__c,' +
                                    'CTA__c,' +
                                    'CTA_Mensuel_ELEC__c,' +
                                    'TICGN__c,' +
                                    'CSPE__c,' +
                                    'T_QuoteTURPE__c,' +
                                    'T_QuoteCEE__c,' +
                                    'T_QuoteFraisDistributionVariable__c,' +
                                    'T_QuoteCAPA__c,' +
                                    'TURPE_Fixe__c,' +
                                    'TURPE_Variable__c,' +
                                    'BudgetgazNaturelHTVAAn__c,' +
                                    'Budget_TTC__c,' +
                                    'TECH_Budget__c,' +
                                    'FraisTransportDistributionCapacite__c, ' +
                                    'CeeMwh__c,' +
                                    'Budget_Energie_Euro_An__c, ' +
                                    'UnitPrice, ' +
                                    'TECH_Segment__c,' +
                                    'TECH_TypeOffre__c,' +
                                    'DebutDeFourniture__c,' +
                                    'Nouvelle_Echeance__c,' +
                                    'TECH_FTA__c,' +
                                    'TECH_TypePDL__c,' +
                                    'PDE__r.Adresse_de_consommation__c,' +
                                    'ConsoHP__c,' +
                                    'ConsoHC__c,' +
                                    'Conso_Pointe__c,' +
                                    'Conso_HPH__c,' +
                                    'Conso_HPE__c,' +
                                    'Conso_HCH__c,' +
                                    'Conso_HCE__c,' +
                                    'Conso_Base__c,' +
                                    'Puissance_souscrite__c,' +
                                    'CAR_New__c,' +
                                    'PointesMWh__c,' +
                                    'PrixBase__c,' +
                                    'PrixHP__c,' +
                                    'PrixHC__c,' +
                                    'PrixHpeMwh__c,' +
                                    'PrixHphMwh__c,' +
                                    'PrixHceMwh__c,' +
                                    'PrixHchMwh__c,' +
                                    'CoutDeCapacite__c' +
                                ' FROM QuoteLineItem' + 
                                ' WHERE Opportunit__c = :oppId' +
                                ' AND TECH_fournisseur__c IN :fournisseursList' +
                                ' AND Quote.QuoteNumber IN :quoteNumberList';
        if (coproId != null) {queryQLI += ' AND PDE__r.EntiteJuridique__c = :coproId';}
        queryQLI += ' ORDER BY PDE__r.TECH_num_compteur__c, Budget_TTC__c';

        for (QuoteLineItem qli : (List<QuoteLineItem>) Database.query(queryQLI)) {

            // Classer les QLI par type de PDE
            if (qli.TECH_TypePDL__c == 'PDE_Gaz') {
                if(mapQLIGazByPdeReference.containsKey(qli.TECH_PdeReference__c)) {
                    mapQLIGazByPdeReference.get(qli.TECH_PdeReference__c).add(qli);
                } else {
                    mapQLIGazByPdeReference.put(qli.TECH_PdeReference__c, new List<QuoteLineItem>{qli});
                }
            } else if (qli.TECH_Segment__c == 'C5' && qli.TECH_FTA__c.contains('4 postes')) {
                if(mapQLIC54postesByPdeReference.containsKey(qli.TECH_PdeReference__c)) {
                    mapQLIC54postesByPdeReference.get(qli.TECH_PdeReference__c).add(qli);
                } else {
                    mapQLIC54postesByPdeReference.put(qli.TECH_PdeReference__c, new List<QuoteLineItem>{qli});
                }
            } else if (qli.TECH_Segment__c == 'C5' && !qli.TECH_FTA__c.contains('4 postes')) {
                if(mapQLIC5BaseByPdeReference.containsKey(qli.TECH_PdeReference__c)) {
                    mapQLIC5BaseByPdeReference.get(qli.TECH_PdeReference__c).add(qli);
                } else {
                    mapQLIC5BaseByPdeReference.put(qli.TECH_PdeReference__c, new List<QuoteLineItem>{qli});
                }
            } else if (qli.TECH_Segment__c == 'C4') {
                if(mapQLIC4ByPdeReference.containsKey(qli.TECH_PdeReference__c)) {
                    mapQLIC4ByPdeReference.get(qli.TECH_PdeReference__c).add(qli);
                } else {
                    mapQLIC4ByPdeReference.put(qli.TECH_PdeReference__c, new List<QuoteLineItem>{qli});
                }
            } else if (qli.TECH_Segment__c == 'C2') {
                if(mapQLIC2ByPdeReference.containsKey(qli.TECH_PdeReference__c)) {
                    mapQLIC2ByPdeReference.get(qli.TECH_PdeReference__c).add(qli);
                } else {
                    mapQLIC2ByPdeReference.put(qli.TECH_PdeReference__c, new List<QuoteLineItem>{qli});
                }
            } else if (qli.TECH_Segment__c == 'C1') {
                if(mapQLIC1ByPdeReference.containsKey(qli.TECH_PdeReference__c)) {
                    mapQLIC1ByPdeReference.get(qli.TECH_PdeReference__c).add(qli);
                } else {
                    mapQLIC1ByPdeReference.put(qli.TECH_PdeReference__c, new List<QuoteLineItem>{qli});
                }
            }
        }

        // Get Situation actuelle QLI
        if (showSectionSituationActuelle) {
            String querylstQliA = 'SELECT  TECH_fournisseur__c,' +
                                        'LogoCompactLayout__c, ' +
                                        'TECH_PdeReference__c, ' +
                                        'AbonnementMois__c, ' +
                                        'PrixMolecule__c,' +
                                        'CTA__c,' +
                                        'CTA_Mensuel_ELEC__c,' +
                                        'TICGN__c,' +
                                        'CSPE__c,' +
                                        'T_QuoteTURPE__c,' +
                                        'T_QuoteCEE__c,' +
                                        'T_QuoteFraisDistributionVariable__c,' +
                                        'T_QuoteCAPA__c,' +
                                        'TURPE_Fixe__c,' +
                                        'TURPE_Variable__c,' +
                                        'BudgetgazNaturelHTVAAn__c,' +
                                        'Budget_TTC__c,' +
                                        'TECH_Budget__c,' +
                                        'FraisTransportDistributionCapacite__c, ' +
                                        'CeeMwh__c,' +
                                        'Budget_Energie_Euro_An__c, ' +
                                        'UnitPrice, ' +
                                        'TECH_Segment__c,' +
                                        'TECH_TypeOffre__c,' +
                                        'DebutDeFourniture__c,' +
                                        'Nouvelle_Echeance__c,' +
                                        'TECH_FTA__c,' +
                                        'TECH_TypePDL__c,' +
                                        'PDE__r.Adresse_de_consommation__c,' +
                                        'ConsoHP__c,' +
                                        'ConsoHC__c,' +
                                        'Conso_Pointe__c,' +
                                        'Conso_HPH__c,' +
                                        'Conso_HPE__c,' +
                                        'Conso_HCH__c,' +
                                        'Conso_HCE__c,' +
                                        'Conso_Base__c,' +
                                        'Puissance_souscrite__c,' +
                                        'CAR_New__c,' +
                                        'PointesMWh__c,' +
                                        'PrixBase__c,' +
                                        'PrixHP__c,' +
                                        'PrixHC__c,' +
                                        'PrixHpeMwh__c,' +
                                        'PrixHphMwh__c,' +
                                        'PrixHceMwh__c,' +
                                        'PrixHchMwh__c,' +
                                        'CoutDeCapacite__c' +
                                    ' FROM QuoteLineItem' + 
                                    ' WHERE Opportunit__c = :oppId' +
                                    ' AND TECH_fournisseur__c = \'Situation Actuelle\'';
            if (coproId != null) {querylstQliA += ' AND PDE__r.EntiteJuridique__c = :coproId';}
            
            for (QuoteLineItem qli : (List<QuoteLineItem>) Database.query(querylstQliA)) {

                // Ajouter la Situation actuelle à la première position
                if (qli.TECH_TypePDL__c == 'PDE_Gaz') {
                    mapQLIGazByPdeReference.get(qli.TECH_PdeReference__c).add(0,qli); 
                } else if (qli.TECH_Segment__c == 'C5' && qli.TECH_FTA__c.contains('4 postes')) {
                    mapQLIC54postesByPdeReference.get(qli.TECH_PdeReference__c).add(0,qli); 
                } else if (qli.TECH_Segment__c == 'C5' && !qli.TECH_FTA__c.contains('4 postes')) {
                    mapQLIC5BaseByPdeReference.get(qli.TECH_PdeReference__c).add(0,qli); 
                }else if (qli.TECH_Segment__c == 'C4') {
                    mapQLIC4ByPdeReference.get(qli.TECH_PdeReference__c).add(0,qli); 
                } else if (qli.TECH_Segment__c == 'C2') {
                    mapQLIC2ByPdeReference.get(qli.TECH_PdeReference__c).add(0,qli); 
                } else if (qli.TECH_Segment__c == 'C1') {
                    mapQLIC1ByPdeReference.get(qli.TECH_PdeReference__c).add(0,qli); 
                }
            }
        }

        // Peupler les liste de liste de QLI
        if (!mapQLIGazByPdeReference.isEmpty()) {
            listQLIGazList.addAll(mapQLIGazByPdeReference.values());
        }

        if (!mapQLIC54postesByPdeReference.isEmpty()) {
            listQLIC54postesList.addAll(mapQLIC54postesByPdeReference.values());
        }

        if (!mapQLIC5BaseByPdeReference.isEmpty()) {
            listQLIC5BaseList.addAll(mapQLIC5BaseByPdeReference.values());
        }

        if (!mapQLIC4ByPdeReference.isEmpty()) {
            listQLIC4List.addAll(mapQLIC4ByPdeReference.values());
        }

        if (!mapQLIC2ByPdeReference.isEmpty()) {
            listQLIC2List.addAll(mapQLIC2ByPdeReference.values());
        }

        if (!mapQLIC1ByPdeReference.isEmpty()) {
            listQLIC1List.addAll(mapQLIC1ByPdeReference.values());
        }

        // Get page fournisseur
        listFournisseurName = new List<String>();
        for(String name : fournisseursList){
            name = name.replace(' ','_').replace('é','e').replace('è','e') + '.jpg';
            if(setFournisseurWithPageInfo.contains(name)){
                listFournisseurName.add(name);
            }
        }

        //Mise à jour du Nom/Email/Phone du commercial pour afficher Ilan Chemla pour les commerciaux Energy +
        User DDCOwner = [SELECT CompanyName,TECH_Responsable_legal_Id__c FROM User WHERE Id =: opp.Demande_Cotation__r.OwnerId];
       
        if (DDCOwner.CompanyName == 'Energy +') {
            System.debug('DDCOwner.TECH_Responsable_legal_Id__c : ' + DDCOwner.TECH_Responsable_legal_Id__c);
            User responsableLegal = [SELECT Name,Email,Phone FROM User WHERE Id =: DDCOwner.TECH_Responsable_legal_Id__c];
            commercialName =  responsableLegal.Name;
            commercialEmail = responsableLegal.Email;
            commercialPhone = responsableLegal.Phone;

        } else {
            commercialName = opp.Demande_Cotation__r.Owner.Name;
            commercialEmail = opp.Demande_Cotation__r.Owner.Email;
            commercialPhone = opp.Demande_Cotation__r.Owner.Phone;
            
        }

        loadTurpeData(oppId);

        // Set PDF filename
        String filename = 'Comparatif_Detaille ' + String.valueOf(DateTime.now().format('dd-mm-yyyy')) + ' ' + accountName;
        Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=' + filename + '.pdf');
    }
    
    /*
    * LWC Methods
    */
    @AuraEnabled
    public static String generatePDFUrl(
        Id opportunityId,
        Id coproId,
        String selectedFournisseurs,
        String selectedQuoteNumber,
        Boolean sectionTTC,
        Boolean sectionSituationActuelle,
        String selectedGOQuoteNumbers,
        Boolean includeAllGO
    ) {
        String baseUrl = Site.getBaseUrl();
        String siteContext = (URL.getCurrentRequestUrl().getPath().contains('/s/')) ? '/s' : '';

        PageReference pdfPage = Page.ComparatifPDF;
        pdfPage.getParameters().put('id', opportunityId);
        pdfPage.getParameters().put('coproId', coproId);
        pdfPage.getParameters().put('fournisseurs', selectedFournisseurs);
        pdfPage.getParameters().put('quoteNumbers', selectedQuoteNumber);
        pdfPage.getParameters().put('goQuoteNumbers', selectedGOQuoteNumbers);
        pdfPage.getParameters().put('includeAllGO', String.valueOf(includeAllGO)); // <-- ajout
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
            : 'Toutes'; // puisque maintenant on affiche toujours toutes

        feed.Body = 'L\'utilisateur ' + UserInfo.getName()
            + ' a téléchargé le comparatif détaillé | Offres: ' + fournisseursLabel
            + ' | Garanties d\'origine: ' + goLabel;

        insert feed;
        
        return baseUrl + siteContext + pdfPage.getUrl();
    }


    @AuraEnabled(cacheable=true)
    public static List<Quote> getInfosComparatif(Id opportunityId) {
        return [
            SELECT Opportunity.Name,
                Opportunity.RecordType.Name,
                Opportunity.SectionSituationActuelle__c,
                Opportunity.Section_TTC__c,
                Fournisseur__c,
                Date_Validite_Offre__c,
                Minimum_date_de_debut__c,
                Maximum_date_de_fin__c,    
                QuoteNumber,
                IsGarantieOrigine__c     
            FROM Quote
            WHERE OpportunityId = :opportunityId
            AND Fournisseur__c != 'Situation Actuelle'
            AND IsGarantieOrigine__c = false
            AND IsOptimisationTurpe__c = false
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityPDERelation__c> getInfosOpportunity(Id opportunityId) {
        return [SELECT PDE__r.EntiteJuridique__c, PDE__r.EntiteJuridique__r.Name, Opportunity__r.Account.RecordType.DeveloperName
                FROM OpportunityPDERelation__c 
                WHERE Opportunity__c = :opportunityId];
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


    /**
     * Méthode accessible au LWC (même principe que getInfosComparatif)
     */
    @AuraEnabled(cacheable=true)
    public static List<Quote> getInfosTurpe(Id opportunityId) {
        return [
            SELECT Id, Name, IsOptimisationTurpe__c, SumEconomieIdentifiee__c,MargeInterventionPEPS__c
            FROM Quote
            WHERE OpportunityId = :opportunityId
            AND IsOptimisationTurpe__c = true
        ];
    }

    /**
     * Récupère la configuration PEPS (marge par défaut, minimale et maximale)
     * depuis la Custom Setting MargePEPS__c.
     * Cette méthode est utilisée côté LWC pour afficher et valider la marge.
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getPEPSConfig() {
        // Récupère le premier enregistrement du custom setting
        MargePEPS__c conf = MargePEPS__c.getOrgDefaults();
        if (conf == null) {
            throw new AuraHandledException('Configuration PEPS non trouvée.');
        }

        return new Map<String, Decimal>{
            'defaultMargin' => conf.DefaultMargin__c,
            'minMargin'     => conf.MinMargin__c,
            'maxMargin'     => conf.MaxMargin__c
        };
    }


    /**
     * Applique la marge utilisateur pour recalculer le montant d'intervention PEP'S.
     * La méthode recharge la configuration pour garantir une validation serveur
     * même si l'appel ne vient pas du LWC (ex: Flow, API, batch...).
     */
    @AuraEnabled
    public static void applyPEPSMargin(Id opportunityId, Decimal userMargin) {
        // Charger la configuration
        MargePEPS__c conf = MargePEPS__c.getOrgDefaults();
        Decimal defaultMargin = conf.DefaultMargin__c;
        Decimal minMargin     = conf.MinMargin__c;
        Decimal maxMargin     = conf.MaxMargin__c;
        Decimal marge;

        // Validation serveur
        if (userMargin < minMargin || userMargin > maxMargin) {
            throw new AuraHandledException(
                'La marge doit être comprise entre ' + minMargin + '% et ' + maxMargin + '%.'
            );
        }

        marge = (userMargin != null) ? userMargin : defaultMargin;


        // Vérifier la présence d'une quote TURPE
        List<Quote> lstTurpeQuote = [
            SELECT Id FROM Quote
            WHERE OpportunityId = :opportunityId
            AND IsOptimisationTurpe__c = true
            LIMIT 1
        ];
        if (lstTurpeQuote.isEmpty()) {
            throw new AuraHandledException('Aucune quote d’optimisation TURPE trouvée pour cette opportunité.');
        }

        // Récupération des QLI associées
        List<QuoteLineItem> lstQLI = [
            SELECT Id, EconomieIdentifie__c, PDE__c
            FROM QuoteLineItem
            WHERE QuoteId = :lstTurpeQuote[0].Id
        ];

        if (lstQLI.isEmpty()) {
            throw new AuraHandledException('Aucune ligne de devis trouvée sur la quote TURPE.');
        }

        // Application du calcul de marge
        List<PDE__c> lstPDEToUpdate = new List<PDE__c>();

        // Application du calcul de marge + mise à jour du PDE
        for (QuoteLineItem qli : lstQLI) {
            Decimal eco = (qli.EconomieIdentifie__c != null) ? qli.EconomieIdentifie__c : 0;
            // Calcul de l’intervention PEPS
            Decimal intervention = (eco * marge / 100);

            // Mise à jour de la QLI
            qli.InterventionPEPS__c = intervention.setScale(2, RoundingMode.HALF_UP);

            // Préparer la mise à jour du PDE associé
            lstPDEToUpdate.add(new PDE__c(
                Id = qli.PDE__c,
                InterventionPEPS__c = qli.InterventionPEPS__c
            ));
        }

        lstTurpeQuote.get(0).MargeInterventionPEPS__c = marge;

        // Mise à jour des QLI
        update lstQLI;
        update lstTurpeQuote;

        // Mise à jour du PDE lié
        if (!lstPDEToUpdate.isEmpty()) {
            update lstPDEToUpdate;
        }
    }
}