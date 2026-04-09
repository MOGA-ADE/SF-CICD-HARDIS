public class GRDFManager {
    
    private static final String NAMED_CREDENTIAL = 'callout:GRDF_API';
    private static final String BASE_PATH = '/adict/v2';
    
    // ========================================
    // MÉTHODES PUBLIQUES - LES 4 ENDPOINTS
    // ========================================
    
    /**
     * 1. PUT - Créer un droit d'accès
     */
    public static DroitAccesResponse createDroitAcces(String idPce, DroitAccesRequest request) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + BASE_PATH + '/pce/' + idPce + '/droit_acces');
        req.setMethod('PUT');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(request.toJSON());
        
        HttpResponse res = executeCallout(req);

        // Préparation de l'objet réponse
        DroitAccesResponse responseWrapper = new DroitAccesResponse();

        if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
            try {
                String cleanBody = cleanJsonResponse(res.getBody());
                return (DroitAccesResponse) JSON.deserialize(cleanBody, DroitAccesResponse.class);
            } catch (JSONException e) {
                // Retourner un objet d'erreur si le JSON ne peut pas être parsé
                DroitAccesResponse errorResponse = new DroitAccesResponse();
                errorResponse.code_statut_traitement = 'JSON_PARSE_ERROR';
                errorResponse.message_retour_traitement = res.getBody(); // JSON brut
                errorResponse.id_droit_acces = null;
                return errorResponse;
            }
        } else { // CAS ERREUR API (400, 401, 403, 429, 500...)
            responseWrapper.id_droit_acces = null;
            responseWrapper.code_statut_traitement = 'HTTP_' + res.getStatusCode();
            
            // On récupère le message d'erreur brut
            String rawError = res.getBody();
            
            // On sécurise la longueur pour ne pas faire planter l'appelant
            if (rawError.length() > 200) {
                rawError = rawError.substring(0, 200) + '...';
            }
            
            responseWrapper.message_retour_traitement = rawError;
            return responseWrapper;
        }
    }
    
    /**
     * 2. POST - Vérifier le statut de plusieurs droits d'accès (NDJSON)
     */
    public static DroitsAccesResultat postDroitsAcces(List<String> idPces) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + BASE_PATH + '/droits_acces');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        // Construction du body avec la liste des PCE
        Map<String, Object> body = new Map<String, Object>();
        body.put('id_pce', idPces);
        req.setBody(JSON.serialize(body));
        
        HttpResponse res = executeCallout(req);
        
        if (res.getStatusCode() == 200) {
            return parseNDJSON(res.getBody());
        }
        
        throw new GRDFException('Impossible de récupérer les droits pour les PCEs: ' + idPces + '. Réponse de GRDF: ' + res.getBody());
    }
    
    /**
     * 3. GET - Récupérer les données contractuelles
     */
    public static DonneesContractuellesWrapper getDonneesContractuelles(String idPce) {
        DonneesContractuellesWrapper wrapper = new DonneesContractuellesWrapper();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + BASE_PATH + '/pce/' + idPce + '/donnees_contractuelles');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        try {
            HttpResponse res = executeCallout(req);
            
            if (res.getStatusCode() == 200) {
                // IMPORTANT : On garde le cleanJsonResponse pour éviter les bugs de parsing
                return (DonneesContractuellesWrapper) JSON.deserialize(cleanJsonResponse(res.getBody()), DonneesContractuellesWrapper.class);
            } else {
                // Cas Erreur HTTP (400, 404, 500...)
                wrapper.statut_restitution = new StatutRestitution();
                wrapper.statut_restitution.code = 'HTTP_' + res.getStatusCode();
                // On limite la taille du message pour éviter "String too long"
                wrapper.statut_restitution.message = (res.getBody().length() > 250) ? res.getBody().substring(0, 250) : res.getBody();
            }
        } catch (Exception e) {
            wrapper.statut_restitution = new StatutRestitution();
            wrapper.statut_restitution.code = 'DONNEES_CONTRACTUELLES APEX_ERROR';
            wrapper.statut_restitution.message = e.getMessage();
        }
        
        return wrapper;
    }
    
    /**
     * 4. GET - Récupérer les données techniques
     */
    public static DonneesTechniquesWrapper getDonneesTechniques(String idPce) {
        DonneesTechniquesWrapper wrapper = new DonneesTechniquesWrapper();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + BASE_PATH + '/pce/' + idPce + '/donnees_techniques');
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        
        try {
            HttpResponse res = executeCallout(req);
            
            if (res.getStatusCode() == 200) {
                // IMPORTANT : On garde le cleanJsonResponse pour éviter les bugs de parsing
                return (DonneesTechniquesWrapper) JSON.deserialize(cleanJsonResponse(res.getBody()), DonneesTechniquesWrapper.class);
            } else {
                // Cas Erreur HTTP (400, 404, 500...)
                wrapper.statut_restitution = new StatutRestitution();
                wrapper.statut_restitution.code = 'HTTP_' + res.getStatusCode();
                // On limite la taille du message pour éviter "String too long"
                wrapper.statut_restitution.message = (res.getBody().length() > 250) ? res.getBody().substring(0, 250) : res.getBody();
            }
        } catch (Exception e) {
            wrapper.statut_restitution = new StatutRestitution();
            wrapper.statut_restitution.code = 'DONNEES_TECHNIQUES APEX_ERROR';
            wrapper.statut_restitution.message = e.getMessage();
        }

        return wrapper;
    }
    
    // ========================================
    // MÉTHODE PRIVÉES - HELPERS
    // ========================================
    
    /**
     * Callout générique avec LOG
     */
    private static HttpResponse executeCallout(HttpRequest req) {
        Http http = new Http();
        HttpResponse res;
        
        try {
            res = http.send(req);
            // TODO: Utiliser la classe de logging
            System.debug('=== GRDF API Call ===');
            System.debug('Endpoint: ' + req.getEndpoint());
            System.debug('Method: ' + req.getMethod());
            System.debug('Body: ' + req.getBody());
            System.debug('Status Code: ' + res.getStatusCode());
            System.debug('Response: ' + res.getBody()); 
        } catch (Exception e) {
            System.debug('Callout Exception: ' + e.getMessage());
            throw new GRDFException('Callout failed: ' + e.getMessage());
        }
        
        return res;
    }
    
    /**
     * Parser le format NDJSON (Newline Delimited JSON)
     * Gestion du JSON formaté (avec indentation)
     */
    private static DroitsAccesResultat parseNDJSON(String ndjsonBody) {
        DroitsAccesResultat resultat = new DroitsAccesResultat();
        resultat.droitsAcces = new List<DroitAccesNDJSON>();
        
        // Extraire les objets JSON complets en comptant les accolades
        List<String> jsonObjects = extractJsonObjects(ndjsonBody);
        
        for (String jsonObj : jsonObjects) {
            if (String.isNotBlank(jsonObj)) {
                try {
                    // Détecter si c'est le statut final ou un droit d'accès
                    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(jsonObj);

                    if (jsonMap.containsKey('code_statut_traitement')) {
                        // C'est le statut final
                        resultat.statutFinal = (StatutTraitement) JSON.deserialize(jsonObj, StatutTraitement.class);
                    } else if (jsonMap.containsKey('id_droit_acces')) {
                        // C'est un droit d'accès
                        DroitAccesNDJSON droit = (DroitAccesNDJSON) JSON.deserialize(jsonObj, DroitAccesNDJSON.class);
                        resultat.droitsAcces.add(droit);
                    }
                } catch (Exception e) {
                    System.debug('Error parsing JSON object: ' + e.getMessage());
                }
            }
        }

        return resultat;
    }

    /**
     * Extraire les objets JSON complets d'une chaîne NDJSON
     * Gère le JSON formaté avec indentations
     */
    private static List<String> extractJsonObjects(String ndjsonBody) {
        List<String> jsonObjects = new List<String>();
        
        if (String.isBlank(ndjsonBody)) {
            return jsonObjects;
        }

        Integer depth = 0;
        Integer startIndex = -1;

        for (Integer i = 0; i < ndjsonBody.length(); i++) {
            String currentChar = ndjsonBody.substring(i, i + 1);

            if (currentChar == '{') {
                if (depth == 0) {
                    startIndex = i; // Début d'un nouvel objet JSON
                }
                depth++;
            } else if (currentChar == '}') {
                depth--;
                if (depth == 0 && startIndex != -1) {
                    // Fin de l'objet JSON - extraire
                    String jsonObj = ndjsonBody.substring(startIndex, i + 1);
                    jsonObjects.add(jsonObj);
                    startIndex = -1;
                }
            }
        }

        return jsonObjects;
    }

    /**
     * Nettoyer le JSON reçu de GRDF (espaces insécables, BOM UTF-8, etc.)
     */
    private static String cleanJsonResponse(String jsonBody) {
        if (String.isBlank(jsonBody)) return '{}';

        // Supprimer BOM UTF-8 (si présent)
        if (jsonBody.startsWith('\uFEFF')) {
            jsonBody = jsonBody.substring(1);
        }

        // Remplacer espaces insécables (code 160) par espaces normaux
        // GRDF utilise des \u00A0 pour indenter le JSON
        jsonBody = jsonBody.replace('\u00A0', ' ');

        // Trim pour supprimer espaces en début/fin
        return jsonBody.trim();
    }
    
    // ========================================
    // INNER CLASSES - WRAPPERS
    // ========================================
    
    /**
     * Requête pour créer un droit d'accès (PUT)
     */
    public class DroitAccesRequest {
        public String role_tiers;
        public String raison_sociale;
        public String code_postal;
        public String courriel_titulaire;
        public String date_debut_droit_acces;
        public String date_fin_droit_acces;
        public String perim_donnees_conso_debut;
        public String perim_donnees_conso_fin;
        public String perim_donnees_contractuelles;
        public String perim_donnees_techniques;
        public String perim_donnees_informatives;
        public String perim_donnees_publiees;
        
        public DroitAccesRequest() {
            this.role_tiers = 'AUTORISE_CONTRAT_FOURNITURE';
            this.perim_donnees_contractuelles = 'Vrai';
            this.perim_donnees_techniques = 'Vrai';
            this.perim_donnees_informatives = 'Vrai';
            this.perim_donnees_publiees = 'Vrai';
        }
        
        /**
         * Générer le JSON avec l'ordre correct des champs (requis par GRDF)
         */
        public String toJSON() {
            JSONGenerator gen = JSON.createGenerator(false);
            gen.writeStartObject();
            gen.writeStringField('role_tiers', this.role_tiers);
            gen.writeStringField('raison_sociale', this.raison_sociale);
            gen.writeStringField('code_postal', this.code_postal);
            gen.writeStringField('courriel_titulaire', this.courriel_titulaire);
            gen.writeStringField('date_debut_droit_acces', this.date_debut_droit_acces);
            gen.writeStringField('date_fin_droit_acces', this.date_fin_droit_acces);
            gen.writeStringField('perim_donnees_conso_debut', this.perim_donnees_conso_debut);
            gen.writeStringField('perim_donnees_conso_fin', this.perim_donnees_conso_fin);
            gen.writeStringField('perim_donnees_contractuelles', this.perim_donnees_contractuelles);
            gen.writeStringField('perim_donnees_techniques', this.perim_donnees_techniques);
            gen.writeStringField('perim_donnees_informatives', this.perim_donnees_informatives);
            gen.writeStringField('perim_donnees_publiees', this.perim_donnees_publiees);
            gen.writeEndObject();
            return gen.getAsString();
        }
    }
    
    /**
     * Réponse du droit d'accès (PUT)
     */
    public class DroitAccesResponse {
        public String code_statut_traitement;
        public String message_retour_traitement;
        public String id_pce;
        public String role_tiers;
        public String id_droit_acces;
        public String etat_droit_acces;
        public String date_creation_droit_acces;
        public String nom_titulaire;
        public String raison_sociale_du_titulaire;
        public String code_postal;
        public String parcours;
        public String courriel_titulaire;
        public String perim_donnees_contractuelles;
        public String perim_donnees_techniques;
        public String perim_donnees_informatives;
        public String perim_donnees_publiees;
        public String date_debut_droit_acces;
        public String date_fin_droit_acces;
        public String perim_donnees_conso_debut;
        public String perim_donnees_conso_fin;
        public String numero_telephone_mobile_titulaire;
    }
    
    /**
     * Wrapper pour le résultat du POST droits_acces (NDJSON)
     */
    public class DroitsAccesResultat {
        public List<DroitAccesNDJSON> droitsAcces;
        public StatutTraitement statutFinal;
    }
    
    /**
     * Objet droit d'accès dans le NDJSON (POST)
     */
    public class DroitAccesNDJSON {
        public String id_droit_acces;
        public String id_pce;
        public String role_tiers;
        public String raison_sociale_du_tiers;
        public String nom_titulaire;
        public String raison_sociale_du_titulaire;
        public String courriel_titulaire;
        public String code_postal;
        public String perim_donnees_contractuelles;
        public String perim_donnees_techniques;
        public String perim_donnees_informatives;
        public String perim_donnees_publiees;
        public String date_creation;
        public String etat_droit_acces;
        public String date_revocation;
        public String source_revocation;
        public String date_passage_a_obsolete;
        public String source_passage_a_obsolete;
        public String date_debut_droit_acces;
        public String date_fin_droit_acces;
        public String perim_donnees_conso_debut;
        public String perim_donnees_conso_fin;
        public String date_passage_a_refuse;
        public String source_passage_a_refuse;
        public String parcours;
        public String statut_controle_preuve;
        public String date_limite_transmission_preuve;
        public String numero_telephone_mobile_titulaire;
    }
    
    /**
     * Statut de traitement (dernière ligne du NDJSON)
     */
    public class StatutTraitement {
        public String code_statut_traitement;
        public String message_retour_traitement;
    }
    
    /**
     * Wrapper pour les données contractuelles (GET)
     */
    public class DonneesContractuellesWrapper {
        public PceInfo pce;
        public DonneesContractuelles donnees_contractuelles;
        public StatutRestitution statut_restitution;
    }
    
    /**
     * Informations PCE
     */
    public class PceInfo {
        public String id_pce;
    }
    
    /**
     * Statut de restitution (en cas d'erreur)
     */
    public class StatutRestitution {
        public String code;
        public String message;
    }
    
    /**
     * Données contractuelles (GET)
     */
    public class DonneesContractuelles {
        public String date_mes;
        public String tarif_acheminement;
        public String date_publication;
        public String consommation_journaliere_plafond;
        public CarInfo car;
        public CjaInfo cja;
        public ProfilInfo profil;
        public ModulationInfo modulation;
    }
    
    public class CarInfo {
        public String car_actuelle;
        public String car_future;
    }
    
    public class CjaInfo {
        public String cja;
        public String cja_journaliere;
        public String cja_mensuelle;
    }
    
    public class ProfilInfo {
        public String date_debut_profil_type_actuel;
        public String date_fin_profil_type_actuel;
        public String profil_type_actuel;
        public String profil_type_futur;
    }
    
    public class ModulationInfo {
        public String modulation_n_1;
        public String modulation_n_2;
        public String modulation_n_3;
        public String assiette;
    }
    
    /**
     * Wrapper pour les données techniques (GET)
     */
    public class DonneesTechniquesWrapper {
        public PceInfo pce;
        public DonneesTechniques donnees_techniques;
        public StatutRestitution statut_restitution;
    }
    
    /**
     * Données techniques (GET)
     */
    public class DonneesTechniques {
        public SituationCompteur situation_compteur;
        public CaracteristiquesCompteur caracteristiques_compteur;
        public PitdInfo pitd;
        public RegimePropriete regime_propriete;
    }
    
    public class SituationCompteur {
        public String numero_rue;
        public String nom_rue;
        public String complement_adresse;
        public String code_postal;
        public String commune;
    }
    
    public class CaracteristiquesCompteur {
        public String frequence;
        public String client_sensible_mig;
        public String code_calibre;
        public String code_debit;
        public String code_debit_normalise;
        public String pression_livraison;
        public String matricule_compteur;
    }
    
    public class PitdInfo {
        public String identifiant_pitd;
        public String libelle_pitd;
    }
    
    public class RegimePropriete {
        public String regime_propriete_compteur;
        public String regime_propriete_convertisseur;
        public String regime_propriete_poste;
        public String regime_propriete_enregistreur;
    }
    
    // Exception personnalisée
    public class GRDFException extends Exception {}
}