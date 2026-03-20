public class Utils {

  public static String toCurrency(Decimal p_ammount) {
    if(p_ammount == null){
      return '0 €';
    }
    List<String> args = new List<String>{ '0', 'number', '###,###,##0.00' };
    List<String> argsNegative = new List<String>{ '- 0', 'number', '###,###,##0.00' };
    String result = '';
    try {
      if( p_ammount < 0 ){
        result = String.format(p_ammount.format(), argsNegative) + ' €';
      }
      else{
        result = String.format(p_ammount.format(), args) + ' €';
      }
    } catch (Exception error) {
    }

    return result;
  }

  @AuraEnabled
  public static boolean isCommunity(){
    Id siteId = Site.getSiteId(); // take a look at the apex class Site, you may find more useful method concerning site/community
    if (siteId != null) {
        return true;
    }
    return false;
  }
    /*
     *La méthode logSGE crée et enregistre un enregistrement Log__c pour suivre une mise à jour d’un point d'énergie,
     *en associant le numéro de compteur, les dates d’action, l’utilisateur actuel et l’identifiant du point d’énergie concerné. 
     */
  @future
  public static void logSGE(String numeroCompteur, Date DateACD, Datetime ActionDate,Id idPDE){
      
      Log__c log = new Log__c();
      log.Name = 'LOG SGE '+ UserInfo.getLastName() + ' ' + UserInfo.getFirstName() + ' '+ numeroCompteur;
      log.NumeroCompteur__c = numeroCompteur;
      log.currentUser__c = UserInfo.getUserId();
      log.Date_ACD__c = DateACD;
      log.Type__c= 'SGE';
      log.ActionDate__c = ActionDate;
      log.Pde__c = idPDE;
      System.debug(' The current user is : '+log.currentUser__r.Name);
      Database.SaveResult result = Database.insert(log, false);

      if (!result.isSuccess()) {
          System.debug(' Erreur lors de l’insertion du log : ' + result.getErrors()[0].getMessage());
      }else {
            System.debug('insertion reussi');
      }

    }
  
  public static void logSGEDocusign(String numeroCompteur, Date DateACD, Datetime ActionDate,Id idPDE,Id ownerId){
    System.debug('logSGEDocusign');
    Log__c log = new Log__c();
    log.Name = 'LOG SGE Signature ACD Docusign ' + numeroCompteur;
    log.NumeroCompteur__c = numeroCompteur;
    log.currentUser__c = ownerId;
    log.Date_ACD__c = DateACD;
    log.Type__c= 'SGE';
    log.ActionDate__c = ActionDate;
    log.Pde__c = idPDE;
    Database.SaveResult result = Database.insert(log, false);

    if (!result.isSuccess()) {
        System.debug(' Erreur lors de l’insertion du log : ' + result.getErrors()[0].getMessage());
    }else {
          System.debug('insertion reussi');
    }
  }


  public static String generateCodePartenaire() {
    Blob b = Crypto.GenerateAESKey(128);
    String s = EncodingUtil.ConvertTohex(b);
    String code = s.SubString(0,8)+ '-' + s.SubString(8,15);
    return code;
  }

  @AuraEnabled
  public static String getSobjectTypeName(Id id){
    return id.getSobjectType().getDescribe().getName();
  }
}