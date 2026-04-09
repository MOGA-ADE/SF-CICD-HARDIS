public class GazelWebhookDTO {

    public class Payload {
        public DossierClientResponse dossierClient;
        public OffreResponse offre;
    }

    // ==========================================
    // 1. STRUCTURE DOSSIER CLIENT
    // ==========================================

    public class DossierClientResponse {
        public String id;
        public String siren;
        public String raisonSociale;
        public Decimal capital;              
        public String numTva;
        public String rcs;
        public String naf;
        public AdresseSociete adresse;      
        public SDC sdc;                     
    }

    public class AdresseSociete {           
        public String value;                
        public String ville;
        public String codePostal;
        public String codeInsee;
    }

    public class SDC {                      
        public String immatricualation;     
        public String libelle;
        public PersonnePhysique syndic;
        public AdresseSociete adresse;
        public List<PersonnePhysique> membresSDC;
    }

    public class PersonnePhysique {         
        public String civilite;
        public String nom;
        public String prenom;
        public String email;
        public String telMobile;
        public String telFixe;
    }

    // ==========================================
    // 2. STRUCTURE OFFRE (ELEC & GAZ)
    // ==========================================

    public class OffreResponse {
        public String id;
        public Integer commodite;           // 1=Elec, 2=Gaz
        public Datetime debut;
        public String dateValidite;
        public Integer duree;
        public Datetime fin;
        public Integer formulePrixId;
        public String formulePrix;
        
        // Champs financiers en Decimal
        public Decimal marge;
        public Decimal volumeEstime;
        public Decimal commissionEstimee;
        public Decimal budgetAnnuel;
        
        public StatutOffreItem status;      

        // --- Spécifique Electricité ---
        public Boolean isGarantieOrigine;
        public Decimal tauxGarantieOrigine;

        // --- Liste des Compteurs (Mixte Elec/Gaz) ---
        public List<CompteurResponse> compteurs;
    }

    public class StatutOffreItem {          
        public Integer code;                
        public String commentaire;
        // Astuce : On utilise un nom de variable différent pour éviter le mot réservé 'date'
        // Il faudra faire un replace dans le body avant désérialisation
        public Datetime dateStatut;         
    }

    // ==========================================
    // 3. STRUCTURE COMPTEURS (ELEC & GAZ)
    // ==========================================

    public class CompteurResponse {
        public String num;                  
        public String siret;
        public Datetime debut;
        public Datetime fin;
        public AdresseCompteur adresse;
        
        // --- Champs Communs Prix/Coûts ---
        public Decimal prixCee;
        public Decimal prixDonCaritatif;
        public Boolean isEligibleCee;

        // --- Spécifique Electricité ---
        public String segment;
        public String turpe;
        public Decimal consoAnnuelle;
        public List<PosteCapacite> coefCapacite;
        public List<PosteEnergie> prixElectron;

        // --- Spécifique Gaz ---
        public Decimal prixMolecule;
        public Decimal termeVariableDistribution;
        public Decimal abonnementTransport;
        public Decimal abonnementDistribution;
        public Decimal abonnement;
        public Decimal estimationCTA;
        public Decimal coutMoyenTotal;
        public Decimal carUtilisee;
        public Decimal consommationTotalePrevisionnelle;
        public Decimal volumeEte;
        public Decimal volumeHiver;
        public Decimal capaciteTransportNomalisee;
        public String profil;
        public String tarifDistribution;
        public Long carActuelle;
        public Long carFuture;
    }

    public class AdresseCompteur {          
        public String libAdresse;
        public String ville;
        public String codePostal;
        public String codeInsee;
        public String stationId;
    }

    // ==========================================
    // 4. SOUS-STRUCTURES PRIX (ELEC)
    // ==========================================

    public class PosteCapacite {            
        public String nom;
        public Decimal coefficient;
        public Decimal montantTheorique;
    }

    public class PosteEnergie {             
        public String nom;
        public FormulePrixEnergieValeur formulePrixEnergieValeur;
    }

    public class FormulePrixEnergieValeur { 
        public Decimal prixAmont;
        public Decimal a;
        public Decimal b;
        public Decimal c;
        public Decimal d;
        public Decimal volumeTotal;
        public Decimal volumeArenh;
        public Decimal additifPrixFixeMarcheInluantArenh;
    }
}