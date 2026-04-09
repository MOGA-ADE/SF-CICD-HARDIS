public with sharing class SM001_GestionDevis {
 
  public static void createLigneDevisFournisseur(Map<Opportunity,List<String>> mapOppFournisseurToCreate ){

    Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
    RecordType RtElec = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Elec' AND SobjectType = 'Quote' LIMIT 1];
    RecordType RtGaz = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Gaz' AND SobjectType = 'Quote' LIMIT 1];

    List<Quote> listQuoteToCreate = new List<Quote>();
    for(Opportunity opp: mapOppFournisseurToCreate.keySet()){
      for(String fournisseur : mapOppFournisseurToCreate.get(opp)){
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

    try {
      Database.insert(listQuoteToCreate, true);
      createQLIfromQuote(listQuoteToCreate);
    } catch (Exception e) {
      System.debug('Error '+e.getMessage());
    }
  }

  public static void addLigneDevis(Map<Id, OpportunityPDERelation__c> mapNewOPR) {

    Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
    RecordType RtElec = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Elec' AND SobjectType = 'Quote' LIMIT 1];
    RecordType RtGaz = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Gaz' AND SobjectType = 'Quote' LIMIT 1];
    PricebookEntry entryGaz = [SELECT Id, Name, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Name = 'GAZ' AND Pricebook2Id = :pb.Id LIMIT 1];
    PricebookEntry entryElec = [SELECT Id, Name, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Name = 'ELEC' AND Pricebook2Id = :pb.Id LIMIT 1];
    Valeur_Annuelle__mdt customMetadataRecord = [SELECT CTA_T1__c,
                                                    CTA_T2__c,
                                                    CTA_T3__c,
                                                    CTA_T4__c,
                                                    CSPE_PuissanceInfOuEgal36Kva__c,
                                                    CSPE_PuissanceSup36OuEgal250__c,
                                                    CSPE_PuissanceSup250__c,
                                                    Frais_Transport_Distribution_Capacite_T1__c,
                                                    Frais_Transport_Distribution_Capacite_T2__c,
                                                    Frais_Transport_Distribution_Capacite_T3__c,
                                                    Frais_Transport_Distribution_Capacite_T4__c
                                                 FROM 
                                                    Valeur_Annuelle__mdt
                                                 LIMIT 1];

    Map<String,Double> mapFournisseurCEEGaz = new Map<String,Double>();
    Map<String,Double> mapFournisseurCEEElec =  new Map<String,Double>();
    for(CEE_Fournisseur__mdt CEEFournisseur : [SELECT CEE__c, Fournisseur__c, Type_energie__c FROM CEE_Fournisseur__mdt]){
      if(CEEFournisseur.Type_energie__c == 'Gaz'){
        mapFournisseurCEEGaz.put(CEEFournisseur.Fournisseur__c,CEEFournisseur.CEE__c);
      } else {
        mapFournisseurCEEElec.put(CEEFournisseur.Fournisseur__c,CEEFournisseur.CEE__c);
      }
    }

    List<Id> listOpportunityId = new List<Id>();
    List<QuoteLineItem> listQLIToInsert = new List<QuoteLineItem>();
    Map<Id, list<Quote>> mapOppIdListQuote = new Map<Id, list<Quote>>();

    for (OpportunityPDERelation__c opr : mapNewOPR.values()) {
      listOpportunityId.add(opr.Opportunity__c);
    }

    for (Quote quote : [SELECT Id, CEE__c,Fournisseur__c, OpportunityId, TECH_PropositionRenouvellement__c, TECH_SituationActuelle__c FROM Quote WHERE OpportunityId IN :listOpportunityId]) {
      if (mapOppIdListQuote.get(quote.OpportunityId) != null) {
        mapOppIdListQuote.get(quote.OpportunityId).add(quote);
      } else {
        List<Quote> tmpListQuote = new List<Quote>();
        tmpListQuote.add(quote);
        mapOppIdListQuote.put(quote.OpportunityId, tmpListQuote);
      }
    }

    for (OpportunityPDERelation__c opr : mapNewOPR.values()) {
      if (mapOppIdListQuote.get(opr.Opportunity__c) != null) {
        for (Quote quote : mapOppIdListQuote.get(opr.Opportunity__c)) {
          if (quote.TECH_PropositionRenouvellement__c) {
            QuoteLineItem qliPropositionRenouvellement = new QuoteLineItem();
            qliPropositionRenouvellement.Product2Id = entryElec.Product2Id;
            qliPropositionRenouvellement.QuoteId = quote.Id;
            qliPropositionRenouvellement.PriceBookEntryId = opr.pde__r.TypePDE__c == 'Gaz' ? entryGaz.Id : entryElec.id;
            qliPropositionRenouvellement.Quantity = 1;
            qliPropositionRenouvellement.UnitPrice = 0;
            qliPropositionRenouvellement.PDE__c = opr.pde__c;
            qliPropositionRenouvellement.Opportunit__c = quote.OpportunityId;
            qliPropositionRenouvellement.DebutdeFourniture__c = opr.pde__r.DateEcheance__c != null ? opr.pde__r.DateEcheance__c  + 1 : null;
            qliPropositionRenouvellement.ConsoHC__c = opr.pde__r.ConsoHC__c;
            qliPropositionRenouvellement.ConsoHP__c = opr.pde__r.ConsoHP__c;
            qliPropositionRenouvellement.Conso_Base__c = opr.pde__r.Conso_Base__c;
            qliPropositionRenouvellement.Conso_HCE__c = opr.pde__r.Conso_HCE__c;
            qliPropositionRenouvellement.Conso_HCH__c = opr.pde__r.Conso_HCH__c;
            qliPropositionRenouvellement.Conso_HPE__c = opr.pde__r.Conso_HPE__c;
            qliPropositionRenouvellement.Conso_HPH__c = opr.pde__r.Conso_HPH__c;
            qliPropositionRenouvellement.Conso_Pointe__c = opr.pde__r.Conso_Pointe__c;
            qliPropositionRenouvellement.Puissance_souscrite__c = opr.pde__r.Puissance_souscrite__c;
            if(opr.pde__r.Calendrier_fournisseur__c == 'HP/HC' || opr.pde__r.Calendrier_fournisseur__c == 'Heures Pleines/Creuses'){
              qliPropositionRenouvellement.TECH_CalendrierFournisseur__c = 'HP/HC';
            }
            else if(opr.pde__r.Calendrier_fournisseur__c == 'Base' || opr.pde__r.Calendrier_fournisseur__c != ''){
              qliPropositionRenouvellement.TECH_CalendrierFournisseur__c = 'Base';
            }

            qliPropositionRenouvellement.CARGaz__c = opr.pde__r.CARGaz__c;
            if (opr.pde__r.TypePDE__c == 'Gaz') {
              if(opr.pde__r.Tarif__c == 'T1'){
                qliPropositionRenouvellement.CTA__c = customMetadataRecord.CTA_T1__c;
                qliPropositionRenouvellement.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T1__c;
              } else if(opr.pde__r.Tarif__c == 'T2'){
                qliPropositionRenouvellement.CTA__c = customMetadataRecord.CTA_T2__c;
                qliPropositionRenouvellement.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T2__c;
              } else if(opr.pde__r.Tarif__c == 'T3'){
                qliPropositionRenouvellement.CTA__c = customMetadataRecord.CTA_T3__c;
                qliPropositionRenouvellement.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T3__c;
              } else if(opr.pde__r.Tarif__c == 'T4'){
                qliPropositionRenouvellement.CTA__c = customMetadataRecord.CTA_T4__c;
                qliPropositionRenouvellement.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T4__c;
              } else {
                qliPropositionRenouvellement.CTA__c = 1;
                qliPropositionRenouvellement.FraisTransportDistributionCapacite__c = 1;
              }
            }
            else{

              if(opr.PDE__r.Puissance_souscrite__c <= 36){
                qliPropositionRenouvellement.CSPE__c = customMetadataRecord.CSPE_PuissanceInfOuEgal36Kva__c;
              }
              else if (opr.PDE__r.Puissance_souscrite__c > 36 && opr.PDE__r.Puissance_souscrite__c <= 250 ){
                qliPropositionRenouvellement.CSPE__c = customMetadataRecord.CSPE_PuissanceSup36OuEgal250__c;
              }
              else {
                qliPropositionRenouvellement.CSPE__c = customMetadataRecord.CSPE_PuissanceSup250__c;
              }
            }
            listQLIToInsert.add(qliPropositionRenouvellement);
          }

          if (quote.TECH_SituationActuelle__c) {
            QuoteLineItem qliSituationActuelle = new QuoteLineItem();
            qliSituationActuelle.Product2Id = entryElec.Product2Id;
            qliSituationActuelle.QuoteId = quote.Id;
            qliSituationActuelle.PriceBookEntryId = opr.pde__r.TypePDE__c == 'Gaz' ? entryGaz.Id : entryElec.id;
            qliSituationActuelle.Quantity = 1;
            qliSituationActuelle.UnitPrice = 0;
            qliSituationActuelle.PDE__c = opr.pde__c;
            qliSituationActuelle.Opportunit__c = quote.OpportunityId;
            qliSituationActuelle.DebutdeFourniture__c = opr.pde__r.DateEcheance__c != null ? opr.pde__r.DateEcheance__c  + 1 : null;
            qliSituationActuelle.ConsoHC__c = opr.pde__r.ConsoHC__c;
            qliSituationActuelle.ConsoHP__c = opr.pde__r.ConsoHP__c;
            qliSituationActuelle.Conso_Base__c = opr.pde__r.Conso_Base__c;
            qliSituationActuelle.Conso_HCE__c = opr.pde__r.Conso_HCE__c;
            qliSituationActuelle.Conso_HCH__c = opr.pde__r.Conso_HCH__c;
            qliSituationActuelle.Conso_HPE__c = opr.pde__r.Conso_HPE__c;
            qliSituationActuelle.Conso_HPH__c = opr.pde__r.Conso_HPH__c;
            qliSituationActuelle.Conso_Pointe__c = opr.pde__r.Conso_Pointe__c;
            qliSituationActuelle.Puissance_souscrite__c = opr.pde__r.Puissance_souscrite__c;
            if(opr.pde__r.Calendrier_fournisseur__c == 'HP/HC' || opr.pde__r.Calendrier_fournisseur__c == 'Heures Pleines/Creuses'){
              qliSituationActuelle.TECH_CalendrierFournisseur__c = 'HP/HC';
            }
            else if(opr.pde__r.Calendrier_fournisseur__c == 'Base' || opr.pde__r.Calendrier_fournisseur__c != ''){
              qliSituationActuelle.TECH_CalendrierFournisseur__c = 'Base';
            }
            qliSituationActuelle.CARGaz__c = opr.pde__r.CARGaz__c;
            if (opr.pde__r.TypePDE__c == 'Gaz') {
              if(opr.pde__r.Tarif__c == 'T1'){
                qliSituationActuelle.CTA__c = customMetadataRecord.CTA_T1__c;
                qliSituationActuelle.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T1__c;
              } else if(opr.pde__r.Tarif__c == 'T2'){
                qliSituationActuelle.CTA__c = customMetadataRecord.CTA_T2__c;
                qliSituationActuelle.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T2__c;
              } else if(opr.pde__r.Tarif__c == 'T3'){
                qliSituationActuelle.CTA__c = customMetadataRecord.CTA_T3__c;
                qliSituationActuelle.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T3__c;
              } else if(opr.pde__r.Tarif__c == 'T4'){
                qliSituationActuelle.CTA__c = customMetadataRecord.CTA_T4__c;
                qliSituationActuelle.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T4__c;
              } else {
                qliSituationActuelle.CTA__c = 1;
                qliSituationActuelle.FraisTransportDistributionCapacite__c = 1;
              }
            }
            else{

              if(opr.PDE__r.Puissance_souscrite__c <= 36){
                qliSituationActuelle.CSPE__c = customMetadataRecord.CSPE_PuissanceInfOuEgal36Kva__c;
              }
              else if (opr.PDE__r.Puissance_souscrite__c > 36 && opr.PDE__r.Puissance_souscrite__c <= 250 ){
                qliSituationActuelle.CSPE__c = customMetadataRecord.CSPE_PuissanceSup36OuEgal250__c;
              }
              else {
                qliSituationActuelle.CSPE__c = customMetadataRecord.CSPE_PuissanceSup250__c;
              }

            }
            listQLIToInsert.add(qliSituationActuelle);
          }

          if (!quote.TECH_PropositionRenouvellement__c && !quote.TECH_SituationActuelle__c){
            QuoteLineItem qliToInsert = new QuoteLineItem();
            qliToInsert.Product2Id = entryElec.Product2Id;
            qliToInsert.QuoteId = quote.Id;
            qliToInsert.PriceBookEntryId = opr.pde__r.TypePDE__c == 'Gaz' ? entryGaz.Id : entryElec.id;
            qliToInsert.Quantity = 1;
            qliToInsert.UnitPrice = 0;
            qliToInsert.PDE__c = opr.pde__c;
            qliToInsert.Opportunit__c = quote.OpportunityId;
            qliToInsert.DebutdeFourniture__c = opr.pde__r.DateEcheance__c != null ? opr.pde__r.DateEcheance__c  + 1 : null;
            qliToInsert.ConsoHC__c = opr.pde__r.ConsoHC__c;
            qliToInsert.ConsoHP__c = opr.pde__r.ConsoHP__c;
            qliToInsert.Conso_Base__c = opr.pde__r.Conso_Base__c;
            qliToInsert.Conso_HCE__c = opr.pde__r.Conso_HCE__c;
            qliToInsert.Conso_HCH__c = opr.pde__r.Conso_HCH__c;
            qliToInsert.Conso_HPE__c = opr.pde__r.Conso_HPE__c;
            qliToInsert.Conso_HPH__c = opr.pde__r.Conso_HPH__c;
            qliToInsert.Conso_Pointe__c = opr.pde__r.Conso_Pointe__c;
            qliToInsert.Puissance_souscrite__c = opr.pde__r.Puissance_souscrite__c;
            if(opr.pde__r.Calendrier_fournisseur__c == 'HP/HC' || opr.pde__r.Calendrier_fournisseur__c == 'Heures Pleines/Creuses'){
              qliToInsert.TECH_CalendrierFournisseur__c = 'HP/HC';
            }
            else if(opr.pde__r.Calendrier_fournisseur__c == 'Base' || opr.pde__r.Calendrier_fournisseur__c != ''){
              qliToInsert.TECH_CalendrierFournisseur__c = 'Base';
            }

            qliToInsert.CARGaz__c = opr.pde__r.CARGaz__c;
            if(quote.CEE__c == 'Soumis'){
              if(opr.pde__r.TypePDE__c == 'Gaz'){
                qliToInsert.CeeMwh__c = mapFournisseurCEEGaz.get(quote.Fournisseur__c) == null ? 0 : mapFournisseurCEEGaz.get(quote.Fournisseur__c); 
              }
              else{
                qliToInsert.CeeMwh__c = mapFournisseurCEEElec.get(quote.Fournisseur__c) == null ? 0 : mapFournisseurCEEElec.get(quote.Fournisseur__c); 
              }
            }
            if (opr.pde__r.TypePDE__c == 'Gaz') {
              if(opr.pde__r.Tarif__c == 'T1'){
                qliToInsert.CTA__c = customMetadataRecord.CTA_T1__c;
                qliToInsert.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T1__c;
              } else if(opr.pde__r.Tarif__c == 'T2'){
                qliToInsert.CTA__c = customMetadataRecord.CTA_T2__c;
                qliToInsert.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T2__c;
              } else if(opr.pde__r.Tarif__c == 'T3'){
                qliToInsert.CTA__c = customMetadataRecord.CTA_T3__c;
                qliToInsert.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T3__c;
              } else if(opr.pde__r.Tarif__c == 'T4'){
                qliToInsert.CTA__c = customMetadataRecord.CTA_T4__c;
                qliToInsert.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T4__c;
              } else {
                qliToInsert.CTA__c = 1;
                qliToInsert.FraisTransportDistributionCapacite__c = 1;
              }
            }
            else{
              if(opr.PDE__r.Puissance_souscrite__c <= 36){
                qliToInsert.CSPE__c = customMetadataRecord.CSPE_PuissanceInfOuEgal36Kva__c;
              }
              else if (opr.PDE__r.Puissance_souscrite__c > 36 && opr.PDE__r.Puissance_souscrite__c <= 250 ){
                qliToInsert.CSPE__c = customMetadataRecord.CSPE_PuissanceSup36OuEgal250__c;
              }
              else {
                qliToInsert.CSPE__c = customMetadataRecord.CSPE_PuissanceSup250__c;
              }
            }
            listQLIToInsert.add(qliToInsert);
          }
        }
      }
    }

    if (!listQLIToInsert.isEmpty()) {
      insert listQLIToInsert;
    }
  }

  public static void addLigneDevisFournisseur(Map<Opportunity,List<String>> mapOppIdListFournisseurToAdd ){

    Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
    RecordType RtElec = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Elec' AND SobjectType = 'Quote' LIMIT 1];
    RecordType RtGaz = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Gaz' AND SobjectType = 'Quote' LIMIT 1];
    List<Quote> listQuoteToInsert = new list<Quote>();
    
    for(Opportunity opp : mapOppIdListFournisseurToAdd.keySet()){
      for(String fournisseur : mapOppIdListFournisseurToAdd.get(opp)){
        listQuoteToInsert.add(
          new Quote(
            OpportunityId = opp.Id,
            ExpirationDate = opp.CloseDate,
            Name = fournisseur.toUpperCase() + ' - ' + opp.Name,
            Fournisseur__c = fournisseur,
            RecordTypeId = opp.TECH_FTA__c == 'Gaz' ? RTGaz.Id : RTElec.Id,
            Pricebook2Id = pb.Id,
            Date_de_fin_de_contrat__c = Date.TODAY(),
            CEE__c = opp.Account.CEE__c
          )
        );
      }
    }

    try {
      Database.insert(listQuoteToInsert, true);
      createQLIfromQuote(listQuoteToInsert);
    } catch (Exception e) {
      system.debug('addLigneDevisFournisseur Error '+ e.getCause());
    }
  }

  public static void addLigneDevisParticulier(List<Opportunity> listOppIdSAToAdd,List<Opportunity> listOppIdPRToAdd){
    
    Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
    RecordType RtElec = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Elec' AND SobjectType = 'Quote' LIMIT 1];
    RecordType RtGaz = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Gaz' AND SobjectType = 'Quote' LIMIT 1];
    List<Quote> listQuoteToInsert = new List<Quote>();
    List<Quote> listQLIToInsert = new List<Quote>();

    if(!listOppIdSAToAdd.isEmpty()){
      for(Opportunity opp: listOppIdSAToAdd){
        listQuoteToInsert.add(
          new Quote(
            OpportunityId = opp.Id,
            ExpirationDate = opp.CloseDate,
            Name = 'SITUATION ACTUELLE' + ' - ' + opp.Name,
            RecordTypeId = opp.TECH_FTA__c == 'Gaz' ? RTGaz.Id : RTElec.Id,
            Pricebook2Id = pb.Id,
            Date_de_fin_de_contrat__c = Date.TODAY(),
            Fournisseur__c = 'Situation Actuelle',
            CEE__c = opp.Account.CEE__c
          )
        );
      }
    }

    if(!listOppIdPRToAdd.isEmpty()){
      for(Opportunity opp: listOppIdPRToAdd){
        listQuoteToInsert.add(
          new Quote(
            OpportunityId = opp.Id,
            ExpirationDate = opp.CloseDate,
            Name = 'PROPOSITION DE RENOUVELLEMENT' + ' - ' + opp.Name,
            RecordTypeId = opp.TECH_FTA__c == 'Gaz' ? RTGaz.Id : RTElec.Id,
            Pricebook2Id = pb.Id,
            Date_de_fin_de_contrat__c = Date.TODAY(),
            Fournisseur__c = 'Proposition Renouvellement',
            CEE__c = opp.Account.CEE__c
          )
        );
      }
    }

    try {
      Database.insert(listQuoteToInsert, true);
      createQLIfromQuote(listQuoteToInsert);
    } catch (Exception e) {
      System.debug('Error '+e.getMessage());
    }
  }

  public static void deleteLigneDevisFournisseur(List<String> listQuoteOppIdFournisseurToDelete){
    try {
      delete [SELECT Id FROM Quote WHERE TECH_OppId_fournisseur__c IN : listQuoteOppIdFournisseurToDelete];
    } catch (Exception e) {
      System.debug('Error '+e.getMessage());
    }
  }

  public static void deleteLigneDevisParticulier(List<Id> listOppIdSAToDelete, List<Id> listOppIdPRToDelete){

    try {
      if(listOppIdSAToDelete != null) {
        delete [SELECT Id FROM Quote WHERE OpportunityId IN : listOppIdSAToDelete AND Tech_situationActuelle__c = True];
      } 
      if(listOppIdPRToDelete != null) {
        delete [SELECT Id FROM Quote WHERE OpportunityId IN : listOppIdPRToDelete AND TECH_PropositionRenouvellement__c = True];
      }
    } catch (Exception e) {
      System.debug('Error '+e.getMessage());
    }
  }

  public static void deleteLigneDevis(Map<Id, OpportunityPDERelation__c> mapOldOPR) {
    List<Id> listOpportunityId = new List<Id>();
    List<QuoteLineItem> listQLIToDelete = new List<QuoteLineItem>();
    Map<Id, list<QuoteLineItem>> mapOppIdListQLI = new Map<Id, list<QuoteLineItem>>();

    for (OpportunityPDERelation__c opr : mapOldOPR.values()) {
      listOpportunityId.add(opr.Opportunity__c);
    }

    for (QuoteLineItem qli : [SELECT Id, PDE__c, TECH_OpportunityId__c FROM QuoteLineItem WHERE TECH_OpportunityId__c IN :listOpportunityId]) {
      if (mapOppIdListQLI.get(qli.TECH_OpportunityId__c) != null) {
        mapOppIdListQLI.get(qli.TECH_OpportunityId__c).add(qli);
      } else {
        List<QuoteLineItem> tmpListQuoteLineItem = new List<QuoteLineItem>();
        tmpListQuoteLineItem.add(qli);
        mapOppIdListQLI.put(qli.TECH_OpportunityId__c, tmpListQuoteLineItem);
      }
    }

    for (OpportunityPDERelation__c opr : mapOldOPR.values()) {
      for (QuoteLineItem qli : mapOppIdListQLI.get(opr.Opportunity__c)) {
        if (qli.PDE__c == opr.PDE__c) {
          listQLIToDelete.add(qli);
        }
      }
    }
    if (!listQLIToDelete.isEmpty()) {
      delete listQLIToDelete;
    }
  }

  public static void deleteAllFournisseurQuote(Set<Id> oppIds) {
    try {
      delete [SELECT Id FROM Quote WHERE OpportunityId IN : oppIds AND Tech_situationActuelle__c = false AND TECH_PropositionRenouvellement__c = false];
    } catch (Exception e) {
      System.debug('Error '+e.getMessage());
    }
  }

  private static void createQLIfromQuote(List<Quote> ListQuote){

    Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
    PricebookEntry entryGaz = [SELECT Id, Name, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Name = 'GAZ' AND Pricebook2Id = :pb.Id LIMIT 1];
    PricebookEntry entryElec = [SELECT Id, Name, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Name = 'ELEC' AND Pricebook2Id = :pb.Id LIMIT 1];
    Valeur_Annuelle__mdt customMetadataRecord = [SELECT CTA_T1__c,
                                                        CTA_T2__c,
                                                        CTA_T3__c,
                                                        CTA_T4__c,
                                                 		CSPE_PuissanceInfOuEgal36Kva__c,
                                                    	CSPE_PuissanceSup36OuEgal250__c,
                                                    	CSPE_PuissanceSup250__c,
                                                        Frais_Transport_Distribution_Capacite_T1__c,
                                                        Frais_Transport_Distribution_Capacite_T2__c,
                                                        Frais_Transport_Distribution_Capacite_T3__c,
                                                        Frais_Transport_Distribution_Capacite_T4__c
                                                    FROM 
                                                      Valeur_Annuelle__mdt
                                                    LIMIT 1];

    Map<String,Double> mapFournisseurCEEGaz = new Map<String,Double>();
    Map<String,Double> mapFournisseurCEEElec =  new Map<String,Double>();
    for(CEE_Fournisseur__mdt CEEFournisseur : [SELECT CEE__c, Fournisseur__c, Type_energie__c FROM CEE_Fournisseur__mdt]){
      if(CEEFournisseur.Type_energie__c == 'Gaz'){
        mapFournisseurCEEGaz.put(CEEFournisseur.Fournisseur__c,CEEFournisseur.CEE__c);
      } else {
        mapFournisseurCEEElec.put(CEEFournisseur.Fournisseur__c,CEEFournisseur.CEE__c);
      }
    }
    Set<Id> oppId = new Set<Id>();
    Map<Id,List<OpportunityPDERelation__c>> mapOppIdListOPR = new Map<Id,List<OpportunityPDERelation__c>>();
    List<QuoteLineItem> listQLIToInsert = new list<QuoteLineItem>();

    // On récupère les OppId depuis la liste des quotes
    for (Quote quote : ListQuote) {
      oppId.add(quote.OpportunityId);
    }

    // On récupère les OPR et on les stock dans une map avec l'oppID
    for (OpportunityPDERelation__c opr : [SELECT  PDE__r.Id, 
                                                  Opportunity__c, 
                                                  PDE__r.TypePDE__c, 
                                                  PDE__r.DateEcheance__c,
                                                  PDE__r.Calendrier_fournisseur__c,
                                                  PDE__r.ConsoHC__c,
                                                  PDE__r.ConsoHP__c,
                                                  PDE__r.Conso_Base__c,
                                                  PDE__r.Conso_HCE__c,
                                                  PDE__r.Conso_HCH__c,
                                                  PDE__r.Conso_HPE__c,
                                                  PDE__r.Conso_HPH__c,
                                                  PDE__r.Conso_Pointe__c,
                                                  PDE__r.Segment__c,
                                                  PDE__r.Puissance_souscrite__c,
                                                  PDE__r.CARGaz__c ,
                                                  PDE__r.Tarif__c
                                          FROM OpportunityPDERelation__c 
                                          WHERE Opportunity__c 
                                          IN :oppId]) {
      if(mapOppIdListOPR.get(opr.Opportunity__c) != null) {
        mapOppIdListOPR.get(opr.Opportunity__c).add(opr);
      } else {
        List<OpportunityPDERelation__c> listOPR = new List<OpportunityPDERelation__c>();
        listOPR.add(opr);
        mapOppIdListOPR.put(opr.Opportunity__c, listOPR);
      }
    }

    // Pour chaque Quote insert
    for (Quote quote : ListQuote) {
      // On parcours les OPR de l'opp associée
      if (mapOppIdListOPR.get(quote.OpportunityId) != null) {
        for (OpportunityPDERelation__c opr : mapOppIdListOPR.get(quote.OpportunityId)) {
          // On créer les QLI correspondantes
          QuoteLineItem qli = new QuoteLineItem();
          qli.Product2Id = entryElec.Product2Id;
          qli.QuoteId = quote.Id;
          qli.PriceBookEntryId = opr.pde__r.TypePDE__c == 'Gaz'? entryGaz.Id: entryElec.id;
          qli.Quantity = 1;
          qli.UnitPrice = 0;
          qli.PDE__c = opr.pde__r.Id;
          qli.DebutdeFourniture__c = opr.pde__r.DateEcheance__c != null ? opr.pde__r.DateEcheance__c  + 1 : null;
          qli.Opportunit__c = quote.OpportunityId;
          qli.ConsoHC__c = opr.pde__r.ConsoHC__c;
          qli.ConsoHP__c = opr.pde__r.ConsoHP__c;
          qli.Conso_Base__c = opr.pde__r.Conso_Base__c;
          qli.Conso_HCE__c = opr.pde__r.Conso_HCE__c;
          qli.Conso_HCH__c = opr.pde__r.Conso_HCH__c;
          qli.Conso_HPE__c = opr.pde__r.Conso_HPE__c;
          qli.Conso_HPH__c = opr.pde__r.Conso_HPH__c;
          qli.Conso_Pointe__c = opr.pde__r.Conso_Pointe__c;
          qli.Puissance_souscrite__c = opr.pde__r.Puissance_souscrite__c;

          if(opr.pde__r.Calendrier_fournisseur__c == 'HP/HC' || opr.pde__r.Calendrier_fournisseur__c == 'Heures Pleines/Creuses'){
            qli.TECH_CalendrierFournisseur__c = 'HP/HC';
          }
          else if(opr.pde__r.Calendrier_fournisseur__c == 'Base' || opr.pde__r.Calendrier_fournisseur__c != ''){
            qli.TECH_CalendrierFournisseur__c = 'Base';
          }
          
          qli.CARGaz__c = opr.pde__r.CARGaz__c;
          
          if(quote.CEE__c == 'Soumis'){
            if(opr.pde__r.TypePDE__c == 'Gaz'){
              qli.CeeMwh__c = mapFournisseurCEEGaz.get(quote.Fournisseur__c) == null ? 0 : mapFournisseurCEEGaz.get(quote.Fournisseur__c); 
            }
            else{
              qli.CeeMwh__c = mapFournisseurCEEElec.get(quote.Fournisseur__c) == null ? 0 : mapFournisseurCEEElec.get(quote.Fournisseur__c); 
            }
          }
          if (opr.pde__r.TypePDE__c == 'Gaz') {
            if(opr.pde__r.Tarif__c == 'T1'){
              qli.CTA__c = customMetadataRecord.CTA_T1__c;
              qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T1__c;
            } else if(opr.pde__r.Tarif__c == 'T2'){
              qli.CTA__c = customMetadataRecord.CTA_T2__c;
              qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T2__c;
            } else if(opr.pde__r.Tarif__c == 'T3'){
              qli.CTA__c = customMetadataRecord.CTA_T3__c;
              qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T3__c;
            } else if(opr.pde__r.Tarif__c == 'T4'){
              qli.CTA__c = customMetadataRecord.CTA_T4__c;
              qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T4__c;
            } else {
              qli.CTA__c = 1;
              qli.FraisTransportDistributionCapacite__c = 1;
            }
          }
          else{

            if(opr.PDE__r.Puissance_souscrite__c <= 36){
              qli.CSPE__c = customMetadataRecord.CSPE_PuissanceInfOuEgal36Kva__c;
            }
            else if (opr.PDE__r.Puissance_souscrite__c > 36 && opr.PDE__r.Puissance_souscrite__c <= 250 ){
              qli.CSPE__c = customMetadataRecord.CSPE_PuissanceSup36OuEgal250__c;
            }
            else {
              qli.CSPE__c = customMetadataRecord.CSPE_PuissanceSup250__c;
            }
          }
          listQLIToInsert.add(qli);
        }
      }
    }
    System.debug('listQLIToInsert '+listQLIToInsert);

    try {
      Database.insert(listQLIToInsert, true);
    } catch (Exception e) {
      System.debug('createQLIfromQuote Error '+e.getMessage());
    }
  }
}