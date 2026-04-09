/**
 * @author Abdellah Boussaidi
 * @date Creation 03/12/2019
 * @description Opportunity Trigger Handler
 */

public with sharing class OpportunityTriggerHandler extends TriggerHandler {
  //private static final String CLASS_NAME = OpportunityTriggerHandler.class.getName();

  public override void afterUpdate() {
    Set<Id> oppIds = new Set<Id>();

    for (SObject sob : Trigger.new) {

      Opportunity opp = (Opportunity) sob;

      if (!opp.bypassGrill__c) {
          oppIds.add(opp.Id);
      }
  }

    if (oppIds.isEmpty()) {
        return;
    }

    List<Opportunity> listOppSimpleRT = new List<Opportunity>([SELECT Id,Liste_Fournisseurs__c,Name,CloseDate,SectionPropositionRenouvellement__c,SectionSituationActuelle__c,TECH_FTA__c, Account.CEE__c FROM Opportunity WHERE REcordType.DeveloperName like '%Simple%' and Id IN :oppIds]);
    List<Opportunity> listOppMasseRT = new List<Opportunity>([SELECT Id,Liste_Fournisseurs__c,Name,CloseDate,SectionPropositionRenouvellement__c,SectionSituationActuelle__c,TECH_FTA__c, Account.CEE__c FROM Opportunity WHERE REcordType.DeveloperName like '%Masse%' and Id IN :oppIds]);
    
    if(!listOppSimpleRT.isEmpty()){

      List<Opportunity> listOppToUpdateQuote = new List<Opportunity>();
      Map<Opportunity,List<String>> mapOppFournisseurToCreate = new Map<Opportunity,List<String>>();
      List<String> listQuoteOppIdFournisseurToDelete = new List<String>();
      Map<Opportunity,List<String>> mapOppListFournisseurToAdd = new Map<Opportunity,List<String>>();
      Set<Id> setOppIdToDeleteAllQuote = new Set<Id>();
      List<Opportunity> listOppIdSAToAdd = new List<Opportunity>();    
      List<Opportunity> listOppIdPRToAdd = new List<Opportunity>();
      List<String> listOppIdSAToDelete = new List<String>();
      List<String> listOppIdPRToDelete = new List<String>();
      Map<Id,List<String>> mapOppIdFournisseurNew = new Map<Id,List<String>>();
      Map<Id,List<String>> mapOppIdFournisseurOld = new Map<Id,List<String>>();
  
      // Pour chaque opp mise à jour
      for(Opportunity opp  : listOppSimpleRT){
        // Check changement fournisseurs
        
        if (opp.Liste_Fournisseurs__c == null && ((Opportunity)Trigger.oldMap.get(opp.Id)).Liste_Fournisseurs__c != null) { // Tous les fournisseurs ont été retirés
          setOppIdToDeleteAllQuote.add(opp.Id);
        } else if(opp.Liste_Fournisseurs__c != ((Opportunity)Trigger.oldMap.get(opp.Id)).Liste_Fournisseurs__c){ // Les fournisseurs ont été modifiés
          if(((Opportunity)Trigger.oldMap.get(opp.Id)).Liste_Fournisseurs__c == null){ // Les fournisseurs étaient vide avant
            mapOppFournisseurToCreate.put(opp,opp.Liste_Fournisseurs__c.split(';'));
          }else{ // Les fournisseurs ont changé (ajout et/ou suppression)
            listOppToUpdateQuote.add(opp);
            mapOppIdFournisseurNew.put(opp.Id,((Opportunity)Trigger.newMap.get(opp.Id)).Liste_Fournisseurs__c.split(';'));
            mapOppIdFournisseurOld.put(opp.Id,((Opportunity)Trigger.oldMap.get(opp.Id)).Liste_Fournisseurs__c.split(';'));
          }
        }
  
        // Check Changement Situation Actuelle
        if(opp.SectionSituationActuelle__c != ((Opportunity)Trigger.oldMap.get(opp.Id)).SectionSituationActuelle__c){
          if(opp.SectionSituationActuelle__c){
            listOppIdSAToAdd.add(opp);
          }else{
            listOppIdSAToDelete.add(opp.Id);
          }
        }
  
        // Check Changement Proposition de Renouvellement
        if(opp.SectionPropositionRenouvellement__c != ((Opportunity)Trigger.oldMap.get(opp.Id)).SectionPropositionRenouvellement__c){
          if(opp.SectionPropositionRenouvellement__c){
            listOppIdPRToAdd.add(opp);
          }else{
            listOppIdPRToDelete.add(opp.Id);
          }
        }
      }
  
      // Si nouveaux fournisseurs
      if(!mapOppFournisseurToCreate.isEmpty()){
        SM001_GestionDevis.createLigneDevisFournisseur(mapOppFournisseurToCreate);
      }
  
      // Si plus de fournisseurs
      if(!setOppIdToDeleteAllQuote.isEmpty()){
        SM001_GestionDevis.deleteAllFournisseurQuote(setOppIdToDeleteAllQuote);
      }
  
      // Si changement de fournisseurs détecté
      if(!listOppToUpdateQuote.isEmpty()){
        // Pour chaque opp où les fournisseurs ont changés
        for(Opportunity opportunity : listOppToUpdateQuote){
          // Pour chaque fournisseurs de l'ancienne liste
          for(String fournisseur : ((Opportunity)Trigger.oldMap.get(opportunity.Id)).Liste_Fournisseurs__c.split(';')){
            // Si la nouvelle liste ne contient plus ce fournisseur
            if(!mapOppIdFournisseurNew.get(opportunity.Id).contains(fournisseur)){
              // Alors on l'ajoute dans la liste des fournisseurs a supprimer en se basant sur son TECH_Id
              listQuoteOppIdFournisseurToDelete.add(opportunity.Id+'_'+fournisseur);
            }
          }
          // Pour chaque fournisseurs de la nouvelle liste
          for(String fournisseur : mapOppIdFournisseurNew?.get(opportunity.Id)){
            // Si l'ancienne liste ne contenait pas ce fournisseur
            if(!mapOppIdFournisseurOld.get(opportunity.Id).contains(fournisseur)){
              // Alors on l'ajoute dans la map des fournisseurs à ajouter
              if(mapOppListFournisseurToAdd.get(opportunity) != null){
                mapOppListFournisseurToAdd.get(opportunity).add(fournisseur);
              } else{
                mapOppListFournisseurToAdd.put(opportunity,new List<String>{fournisseur});
              }
            }
          }
        }
  
        if(!listQuoteOppIdFournisseurToDelete.isEmpty()){
          SM001_GestionDevis.deleteLigneDevisFournisseur(listQuoteOppIdFournisseurToDelete);
        }
  
        if(!mapOppListFournisseurToAdd.isEmpty()){
          SM001_GestionDevis.addLigneDevisFournisseur(mapOppListFournisseurToAdd);
        }
      }
  
      // Si ajout Situation Actuelle / Proposition Renouvellement
      if(!listOppIdSAToAdd.isEmpty() || !listOppIdPRToAdd.isEmpty()){
        SM001_GestionDevis.addLigneDevisParticulier(listOppIdSAToAdd,listOppIdPRToAdd);
      }
  
      // SI Suppression Situation Actuelle / Proposition Renouvellement
      if(!listOppIdSAToDelete.isEmpty() || !listOppIdPRToDelete.isEmpty()){
        SM001_GestionDevis.deleteLigneDevisParticulier(listOppIdSAToDelete, listOppIdPRToDelete);
      }
    }

    if(!listOppMasseRT.isEmpty()){
      List<Opportunity> listOppMasseToUpdate = new List<Opportunity>();
      List<Opportunity> listOppDeleteAllDevis = new List<Opportunity>();
      for(Opportunity opp : listOppMasseRT){
        //Si on a ni fournisseur ni sections particulières
        if (opp.Liste_Fournisseurs__c != ((Opportunity)Trigger.oldMap.get(opp.Id)).Liste_Fournisseurs__c
            && opp.Liste_Fournisseurs__c == null
            && !opp.SectionSituationActuelle__c
            && !opp.SectionPropositionRenouvellement__c){
              listOppDeleteAllDevis.add(opp);
          //Vérifier aussi les section 
        }
        if(opp.Liste_Fournisseurs__c != ((Opportunity)Trigger.oldMap.get(opp.Id)).Liste_Fournisseurs__c
            || !opp.SectionSituationActuelle__c != !((Opportunity)Trigger.oldMap.get(opp.Id)).SectionSituationActuelle__c
            || !opp.SectionPropositionRenouvellement__c != !((Opportunity)Trigger.oldMap.get(opp.Id)).SectionPropositionRenouvellement__c ){
          listOppMasseToUpdate.add(opp);
        }
      }
      if(!listOppMasseToUpdate.isEmpty()){
        //Si la nouvelle map est null alors faire que de la suppression
        SM002_GestionDevisMasse.generateDevis(listOppMasseToUpdate);
      }

      if(!listOppDeleteAllDevis.isEmpty()){
       SM002_GestionDevisMasse.deleteAllDevis(listOppDeleteAllDevis);
      }
    }
  }
}