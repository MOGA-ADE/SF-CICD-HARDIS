public with sharing class ShowPDECoproController {
  @AuraEnabled
  public static List<PDE__c> retrievePDE(String recordId) {
    List<Id> listCopros = new List<Id>();
    for (Account acc : [SELECT Id FROM Account WHERE Syndic__c = :recordId]) {
      listCopros.add(acc.Id);
    }
    return [
      SELECT
        Id,
        Name,
        Siret_payeur__c,
        EntiteJuridique__c,
        EntiteJuridique__r.Name,
        Contrat_actif__c,
        CARGaz__c,
        TECH_num_compteur__c,
        Consommation_Annuelle_de_R_f_rence_Elec__c,
        TypePDE__c,
        DateEcheance__c
      FROM PDE__c
      WHERE EntiteJuridique__c IN :listCopros
    ];
  }

  @AuraEnabled
  public static Boolean deletePDERowAction(List<String> listPDEId) {
    List<PDE__c> listPDEToDelete = [
      SELECT Id, EntiteJuridique__r.Syndic__c
      FROM PDE__c
      WHERE Id IN :listPDEId
    ];
    System.debug('listToDElete '+listPDEToDelete.size());
    if (listPDEToDelete.size() > 0) {
      Database.DeleteResult[] srList = Database.delete(listPDEToDelete, false);
      for (Database.DeleteResult sr : srList) {
        if (!sr.isSuccess()) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}