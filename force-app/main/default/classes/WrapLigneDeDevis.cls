public class WrapLigneDeDevis implements Comparable {

  public enum SortField{siteDeConsoEnum, DateFinEnum}
  public static SortField SORT_FIELD = SortField.siteDeConsoEnum;
  public Integer DateFinInt{
      get{
          if(DateFin != null){
            return Integer.valueOf(DateFin.year());
          }return 0;
      }set;
  }
  public Date DateDebut { get; set; }
  public Date DateFin{get;set;}
  public Decimal BudgetTTC;
  public Decimal carElec { get; set; }
  public Decimal displayabonnement { get; set; }
  public Decimal displayBudgetAnnuel { get; set; }
  public Decimal displayBudgetAnnuelEstime { get; set; }
  public Decimal displayBudgetHT { get; set; }
  public Decimal displayBudgetTTC { get; set; }
  public String  displayCEE { get; set; }
  public Decimal displayCoutDeCapacite { get; set; }
  public Decimal displayCSPE { get; set; }
  public Decimal displayCTA { get; set; }
  public Decimal displayCTAGaz { get; set; }
  public Decimal displayDistribution { get; set; }
  public Decimal displayPrixBase { get; set; }
  public Decimal displayPrixHC { get; set; }
  public Decimal displayPrixHCE { get; set; }
  public Decimal displayPrixHCH { get; set; }
  public Decimal displayPrixHP { get; set; }
  public Decimal displayPrixHPE { get; set; }
  public Decimal displayPrixHPH { get; set; }
  public Decimal displayPrixMolecule { get; set; }
  public Decimal displayPrixpointes { get; set; }
  public Decimal displayTCFE { get; set; }
  public Decimal displayTICGN { get; set; }
  public Decimal displayTURPE { get; set; }
  public Decimal displayTVA { get; set; }
  public String periodeCouverture { get; set; }
  public String SITE_DE_CONSOMMATION{get;set;}
  public String fournisseurLogo {get;set;}
  public String identifiantSite {get;set;}
  public String TECHOdreAlpha {get;set;}
  public String typeOffre {get;set;}
  public String dateEchancePDE {get;set;}
  public Decimal displayConsoHP_Base {get;set;}
  public Decimal displayPrixHP_Base {get;set;}

  public WrapLigneDeDevis(QuoteLineItem qli){
    SITE_DE_CONSOMMATION = '';
    SITE_DE_CONSOMMATION += qli.pde__r.SiteConsommation__c != null
      ? qli.pde__r.SiteConsommation__c + ' ' + '-' + ' '
      : '';
    SITE_DE_CONSOMMATION += qli.pde__r.NumeroVoie__c != null
      ? qli.pde__r.NumeroVoie__c + ' '
      : '';
    SITE_DE_CONSOMMATION += qli.pde__r.voie__c != null
      ? qli.pde__r.voie__c + ' '
      : '';
    SITE_DE_CONSOMMATION += qli.pde__r.Code_Postal__c != null
      ? qli.pde__r.Code_Postal__c + ' '
      : '';
    SITE_DE_CONSOMMATION += qli.pde__r.Ville__c != null
      ? qli.pde__r.Ville__c
      : '';
    
    Boolean isCU;
    if(qli.PDE__r?.FTA__c == null){
      isCU = false;
    }else{
      isCU = qli.PDE__r.FTA__c.contains('CU');
    }
    Decimal tupeVariable = qli.TURPE_Variable__c != null ? qli.TURPE_Variable__c : 0;
    Decimal tupeFixe = qli.TURPE_Fixe__c != null ? qli.TURPE_Fixe__c : 0;
    BudgetTTC = qli.Budget_TTC__c;
    if (qli.CAR_New__c == null) {
      carElec = 1;
    } else {
      carElec = qli.CAR_New__c == 0 ? 1 : qli.CAR_New__c;
    }
    DateDebut = qli.DebutDeFourniture__c;
    DateFin = qli.Nouvelle_Echeance__c;
    if(qli.PDE__r.DateEcheance__c == null){
      if(qli.PDE__r.Premiere_mise_en_service__c){
        dateEchancePDE = 'Première MES';
      }
      else {
        dateEchancePDE = 'Pas de date d\'échéance';
      }
    } else{
      dateEchancePDE = qli.pde__r.DateEcheance__c.format();
    }


    displayabonnement = qli.AbonnementMois__c;
    displayBudgetAnnuel = qli.BudgetFourniture__c;
    displayBudgetAnnuelEstime = qli.BudgetFourniture__c;
    // displayBudgetHT = qli.BudgetHTTan__c;
    displayBudgetHT = qli.TECH_Budget__c;
    displayBudgetTTC = qli.Budget_TTC__c;
    displayCoutDeCapacite = qli.CoutDeCapacite__c == null ? 0.0 : qli.CoutDeCapacite__c  ;
    displayCSPE = qli?.Taxes__c ? qli?.CSPE__c : null;
    displayCTA = qli.CTA_Mensuel_ELEC__c;
    displayCTAGaz = qli.CTA__c;
    displayDistribution = qli.FraisTransportDistributionCapacite__c;
    displayPrixHCE = qli.PrixHceMwh__c;
    displayPrixHCH = qli.PrixHchMwh__c;
    displayPrixHPE = qli.PrixHpeMwh__c;
    displayPrixHPH = qli.PrixHphMwh__c;
    displayPrixMolecule = qli.PrixMolecule__c;
    displayPrixBase = qli.PrixBase__c;
    displayPrixHC = qli.PrixHC__c == null ? 0.0 : qli.PrixHC__c ;
    displayPrixHP = qli.PrixHP__c;
    displayTCFE = qli?.Taxes__c ? qli?.TECH_TCFE__c : null;
    displayTICGN = qli.TICGN__c;
    displayTURPE = (tupeFixe * 12 + tupeVariable * carElec) / carElec;
    displayTVA = qli.TVA__c;
    displayPrixpointes = qli.PointesMWh__c;
    fournisseurLogo = qli.Quote.TECH_FournisseurLogo__c;
    typeOffre = qli.Quote.TypeOffre__c;
    identifiantSite = qli.PDE__r.ReferencePointEnergie_Refonte__c != null ? qli.PDE__r.ReferencePointEnergie_Refonte__c : qli.PDE__r.PCE_Refonte__c;
    PeriodeCouverture = String.valueOf(DateDebut.format()) + '<br> - <br>' + String.valueOf(DateFin.format());

    TECHOdreAlpha = SITE_DE_CONSOMMATION + String.valueOf(DateFin.year()) + String.valueOf(DateDebut.year());
    displayConsoHP_Base = isCU ? qli.pde__r.Conso_Base__c : qli.pde__r.ConsoHP__c; 
    displayPrixHP_Base  = isCU ? displayPrixBase : displayPrixHP; 

    if (qli.T_QuoteCEE__c == 'Non Soumis') {
      displayCEE = 'Non Soumis';
    } else if (qli.T_QuoteCEE__c == 'Inclus') {
      displayCEE = 'Inclus';
    } else if (qli.T_QuoteCEE__c == 'Soumis' || qli.T_QuoteCEE__c == null) {
      displayCEE = Utils.toCurrency(qli.CeeMwh__c);
    }
  }

  public Integer compareTo(Object compareTo) {
    WrapLigneDeDevis compareToWF = (WrapLigneDeDevis)compareTo;
    // The return value of 0 indicates that both elements are equal.
    Integer returnValue = 0;
    if ((this.TECHOdreAlpha == null) && (compareToWF.TECHOdreAlpha == null)) {
        // both wrappers have null TECHOdreAlphas
        returnValue = 0;
    } else if ((this.TECHOdreAlpha == null) && (compareToWF.TECHOdreAlpha != null)){
        // nulls-first implementation
        returnValue = -1;
    } else if ((this.TECHOdreAlpha != null) && (compareToWF.TECHOdreAlpha == null)){
        // nulls-first implementation
        returnValue = 1;
    } else if (this.TECHOdreAlpha > compareToWF.TECHOdreAlpha) {
        // Set return value to a positive value.
        returnValue = 1;
    } else if (this.TECHOdreAlpha < compareToWF.TECHOdreAlpha) {
        // Set return value to a negative value.
        returnValue = -1;
    } 
    return returnValue;
  }


  // public Integer compareTo(Object other) {
  //     if(SORT_FIELD == SortField.siteDeConsoEnum)
  //         return compareToSiteDeConsommation(other);
  //     else if (SORT_FIELD == SortField.DateFinEnum)
  //         return compareToDateFin(other);
  //     else
  //         return 0;
  // }
  
  // public Integer compareToDateFin(Object compareTo){
  //     WrapLigneDeDevis compareToModel = (WrapLigneDeDevis)compareTo;
  //     // Ascending Order comparison.
  //     if(DateFinInt > compareToModel.DateFinInt)
  //         return 1;
  //     else if(DateFinInt == compareToModel.DateFinInt)
  //         return 0;
  //     else
  //         return -1;
  // }
  
  // public Integer compareToSiteDeConsommation(Object compareTo){
  //   WrapLigneDeDevis compareToModel = (WrapLigneDeDevis)compareTo;
  //     // Ascending Order comparison.
  //     if(SITE_DE_CONSOMMATION > compareToModel.SITE_DE_CONSOMMATION)
  //         return 1;
  //     else if(SITE_DE_CONSOMMATION == compareToModel.SITE_DE_CONSOMMATION)
  //         return 0;
  //     else
  //         return -1;
  // }
}