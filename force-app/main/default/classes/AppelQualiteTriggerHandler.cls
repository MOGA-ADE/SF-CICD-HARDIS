public with sharing class AppelQualiteTriggerHandler extends TriggerHandler {

    List<Appel_qualite__c> appQualiteList = new List<Appel_qualite__c>();
    List<Appel_qualite__c> updateappQualiteList = new List<Appel_qualite__c>();


    private Double calculateScore(List<String> listValue)   {
        System.debug('calculateScore');
        Double score = 0;
        for(String l : listValue) {
            if(/*l != 'Énergie' && */l != 'S’est présenté comme travaillant avec ADE' && l != 'Numéro de téléphone signataire' && l != 'Mail signataire')  {
                score += 1;
            }
        }
        return score;
    }

    public override void beforeInsert(){
        for(Appel_qualite__c aq : (List<Appel_qualite__c>)Trigger.New) {
            System.debug('aq.elements_conformes__c '+ aq.elements_conformes__c);
            aq.TECH_Score_conformite__c = aq.elements_conformes__c == null ? 0 : calculateScore(aq.elements_conformes__c.split(';'));
        }
    }

    public override void beforeUpdate(){
        System.debug('beforeUpdate');
        for(Appel_qualite__c aq :  (List<Appel_qualite__c>)Trigger.New){
            if(aq.elements_conformes__c != ((Appel_qualite__c)Trigger.oldMap.get(aq.Id)).elements_conformes__c){
                aq.TECH_Score_conformite__c = aq.elements_conformes__c == null ? 0 : calculateScore(aq.elements_conformes__c.split(';'));
            }
        }
    }
}