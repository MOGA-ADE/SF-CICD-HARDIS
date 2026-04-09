public class GazelActionSendQuote {

    @InvocableMethod(label='Gazel - Envoyer Cotation' description='Envoie le Devis courant à l\'API Gazel pour chiffrage' callout=true)
    public static List<Output> GazelActionSendQuote(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        Output out = new Output();
        Input input = inputs[0];
        Account relatedCopro;

        try {
            // 1. Validation SDC (Copropriété)
            if (input.clientType == 'SDC') {
                // Récupérer les IDs des comptes liés
                Set<Id> accountIds = new Set<Id>();
                for (QuoteLineItem qli : [SELECT PDE__r.EntiteJuridique__c FROM QuoteLineItem WHERE QuoteId = :input.quoteId]) {
                    accountIds.add(qli.PDE__r.EntiteJuridique__c);
                }

                // Requête sur les comptes avec les IDs collectés
                List<Account> relatedCopros = [SELECT Id, Name, Numero_voie__c, Voie__c, Code_postal__c, Ville__c 
                                             FROM Account 
                                             WHERE RecordType.DeveloperName = 'Copropriete' 
                                             AND Id IN :accountIds];

                // Validation nombre de copro
                if (relatedCopros.isEmpty()) {
                    return createErrorOutput(outputs, 'Aucune copropriété liée à ce devis. Veuillez changer le type de client.');
                } 
                if (relatedCopros.size() > 1) {
                    return createErrorOutput(outputs, 'Plusieurs copropriétés sont liées. Gazel n\'accepte pas le multi-copro.');
                }

                // Validation de l'adresse complète de la copropriété
                relatedCopro = relatedCopros[0];
                if (String.isBlank(relatedCopro.Numero_voie__c) || String.isBlank(relatedCopro.Voie__c) || String.isBlank(relatedCopro.Code_postal__c) || String.isBlank(relatedCopro.Ville__c)) {
                    return createErrorOutput(outputs, 'Adresse de facturation incomplète pour la copropriété. (Numéro de voie, Voie, CP et Ville requis).');
                }
            }
            
            // 2. Appel du Service
            GazelDTO.Response response = GazelService.processQuote(input, relatedCopro);
            out.isSuccess = response.isSuccess;

            if (response.isSuccess) {
                out.userMessage = 'Cotation envoyée avec succès ! ID Gazel : ' + response.cotationId;
            } else {
                out.userMessage = 'Echec de l\'envoi. Vérifiez les données.';
                out.technicalMessage = response.message + ' (Ref: ' + response.technicalErrorDetail + ')';
            }

        } catch (Exception e) {
            out.isSuccess = false;
            out.userMessage = 'Erreur système inattendue.';
            out.technicalMessage = e.getMessage() + '\n' + e.getStackTraceString();
        }
        
        outputs.add(out);
        return outputs;
    }

    // Helper pour stopper proprement le flux en cas d'erreur de validation
    private static List<Output> createErrorOutput(List<Output> outputs, String message) {
        Output out = new Output();
        out.isSuccess = false;
        out.userMessage = message;
        outputs.add(out);
        return outputs;
    }

    public class Input {
        @InvocableVariable(label='Quote ID' required=true)
        public Id quoteId;

        @InvocableVariable(label='Quote Type' required=true)
        public String quoteType;

        @InvocableVariable(label='Formule Prix')
        public Integer formulePrix;

        @InvocableVariable(label='Prix Horosaisonnier')
        public Integer prixHorosaisonnier;

        @InvocableVariable(label='Marge (€/MWh)' required=true)
        public Double marge;

        @InvocableVariable(label='Demande Contournement Liasse')
        public Boolean demandeContournementLiasse;

        @InvocableVariable(label='cPmanuel (si Demande Contournement Liasse)')
        public String cPmanuel;

        @InvocableVariable(label='pEmanuel (si Demande Contournement Liasse)')
        public String pEmanuel;

        @InvocableVariable(label='rEmanuel (si Demande Contournement Liasse)')
        public String rEmanuel;

        @InvocableVariable(label='Garantie d\'Origine (Elec)')
        public Boolean isGarantieOrigine;

        @InvocableVariable(label='Taux Garantie d\'Origine (%)')
        public Double tauxGarantieOrigine;

        @InvocableVariable(label='Complément Prix Spot')
        public Boolean isComplementPrixSpot;

        @InvocableVariable(label='Dérogation Pénalités Retard')
        public Boolean isClauseDerogationPenalitesRetardPaiement;

        @InvocableVariable(label='Type de Client (ex: SDC)')
        public String clientType;

        @InvocableVariable(label='Immatriculation (si SDC)')
        public String immatriculation;
    }

    public class Output {
        @InvocableVariable(label='Succès ?')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Message Utilisateur')
        public String userMessage;
        
        @InvocableVariable(label='Détail Technique')
        public String technicalMessage;
    }
}