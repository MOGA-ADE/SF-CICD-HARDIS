public class GRDFCreateDroitsQueueable implements Queueable, Database.AllowsCallouts {
    
    private List<PDE__c> allPces;
    private String userEmail;
    private Integer startIndex;
    private Integer totalSuccess;
    private Integer totalErrors;
    private List<ResultErrorLine> resultErrorLines;
    
    // Batch size à 1 pour SLA de l'API
    private static final Integer BATCH_SIZE = 1;
    
    /**
     * Constructeur initial (premier appel depuis l'Invocable)
     */
    public GRDFCreateDroitsQueueable(List<PDE__c> pces, String email) {
        this.allPces = pces;
        this.userEmail = email;
        this.startIndex = 0;
        
        // Init des compteurs
        this.totalSuccess = 0;
        this.totalErrors = 0;
        this.resultErrorLines = new List<ResultErrorLine>();
    }
    
    /**
     * Constructeur privé pour le chaining
     * On passe les compteurs et la liste d'erreurs pour ne pas les perdre
     */
    private GRDFCreateDroitsQueueable(List<PDE__c> allPces, String email, Integer index, Integer currentSuccess, Integer currentErrors, List<ResultErrorLine> currentErrorLines) {
        this.allPces = allPces;
        this.userEmail = email;
        this.startIndex = index;
        
        // Récupération de l'état précédent
        this.totalSuccess = currentSuccess;
        this.totalErrors = currentErrors;
        this.resultErrorLines = currentErrorLines;
    }
    
    /**
     * Exécution du job
     */
    public void execute(QueueableContext context) {
        
        // Calcul de la fin du lot actuel (Record actuel + BATCH_SIZE)
        Integer endIndex = Math.min(startIndex + BATCH_SIZE, allPces.size());
        List<PDE__c> pcesToUpdate = new List<PDE__c>();
        
        // Traitement du lot (1 itération)
        for (Integer i = startIndex; i < endIndex; i++) {
            PDE__c pce = allPces[i];
            
            try {
                GRDFManager.DroitAccesRequest request = buildRequest(pce);
                
                // Appel API
                GRDFManager.DroitAccesResponse response = GRDFManager.createDroitAcces(pce.TECH_num_compteur__c, request);

                // --- CAS SUCCÈS ---
                if (String.isNotBlank(response.id_droit_acces)) {
                    pce.GRDF_Id_Droit_Acces__c = response.id_droit_acces;
                    pce.GRDF_Statut_Droit_Acces__c = 'Demande d\'accès en attente de validation';
                    pce.GRDF_Erreur_Droit_Acces__c = null;
                    
                    this.totalSuccess++; 

                // --- CAS ERREUR MÉTIER (API répond mais pas OK) ---
                } else {
                    // Filtrer l'erreur 1000000006 (Droit d'accès déjà existant)
                    if (!response.message_retour_traitement.contains('1000000006')) {
                        pce.GRDF_Id_Droit_Acces__c = null;
                        pce.GRDF_Statut_Droit_Acces__c = 'Demande d\'accès rejetée';
                    }

                    String errorMsg = '[' + response.code_statut_traitement + '] ' + response.message_retour_traitement;
                    pce.GRDF_Erreur_Droit_Acces__c = errorMsg.left(255);

                    this.totalErrors++;
                    this.resultErrorLines.add(new ResultErrorLine(pce.TECH_num_compteur__c, 'ERREUR', pce.GRDF_Erreur_Droit_Acces__c));
                }

                pcesToUpdate.add(pce);

            // --- CAS ERREUR TECHNIQUE (Exception Apex) ---
            } catch (Exception e) {
                System.debug('Erreur technique PCE ' + pce.TECH_num_compteur__c + ': ' + e.getMessage());

                pce.GRDF_Id_Droit_Acces__c = null;
                pce.GRDF_Statut_Droit_Acces__c = 'Demande d\'accès rejetée';
                
                String techError = 'Erreur technique SF: ' + e.getMessage();
                pce.GRDF_Erreur_Droit_Acces__c = techError.left(255);

                pcesToUpdate.add(pce);
                this.totalErrors++;
                this.resultErrorLines.add(new ResultErrorLine(pce.TECH_num_compteur__c, 'ERREUR TECHNIQUE', pce.GRDF_Erreur_Droit_Acces__c));
            }
        }
        

        if (!pcesToUpdate.isEmpty()) {
            Database.update(pcesToUpdate, false);
        }
        
        // --- GESTION DU CHAINING ---
        Integer nextIndex = startIndex + BATCH_SIZE;
        
        // S'il reste des PCE à traiter dans la liste globale
        if (nextIndex < allPces.size()) {
            
            // On chaine en passant les compteurs à jour au prochain job
            GRDFCreateDroitsQueueable nextJob = new GRDFCreateDroitsQueueable(allPces, userEmail, nextIndex, this.totalSuccess, this.totalErrors, this.resultErrorLines);
            
            // Sécurité : ne pas enchaîner en test unitaire pour éviter la boucle infinie
            if(!Test.isRunningTest()) {
                sleep(200); // Pause pour respecter les limites d'appel API
                System.enqueueJob(nextJob);
            }
            
        } else {
            // FIN DU TRAITEMENT : Tous les lots sont passés, on envoie l'email final
            sendSummaryEmail();
        }
    }
    
    /**
     * Construire la requête GRDF depuis le PCE
     */
    private GRDFManager.DroitAccesRequest buildRequest(PDE__c pce) {
        GRDFManager.DroitAccesRequest request = new GRDFManager.DroitAccesRequest();

        // Infos titulaire
        request.raison_sociale = pce.Nom_du_compte__c;
        request.code_postal = pce.Code_Postal__c;
        request.courriel_titulaire = userEmail;
        
        // Ajout d'une sécurité null check sur la date
        if(pce.Date_signature_ACD__c != null) {
            request.date_debut_droit_acces = String.valueOf(pce.Date_signature_ACD__c);
            request.date_fin_droit_acces = String.valueOf(pce.Date_signature_ACD__c.addYears(1));
            request.perim_donnees_conso_debut = String.valueOf(pce.Date_signature_ACD__c);
            request.perim_donnees_conso_fin = String.valueOf(pce.Date_signature_ACD__c.addYears(1));
        }
        
        return request;
    }
    
    /**
     * Envoyer l'email de récapitulation
     */
    private void sendSummaryEmail() {

        // Construire l'email HTML
        String emailBody = '<html><body>';
        emailBody += '<h2>Récapitulatif de la création des droits d\'accès GRDF</h2>';
        emailBody += '<div style="background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px;">';
        emailBody += '<p style="margin: 5px 0;"><strong>Total traité :</strong> ' + (this.totalSuccess + this.totalErrors) + ' PCE(s)</p>';
        emailBody += '<p style="margin: 5px 0; color: green;"><strong>Succès :</strong> ' + this.totalSuccess + '</p>';
        emailBody += '<p style="margin: 5px 0; color: red;"><strong>Erreurs :</strong> ' + this.totalErrors + '</p>';
        emailBody += '</div>';

        // Afficher le tableau UNIQUEMENT s'il y a des erreurs
        if (this.totalErrors > 0) {
            emailBody += '<h3 style="color: red;">PCE en erreur (' + this.totalErrors + ')</h3>';
            emailBody += '<table border="1" cellpadding="8" cellspacing="0" style="border-collapse: collapse; width: 100%;">';
            emailBody += '<thead><tr style="background-color: #dc3545; color: white;">';
            emailBody += '<th>Numéro PCE</th>';
            emailBody += '<th>Message d\'erreur</th>';
            emailBody += '</tr></thead>';
            emailBody += '<tbody>';

            for (ResultErrorLine line : this.resultErrorLines) {
                emailBody += '<tr style="background-color: #f8d7da;">';
                emailBody += '<td><strong>' + line.pceNumber + '</strong></td>';
                emailBody += '<td>' + line.message + '</td>';
                emailBody += '</tr>';
            }

            emailBody += '</tbody></table>';
        } else {
            emailBody += '<p style="color: green; font-size: 16px;"><strong>Tous les droits d\'accès ont été créés avec succès !</strong></p>';
        }

        emailBody += '<br/><p style="color: #6c757d; font-size: 12px;">Vous devez valider les droits d\'accès crées avant de pouvoir récupérer les données techniques et contractuelles. La validation sera effective sous 48h si aucune action manuelle n\'est réalisée.</p>';
        emailBody += '</body></html>';

        // Récupérer l'Org-Wide Address
        List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'service-client@alliancedesenergies.fr' LIMIT 1];

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if (!owea.isEmpty()) {email.setOrgWideEmailAddressId(owea[0].Id);} 
        email.setToAddresses(new String[] { userEmail });
        email.setSubject('GRDF - Création des droits d\'accès terminée (' + this.totalSuccess + ' OK / ' + this.totalErrors + ' KO)');
        email.setHtmlBody(emailBody);
        email.setUseSignature(false);

        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        } catch (Exception e) {
            System.debug('Erreur envoi email : ' + e.getMessage());
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

    /**
     * Inner class pour stocker les résultats en erreur
     */
    public class ResultErrorLine {
        public String pceNumber;
        public String status;
        public String message;
        
        public ResultErrorLine(String pceNumber, String status, String message) {
            this.pceNumber = pceNumber;
            this.status = status;
            this.message = message;
        }
    }
}