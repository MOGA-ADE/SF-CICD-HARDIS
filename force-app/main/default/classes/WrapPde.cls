public class WrapPde implements Comparable {
  public Id id;
  public String SITE_DE_CONSOMMATION { get; set; }
  public String SIRET_PAYEUR { get; set; }
  public String RAE { get; set; }
  public String Echeance { get; set; }
  public String Profil { get; set; }
  public String Segment { get; set; }
  public String Tarif { get; set; }
  public String Puissance { get; set; }
  public Decimal displayConsopointes { get; set; }
  public Decimal displayConsoHPH { get; set; }
  public Decimal displayConsoHCH { get; set; }
  public Decimal displayConsoHPE { get; set; }
  public Decimal displayConsoHCE { get; set; }
  public Decimal displayConsoHC { get; set; }
  public Decimal displayConsoHP { get; set; }
  public Decimal displayConsoBase { get; set;}
  public Decimal displayCAR { get; set; }
  public Decimal displayCAR_Gaz { get; set; }
  public Decimal CAR_Gaz { get; set; }
  public String PCE { get; set; }

  public String Profil_Gaz { get; set; }

  public String fournisseur { get; set; }
  public String adresse { get; set; }
  public List<WrapLigneDeDevis> listLigneDeDevis { get; set; }

  public Decimal displayConsoHP_Base {get;set;}

  public WrapPde(OpportunityPDERelation__c opr) {
    Boolean isCU;
    if(opr.PDE__r?.FTA__c == null){
      isCU = false;
    }else{
      isCU = opr.PDE__r.FTA__c.contains('CU');
    }
    system.debug('isCU '+isCU); 
    Id = opr.pde__r.Id;
    listLigneDeDevis = new List<WrapLigneDeDevis>();
    //SITE_DE_CONSOMMATION

    SITE_DE_CONSOMMATION = '';
    SITE_DE_CONSOMMATION += opr.pde__r.SiteConsommation__c != null
      ? opr.pde__r.SiteConsommation__c + ' ' + '-' + ' '
      : '';
    SITE_DE_CONSOMMATION += opr.pde__r.NumeroVoie__c != null
      ? opr.pde__r.NumeroVoie__c + ' '
      : '';
    SITE_DE_CONSOMMATION += opr.pde__r.voie__c != null
      ? opr.pde__r.voie__c + ' '
      : '';
    SITE_DE_CONSOMMATION += opr.pde__r.Code_Postal__c != null
      ? opr.pde__r.Code_Postal__c + ' '
      : '';
    SITE_DE_CONSOMMATION += opr.pde__r.Ville__c != null
      ? opr.pde__r.Ville__c
      : '';
    //SIRET
    RAE = opr.pde__r.ReferencePointEnergie_Refonte__c;
    if(opr.pde__r.DateEcheance__c == null){
      if(opr.PDE__r.Premiere_mise_en_service__c){
        Echeance = 'Première MES';
      }
      else {
        Echeance = 'Pas de date d\'échéance';
      }
    } else{
      Echeance  = opr.pde__r.DateEcheance__c.format();
    }
    Profil = opr.pde__r.FTA__c;
    Segment = String.valueOf(opr.pde__r.Segment__c);
    Tarif = String.valueOf(opr.pde__r.Tarif__c);
    Puissance = String.valueOf(opr.pde__r.Puissance_souscrite__c);
    SIRET_PAYEUR = opr.pde__r.Siret_payeur__c;

    fournisseur = opr.pde__r.fournisseur__c;
    adresse = opr.pde__r.Adresse_de_consommation__c;

    displayConsoHP = opr.pde__r.ConsoHP__c;
    displayConsoPointes = opr.pde__r.Conso_Pointe__c;
    displayConsoHPH = opr.pde__r.Conso_HPH__c;
    displayConsoHCH = opr.pde__r.Conso_HCH__c;
    displayConsoHPE = opr.pde__r.Conso_HPE__c;
    displayConsoHCE = opr.pde__r.Conso_HCE__c;
    displayConsoBase = opr.pde__r.Conso_Base__c;
    displayCAR = opr.pde__r.Consommation_Annuelle_de_R_f_rence_Elec__c;

    displayCAR_Gaz = opr.pde__r.CARGaz__c;
    PCE = opr.pde__r.PCE_Refonte__c;
    Profil_Gaz = String.valueOf(opr.pde__r.Profil__c) != null
      ? Tarif + '-' + String.valueOf(opr.pde__r.Profil__c)
      : Tarif;

      if(!isCU){
        displayConsoHC = opr.pde__r.ConsoHC__c == null ? 0.00 : opr.pde__r.ConsoHC__c;
        displayConsoHP_Base = displayConsoHP;
      }else{
        displayConsoHC = 0.00;
        displayConsoHP_Base = displayConsoBase;
      }
  }

  public Integer compareTo(Object compareTo) {
    WrapPDE compareToWPDE = (WrapPDE) compareTo;


    // The return value of 0 indicates that both elements are equal.
    Integer returnValue = 0;
    if ((this.SITE_DE_CONSOMMATION == null) && (compareToWPDE.SITE_DE_CONSOMMATION == null)){
      returnValue = 0;
    } else if ((this.SITE_DE_CONSOMMATION == null) && (compareToWPDE.SITE_DE_CONSOMMATION != null)){
      returnValue = -1;
    } else if ((this.SITE_DE_CONSOMMATION != null) && (compareToWPDE.SITE_DE_CONSOMMATION == null)){
      returnValue = 1;
    } else if (this.SITE_DE_CONSOMMATION > compareToWPDE.SITE_DE_CONSOMMATION) {
      returnValue = 1;
    } else if (this.SITE_DE_CONSOMMATION < compareToWPDE.SITE_DE_CONSOMMATION) {
      returnValue = -1;
    }
    return returnValue;
  }
}