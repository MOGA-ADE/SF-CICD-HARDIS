public class GRDFFetchData {

    // ========================================
    // INVOCABLE METHOD
    // ========================================
    @InvocableMethod(label='GRDF - Récupérer Données PCE' description='Récupère les données contractuelles et techniques via API' category='GRDF')
    public static void fetchData(List<Request> requests) {
        
        Set<Id> pceIds = new Set<Id>();
        String processingMode = 'ASYNC'; // Valeur par défaut

        // 1. Collecte des IDs et détermination du mode
        for (Request req : requests) {
            if (req.pceRecords != null && !req.pceRecords.isEmpty()) {
                for (PDE__c pce : req.pceRecords) {
                    if (pce.Id != null) pceIds.add(pce.Id);
                }
            }

            if (req.type_action == 'MANUAL') {
                processingMode = 'MANUAL';
            }
        }

        if (pceIds.isEmpty()) return;

        // 2. Aiguillage selon le mode
        if (processingMode == 'MANUAL') {
            processPCEs(new List<Id>(pceIds));
        } else {
            System.enqueueJob(new GRDFFetchDataQueueable(new List<Id>(pceIds)));
        }
    }

    // ========================================
    // LOGIQUE MÉTIER CENTRALISÉE
    // ========================================
    public static void processPCEs(List<Id> pceIds) {
        List<PDE__c> pces = [SELECT Id, Name, TECH_num_compteur__c FROM PDE__c WHERE Id IN :pceIds];
        List<PDE__c> pcesToUpdate = new List<PDE__c>();

        for (PDE__c pce : pces) {

            try {
                // Get Contract and Technical data
                GRDFManager.DonneesContractuellesWrapper contractData = GRDFManager.getDonneesContractuelles(pce.TECH_num_compteur__c);
                sleep(1200); // Pause pour respecter les limites d'appel API
                GRDFManager.DonneesTechniquesWrapper techData = GRDFManager.getDonneesTechniques(pce.TECH_num_compteur__c);
                
                // Mapping
                mapContractData(pce, contractData);
                mapTechData(pce, techData);
                pcesToUpdate.add(pce);
            } catch (Exception e) {
                // Optionnel : Logger l'erreur ici pour ne pas bloquer le flow écran
                System.debug('Erreur lors du callout pour ' + pce.Name + ': ' + e.getMessage());
            }
        }

        if (!pcesToUpdate.isEmpty()) {
            Database.update(pcesToUpdate, false);
        }
    }

    // ========================================
    // MÉTHODE UTILITAIRE "SLEEP"
    // ========================================
    private static void sleep(Integer milliseconds) {
        Long startTime = System.currentTimeMillis();
        while (System.currentTimeMillis() < startTime + milliseconds) {
            // Boucle d'attente active : ne rien faire jusqu'à ce que le temps soit écoulé
        }
    }

    // ========================================
    // INNER CLASS - QUEUEABLE
    // ========================================
    public class GRDFFetchDataQueueable implements Queueable, Database.AllowsCallouts {
        
        private List<Id> itemsToProcess;
        private final Integer CHUNK_SIZE = 1; 

        public GRDFFetchDataQueueable(List<Id> ids) {
            this.itemsToProcess = ids;
        }

        public void execute(QueueableContext context) {
            List<Id> currentBatchIds = new List<Id>();
            List<Id> remainingIds = new List<Id>();

            // Découpage en lots
            for (Integer i = 0; i < this.itemsToProcess.size(); i++) {
                if (i < CHUNK_SIZE) {
                    currentBatchIds.add(this.itemsToProcess[i]);
                } else {
                    remainingIds.add(this.itemsToProcess[i]);
                }
            }

            // Traitement via la méthode partagée
            if (!currentBatchIds.isEmpty()) {
                GRDFFetchData.processPCEs(currentBatchIds);
            }

            // Chaining
            if (!remainingIds.isEmpty() && !Test.isRunningTest()) {
                System.enqueueJob(new GRDFFetchDataQueueable(remainingIds));
            }
        }
    }

    // ========================================
    // METHODES DE MAPPING (Helpers)
    // ========================================
    public static void mapContractData(PDE__c pce, GRDFManager.DonneesContractuellesWrapper wrapper) {

        if (wrapper.donnees_contractuelles == null) {
           pce.GRDF_Statut_Donnees_Contractuelles__c = 'Récupération Impossible';
           String fullError = wrapper.statut_restitution.code + ': ' + wrapper.statut_restitution.message;
           pce.GRDF_Erreur_donnees_contractuelles__c = fullError.left(255);
           return;
        }

        GRDFManager.DonneesContractuelles data = wrapper.donnees_contractuelles;

        pce.Date_MES__c = data.date_mes != null ? Date.valueOf(data.date_mes) : null;
        pce.Date_publication_tarif__c = data.date_publication != null ? Date.valueOf(data.date_publication) : null;
        pce.CARGaz__c = data.car.car_actuelle != null ? (Decimal.valueOf(data.car.car_actuelle) / 1000).setScale(2) : null;
        pce.CARGaz_Future__c = data.car.car_future != null ? (Decimal.valueOf(data.car.car_future) / 1000).setScale(2) : null;
        pce.Consommation_Journaliere_Plafond__c = data.consommation_journaliere_plafond != null ? (Decimal.valueOf(data.consommation_journaliere_plafond) / 1000).setScale(2) : null;
        pce.CJA__c = data.cja.cja != null ? (Decimal.valueOf(data.cja.cja) / 1000).setScale(2): null;
        pce.CJA_Journaliere__c = data.cja.cja_journaliere != null ? (Decimal.valueOf(data.cja.cja_journaliere) / 1000).setScale(2): null;
        pce.CJA_Menuselle__c = data.cja.cja_mensuelle != null ? (Decimal.valueOf(data.cja.cja_mensuelle) / 1000).setScale(2): null;
        pce.Profil__c = data.profil.profil_type_actuel;
        pce.Profil_Futur__c = data.profil.profil_type_futur;
        pce.GRDF_Statut_Donnees_Contractuelles__c = 'Données récupérées';
        pce.GRDF_Erreur_donnees_contractuelles__c = null;
    }
    
    public static void mapTechData(PDE__c pce, GRDFManager.DonneesTechniquesWrapper wrapper) {

        if (wrapper.donnees_techniques == null) {
            pce.GRDF_Statut_Donnees_Techniques__c = 'Récupération Impossible';
            String fullError = wrapper.statut_restitution.code + ': ' + wrapper.statut_restitution.message;
            pce.GRDF_Erreur_donnees_techniques__c = fullError.left(255);
            return;
        }
 
        GRDFManager.DonneesTechniques data = wrapper.donnees_techniques;
 
        pce.NumeroVoie__c = data.situation_compteur.numero_rue;
        pce.voie__c = data.situation_compteur.nom_rue;
        pce.Code_Postal__c = data.situation_compteur.code_postal;
        pce.Ville__c = data.situation_compteur.commune;
        pce.Frequence__c = data.caracteristiques_compteur.frequence;
        pce.Identifiant_PITD__c = data.pitd.identifiant_pitd;
        pce.GRDF_Statut_Donnees_Techniques__c = 'Données récupérées';
        pce.GRDF_Erreur_donnees_techniques__c = null;
    }

    // ========================================
    // WRAPPER INPUT
    // ========================================
    public class Request {
        @InvocableVariable(label='Liste d\'enregistrements PCE' description='Liste des enregistrements PCE à traiter (peut contenir un ou plusieurs éléments)' required=true)
        public List<PDE__c> pceRecords; 

        @InvocableVariable(label='Mode d\'action' description='Mettre "MANUAL" pour synchrone, sinon laisser vide pour Queueable' required=false)
        public String type_action;
    }
}