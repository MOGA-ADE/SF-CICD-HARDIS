public  class WrapPDEInfoEnedis {

    @AuraEnabled @InvocableVariable public String siteName ;
    @AuraEnabled public Decimal consoBase {get;set;}
    @AuraEnabled public Decimal consoHP {get;set;}
    @AuraEnabled public Decimal consoHC {get;set;}
    @AuraEnabled public Decimal consoHPH {get;set;}
    @AuraEnabled public Decimal consoHCH {get;set;}
    @AuraEnabled public Decimal consoHCE {get;set;}
    @AuraEnabled public Decimal consoHPE {get;set;}
    @AuraEnabled public Decimal consoPointe {get;set;}
    @AuraEnabled public Decimal psBase {get;set;}
    @AuraEnabled public Decimal psHP {get;set;}
    @AuraEnabled public Decimal psHC {get;set;}
    @AuraEnabled public Decimal psHPH {get;set;}
    @AuraEnabled public Decimal psHCH {get;set;}
    @AuraEnabled public Decimal psHCE {get;set;}
    @AuraEnabled public Decimal psHPE {get;set;}
    @AuraEnabled public Decimal psPointe {get;set;}
    @AuraEnabled public Decimal psMoyenne {get;set;}
    @AuraEnabled public Decimal psSoutirage {get;set;}
    @AuraEnabled public Decimal carSite {get;set;}
    @AuraEnabled public String FTA {get;set;}
    @AuraEnabled public String CalendrierFrn {get;set;}
    @AuraEnabled public String adresse {get;set;}
    @AuraEnabled public String codePostal {get;set;}
    @AuraEnabled public String ville {get;set;}
    @AuraEnabled public String segment {get;set;}
    @AuraEnabled public String etatContractuel {get;set;}
    @AuraEnabled public Date dateConsoStart {get;set;}
    @AuraEnabled public Date dateConsoEnd {get;set;}  
    @AuraEnabled public Date dateDerniereModificationFTA {get;set;}  
    @AuraEnabled @InvocableVariable public String messageConsulterMesure;
    @AuraEnabled @InvocableVariable public String messageConsulterPoint;
    @AuraEnabled @InvocableVariable public String messageUpdate;
    @AuraEnabled public Boolean mesuresUpdatable {get;set;}
    @AuraEnabled public Boolean techDataUpdatable {get;set;}
    @AuraEnabled public Boolean lessThan12months {get;set;}
    @AuraEnabled public String bodyM {get;set;}
    @AuraEnabled public String bodyT {get;set;}
    
    public WrapPDEInfoEnedis() {
        consoBase = 0;
        consoHP = 0;
        consoHC = 0;
        consoHPH = 0;
        consoHCH = 0;
        consoHPE = 0;
        consoHCE = 0;
        consoPointe = 0;
        psBase = 0;
        psHP = 0;
        psHC = 0;
        psHPH = 0;
        psHCH = 0;
        psHPE = 0;
        psHCE = 0;
        psPointe = 0;
        mesuresUpdatable = false;
        techDataUpdatable = false;
    }

    public void calculateCAR () {
        this.carSite = consoBase + consoHP + consoHC + consoHPH + consoHCH + consoHPE + consoHCE + consoPointe;
    }
}