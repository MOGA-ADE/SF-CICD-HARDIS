public with sharing class WrapFournisseur implements Comparable{
  public String NomFournisseur {get;set;}
  public String logo {get;set;}
  public Integer numberOfQLI {get;set;}
  public Decimal TotalBudgetTTC {get;set;}
  public String typeOffre {get;set;}
  public List<WrapLigneDeDevis> listQLI {get;set;}
  public Map<String,WrapLigneDeDevis> mapQLI {get;set;}
  public Integer minDateYear {get;set;}
  public Integer maxDateYear {get;set;}

  public Decimal prixMoyenParAn {
    get{
        return TotalBudgetTTC / numberOfQLI;
    }set;
  }

  
  public WrapFournisseur(Quote quote, List<WrapLigneDeDevis> qlis){
    typeOffre = quote.TypeOffre__c;
    NomFournisseur = quote.Fournisseur__c;
    logo = quote.TECH_FournisseurLogo__c;
    numberOfQLI = quote.LineItemCount;
    TotalBudgetTTC = quote.TotalBudgetTTC__c;
    listQLI = qlis;
  }

  public WrapFournisseur(Quote quote, Map<String,WrapLigneDeDevis> mapQLIs, List<WrapLigneDeDevis> qlis){
    typeOffre = quote.TypeOffre__c;
    NomFournisseur = quote.Fournisseur__c;
    logo = quote.TECH_FournisseurLogo__c;
    numberOfQLI = quote.LineItemCount;
    TotalBudgetTTC = quote.TotalBudgetTTC__c;
    mapQLI = mapQLIs;
    minDateYear = quote.Minimum_date_de_debut__c.year();
    maxDateYear = quote.Maximum_date_de_fin__c.year();
    listQLI = qlis;
  }

  public Integer compareTo(Object compareTo) {
    WrapFournisseur compareToWF = (WrapFournisseur)compareTo;
    
    // The return value of 0 indicates that both elements are equal.
    Integer returnValue = 0;
    if ((this.prixMoyenParAn == null) && (compareToWF.prixMoyenParAn == null)) {
        // both wrappers have null prixMoyenParAns
        returnValue = 0;
    } else if ((this.prixMoyenParAn == null) && (compareToWF.prixMoyenParAn != null)){
        // nulls-first implementation
        returnValue = -1;
    } else if ((this.prixMoyenParAn != null) && (compareToWF.prixMoyenParAn == null)){
        // nulls-first implementation
        returnValue = 1;
    } else if (this.prixMoyenParAn > compareToWF.prixMoyenParAn) {
        // Set return value to a positive value.
        returnValue = 1;
    } else if (this.prixMoyenParAn < compareToWF.prixMoyenParAn) {
        // Set return value to a negative value.
        returnValue = -1;
    } 
    return returnValue;
  }
}