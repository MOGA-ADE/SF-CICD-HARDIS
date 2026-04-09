/**
 * Batch schedulé pour vérifier le statut des droits d'accès GRDF
 * Tourne toutes les 30 minutes pour checker si les droits sont validés
 */
public class GRDFCheckValidationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    /**
     * Start - Récupérer tous les PCE "Droit d'accès déclaré"
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('Start: Batch GRDFCheckValidationBatch démarré');
        return Database.getQueryLocator([
            SELECT Id, TECH_num_compteur__c, GRDF_Statut_Droit_acces__c, GRDF_Id_Droit_Acces__c
            FROM PDE__c
            WHERE GRDF_Statut_Droit_acces__c = 'Demande d\'accès en attente de validation'
        ]);
    }
    
    /**
     * Execute - Traiter le lot de PCE (1 seul callout par scope)
     */
    public void execute(Database.BatchableContext bc, List<PDE__c> scope) {
        
        System.debug('Execute, scope : ' + scope);
        // Construire la liste des IDs PCE pour l'API
        List<String> pceIds = new List<String>();
        Map<String, PDE__c> pceByNumber = new Map<String, PDE__c>();
        
        for (PDE__c pce : scope) {
            pceIds.add(pce.TECH_num_compteur__c);
            pceByNumber.put(pce.TECH_num_compteur__c, pce);
        }
        
        try {
            // Appel API POST unique pour tous les PCE du scope
            GRDFManager.DroitsAccesResultat resultat = GRDFManager.postDroitsAcces(pceIds);
            
            List<PDE__c> pcesToUpdate = new List<PDE__c>();
            
            // Analyser chaque droit d'accès retourné
            for (GRDFManager.DroitAccesNDJSON droit : resultat.droitsAcces) {
                
                PDE__c pce = pceByNumber.get(droit.id_pce);
                
                if (pce != null) {
                    // Vérifier l'état du droit d'accès
                    if (droit.etat_droit_acces == 'Active') {
                        // Droit validé → passer à l'étape suivante
                        pce.GRDF_Statut_Droit_Acces__c = 'Demande d\'accès validée';
                        pce.GRDF_Date_fin_droit_acces__c = droit.date_fin_droit_acces  != null ? Date.valueOf(droit.date_fin_droit_acces) : null;
                        pcesToUpdate.add(pce);
                    } else if (droit.etat_droit_acces == 'Refusée') {
                        // Droit Obsolète
                        pce.GRDF_Statut_Droit_Acces__c = 'Demande d\'accès refusée';
                        pce.GRDF_Erreur_Droit_Acces__c = droit.source_passage_a_refuse;
                        pcesToUpdate.add(pce);
                    }
                }
            }
            
            // Mise à jour des PCE
            if (!pcesToUpdate.isEmpty()) {
                Database.update(pcesToUpdate, false);
            }
            
        } catch (Exception e) {
            System.debug('Erreur lors du check validation : ' + e.getMessage());
            //TODO: Log 
        }
    }
    
    /**
     * Finish - Logging final
     */
    public void finish(Database.BatchableContext bc) {
        System.debug('Finish: Batch GRDFCheckValidationBatch terminé');
        //TODO: Log
    }
    
    /**
     * Méthode pour scheduler le batch (toutes les 30 minutes)
     * À appeler depuis Execute Anonymous ou lors du déploiement
     */
    public static void scheduleJob() {
        // Scheduler pour tourner toutes les 30 minutes
        String cronExp = '0 0,30 7-20 ? * MON-FRI'; // À 00 et 30 de chaque heure entre 7et 20h du Lundi au Vendredi
        System.schedule('GRDF Check Validation Batch', cronExp, new GRDFCheckValidationScheduler());
    }
}