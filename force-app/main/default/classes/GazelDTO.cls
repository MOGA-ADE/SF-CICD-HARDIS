public class GazelDTO {

    /**
     * Structure Racine de la demande de cotation
     * Utiliser JSON.serialize(obj, true) pour ne pas envoyer les champs nuls.
     */
    public class DemandeCotation {
        public String emailCourtier;                // Obligatoire
        public DossierClient dossierClient;         
        public Offre offre;                         
    }

    /**
     * Détails du client final
     */
    public class DossierClient {
        public String siren;                        // Obligatoire
        public Boolean mandatDonneesDisponible;     // Obligatoire
        public Boolean demandeContournementLiasse;  // False pour envoyer liasse fiscale
        
        // --- Champs Financiers Optionnels (Si contournement liasse) ---
        public String cPmanuel;                     // Capitaux propres (String ou Float selon doc, String + sûr)
        public String pEmanuel;                     // Produit d'exploitation
        public String rEmanuel;                     // Résultat d'exploitation

        // --- Contacts & Structures ---
        public Personne acheteur;                   // Le signataire/contact principal
        public SDC sdc;                             // Optionnel : Si client est un Syndicat de Copro
        
        // Note: L'adresse est souvent gérée via le SIREN, mais la doc SDC mentionne une adresse spécifique
        public Adresse adresse;                     // Adresse manuelle si besoin (contexte SDC)
    }

    /**
     * Structure générique pour Acheteur, Syndic ou Membre SDC
     */
    public class Personne {
        public String civilite;                     // "Monsieur" ou "Madame"
        public String nom;                          
        public String prenom;                       
        public String email;                        
        public String telMobile;                    
        public String telFixe;                      
    }

    /**
     * Détails spécifiques aux Syndicats de Copropriété (SDC)
     */
    public class SDC {
        public String immatriculation;              
        public String libelle;                      // Nom de la SDC
        public Adresse adresse;                     
        public Personne syndic;                     // (Parfois "A ne pas valoriser" selon contexte, mais présent)
        public List<Personne> membresSDC;           // Liste des membres du conseil syndical
    }

    /**
     * Structure d'Adresse (utilisée dans SDC)
     */
    public class Adresse {
        public String value;                        // Numéro et voie
        public String ville;                        
        public String codePostal;                   
        public String codeInsee;                    // Souvent "A ne pas valoriser"
    }

    /**
     * Détails de l'offre et du pricing
     */
    public class Offre {
        // --- Champs Communs (Elec & Gaz) ---
        public Datetime debut;                      // UTC. Ex: 2026-01-01T00:00:00+00
        public Integer duree;                       // En mois
        public Integer formulePrix;                 // ID de la formule (1, 2, 100...)
        public Decimal marge;                       // Marge courtier
        public Boolean isComplementPrixSpot;        // Clause complément Spot
        public Boolean isDonCaritatif;              // Option don caritatif
        
        // --- Clauses Contractuelles & Paiement ---
        public Boolean isClauseDerogationPenalitesRetardPaiement; 
        public Integer delaiPaiementJours;          // Ex: 15, 20...
        public Integer modePaiement;                // 1=Prélèvement, 2=Virement
        public Boolean isClauseRenegociationContrat;
        
        // --- Spécifique Electricité ---
        public Boolean isPrixLisse;                 // True=Prix unique, False=Prix par année
        public Integer horosaisonnier;              // 0=Sans découpage, 1=Avec découpage (TURPE)
        public Boolean isGarantieOrigine;           
        public Decimal tauxGarantieOrigine;         // 0 à 100

        // --- Compteurs ---
        public List<Compteur> compteurs;            
    }

    /**
     * Détails d'un point de livraison (PDL ou PCE)
     */
    public class Compteur {
        public String num;                          // Numéro PDL (14 chiffres) ou PCE
        public String siret;                        // SIRET de l'établissement du compteur
        public String codeNAF;                      // Code NAF de l'établissement
        public Datetime debut;                      // Doit être inclus dans l'offre
        public Datetime fin;                        // Optionnel
    }

    // ==========================================
    // STRUCTURE DE RÉPONSE (Interne Salesforce)
    // ==========================================
    
    public class Response {
        public Boolean isSuccess;
        public String message;              
        public String technicalErrorDetail;
        public String cotationId;           
    }
}