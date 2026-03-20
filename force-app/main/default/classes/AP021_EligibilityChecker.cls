global with sharing class AP021_EligibilityChecker { 
    
    global class FlowInput {
        @invocableVariable public Id recordId;
    }

    global class FlowOutput {
        @InvocableVariable(label='Liste de résultats')
        public List<WrapFournisseursEligibleGrille> fournisseurs;

    }

    @InvocableMethod(callout=true label='Eligibilite fournisseurs')
    global static List<FlowOutput> checkEligibility(List<FlowInput> inputs) {
        
        List<WrapFournisseursEligibleGrille> results  = new List<WrapFournisseursEligibleGrille>();
        FlowOutput output = new FlowOutput();
        System.debug('Début de la méthode checkEligibility');
        Set<Id> recordIds = new Set<Id>();
        // Je recupere que l'id de l'opportunity
        for (FlowInput inpt : inputs) {
            if (inpt.recordId != null) {
                recordIds.add(inpt.recordId);
            }
        }
        List<OpportunityPDERelation__c> pdeRelations = [

        SELECT PDE__c, 
            PDE__r.EntiteJuridique__r.TECH_last_credit_score__c,
            PDE__r.X12_mois_consommation_SGE__c,
            PDE__r.Segment__c, 
            PDE__r.Tarif__c,
            PDE__r.Entite_facturation__c,
            PDE__r.EntiteJuridique__r.ELLISPHERE__Elli_code_ape08__c, 
            PDE__r.Fournisseur__c, 
            PDE__r.DateEcheance__c,
            PDE__r.Calendrier_fournisseur__c,
            PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c,
            PDE__r.CARGaz__c, 
            PDE__r.RecordType.Name
        FROM OpportunityPDERelation__c 
        WHERE Opportunity__c IN :recordIds
        ];

        System.debug('Nombre de PDE récupérées : ' + pdeRelations.size());

         Map<Id, OpportunityPDERelation__c> pdeMapById = new Map<Id, OpportunityPDERelation__c>();

        for (OpportunityPDERelation__c pde : pdeRelations) {
            // Clé = Id du PDE
            pdeMapById.put(pde.PDE__c, pde);
        }

        if (checkEligibiliteTotal(pdeMapById)) results.add(new WrapFournisseursEligibleGrille('TotalEnergies'));
        if (checkEligibiliteEkwateur(pdeMapById)) results.add(new WrapFournisseursEligibleGrille('Ekwateur'));
        if (checkEligibiliteVattenfall(pdeMapById)) results.add(new WrapFournisseursEligibleGrille('Vattenfall'));
        if (checkEligibiliteIlek(pdeMapById)) results.add(new WrapFournisseursEligibleGrille('Ilek'));
        if (checkEligibiliteGEG(pdeMapById)) results.add(new WrapFournisseursEligibleGrille('GEG'));
        if (checkEligibiliteEngiePro(pdeMapById)) results.add(new WrapFournisseursEligibleGrille('Engie'));
       
        output.fournisseurs = results;
        return new List<FlowOutput>{output};
    }

    // Méthodes d'éligibilité Forunisseur Total 
 public static Boolean checkEligibiliteTotal(Map<Id, OpportunityPDERelation__c> pdeMap) { 
    List<String> segmentsNonEligibles = new List<String>{'C2', 'C3', 'T3', 'T4'};
    
    for(Id pdeId : pdeMap.keySet()) {
        OpportunityPDERelation__c pde = pdeMap.get(pdeId);
        
        // Vérifie les conditions pour CETTE PDE
        Boolean isEligible = pde.PDE__r.EntiteJuridique__r.TECH_last_credit_score__c >= 3 && 
                            pde.PDE__r.Fournisseur__c != 'TotalEnergies' && 
                            !segmentsNonEligibles.contains(pde.PDE__r.Segment__c) && 
                            pde.PDE__r.DateEcheance__c <= Date.today().addMonths(12);
        
        // Si UNE SEULE PDE n'est pas éligible
        if(!isEligible) {
            System.debug('PDE ' + pdeId + ' non éligible pour Total → fournisseur non éligible');
            return false; 
        }
    }
        return true;
}

 public static Boolean checkEligibiliteEkwateur( Map<Id, OpportunityPDERelation__c> pdeMap) { 
    String labelCode = '';
    Boolean isEligible = false;
    Map<String, Grille_Ekwateur__mdt>  grilleEkwateur = Grille_Ekwateur__mdt.getAll();
    Grille_Ekwateur__mdt prixGrille = null; 

    List<String> segmentsEligibles = new List<String>{'C4', 'C5', 'T1', 'T2'};
    
    for(Id pdeId : pdeMap.keySet()) {

        OpportunityPDERelation__c pde = pdeMap.get(pdeId);

        // recuperation de la grille correspondante au segment
        for(String devName : grilleEkwateur.keySet()) {
            if (pde.PDE__r.Segment__c == 'C5' && devName.contains('C5')) {
                prixGrille = grilleEkwateur.get(devName);
                break;
            } else if (pde.PDE__r.Segment__c == 'C4' && devName.contains('C4')) {
                prixGrille = grilleEkwateur.get(devName);
                break;
            } else if (pde.PDE__r.RecordType.Name.contains('Gaz') && devName.contains('T1T2T3')) {  
                prixGrille = grilleEkwateur.get(devName);
                break;
            }
            }
            if (prixGrille == null) {
                //eligibilityMap.put(pdeId, false);
                continue; // Passe à la prochaine itération si aucune grille n'est trouvée
            }

        if((pde.PDE__r.DateEcheance__c.addDays(1) > prixGrille.Date_debut_min1__c && pde.PDE__r.DateEcheance__c.addDays(1) < prixGrille.Date_debut_max1__c) ||
        (pde.PDE__r.DateEcheance__c.addDays(1) > prixGrille.Date_debut_min2__c && pde.PDE__r.DateEcheance__c.addDays(1) < prixGrille.Date_debut_max2__c) ||
        (pde.PDE__r.DateEcheance__c.addDays(1) > prixGrille.Date_debut_min3__c && pde.PDE__r.DateEcheance__c.addDays(1) < prixGrille.Date_debut_max3__c)){
            
            isEligible = pde.PDE__r.EntiteJuridique__r.TECH_last_credit_score__c >= 5 && 
                                segmentsEligibles.contains(pde.PDE__r.Segment__c);
            
        }
        if (!isEligible) {
            System.debug('PDE ' + pdeId + ' non éligible pour Ekwateur → date d\'échéance non éligible');
            return false;
        }
            


    }
        return true;
 }

 public static Boolean checkEligibiliteVattenfall( Map<Id, OpportunityPDERelation__c> pdeMap) { 
    
    for(Id pdeId : pdeMap.keySet()) {
        OpportunityPDERelation__c pde = pdeMap.get(pdeId);
        
        // Conditions Vattenfall
        Boolean isEligible = pde.PDE__r.EntiteJuridique__r.TECH_last_credit_score__c >= 3 && 
                            pde.PDE__r.Segment__c == 'C5' &&
                            (
                                // Si fournisseur = Vattenfall
                                (pde.PDE__r.Fournisseur__c == 'Vattenfall' && 
                                pde.PDE__r.DateEcheance__c > Date.today().addMonths(4)&& pde.PDE__r.DateEcheance__c <= Date.today().addMonths(12)) ||
                                // Si fournisseur ≠ Vattenfall  
                                (pde.PDE__r.Fournisseur__c != 'Vattenfall' && 
                                pde.PDE__r.DateEcheance__c <= Date.today().addMonths(12))
                            );
        
        if(!isEligible) {
            System.debug('PDE ' + pdeId + ' non éligible pour Vattenfall → fournisseur non éligible');
            return false;       
        }
    
    }
    return true;
 }

public static Boolean checkEligibiliteIlek(Map<Id, OpportunityPDERelation__c> pdeMap) { 
    
    for(Id pdeId : pdeMap.keySet()) {
        OpportunityPDERelation__c pde = pdeMap.get(pdeId);
        
        // Conditions Ilek
        Boolean isEligible = pde.PDE__r.EntiteJuridique__r.TECH_last_credit_score__c >= 4 && 
                            pde.PDE__r.Segment__c == 'C5' &&  // C5 uniquement
                            pde.PDE__r.DateEcheance__c.addDays(1) <= Date.today().addMonths(6);
        
        if(!isEligible) {
            System.debug('PDE ' + pdeId + ' non éligible pour Ilek → fournisseur non éligible');
            return false;
    }
    }
    
    return true;
}

public static Boolean checkEligibiliteGEG(Map<Id, OpportunityPDERelation__c> pdeMap) { 

    
    for(Id pdeId : pdeMap.keySet()) {
        OpportunityPDERelation__c pde = pdeMap.get(pdeId);
        
        
        // Conditions GEG
        Boolean isEligible = pde.PDE__r.EntiteJuridique__r.TECH_last_credit_score__c >= 6 && 
                            (pde.PDE__r.Segment__c == 'C5' || pde.PDE__r.Segment__c == 'C4' || pde.PDE__r.Segment__c == 'C2') &&  // C5 ou C4 ou C2 uniquement
                            (pde.PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c > 30 ) && pde.PDE__r.X12_mois_consommation_SGE__c == true;
       
        if(!isEligible) {
            System.debug('PDE ' + pdeId + ' non éligible pour GEG → fournisseur non éligible');
            return false;
        }
    }
    
    return true;
}

public static Boolean checkEligibiliteEngiePro(Map<Id, OpportunityPDERelation__c> pdeMap) { 
    List<String> segmentsEligibles = new List<String>{'C4', 'C5', 'T1', 'T2'};

    Codes_NAF__mdt codeNaf = [SELECT Id, Code_NAF__c FROM Codes_NAF__mdt WHERE DeveloperName = 'EngiePro' LIMIT 1];


    
    for(Id pdeId : pdeMap.keySet()) {
        OpportunityPDERelation__c pde = pdeMap.get(pdeId);
        // Conditions Engie Pro
    

        if (codeNaf == null) {
            System.debug('Code NAF éligible pour Engie Pro : ');  
        return false;
        }
        System.debug('Code NAF éligible pour Engie Pro : ' + codeNaf.Code_NAF__c);
        System.debug('Code NAF de la PDE : ' + pde.PDE__r.EntiteJuridique__r.ELLISPHERE__Elli_code_ape08__c);
        System.debug('Segment de la PDE : ' + pde.PDE__r.Segment__c);
        System.debug('Tarif de la PDE : ' + pde.PDE__r.Tarif__c);
        if (codeNaf.Code_NAF__c.contains(pde.PDE__r.EntiteJuridique__r.ELLISPHERE__Elli_code_ape08__c)) {
            // Code NAF  éligible
            Boolean isEligible = (segmentsEligibles.contains(pde.PDE__r.Segment__c) || segmentsEligibles.contains(pde.PDE__r.Tarif__c)) && pde.PDE__r.Entite_facturation__c != 'ENGIE PRO' &&
                                (pde.PDE__r.DateEcheance__c >= Date.today().addDays(5) && pde.PDE__r.DateEcheance__c <= Date.today().addMonths(12));
            if (!isEligible) {
                System.debug('PDE ' + pdeId + ' non éligible pour Engie Pro → fournisseur non éligible');
                return false;  
            }
  
                                
        }else {
            System.debug('PDE ' + pdeId + ' non éligible pour Engie Pro → code NAF non éligible');
            return false;
        }
    }
    return true;
}

}