public without sharing class AP028_CheckNbDemandeCotationFromFlow {

    public static Integer getLimiteNbDossier(Date dateCible) {

        Integer retour = 200;
        List<Limite_DemandeCotation__mdt> limites = [
            SELECT Nb_dossier__c, Date_debut__c, Date_fin__c
            FROM Limite_DemandeCotation__mdt
            WHERE Date_debut__c <= :dateCible AND Date_fin__c >= :dateCible
            ];

        if (!limites.isEmpty()) {
            System.debug('limite trouvée ');
            System.debug('Integer.valueOf(limites[0].Nb_dossier__c)  '+Integer.valueOf(limites[0].Nb_dossier__c));

            return Integer.valueOf(limites[0].Nb_dossier__c);
        }

        Limite_Defaut_DDC__c config = Limite_Defaut_DDC__c.getInstance();

        if (config != null && config.max_dossier_defaut__c != null) {
            retour = Integer.valueOf(config.max_dossier_defaut__c);
        }

        return retour;
    }
    
    @invocableMethod(label='Vérification nombre de dossier vente indirecte')
    public static List<FlowOutput> checkNbDossier(List<FlowInputs> params) {
        System.debug('### LIGOT' + params);
        FlowInputs param = params[0];
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();

        Date targetDate = param.DateRDVClient.date();
        DateTime startOfDay = DateTime.newInstanceGMT(targetDate, Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay = startOfDay.addDays(1);

        Integer limiteNbDossier = getLimiteNbDossier(targetDate);
        Set<String> setPartenairesExclus = new Set<String>();
        
        for (Partenaires_hors_limite_DDC_par_jour__mdt partenaire : [SELECT Label
            FROM Partenaires_hors_limite_DDC_par_jour__mdt ]) {
            setPartenairesExclus.add(partenaire.Label);
        }
        setPartenairesExclus.add('ADE');

        if (param.UserCompany != 'ADE') {

            List<AggregateResult> demandes = [
                SELECT count(id) NombreDeDDCPourleJour
                FROM Demande_Cotation__c
                WHERE 
                    TECH_Date_RDV_Reactu__c >= :startOfDay
                AND TECH_Date_RDV_Reactu__c <= :endOfDay
                AND Societe_du_commercial__c NOT IN :setPartenairesExclus
                AND Statut__c <> 'Refusée'
            ];

            Integer nbDossiersLeJour = Integer.valueOf(demandes.get(0).get('NombreDeDDCPourleJour'));
            System.debug('### nbDossiersLeJour ' + nbDossiersLeJour);
            System.debug('### limiteDossiersLeJour ' + limiteNbDossier);
            
            if (nbDossiersLeJour >= limiteNbDossier) {
                output.DMLSuccess = false;
                output.ErrorMessage = 'Notre planning est complet, Veuillez choisir une autre date pour le rendez-vous client';
            } else {
                output.DMLSuccess = true;
            }

            outputs.add(output);
            return outputs;
        }

        return null;
    
    }



    public class FlowInputs {
        @invocableVariable public String UserCompany;
        @invocableVariable public DateTime DateRDVClient;

    }
    
    public class FlowOutput {
        @InvocableVariable
        public Boolean DMLSuccess;
        @InvocableVariable
        public String ErrorMessage;
    }

}