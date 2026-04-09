public class WrapOpport {
  public String Template { get; set; }
  public String Courtier { get; set; }
  public String CourtierTelephone { get; set; }
  public String CourtierEmail { get; set; }
  public String Commentaire { get; set; }
  public String Raison_sociale { get; set; }
  public String SIREN { get; set; }
  public String Prenom_NOM { get; set; }
  public String Telephone { get; set; }
  public String Email { get; set; }
  public String Activite { get; set; }

  public Boolean displayContribution { get; set; }
  public Boolean displayAcheminement { get; set; }
  public Boolean displayTTC { get; set; }

  public WrapOpport(OpportunitycontactRole ocr) {
    Template = ocr.opportunity.TemplateCotation__c;
    String courtierPrenom = ocr.opportunity.responsableCotation__r.FirstName == null ? '' : ocr.opportunity.responsableCotation__r.FirstName;
    String clientPrenom =  ocr.Contact.FirstName == null ? ''  : ocr.Contact.FirstName;
    Courtier = courtierPrenom + ' ' + ocr.opportunity.responsableCotation__r.LastName.toUpperCase();
    CourtierTelephone = ocr.opportunity.responsableCotation__r.phone;
    CourtierEmail = ocr.opportunity.responsableCotation__r.Email;
    Commentaire = ocr.opportunity.Commentaire_Comparatif__c;
    Raison_sociale = ocr.opportunity.Account.Name;
    Activite = ocr.opportunity.Account.activite__c;
    SIREN = ocr.opportunity.Account.Siren__c;
    Prenom_NOM = clientPrenom + ' ' + ocr.Contact.LastName.toUpperCase();
    Telephone = ocr.Contact.Phone;
    Email = ocr.Contact.Email;
    displayContribution = ocr.opportunity.Section_contribution__c;
    displayAcheminement = ocr.opportunity.section_Acheminement__c;
    displayTTC = ocr.opportunity.section_TTC__c;
  }
}