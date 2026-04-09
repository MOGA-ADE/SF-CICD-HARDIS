public class GazelService {

    public class ServiceException extends Exception {}

    public static GazelDTO.Response processQuote(GazelActionSendQuote.Input input, Account relatedCopro) {
        List<QuoteLineItem> QLIS = [
            SELECT  DebutDeFourniture__c,
                    Nouvelle_Echeance__c,
                    PDE__r.EntiteJuridique__r.Code_NAF__r.Name,
                    PDE__r.EntiteJuridique__r.Syndic__r.Code_NAF__r.Name,
                    PDE__r.TECH_num_compteur__c,
                    PDE__r.Siret_payeur__c,
                    Quote.Minimum_date_de_debut__c,
                    Quote.Duree_offre_en_mois__c,
                    Quote.Opportunity.Owner.Email,
                    Quote.Account.Siren__c,            
                    Quote.Opportunity.Demande_Cotation__r.Signataire__r.Salutation,
                    Quote.Opportunity.Demande_Cotation__r.Signataire__r.firstName,
                    Quote.Opportunity.Demande_Cotation__r.Signataire__r.lastName,
                    Quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone,
                    Quote.Opportunity.Demande_Cotation__r.Signataire__r.Email
            FROM QuotelineItem 
            WHERE QuoteId = :input.quoteId
        ];

        QuoteLineItem firstQLI = QLIS[0];
        Boolean isGaz = input.quoteType.containsIgnoreCase('Gaz');

        // 2. MAPPING : Salesforce -> DTO
        GazelDTO.DemandeCotation payload = new GazelDTO.DemandeCotation();
        
        //Infos Courtier
        payload.emailCourtier = 'pricing-ade@alliancedesenergies.fr';

        // Dossier Client
        payload.dossierClient = new GazelDTO.DossierClient();
        payload.dossierClient.siren = firstQLI.Quote.Account.Siren__c;
        payload.dossierClient.mandatDonneesDisponible = true;

        // Acheteur (Signataire de la Demande de Cotation)
        payload.dossierClient.acheteur = new GazelDTO.Personne();
        payload.dossierClient.acheteur.nom = firstQLI.Quote.Opportunity.Demande_Cotation__r.Signataire__r.LastName;
        payload.dossierClient.acheteur.prenom = firstQLI.Quote.Opportunity.Demande_Cotation__r.Signataire__r.FirstName;
        payload.dossierClient.acheteur.email = firstQLI.Quote.Opportunity.Demande_Cotation__r.Signataire__r.Email;
        payload.dossierClient.acheteur.telMobile = firstQLI.Quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone;
        payload.dossierClient.acheteur.telFixe = firstQLI.Quote.Opportunity.Demande_Cotation__r.Signataire__r.Phone;
        payload.dossierClient.acheteur.civilite = getProperSalutation(firstQLI.Quote.Opportunity.Demande_Cotation__r.Signataire__r.Salutation) ?? 'Monsieur';

        // Copropriété (si client SDC)
        if (input.clientType == 'SDC') {
            payload.dossierClient.sdc = new GazelDTO.SDC();
            payload.dossierClient.sdc.immatriculation = input.immatriculation;
            payload.dossierClient.sdc.adresse = new GazelDTO.Adresse();
            payload.dossierClient.sdc.adresse.value = relatedCopro.Numero_voie__c + ' ' + relatedCopro.Voie__c;
            payload.dossierClient.sdc.adresse.codePostal = relatedCopro.Code_postal__c;
            payload.dossierClient.sdc.adresse.ville = relatedCopro.Ville__c;
            
            payload.dossierClient.sdc.syndic = new GazelDTO.Personne();
            payload.dossierClient.sdc.syndic.civilite = '';
            payload.dossierClient.sdc.syndic.nom = '';            
            payload.dossierClient.sdc.syndic.prenom = '';            
            payload.dossierClient.sdc.syndic.email = '';            
            payload.dossierClient.sdc.syndic.telMobile = '';            
            payload.dossierClient.sdc.syndic.telFixe = '';  
            
            payload.dossierClient.sdc.libelle = relatedCopro.Name;

            payload.dossierClient.sdc.membresSDC = new List<GazelDTO.Personne>();
            payload.dossierClient.sdc.membresSDC.add(payload.dossierClient.acheteur);
        }
        
        payload.dossierClient.demandeContournementLiasse = input.demandeContournementLiasse;
        if (!input.demandeContournementLiasse) {
            payload.dossierClient.cPmanuel = input.cPmanuel;
            payload.dossierClient.pEmanuel = input.pEmanuel;
            payload.dossierClient.rEmanuel = input.rEmanuel;
        }

        // Offre
        payload.offre = new GazelDTO.Offre();
        payload.offre.debut = toUtcDatetime(firstQLI.Quote.Minimum_date_de_debut__c); 
        payload.offre.duree = Integer.valueOf(firstQLI.Quote.Duree_offre_en_mois__c);
        payload.offre.marge = input.marge;
        payload.offre.formulePrix = isGaz? 1 : input.formulePrix;
        if (!isGaz) {
            payload.offre.isPrixLisse = true; 
            payload.offre.horosaisonnier = input.prixHorosaisonnier; 
            payload.offre.isGarantieOrigine = input.isGarantieOrigine;
            payload.offre.tauxGarantieOrigine = input.isGarantieOrigine ? input.tauxGarantieOrigine : 0; 
        }
        payload.offre.isClauseDerogationPenalitesRetardPaiement = input.isClauseDerogationPenalitesRetardPaiement;
        payload.offre.isComplementPrixSpot = input.isComplementPrixSpot;
        payload.offre.isDonCaritatif = false;
        payload.offre.isClauseRenegociationContrat = false;
        payload.offre.delaiPaiementJours = isGaz ? 20 : 15;
        payload.offre.modePaiement = 1;


        // Compteurs (QuoteLineItems -> List<Compteur>)
        payload.offre.compteurs = new List<GazelDTO.Compteur>();

        for (QuoteLineItem qli : QLIS) {
            GazelDTO.Compteur c = new GazelDTO.Compteur();
            c.num = qli.PDE__r.TECH_num_compteur__c; 
            c.siret = qli.PDE__r.Siret_payeur__c;
            c.codeNAF = input.clientType == 'SDC' ? qli.PDE__r.EntiteJuridique__r.Syndic__r.Code_NAF__r.Name : qli.PDE__r.EntiteJuridique__r.Code_NAF__r.Name;
            c.debut = toUtcDatetime(qli.DebutDeFourniture__c);
            c.fin = toUtcDatetime(qli.Nouvelle_Echeance__c);
            payload.offre.compteurs.add(c);
        }

        // 3. CALLOUT
        return GazelAPI.sendQuote(payload, isGaz, input);
    }

    /**
     * Traitement du Webhook avec DTO typé
     */
    public static void processWebhookUpdate(GazelWebhookDTO.Payload payload) {
        String gazelId = payload.offre.id;

        List<Quote> quotes = [SELECT Id, Api_status__c, Api_error_message__c, Date_Validite_Offre__c FROM Quote WHERE API_Offre_ID__c = :gazelId LIMIT 1];
        if (quotes.isEmpty()) return;
        Quote q = quotes[0];

        Integer statusCode = payload.offre.status != null ? payload.offre.status.code : null;
        String apiMessage = payload.offre.status != null ? payload.offre.status.commentaire : '';
        Boolean hasTechnicalData = (payload.offre.compteurs != null && !payload.offre.compteurs.isEmpty()) || payload.dossierClient != null;

        if (hasTechnicalData) { // On a reçu le chiffrage
            q.Api_status__c = 'Demande de prix validée par le fournisseur';

            String rawDate = payload.offre.dateValidite;
            String dateOnly = rawDate.left(10); // YYYY-MM-DD = 10 caractères
            String forcedTimeDate = dateOnly + ' 11:00:00';
            q.Date_Validite_Offre__c = DateTime.valueOf(forcedTimeDate);

            Enchere_de_capacite__mdt edc = Enchere_de_capacite__mdt.getInstance('Enchere_de_capacite');
            Map<String, QuoteLineItem> qliByNumPdl = new Map<String, QuoteLineItem>();
            List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();

            for (QuoteLineItem qli : [  SELECT  Id, 
                                                PDE__r.TECH_num_compteur__c, 
                                                PrixHceMwh__c, 
                                                PrixHchMwh__c, 
                                                PrixHpeMwh__c, 
                                                PrixHphMwh__c,
                                                PointesMWh__c,
                                                UnitPrice,
                                                CeeMwh__c,
                                                Capa_HCE__c,
                                                Capa_HCH__c,
                                                Capa_HPE__c,
                                                Capa_HPH__c,
                                                Capa_Pointes__c,
                                                AbonnementMois__c,
                                                PrixMolecule__c,
                                                T_QuoteCEE__c
                                        FROM QuoteLineItem 
                                        WHERE QuoteId = :q.Id]) {
                qliByNumPdl.put(qli.PDE__r.TECH_num_compteur__c, qli);
            }

            // Parcours des compteurs renvoyés par Gazel
            for (GazelWebhookDTO.CompteurResponse cDto : payload.offre.compteurs) {
                if (qliByNumPdl.containsKey(cDto.num)) {
                    QuoteLineItem targetQli = qliByNumPdl.get(cDto.num);

                    targetQli.CeeMwh__c = targetQli.T_QuoteCEE__c == 'Soumis' ? cDto.prixCee : 0;

                    if (payload.offre.commodite == 1) { // Offre Elec
                        targetQli.Capa_HCE__c = (cDto.coefCapacite[0].coefficient * edc.Montant__c).setScale(2);
                        targetQli.Capa_HCH__c = (cDto.coefCapacite[0].coefficient * edc.Montant__c).setScale(2);
                        targetQli.Capa_HPE__c = (cDto.coefCapacite[0].coefficient * edc.Montant__c).setScale(2);
                        targetQli.Capa_HPH__c = (cDto.coefCapacite[0].coefficient * edc.Montant__c).setScale(2);
                        if (cDto.turpe != 'BTSUPCU4') {
                            targetQli.Capa_Pointes__c = (cDto.coefCapacite[0].coefficient * edc.Montant__c).setScale(2);
                        }

                        // Mapping des prix Electron (Postes A, B, C, D)
                        for (GazelWebhookDTO.PosteEnergie poste : cDto.prixElectron) {
                            Decimal finalPrice = extractValueFromPoste(poste.formulePrixEnergieValeur).setScale(2);
                            switch on poste.nom {
                                when 'HPH' { 
                                    targetQli.PrixHphMwh__c = finalPrice; 
                                    if (cDto.turpe != 'BTSUPCU4' && cDto.segment == 'C4') targetQli.PointesMWh__c = finalPrice;
                                }
                                when 'HCH' { targetQli.PrixHchMwh__c = finalPrice; }
                                when 'HPE' { targetQli.PrixHpeMwh__c = finalPrice; }
                                when 'HCE' { targetQli.PrixHceMwh__c = finalPrice; }
                                when 'PF' { targetQli.PointesMWh__c = finalPrice; }
                                when 'BASE' {
                                    targetQli.PrixHchMwh__c = finalPrice; 
                                    targetQli.PrixHpeMwh__c = finalPrice; 
                                    targetQli.PrixHceMwh__c = finalPrice; 
                                    targetQli.PrixHphMwh__c = finalPrice; 
                                    if (cDto.turpe != 'BTSUPCU4') targetQli.PointesMWh__c = finalPrice;
                                }
                            }
                        }
                    } else { // Offre Gaz
                      targetQli.AbonnementMois__c = cDto.abonnement.setScale(2);
                      targetQli.PrixMolecule__c= cDto.prixMolecule.setScale(2); 
                    }
                    
                    qlisToUpdate.add(targetQli);
                }
            }

            // Ajouter sur UNE SEULE QLI (la première) la commission estimée pour que ça remonte dans le grand total quote. 
            //C'est un hack pour compenser le fait que la commission n'est pas répartie par compteur dans le payload Gazel.
            // Hack Commission sur la première ligne
            if (!qlisToUpdate.isEmpty()) {
                qlisToUpdate[0].UnitPrice = payload.offre.commissionEstimee.setScale(2);
                update qlisToUpdate;
            }


        } else {
            // On affine le statut SF uniquement pour distinguer "Erreur" de "Action Manuelle"
            Set<Integer> errorCodes = new Set<Integer>{90, 120, 130, 133, 136, 300, 310};
    
            if (errorCodes.contains(statusCode)) {
                q.Api_status__c = 'Demande de prix rejetée par le fournisseur';
                q.Api_error_message__c = apiMessage + '. Error Code: ' + statusCode;
            } else {
                // Par défaut, si pas de données et pas une erreur franche, 
                // c'est une dérogation (20, 21, 60, 80...)
                q.Api_status__c = 'Demande de prix en attente d\'action manuelle';
                q.Api_error_message__c = apiMessage + '. Action Manuelle Code: ' + statusCode;
            }
        }

        update q;
    }

    private static String getProperSalutation(String salutation) {
        if (salutation == 'M') return 'Monsieur';
        if (salutation == 'MME') return 'Madame';
        return salutation;
    }

    private static Datetime toUtcDatetime(Date d) {
        return Datetime.newInstanceGmt(d.year(), d.month(), d.day());
    }

    /**
    * Logique pour trouver quelle clé (A, B, C ou D) contient le prix
    */
    private static Decimal extractValueFromPoste(GazelWebhookDTO.FormulePrixEnergieValeur f) {
        if (f == null) return 0;
        // On retourne la première valeur non nulle rencontrée parmi A, B, C, D
        if (f.a != null && f.a != 0) return f.a;
        if (f.b != null && f.b != 0) return f.b;
        if (f.c != null && f.c != 0) return f.c;
        if (f.d != null && f.d != 0) return f.d;
        return 0;
    }
}