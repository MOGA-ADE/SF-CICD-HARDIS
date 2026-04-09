public with sharing class SM002_GestionDevisMasse {

    public static void generateDevis(List<Opportunity> listOpp){

        Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
        RecordType RtElec = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Elec' AND SobjectType = 'Quote' LIMIT 1];
        RecordType RtGaz = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Gaz' AND SobjectType = 'Quote' LIMIT 1];
        List<Id> listOppId = new List<Id>();
        List<Quote> listQuoteToCreate = new List<Quote>();
        for(Opportunity opp : listOpp){
            listOppId.add(opp.Id);
        }
        try {
            Database.delete([SELECT Id from Quote where OpportunityId in :listOppId],true);
        } catch (Exception e) {
            System.debug('Error '+e.getMessage());
        }

        for(Opportunity opp: listOpp){
            if(opp.Liste_Fournisseurs__c != null){
                for(String fournisseur : opp.Liste_Fournisseurs__c.split(';')){
                    Quote quote = new Quote();
                    quote.OpportunityId = opp.Id;
                    // quote.UniqueId__c = fournisseur.toUpperCase() + '-' + opp.Id;
                    quote.ExpirationDate = opp.CloseDate;
                    quote.Name = fournisseur.toUpperCase() + ' - ' + opp.Name;
                    quote.Fournisseur__c = fournisseur;
                    quote.RecordTypeId = opp.TECH_FTA__c == 'Gaz' ? RTGaz.Id : RTElec.Id;
                    quote.Pricebook2Id = pb.Id;
                    quote.Date_de_fin_de_contrat__c = Date.TODAY();
                    quote.CEE__c = opp.Account.CEE__c;
                    listQuoteToCreate.add(quote);
                }
            }
            if(opp.SectionPropositionRenouvellement__c){
                listQuoteToCreate.add(
                    new Quote(
                      OpportunityId = opp.Id,
                      ExpirationDate = opp.CloseDate,
                      Name = 'PROPOSITION DE RENOUVELLEMENT' + ' - ' + opp.Name,
                      RecordTypeId = opp.TECH_FTA__c == 'Gaz' ? RTGaz.Id : RTElec.Id,
                      Pricebook2Id = pb.Id,
                      CEE__c = opp.Account.CEE__c,
                      Date_de_fin_de_contrat__c = Date.TODAY(),
                      Fournisseur__c = 'Proposition Renouvellement'
                    )
                  );
            }
            if(opp.SectionSituationActuelle__c){
                listQuoteToCreate.add(
                    new Quote(
                      OpportunityId = opp.Id,
                      ExpirationDate = opp.CloseDate,
                      Name = 'SITUATION ACTUELLE' + ' - ' + opp.Name,
                      RecordTypeId = opp.TECH_FTA__c == 'Gaz' ? RTGaz.Id : RTElec.Id,
                      Pricebook2Id = pb.Id,
                      CEE__c = opp.Account.CEE__c,
                      Date_de_fin_de_contrat__c = Date.TODAY(),
                      Fournisseur__c = 'Situation Actuelle'
                    )
                  );
            }
        }

        try {
            Database.insert(listQuoteToCreate, true);
        } catch (Exception e) {
            System.debug('Error SM002_GestionDevisMasse generateDevis '+e.getMessage());
        }
    }

    public static void deleteAllDevis(List<Opportunity> listOpp){
        List<Id> listOppId = new List<Id>();
        for(Opportunity opp : listOpp){
            listOppId.add(opp.Id);
        }
        try {
            Database.delete([SELECT Id from Quote where OpportunityId in :listOppId],true);
        } catch (Exception e) {
            System.debug('Error SM002_GestionDevisMasse deleteAllDevis '+e.getMessage());
        }
    }
}