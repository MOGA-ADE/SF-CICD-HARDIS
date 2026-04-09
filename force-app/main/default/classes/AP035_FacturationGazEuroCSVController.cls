public with sharing class AP035_FacturationGazEuroCSVController {
    public class CsvResult {
        @AuraEnabled
        public String csv;
        @AuraEnabled
        public Boolean hasData;

        public CsvResult(String csv, Boolean hasData) {
            this.csv = csv;
            this.hasData = hasData;
        }
    }

    @AuraEnabled(cacheable=false)
    public static CsvResult generateCSV(
        Integer monthNumber,
        Integer yearNumber
    ) {
        List<Appel_facturation__c> lstAAF;

        if (monthNumber == 0) {
            lstAAF = [
                SELECT
                    Id,
                    Name,
                    Montant__c,
                    Contrat__c,
                    Contrat__r.Name,
                    Contrat__r.Account.Name,
                    Contrat__r.Entite_facturation__c,
                    Contrat__r.StartDate,
                    Contrat__r.ContractTerm,
                    Contrat__r.CAR__c,
                    Contrat__r.Marge_Mwh_T1__c,
                    Contrat__r.Marge_Mwh_T2__c,
                    Contrat__r.Marge_Mwh_T3__c,
                    Contrat__r.Marge_Mwh_T4__c,
                    Contrat__r.Commission_ADE__c,
                    Contrat__r.FournisseurPicklist__c
                FROM Appel_facturation__c
                WHERE
                    CALENDAR_YEAR(Mois_facturation_concerne__c) = :yearNumber
                    AND Contrat__r.FournisseurPicklist__c = 'Gaz Européen'
            ];
        } else {
            lstAAF = [
                SELECT
                    Id,
                    Name,
                    Montant__c,
                    Contrat__c,
                    Contrat__r.Name,
                    Contrat__r.Account.Name,
                    Contrat__r.Entite_facturation__c,
                    Contrat__r.StartDate,
                    Contrat__r.ContractTerm,
                    Contrat__r.CAR__c,
                    Contrat__r.Marge_Mwh_T1__c,
                    Contrat__r.Marge_Mwh_T2__c,
                    Contrat__r.Marge_Mwh_T3__c,
                    Contrat__r.Marge_Mwh_T4__c,
                    Contrat__r.Commission_ADE__c,
                    Contrat__r.FournisseurPicklist__c
                FROM Appel_facturation__c
                WHERE
                    CALENDAR_MONTH(Mois_facturation_concerne__c) = :monthNumber
                    AND CALENDAR_YEAR(
                        Mois_facturation_concerne__c
                    ) = :yearNumber
                    AND Contrat__r.FournisseurPicklist__c = 'Gaz Européen'
            ];
        }

        if (lstAAF.isEmpty()) {
            return new CsvResult(buildHeader(), false);
        }

        Set<Id> setContractIds = new Set<Id>();
        for (Appel_facturation__c aaf : lstAAF) {
            if (aaf.Contrat__c != null) setContractIds.add(aaf.Contrat__c);
        }

        Map<Id, Prix_contrat_PDE__c> pdeByContract = new Map<Id, Prix_contrat_PDE__c>();
        if (!setContractIds.isEmpty()) {
            for (Prix_contrat_PDE__c p : [
                SELECT
                    Id,
                    Contract__c,
                    Numero_compteur__c,
                    Point_energie__r.Adresse_de_consommation__c
                FROM Prix_contrat_PDE__c
                WHERE Contract__c IN :setContractIds
            ]) {
                if (!pdeByContract.containsKey(p.Contract__c)) {
                    pdeByContract.put(p.Contract__c, p);
                }
            }
        }

        String csv = buildHeader();

        for (Appel_facturation__c aaf : lstAAF) {
            Prix_contrat_PDE__c pde = pdeByContract.get(aaf.Contrat__c);

            if (pde == null) {
                continue;
            }

            csv +=
                safe(aaf.Contrat__r.Entite_facturation__c) + ';' +                          // Entité de facturation
                safe(aaf.Contrat__r.Account.Name) + ';' +                                   // Nom du représentant
                safe(pde.Numero_compteur__c) + ';' +                                        // PDE
                safe(pde.Point_energie__r.Adresse_de_consommation__c) + ';' +               // Adresse du site
                safe(aaf.Contrat__r.CAR__c) + ';' +                                         // Volume prévisionnel
                safe(formatDate(aaf.Contrat__r.StartDate)) + ';' +                          // Début contrat
                safe(aaf.Contrat__r.ContractTerm) + ';' +                                   // Durée
                ((aaf.Contrat__r.Marge_Mwh_T1__c == null) ? '' :
                    String.valueOf(aaf.Contrat__r.Marge_Mwh_T1__c / 2)) + ';' +             // Marge T1                                                                                                                           
                ((aaf.Contrat__r.Marge_Mwh_T2__c == null) ? '' :
                    String.valueOf(aaf.Contrat__r.Marge_Mwh_T2__c / 2)) + ';' +             // Marge T2
                ((aaf.Contrat__r.Marge_Mwh_T3__c == null) ? '' :
                    String.valueOf(aaf.Contrat__r.Marge_Mwh_T3__c / 2)) + ';' +             // Marge T3
                ((aaf.Contrat__r.Marge_Mwh_T4__c == null) ? '' :
                    String.valueOf(aaf.Contrat__r.Marge_Mwh_T4__c / 2)) + ';' +             // Marge T4
                safe(aaf.Montant__c) + ';' +                                                // Montant
                safe(aaf.Contrat__r.Commission_ADE__c) + ';' +                              // Commission ADE
                safe(aaf.Contrat__r.Name) +                                                 // Numéro contrat
                '\n';
        }

        return new CsvResult(csv, true);
    }

    private static String buildHeader() {
        return 'Entité de facturation;Nom du représentant;PDE;Adresse du site;Volume (prévisionnel);' +
               'Date de démarrage du contrat;Durée du contrat;Marge T1;Marge T2;Marge T3;Marge T4;' +
               'Montant;Commission ADE;Numéro de contrat\n';
    }

    private static String safe(Object v) {
        return v == null ? '' : String.valueOf(v);
    }

    private static String formatDate(Date d) {
        return d == null ? '' : d.format(); 
    }
}