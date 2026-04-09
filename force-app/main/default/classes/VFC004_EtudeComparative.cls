public without sharing class VFC004_EtudeComparative {
  public static Opportunity opportunity { get; set; }
  public static OpportunityContactRole signataire { get; set; }
  public static WrapOpport opportunite { get; set; }
  public static List<WrapPde> listPDE { get; set; }
  public static List<WrapFournisseur> listFournisseur { get; set; }
  public static List<String> listFournisseurName { get; set; }
  public static Set<String> setFournisseurWithPageInfo { get; set; }
  public static Set<String> setPartenaireWithPageInfo { get; set; }
  public static Boolean isMonosite { get; set; }
  public static Boolean showVisuelPartenaire {get ; set;}
  public static String visuelPartenaireFileName {get; set;}
  public Map<String,WrapFournisseur> mapFourisseurWrapFournisseur = new Map<String,WrapFournisseur>();

  public VFC004_EtudeComparative(ApexPages.StandardController stdController) {
    setFournisseurWithPageInfo = new Set<String>{'Alterna.png','Dyneff.png','Ekwateur.png','Endesa.png','Engie.png','ENI.png','Enovos.png','Gaz_Europeen.png','Gazel_Energie.png','MET_Energie.png','Picoty.png','Primeo_Energie.png','SEFE_Energy.png','TotalEnergies.png','Vattenfall.png','OHM_Energie.png'};
    setPartenaireWithPageInfo = new Set<String>{'Le_Froid_Pecomark.png'};
    listPDE = new List<WrapPde>();
    opportunity = (Opportunity) stdController.getRecord();
    
    // Récupérer le signataire et les infos de l'opp
    signataire = [SELECT  Contact.Phone,
                          Contact.Email,
                          Contact.FirstName,
                          Contact.LastName,
                          Opportunity.Account.Activite__c,
                          Opportunity.Account.Name,
                          Opportunity.Account.Parent.Name,
                          Opportunity.Account.Siren__c,
                          Opportunity.Commentaire_Comparatif__c,
                          Opportunity.Liste_Fournisseurs__c,
                          Opportunity.ResponsableCotation__r.LastName,
                          Opportunity.ResponsableCotation__r.FirstName,
                          Opportunity.ResponsableCotation__r.Phone,
                          Opportunity.ResponsableCotation__r.Email,
                          Opportunity.Section_contribution__c,
                          Opportunity.Section_Acheminement__c,
                          Opportunity.Section_TTC__c,
                          Opportunity.TemplateCotation__c,
                          Opportunity.visuel_partenaire__c
                  FROM OpportunityContactRole
                  WHERE OpportunityId = :opportunity.Id AND Role = 'Signataire'
                  LIMIT 1];
    opportunite = new WrapOpport(signataire);

    // Récupérer les PDEs depuis les OPRs
    for(OpportunityPDERelation__c opr : [ SELECT Id,
                                          PDE__r.Adresse_de_consommation__c,
                                          PDE__r.CARGaz__c,
                                          PDE__r.Code_Postal__c,
                                          PDE__r.Conso_Base__c,
                                          PDE__r.Conso_HCE__c,
                                          PDE__r.Conso_HCH__c,
                                          PDE__r.Conso_HPE__c,
                                          PDE__r.Conso_HPH__c,
                                          PDE__r.Conso_Pointe__c,
                                          PDE__r.ConsoHC__c,
                                          PDE__r.ConsoHP__c,
                                          PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c,
                                          PDE__r.DateEcheance__c,
                                          PDE__r.fournisseur__c,
                                          PDE__r.FTA__c,
                                          PDE__r.NumeroVoie__c,
                                          PDE__r.PCE_Refonte__c,
                                          PDE__r.Premiere_mise_en_service__c,
                                          PDE__r.Profil__c,
                                          PDE__r.Puissance_souscrite__c,
                                          PDE__r.ReferencePointEnergie_Refonte__c,
                                          PDE__r.Segment__c,
                                          PDE__r.Siret_payeur__c,
                                          PDE__r.SiteConsommation__c,
                                          PDE__r.Tarif__c,
                                          PDE__r.Ville__c,
                                          PDE__r.Voie__c
                                          FROM OpportunityPDERelation__c
                                          WHERE Opportunity__c = :opportunity.Id]){
                                listPDE.add(new WrapPde(opr));
    }

    listPDE.sort();
    isMonosite = listPDE.size() == 1;

    // Fusionner les quotes qui on le même fournisseur
    for (Quote quote : [SELECT  Fournisseur__c,
                                LineItemCount,
                                TotalBudgetTTC__c,
                                TECH_FournisseurLogo__c,
                                TypeOffre__c,
                                ( SELECT  AbonnementMois__c,  
                                          Budget_TTC__c,
                                          BudgetFourniture__c,
                                          BudgetHTTan__c,
                                          CAR_New__c,
                                          CeeMwh__c,  
                                          CoutDeCapacite__c,
                                          CSPE__c,
                                          CTA__c,
                                          CTA_Mensuel_ELEC__c,
                                          DebutDeFourniture__c,
                                          FraisTransportDistributionCapacite__c,  
                                          Nouvelle_Echeance__c,
                                          PDE__r.FTA__c,
                                          PDE__r.Code_Postal__c,   
                                          PDE__r.NumeroVoie__c,   
                                          PDE__r.SiteConsommation__c,
                                          PDE__r.Ville__c,   
                                          PDE__r.voie__c,   
                                          PDE__r.DateEcheance__c, 
                                          PDE__r.ReferencePointEnergie_Refonte__c,
                                          PDE__r.Premiere_mise_en_service__c,
                                          PDE__r.PCE_Refonte__c,
                                          PDE__r.Conso_Base__c,
                                          PDE__r.ConsoHP__c,
                                          PointesMWh__c,
                                          PrixBase__c,
                                          PrixHC__c,
                                          PrixHceMwh__c,
                                          PrixHchMwh__c,
                                          PrixHP__c,
                                          PrixHpeMwh__c,
                                          PrixHphMwh__c,
                                          PrixMolecule__c,  
                                          T_QuoteCEE__c,  
                                          Taxes__c,
                                          TECH_TCFE__c,
                                          TECH_Budget__c,
                                          TICGN__c,
                                          TURPE_Fixe__c,
                                          TURPE_Variable__c,
                                          TVA__c,
                                          Quote.TECH_FournisseurLogo__c,
                                          Quote.TypeOffre__c
                                  FROM QuoteLineItems)
                        FROM Quote 
                        WHERE OpportunityId = :opportunity.Id]) {

      if(mapFourisseurWrapFournisseur.containsKey(quote.Fournisseur__c)) {
        List<WrapLigneDeDevis> qlis = new List<WrapLigneDeDevis>();
        // For loop mandatory if quotelinesitems.size > 200 else it'll crashes
        for (QuoteLineItem qli : quote.QuoteLineItems) {
          WrapLigneDeDevis wrapQLI = new WrapLigneDeDevis(qli);
          qlis.add(wrapQLI);
        }

        WrapFournisseur wrapFrounisseur = new WrapFournisseur(quote, qlis);
        WrapFournisseur wrapFournisseurToMerge = mapFourisseurWrapFournisseur.get(quote.Fournisseur__c);
        List<WrapLigneDeDevis> listQLI = wrapFournisseurToMerge.listQLI;

        wrapFournisseurToMerge.TotalBudgetTTC += quote.TotalBudgetTTC__c;
        wrapFournisseurToMerge.numberOfQLI += quote.LineItemCount;
        listQLI.addAll(wrapFrounisseur.listQLI);

        wrapFournisseurToMerge.listQLI = listQLI;
        mapFourisseurWrapFournisseur.put(quote.Fournisseur__c, wrapFournisseurToMerge);

      } else {

        List<WrapLigneDeDevis> qlis = new List<WrapLigneDeDevis>();
        // For loop mandatory if quotelinesitems.size > 200 else it'll crashes
        for (QuoteLineItem qli : quote.QuoteLineItems) {
          WrapLigneDeDevis wrapQLI = new WrapLigneDeDevis(qli);
          qlis.add(wrapQLI);
        }

        WrapFournisseur wrapFrounisseur = new WrapFournisseur(quote, qlis);
        mapFourisseurWrapFournisseur.put(quote.Fournisseur__c, wrapFrounisseur);
      }
    }

    listFournisseur = mapFourisseurWrapFournisseur.values();
    listFournisseur.sort();
    for(WrapFournisseur fournisseur: listFournisseur){
      fournisseur.listQLI  = sortQLIs(fournisseur.listQLI); 
    }

    listFournisseurName = new List<String>();
    for(String name : signataire.Opportunity.Liste_Fournisseurs__c.replace(' ','_').replace('é','e').replace('è','e').split(';')){
      name = name+'.png';
      if(setFournisseurWithPageInfo.contains(name)){
        listFournisseurName.add(name);
      }
    }

    if(signataire.Opportunity.Account.Parent.Name != null ) {
      visuelPartenaireFileName = signataire.Opportunity.Account.Parent.Name.replace(' ','_').replace('é','e').replace('è','e') + '.png';
      showVisuelPartenaire = signataire.Opportunity.visuel_partenaire__c && setPartenaireWithPageInfo.contains(visuelPartenaireFileName);
    }
    
    String filename =
      'Etude_Comparative ' +
      String.valueOf(Date.today().format().replace('/','-')) +
      ' ' +
      signataire.Opportunity.Account.Name;
    Apexpages.currentPage()
      .getHeaders()
      .put('content-disposition', 'inline; filename=' + filename + '.pdf');
  }

  private List<WrapLigneDeDevis> sortQLIs(List<WrapLigneDeDevis> listWrapLigneDeDevis) {
        listWrapLigneDeDevis.sort();
        // listWrapLigneDeDevis = multiSort(listWrapLigneDeDevis);
    return listWrapLigneDeDevis;
  }

  //Refer to https://salesforcekings.blogspot.com/2015/08/how-to-sort-more-than-one-fieldcolumn.html
  // private List<WrapLigneDeDevis> multiSort(List<WrapLigneDeDevis> listWrapLigneDeDevis){
  //   List<WrapLigneDeDevis> templistWrapLigneDeDevis = new List<WrapLigneDeDevis>();
  //   Map<String,List<WrapLigneDeDevis>> phMap = new Map<String,List<WrapLigneDeDevis>>();

  //   for(WrapLigneDeDevis currPurchase: listWrapLigneDeDevis){
  //     if(phMap.containsKey(currPurchase.SITE_DE_CONSOMMATION)) {
  //         phMap.get(currPurchase.SITE_DE_CONSOMMATION).add(currPurchase);
  //     } else {
  //       phMap.put(currPurchase.SITE_DE_CONSOMMATION,new List<WrapLigneDeDevis>{currPurchase});
  //     }
  //   }

  //   for(String key : phMap.keySet()) {
  //       List<WrapLigneDeDevis> phTemp = phMap.get(key);

  //       WrapLigneDeDevis.SORT_FIELD = WrapLigneDeDevis.SortField.DateFinEnum;
  //       phTemp.sort();
  //       templistWrapLigneDeDevis.addAll(phTemp);  
  //   }

  //   return templistWrapLigneDeDevis;
  // }
}