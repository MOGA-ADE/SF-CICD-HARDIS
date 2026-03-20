/**
 * Classe Queueable chargée de rafraîchir les informations Enedis pour un ensemble de PDE.
 * 
 * Le traitement se fait par lots de 40 PDE maximum pour éviter les limites de gouvernance.
 * Chaque lot exécute les WebServices SGE,
 * met à jour les enregistrements PDE et relance un nouveau lot jusqu'à épuisement de la liste.
 */
public class SGERefreshSiteQueueable implements Queueable, Database.AllowsCallouts {

    private List<Id> pdeIds;
    private Integer startIndex;
    private static final Integer BATCH_SIZE = 40; // Taille maximale d'un lot

    public SGERefreshSiteQueueable(List<Id> pdeIds) {
        this(pdeIds, 0);
    }

    public SGERefreshSiteQueueable(List<Id> pdeIds, Integer startIndex) {
        this.pdeIds = pdeIds;
        this.startIndex = startIndex;
    }

    public void execute(QueueableContext context) {
        try {
            Integer endIndex = Math.min(startIndex + BATCH_SIZE, pdeIds.size());
            List<Id> currentBatch = new List<Id>();

            // Préparation du lot courant
            for (Integer i = startIndex; i < endIndex; i++) {
                currentBatch.add(pdeIds[i]);
            }

            // Récupération des PDE à traiter
            List<PDE__c> pdes = [
                SELECT Id, Name, ReferencePointEnergie_Refonte__c, NumeroVoie__c, voie__c,
                       Date_signature_ACD__c, OwnerId, ACD_valide__c
                FROM PDE__c
                WHERE Id IN :currentBatch
            ];

            for (PDE__c pde : pdes) {
                if (!pde.ACD_valide__c) continue;

                WrapPDEInfoEnedis result = new WrapPDEInfoEnedis();

                try {
                    result.siteName = pde.Name;
                    SGEManager.callConsulterMesure(pde.ReferencePointEnergie_Refonte__c, result);
                    SGEManager.consulterPoint(pde.ReferencePointEnergie_Refonte__c, result);
                    SGEManager.updateSite(pde.Id, result);
                    result.messageUpdate = SGEManager.SUCCESS_MESSAGE;

                    PDE__c pdeToUpdate = [
                        SELECT Id, NumeroVoie__c, voie__c, ReferencePointEnergie_Refonte__c,
                               Date_signature_ACD__c, OwnerId
                        FROM PDE__c
                        WHERE Id = :pde.Id
                        LIMIT 1
                    ];

                    String numeroVoie = pdeToUpdate.NumeroVoie__c ?? '';
                    String voie = pdeToUpdate.voie__c ?? '';
                    pdeToUpdate.Name = (numeroVoie + ' ' + voie).trim();
                    update pdeToUpdate;

                    Datetime actionsDate = Datetime.now().addHours(+1);
                    Utils.logSGEDocusign(
                        pdeToUpdate.ReferencePointEnergie_Refonte__c,
                        pdeToUpdate.Date_signature_ACD__c,
                        actionsDate,
                        pdeToUpdate.Id,
                        pdeToUpdate.OwnerId
                    );

                } catch (Exception e) {
                    System.debug('Compteur non reconnu : ' + e.getMessage());
                }
            }

            // Si d'autres PDE restent à traiter, on enchaîne le lot suivant
            if (endIndex < pdeIds.size()) {
                System.enqueueJob(new SGERefreshSiteQueueable(pdeIds, endIndex));
            }

        } catch (Exception e) {
            System.debug('Erreur critique dans SGERefreshSiteQueueable : ' + e.getMessage());
        }
    }
}