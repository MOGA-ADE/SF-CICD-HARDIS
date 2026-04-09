global with sharing class AP021_CreateQuoteQLIGrille {

    @InvocableMethod(label='Créer Quote depuis Wrapper')
    public static List<FlowOutput> creationQuoteQLI(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        FlowOutput output = new FlowOutput();
        Id oppId = inputs[0].opportunityId;

        // --- SUPPRESSION DES DOUBLONS ---
        Set<String> fournisseursCibles = new Set<String>();
        Set<String> dureesCibles = new Set<String>();

        for(FlowInput input : inputs) {
            for (WrapCreationQuoteGrille w : input.wrappers) {
                if (String.isNotBlank(w.fournisseurs)) fournisseursCibles.add(w.fournisseurs);
                if (String.isNotBlank(w.duree)) {
                    for(String d : w.duree.split(';')) {
                        String cleanDuree = d.split('_')[0].trim();
                        dureesCibles.add(cleanDuree); 
                    }
                }
            }
        }

        // On récupère les quotes et leurs Qli pour avoir la durée
        List<Quote> quotesToDelete = [SELECT Id, Name, Fournisseur__c, 
                                    (SELECT DureeEngagement__c FROM QuoteLineItems LIMIT 1) 
                                    FROM Quote 
                                    WHERE OpportunityId = :oppId 
                                    AND Fournisseur__c IN :fournisseursCibles
                                    AND Calcul_grille__c = true];

        List<Quote> toDelete = new List<Quote>();

        for(Quote oldQ : quotesToDelete) {

            if (oldQ.Fournisseur__c == 'Ekwateur' || oldQ.Fournisseur__c == 'Ilek') {

                toDelete.add(oldQ);
                continue; 
            }

            if (!oldQ.QuoteLineItems.isEmpty()) {
                Decimal existingDuree = oldQ.QuoteLineItems[0].DureeEngagement__c;
                
                if (existingDuree != null) {
                    String existingDureeStr = String.valueOf(existingDuree.intValue());

                    // Vérification de la correspondance
                    if (dureesCibles.contains(existingDureeStr)) {
                        toDelete.add(oldQ);
                    } else {
                    }
                } else {
                    System.debug('ATTENTION : DureeEngagement__c est NULL sur la QLI de cette Quote.');
                }
            } else {
                System.debug(' ATTENTION : Aucun QuoteLineItem trouvé pour cette Quote.');
            }
        }

        if(!toDelete.isEmpty()) {
            delete toDelete;
        }  
       
        Integer dureeEngagement = 0;
        List<Quote> allQuotesToInsert = new List<Quote>();
        List<QuoteLineItem> allQLIToInsert = new List<QuoteLineItem>();
        List<QuoteContext> contexts = new List<QuoteContext>();

        // Requête PDE
        Valeur_Annuelle__mdt customMetadataRecord = [SELECT CTA_T1__c,
                                                    CTA_T2__c,
                                                    CTA_T3__c,
                                                    CTA_T4__c,
                                                    CSPE_PuissanceInfOuEgal36Kva__c,
                                                    CSPE_PuissanceSup36OuEgal250__c,
                                                    CSPE_PuissanceSup250__c,
                                                    Frais_Transport_Distribution_Capacite_T1__c,
                                                    Frais_Transport_Distribution_Capacite_T2__c,
                                                    Frais_Transport_Distribution_Capacite_T3__c,
                                                    Frais_Transport_Distribution_Capacite_T4__c
                                                FROM 
                                                    Valeur_Annuelle__mdt
                                                LIMIT 1];

        List<OpportunityPDERelation__c> pdeRelations = [
            SELECT PDE__c,
                Opportunity__r.Name,
                Opportunity__r.Id,
                Opportunity__r.TECH_FTA__c,
                Opportunity__r.Liste_fournisseurs__c,
                PDE__r.RecordType.Name,
                PDE__r.Puissance_souscrite__c,
                PDE__r.Tarif__c,
                PDE__r.TypePDE__c,
                PDE__r.ConsoHC__c,
                PDE__r.ConsoHP__c,
                PDE__r.Conso_Base__c,
                PDE__r.Conso_HCE__c,
                PDE__r.Conso_HCH__c,
                PDE__r.Conso_HPE__c,
                PDE__r.Conso_HPH__c,
                PDE__r.Conso_Pointe__c,
                PDE__r.EntiteJuridique__c,
                PDE__r.EntiteJuridique__r.CEE__c,
                PDE__r.EntiteJuridique__r.TECH_last_credit_score__c, 
                PDE__r.Segment__c, 
                PDE__r.EntiteJuridique__r.ELLISPHERE__Elli_code_ape08__c, 
                PDE__r.Fournisseur__c, 
                PDE__r.DateEcheance__c,
                PDE__r.Calendrier_fournisseur__c,
                PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c,
                PDE__r.CARGaz__c
            FROM OpportunityPDERelation__c 
            WHERE Opportunity__c = :oppId
        ];
        Pricebook2 pb = [SELECT Id, IsActive, Name FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'AllianceDesEnergies' LIMIT 1];
        RecordType RtElec = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Elec' AND SobjectType = 'Quote' LIMIT 1];
        RecordType RtGaz = [SELECT id, DeveloperName, SobjectType FROM RecordType WHERE DeveloperName = 'Quote_Gaz' AND SobjectType = 'Quote' LIMIT 1];
        PricebookEntry entryGaz = [SELECT Id, Name, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Name = 'GAZ' AND Pricebook2Id = :pb.Id LIMIT 1];
        PricebookEntry entryElec = [SELECT Id, Name, Pricebook2Id, Product2Id FROM PricebookEntry WHERE Name = 'ELEC' AND Pricebook2Id = :pb.Id LIMIT 1];

        if(pdeRelations.isEmpty()) {
            System.debug('ATTENTION : Aucune PDE trouvée pour l\'opportunité ' + oppId);
        } 

        if (!pdeRelations.isEmpty()) {
            // Récupérer l'opportunité à jour
            Opportunity oppToUpdate = new Opportunity(Id = oppId);
            
            // Récupérer la liste existante des fournisseurs
            Set<String> existingFournisseurs = new Set<String>();
            if (pdeRelations[0].Opportunity__r.Liste_fournisseurs__c != null) {
                String existingList = pdeRelations[0].Opportunity__r.Liste_fournisseurs__c;
                // Splitter la liste existante si elle contient des séparateurs
                if (existingList.contains(';')) {
                    existingFournisseurs.addAll(existingList.split(';'));
                } else {
                    existingFournisseurs.add(existingList);
                }
            }
            
            
            // Ajouter les nouveaux fournisseurs du wrapper
            for (WrapCreationQuoteGrille w : inputs[0].wrappers) {
                if (String.isNotBlank(w.fournisseurs)) {
                    existingFournisseurs.add(w.fournisseurs);
                }
            }
            
            
            // Reconstruire la liste avec séparateur point-virgule
            List<String> fournisseursList = new List<String>(existingFournisseurs);
            oppToUpdate.Liste_fournisseurs__c = String.join(fournisseursList, ';');
            oppToUpdate.bypassGrill__c = true;

            
            // Mettre à jour l'opportunité
            update oppToUpdate;
        }

        for(FlowInput input : inputs) {
            
            List<WrapCreationQuoteGrille> wrappers = input.wrappers;
            
            // On boucle sur chaque ligne du wrapper (chaque fournisseur)
            for (WrapCreationQuoteGrille w : input.wrappers) {

                // Si la durée est vide , on peut décider de l'ignorer ou de gérer un cas par défaut
                if (String.isBlank(w.duree) ) {
                    System.debug('Durée vide ou nulle pour fournisseur ' + w.fournisseurs + ' - IGNORÉ');
                    continue; 
                }
                
                // On split la chaîne "12;24;36" en une liste ['12', '24', '36']
                List<String> durees = w.duree.split(';');


                for (String d : durees) {
                    String quoteName = '';

                    Quote q = new Quote();
                    q.OpportunityId = input.opportunityId;
                    // Nom de la quote dynamique
                    quoteName = w.fournisseurs.toUpperCase() + ' - ' + pdeRelations[0].Opportunity__r.Name;
                    //q.RecordTypeId = pdeRelations[0].Opportunity__r.TECH_FTA__c == 'Gaz' ? RtGaz.Id : RtElec.Id;
                    q.Pricebook2Id = pb.Id;
                    q.Name = quoteName;
                    q.Calcul_grille__c = true;
                    if (pdeRelations[0].PDE__r.EntiteJuridique__r.CEE__c == 'Soumis' && (w.fournisseurs == 'Engie' || w.fournisseurs == 'TotalEnergies'||w.fournisseurs == 'Vattenfall'|| w.fournisseurs == 'Ilek'|| w.fournisseurs == 'Ekwateur')) {
                        q.CEE__c = 'Inclus';
                    }else {
                        q.CEE__c = pdeRelations[0].PDE__r.EntiteJuridique__r.CEE__c;

                    }

                    
                    if (w.fournisseurs == 'Ilek') {
                        q.CAPA__c = 'Inclus'; 
                        q.TURPE__c = 'Inclus';
                    }
                    q.Fournisseur__c = w.fournisseurs; 
                    q.Date_de_fin_de_contrat__c = date.today();

                    
                    if (String.isNotBlank(w.marge)) {
                        System.debug('Marge avant conversion : ' + w.marge);
                        //mapQuoteToMarge.put(q, w.marge);
                    }

                    QuoteContext ctx = new QuoteContext();
                    ctx.quote = q;
                    ctx.duree = d;
                    ctx.marge = w.marge;

                    contexts.add(ctx);
                    allQuotesToInsert.add(q);
                }
                
            }
        }
        
        if (!allQuotesToInsert.isEmpty()) {

            for (Database.SaveResult sr : Database.insert(allQuotesToInsert)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors().get(0).getMessage();
                    outputs.add(output);    
                    return outputs;  
                }
            }
                // contexts va contenir pour chaque quote  la quote elle même, la durée associée et la marge associée
            for (QuoteContext ctx : contexts) {
            
                
                Quote newQuote = ctx.quote;
                String dureeInfo = ctx.duree;
                String margeInfo = ctx.marge;


                for (OpportunityPDERelation__c pdeRel : pdeRelations) {

                    QuoteLineItem qli = new QuoteLineItem();
                    String labelCode = '';
                    qli.QuoteId = newQuote.Id; // Liaison à la Quote fraîchement créée
                    qli.PDE__c = pdeRel.PDE__c; // Liaison au PDE
                    System.debug('Date de debut FOURNITURE : ' + pdeRel.PDE__r.DateEcheance__c.addDays(1));
                    qli.DebutDeFourniture__c = pdeRel.PDE__r.DateEcheance__c.addDays(1);



                    if (!String.isBlank(dureeInfo)) {

                        List<String> parts = dureeInfo.trim().split('_');

                        if (!parts.isEmpty() && String.isNotBlank(parts[0])) {
                            dureeEngagement = Integer.valueOf(parts[0]);
                        }
                    }                    

                    if (ctx.quote.Fournisseur__c == 'Ekwateur') {
                        if (pdeRel.PDE__r.RecordType.Name == 'Gaz') {
                             labelCode = 'T1T2T3_' + Date.today().year() + '_' + ctx.marge;
                        } else if ((pdeRel.PDE__r.RecordType.Name.contains('Elec'))) {
                             labelCode = 'C5_' + Date.today().year() + '_' + ctx.marge;
                        }

                        Grille_Ekwateur__mdt grilleEkwateur = Grille_Ekwateur__mdt.getinstance(labelCode);
                        
                        Integer moisEcheance = (pdeRel.PDE__r.DateEcheance__c.monthsBetween(grilleEkwateur.Date_fin__c)) -1 ;
                        if (grilleEkwateur != null) {
                            qli.Nouvelle_Echeance__c = grilleEkwateur.Date_fin__c;
                            qli.DureeEngagement__c = moisEcheance;
                        } 
                    }else{
                        Date Nouvelle_Echeance = pdeRel.PDE__r.DateEcheance__c.addMonths(dureeEngagement == null ? 0 : Integer.valueOf(dureeEngagement));
                        qli.Nouvelle_Echeance__c = Nouvelle_Echeance;

                        if ((ctx.quote.Fournisseur__c == 'Engie'|| ctx.quote.Fournisseur__c == 'GEG') && (pdeRel.PDE__r.DateEcheance__c.addDays(1).day() != 1) ) {

                            qli.Nouvelle_Echeance__c = Nouvelle_Echeance.toStartOfMonth().addDays(-1);
                        }


                        qli.DureeEngagement__c = dureeEngagement;                   
                    }

                    
                    qli.Product2Id = entryElec.Product2Id;
                    qli.PricebookEntryId= entryElec.Id;
                    qli.UnitPrice = 0;
                    qli.Quantity = 1;
                    qli.Opportunit__c = pdeRel.Opportunity__r.Id;
                    qli.ConsoHC__c = pdeRel.PDE__r.ConsoHC__c;
                    qli.ConsoHP__c = pdeRel.PDE__r.ConsoHP__c;
                    qli.Conso_Base__c = pdeRel.PDE__r.Conso_Base__c;
                    qli.Conso_HCE__c = pdeRel.PDE__r.Conso_HCE__c;
                    qli.Conso_HCH__c = pdeRel.PDE__r.Conso_HCH__c;
                    qli.Conso_HPE__c = pdeRel.PDE__r.Conso_HPE__c;
                    qli.Conso_HPH__c = pdeRel.PDE__r.Conso_HPH__c;
                    qli.Conso_Pointe__c = pdeRel.PDE__r.Conso_Pointe__c;
                    qli.Puissance_souscrite__c = pdeRel.PDE__r.Puissance_souscrite__c;
                    qli.CAR_New__c = pdeRel.PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c;
                    qli.CARGaz__c = pdeRel.PDE__r.CARGaz__c;
                    if(pdeRel.PDE__r.Calendrier_fournisseur__c == 'HP/HC' || pdeRel.PDE__r.Calendrier_fournisseur__c == 'Heures Pleines/Creuses'){
                        qli.TECH_CalendrierFournisseur__c = 'HP/HC';
                    }
                    else if(pdeRel.PDE__r.Calendrier_fournisseur__c == 'Base' || pdeRel.PDE__r.Calendrier_fournisseur__c != ''){
                        qli.TECH_CalendrierFournisseur__c = 'Base';
                    }
                    if (pdeRel.PDE__r.TypePDE__c == 'Gaz') {
                        if(pdeRel.PDE__r.Tarif__c == 'T1'){
                        qli.CTA__c = customMetadataRecord.CTA_T1__c;
                        qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T1__c;
                        } else if(pdeRel.PDE__r.Tarif__c == 'T2'){
                        qli.CTA__c = customMetadataRecord.CTA_T2__c;
                        qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T2__c;
                        } else if(pdeRel.PDE__r.Tarif__c == 'T3'){
                        qli.CTA__c = customMetadataRecord.CTA_T3__c;
                        qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T3__c;
                        } else if(pdeRel.PDE__r.Tarif__c == 'T4'){
                        qli.CTA__c = customMetadataRecord.CTA_T4__c;
                        qli.FraisTransportDistributionCapacite__c = customMetadataRecord.Frais_Transport_Distribution_Capacite_T4__c;
                        } else {
                        qli.CTA__c = 1;
                        qli.FraisTransportDistributionCapacite__c = 1;
                        }
                    }
                    else{

                        if(pdeRel.PDE__r.Puissance_souscrite__c <= 36){
                        qli.CSPE__c = customMetadataRecord.CSPE_PuissanceInfOuEgal36Kva__c;
                        }
                        else if (pdeRel.PDE__r.Puissance_souscrite__c > 36 && pdeRel.PDE__r.Puissance_souscrite__c <= 250 ){
                        qli.CSPE__c = customMetadataRecord.CSPE_PuissanceSup36OuEgal250__c;
                        }
                        else {
                        qli.CSPE__c = customMetadataRecord.CSPE_PuissanceSup250__c;
                        }
                    }

                    allQLIToInsert.add(qli);
                }
                
            }

            
            if (!allQLIToInsert.isEmpty()) {
                for (Database.SaveResult sr : Database.insert(allQLIToInsert)) {
                    if (!sr.isSuccess()) {
                        output.success = false;
                        output.message = sr.getErrors().get(0).getMessage();
                        outputs.add(output);    
                        return outputs;
                    }
                }
                Opportunity oppToUpdate = new Opportunity(Id = oppId);

                oppToUpdate.bypassGrill__c = false;
                update oppToUpdate;


                Boolean hasErrors = false;
                String errorMessages = '';

                for ( QuoteContext ctx : contexts) {
                   
                    try {
                        List<AP021_GrilleFournisseur.FlowInput> inputList = new List<AP021_GrilleFournisseur.FlowInput>();
                        AP021_GrilleFournisseur.FlowInput inputPourCalcul = new AP021_GrilleFournisseur.FlowInput();
                        Decimal margeValue = String.isNotBlank(ctx.marge) ? Decimal.valueOf(ctx.marge.replace(',', '.')) : 0;

                        inputPourCalcul.recordId = ctx.quote.Id;
                        inputPourCalcul.fournisseur = ctx.quote.Fournisseur__c;
                        inputPourCalcul.dureeOffre = ctx.duree;
                        inputPourCalcul.margeMwh = margeValue;
                        inputList.add(inputPourCalcul);
                        List<AP021_GrilleFournisseur.FlowOutput> results = AP021_GrilleFournisseur.GET_Prix(inputList);
                        if (results != null && !results.isEmpty()) {
                             if (results.get(0).success != true) {
                                output.success = false;
                                output.message = results.get(0).message;
                            }
                        }
                            
                    
                    } catch (Exception e) {

                        hasErrors = true;
                        errorMessages += 'Exception pour ' + ctx.quote.Fournisseur__c + ' : ' + e.getMessage() + '\n';                    }                          
                }
                if (hasErrors) {
                    output.success = false;
                    output.message = 'Des erreurs sont survenues lors du calcul des prix :\n' + errorMessages;
                } else {
                    output.success = true;
                    output.message = 'Les devis et QLI compatibles ont été mis à jour avec succès';
                }

            } else {
                output.success = false;
                output.message = 'ATTENTION : Aucun QLI à insérer' ;
            }
        }else {
            output.success = false;
            output.message = 'ATTENTION : Aucun devis à insérer' ;
        }
        outputs.add(output);
        return outputs;
    }

    
    global class FlowInput {
        @InvocableVariable(required=true)
        public Id opportunityId;
        @InvocableVariable(required=true)
        public List<WrapCreationQuoteGrille> wrappers;
    }
    public class FlowOutput {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }

      class QuoteContext {
        public Quote quote;
        public String duree;
        public String marge;
    }

}