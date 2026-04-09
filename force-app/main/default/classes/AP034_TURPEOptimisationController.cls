public without sharing class AP034_TURPEOptimisationController {

    /**
     * Récupère les informations TURPE depuis les PDE du compte
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getInfosTurpeByAccount(Id accountId) {
        System.debug('Récupération des infos TURPE pour le compte : ' + accountId);
        Map<String, Object> result = new Map<String, Object>();
        List<PDE__c> lstPDE = new List<PDE__c>();

        // Récupération des PDE liés à l'entité juridique (compte)
        try {
            lstPDE = [
                SELECT Id,
                    Name,
                    BudgetTotalActuel__c, BudgetTotalOptimal__c, EconomieIdentifie__c,
                    HCEActuel__c, HPEActuel__c, HCHActuel__c, HPHActuel__c, POINTEActuel__c,
                    HCEOptimal__c, HPEOptimal__c, HCHOptimal__c, HPHOptimal__c, POINTEOptimal__c,
                    PartFixeCSActuel__c, PartVariableCSActuel__c, DepassementActuel__c, TaxeCTAActuel__c,
                    PartFixeCSOptimal__c, PartVariableCSOptimal__c, DepassementOptimal__c, TaxeCTAOptimal__c, InterventionPEPS__c,
                    Conso_HCE__c, Conso_HPE__c, Conso_HCH__c, Conso_HPH__c, Conso_Pointe__c,TECH_num_compteur__c
                FROM PDE__c
                WHERE EntiteJuridique__c = :accountId
                AND EconomieIdentifie__c > 0
                WITH SECURITY_ENFORCED
                ORDER BY Name
            ];
        } catch (System.QueryException e) {
            lstPDE = [
                SELECT Id,
                    Name,
                    BudgetTotalActuel__c, BudgetTotalOptimal__c, EconomieIdentifie__c,
                    HCEActuel__c, HPEActuel__c, HCHActuel__c, HPHActuel__c, POINTEActuel__c,
                    HCEOptimal__c, HPEOptimal__c, HCHOptimal__c, HPHOptimal__c, POINTEOptimal__c,
                    PartFixeCSActuel__c, PartVariableCSActuel__c, DepassementActuel__c, TaxeCTAActuel__c,
                    PartFixeCSOptimal__c, PartVariableCSOptimal__c, DepassementOptimal__c, TaxeCTAOptimal__c, InterventionPEPS__c,
                    Conso_HCE__c, Conso_HPE__c, Conso_HCH__c, Conso_HPH__c, Conso_Pointe__c,TECH_num_compteur__c
                FROM PDE__c
                WHERE EntiteJuridique__c = :accountId
                AND EconomieIdentifie__c > 0
                ORDER BY Name
            ];
            for (PDE__c p : lstPDE) {
                p.HCEOptimal__c = 00;
                p.HPEOptimal__c = 00;
                p.HCHOptimal__c = 00;
                p.HPHOptimal__c = 00;
                p.POINTEOptimal__c = 00;
            }
            result.put('blurPuissanceOptimal', true);
        }


        // Si aucun PDE trouvé 
        if (lstPDE.isEmpty()) {
            result.put('lstPDE', new List<PDE__c>());
            result.put('isMonoSite', true);
            result.put('totalBudgetActuel', 0);
            result.put('totalBudgetOptimal', 0);
            result.put('totalEconomie', 0);
            result.put('noteDateText', null);
            result.put('noteConsoText', null);
            return result;
        }

        // Sommes globales 
        Decimal totalBudgetActuel  = 0;
        Decimal totalBudgetOptimal = 0;
        Decimal totalEconomie      = 0;

        for (PDE__c p : lstPDE) {
            totalBudgetActuel  += (p.BudgetTotalActuel__c  != null ? p.BudgetTotalActuel__c  : 0);
            totalBudgetOptimal += (p.BudgetTotalOptimal__c != null ? p.BudgetTotalOptimal__c : 0);
            totalEconomie      += (p.EconomieIdentifie__c  != null ? p.EconomieIdentifie__c  : 0);
        }

        Boolean isMonoSite = (lstPDE.size() == 1);
        Date endDate   = Date.today().addDays(-1);
        Date startDate = endDate.addYears(-1);
        String startStr = DateTime.newInstance(startDate, Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');
        String endStr   = DateTime.newInstance(endDate, Time.newInstance(0, 0, 0, 0)).format('dd/MM/yyyy');

        String noteDateText = 'Note : l\'optimisation se base sur les consommations du ' + startStr +
            ' au ' + endStr + ' et suppose qu\'elles seront similaires à l\'avenir.';

        // Texte de consommation (uniquement pour monosite)
        String noteConsoText = null;
        if (isMonoSite) {
            PDE__c pde = lstPDE[0];
            noteConsoText =
                'HCE : ' + (pde.Conso_HCE__c != null ? String.valueOf(pde.Conso_HCE__c) : '—') + ' kWh — ' +
                'HPE : ' + (pde.Conso_HPE__c != null ? String.valueOf(pde.Conso_HPE__c) : '—') + ' kWh — ' +
                'HCH : ' + (pde.Conso_HCH__c != null ? String.valueOf(pde.Conso_HCH__c) : '—') + ' kWh — ' +
                'HPH : ' + (pde.Conso_HPH__c != null ? String.valueOf(pde.Conso_HPH__c) : '—') + ' kWh — ' +
                'Pointe : ' + (pde.Conso_Pointe__c != null ? String.valueOf(pde.Conso_Pointe__c) : '—') + ' kWh';
        }

        // Ajout au résultat renvoyé au LWC
        result.put('lstPDE', lstPDE);
        result.put('isMonoSite', isMonoSite);
        result.put('totalBudgetActuel', totalBudgetActuel);
        result.put('totalBudgetOptimal', totalBudgetOptimal);
        result.put('totalEconomie', totalEconomie);
        result.put('noteDateText', noteDateText);
        result.put('noteConsoText', noteConsoText);
        
        return result;
    }

    /**
    * Applique les regles TURPE : verifie l'eligibilite du PDE et declenche OPTIMISATION ou RENOUVELLEMENT
    */
    public static void invokeTURPEIfEligible(Id pdeId) {
        try {
            PDE__c pde = [
                SELECT
                    Id,
                    Name,
                    IdSource__c,
                    IdAnalyse__c,
                    IdBuilding__c,
                    RecordType.DeveloperName,
                    Taux_puissance_souscrite_utilisee__c,
                    Puissance_souscrite__c,
                    PSMaxActive__c,
                    DatePremierAppel__c,
                    TECH_OptimisationFieldsMissing__c,
                    AppelEnCours__c,
                    SignataireACD__c
                FROM PDE__c
                WHERE Id = :pdeId
            ];

            // Sortie immediate si record type non eligible ou taux hors plage
            if (
                pde.AppelEnCours__c ||
                pde.SignataireACD__c == null || 
                pde.RecordType.DeveloperName == 'PDE_Gaz' ||
                pde.RecordType.DeveloperName == 'PDE_ElecC5' ||
                (pde.Taux_puissance_souscrite_utilisee__c >= 80 &&
                pde.Taux_puissance_souscrite_utilisee__c <= 120)
            ) {
                return;
            }

            Boolean hasAnalyse = (pde.IdAnalyse__c != null);
            // Si hasAnalyse != null et que DatePremierAppel__c > 3 mois → OPTIMISATION
            if (hasAnalyse && datePremierAppelExceeds3Months(pde)) {
                AP034_TURPEOptimisationService.invokeTURPECallFromApex(
                    'PDE_OPTIMISATION_RENEW', 
                    (String) pde.Id,
                    (String) pde.IdSource__c,
                    (String) pde.IdAnalyse__c,
                    (String) pde.IdBuilding__c
                );
                return;
            }
            // Si hasAnalyse != null → verifier si champs optimisation manquants
            if (hasAnalyse && pde.TECH_OptimisationFieldsMissing__c) {
                AP034_TURPEOptimisationService.invokeTURPECallFromApex(
                    'PDE_RENOUVELLEMENT',
                    (String) pde.Id,
                    (String) pde.IdSource__c,
                    (String) pde.IdAnalyse__c,
                    (String) pde.IdBuilding__c
                );
            }
            // Cas par defaut
            AP034_TURPEOptimisationService.invokeTURPECallFromApex(
                'PDE_OPTIMISATION',
                (String) pde.Id,
                (String) pde.IdSource__c,
                (String) pde.IdAnalyse__c,
                (String) pde.IdBuilding__c
            );
        } catch (Exception e) {
            System.debug('Erreur lors du declenchement TURPE : ' + e.getMessage());
        }
    }

    /**
     * Indique si la date du premier appel TURPE dépasse 3 mois
     */
    private static Boolean datePremierAppelExceeds3Months(PDE__c pde) {
        if (pde.DatePremierAppel__c == null) return false;
        return pde.DatePremierAppel__c.addMonths(3) < Date.today();
    }
}