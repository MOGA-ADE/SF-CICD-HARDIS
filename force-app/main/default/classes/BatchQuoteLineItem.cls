/*

Ce batch permet de relancer tous les calculs de budget sur toutes les QLI selon la clause WHERE donnée en entrée


*/
global class BatchQuoteLineItem implements Database.Batchable<sObject>, Database.Stateful {

    public Boolean isFirstTime = true;
    public Valeur_Annuelle__mdt valeurAnnuelle;
    public List<TURPE__mdt> listTURPE;
    public String WhereQuery,finalQuery;
    public List<QuoteLineItem> updatedQLIs = new List<QuoteLineItem>();

    global Database.QueryLocator start(Database.BatchableContext BC) {
        // Déclaration de la base de la requête
        String baseQuery = 'SELECT BudgetHTTan__c, BudgetFourniture__c, Budget_Acheminement_Annuel_HTT__c, ' +
                           'Budget_Taxes_annuel_HTVA__c, TECH_RT__c, TECH_MU_CU__c, ' +
                           'PrixHceMwh__c, PrixHchMwh__c, PrixHpeMwh__c, PrixHphMwh__c, PointesMWh__c, ' +
                           'PrixMolecule__c, PrixHP__c, PrixHC__c, PrixBase__c, Puissance_souscrite__c, ' +
                           'Conso_HCE__c, Conso_HCH__c, Conso_HPE__c, Conso_HPH__c, Conso_Pointe__c, ' +
                           'ConsoHP__c, ConsoHC__c, Conso_Base__c, Capa_HPH__c, Capa_HCH__c, Capa_HPE__c, ' +
                           'Capa_HCE__c, Capa_Pointes__c, Capa_Base__c, Capa_HP__c, Capa_HC__c, CSPE__c, ' +
                           'CTA__c, CTA_new__c, CeeMwh__c, CARGaz__c, FraisTransportDistributionCapacite__c, ' +
                           'AbonnementMois__c, TCCFE__c, TDCFE__c, TECH_TCFE__c, TECH_FTA__c, ' +
                           'PDE__r.TECH_C5_4Postes__c, PDE__r.Segment__c, PDE__r.RecordType.DeveloperName, ' +
                           'PDE__r.Puissance_souscrite__c, Quote.TURPE__c, TICGN__c ' +
                           'FROM QuoteLineItem';
    
        finalQuery = baseQuery + WhereQuery;
    
        System.debug('SOQL Query: ' + finalQuery);
        
        return Database.getQueryLocator(finalQuery);
    }
    

    global void execute(Database.BatchableContext BC, List<QuoteLineItem> scope) {
        valeurAnnuelle = Valeur_Annuelle__mdt.getInstance('Valeur');
        listTURPE = TURPE__mdt.getAll().values();
        try {
            for(QuoteLineItem qli : scope){
                QuoteLineItem newQLI = new QuoteLineItem(Id = qli.Id);
                Decimal budgetFourniture =  formulaBudgetFourniture(qli);
                newQLI.BudgetFourniture__c = budgetFourniture.setScale(2);
                newQLI.BudgetObligationsMWH__c = formulaBudgetObligationsMWH(qli).setScale(2);
                newQLI.CAR_New__c = formulaCARNew(qli).setScale(2);
                newQLI.TECH_Budget__c = formulaBudgetHTTAn(qli).setScale(2);//qli.BudgetHTTan__c;
                newQLI.TURPE_Fixe__c = formulaTURPEFixe(qli).setScale(2);
                newQLI.TURPE_Variable__c = formulaTURPEVariable(qli).setScale(2);
                newQLI.TVA__c = formulaTVA(qli).setScale(2);
                newQLI.Budget_TTC__c = formulaBudgetTTC(qli).setScale(2);
                newQLI.CoutDeCapacite__c = formulaCoutDeCapacite(qli).setScale(2);
                newQLI.Conso_HCE__c = qli.Conso_HCE__c;
                newQLI.Conso_HCH__c = qli.Conso_HCH__c;
                newQLI.Conso_HPE__c = qli.Conso_HPE__c;
                newQLI.Conso_HPH__c = qli.Conso_HPH__c;
                newQLI.Conso_Pointe__c = qli.Conso_Pointe__c;
                newQLI.Puissance_souscrite__c = qli.Puissance_souscrite__c;
                newQLI.Conso_Base__c = qli.Conso_Base__c;
                newQLI.ConsoHP__c = qli.ConsoHP__c;
                newQLI.ConsoHC__c = qli.ConsoHC__c;
                newQLI.CTA_Mensuel_ELEC__c = formulaCTAMensuel(qli).setScale(2);
                updatedQLIs.add(newQLI);
            }
        }
        catch (Exception e) {
            System.debug('Calcul du budget impossible: ' + e.getMessage());
            System.debug('Stack : ' + e.getStackTraceString());    
        }

    }

    global void finish(Database.BatchableContext BC){
        if (!updatedQLIs.isEmpty()) {
            update updatedQLIs;
        }
    }

    // Calcul methods
    private Decimal formulaBudgetFourniture(QuoteLineItem qli) {
        if(qli.TECH_RT__c == 'Elec_C1C2' || qli.TECH_RT__c == 'Elec_C3_C4'){
            return 
            (qli.AbonnementMois__c * 12) +
            (qli.PrixHceMwh__c * qli.Conso_HCE__c) +
            (qli.PrixHchMwh__c * qli.Conso_HCH__c) +
            (qli.PrixHpeMwh__c * qli.Conso_HPE__c) +
            (qli.PrixHphMwh__c * qli.Conso_HPH__c) +
            (qli.PointesMWh__c * qli.Conso_Pointe__c);
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' && (qli.TECH_MU_CU__c == 'CU' || qli.TECH_FTA__c == 'BT <= 36 kVA - LU EP') &&  !qli.pde__r.TECH_C5_4Postes__c){
            return 
            (qli.AbonnementMois__c * 12) + 
            (qli.Conso_Base__c * qli.PrixBase__c);
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' && qli.TECH_MU_CU__c == 'MU' &&  !qli.pde__r.TECH_C5_4Postes__c){
            return
            (qli.AbonnementMois__c * 12) + 
            (qli.ConsoHP__c * qli.PrixHP__c ) + 
            (qli.ConsoHC__c * qli.PrixHC__c);
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' &&  qli.pde__r.TECH_C5_4Postes__c){
            return
            ( qli.AbonnementMois__c * 12) +
            ( qli.PrixHceMwh__c * qli.Conso_HCE__c) +
            ( qli.PrixHchMwh__c * qli.Conso_HCH__c) +
            ( qli.PrixHpeMwh__c * qli.Conso_HPE__c) +
            ( qli.PrixHphMwh__c * qli.Conso_HPH__c);
        }
        else if(qli.TECH_RT__c == 'PDE_Gaz'){
            return 
            (qli.AbonnementMois__c*12) + 
            (qli.PrixMolecule__c * qli.CARGaz__c) + 
            (qli.FraisTransportDistributionCapacite__c * qli.CARGaz__c);
        }
        else{
            return 0.0;
        }
    }

    private Decimal formulaBudgetObligationsMWH(QuoteLineItem qli) {
        if(qli.TECH_RT__c == 'Elec_C1C2' || qli.TECH_RT__c == 'Elec_C3_C4'){
                return 
                (qli.CeeMwh__c * formulaCARNew(qli)) +
                (qli.Capa_HPH__c * qli.Conso_HPH__c) +
                (qli.Capa_HCH__c * qli.Conso_HCH__c) +
                (qli.Capa_HPE__c * qli.Conso_HPE__c) +
                (qli.Capa_HCE__c * qli.Conso_HCE__c) +
                (qli.Capa_Pointes__c * qli.Conso_Pointe__c);
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' && (qli.TECH_MU_CU__c == 'CU' || qli.TECH_FTA__c == 'BT <= 36 kVA - LU EP') &&  !qli.pde__r.TECH_C5_4Postes__c){
            return
            (qli.CeeMwh__c * formulaCARNew(qli)) +
            (qli.Capa_Base__c * formulaCARNew(qli));

        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' && qli.TECH_MU_CU__c == 'MU' &&  !qli.pde__r.TECH_C5_4Postes__c){
            return
            (qli.CeeMwh__c * formulaCARNew(qli)) +
            (qli.Capa_HP__c * qli.ConsoHP__c) +
            (qli.Capa_HC__c * qli.ConsoHC__c);
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' &&  qli.pde__r.TECH_C5_4Postes__c){
            return
            (qli.CeeMwh__c * formulaCARNew(qli)) +
            (qli.Capa_HPH__c * qli.Conso_HPH__c) +
            (qli.Capa_HCH__c * qli.Conso_HCH__c) +
            (qli.Capa_HPE__c * qli.Conso_HPE__c) +
            (qli.Capa_HCE__c * qli.Conso_HCE__c);
        }
        else if(qli.TECH_RT__c == 'PDE_Gaz'){
            return 
            (qli.CeeMwh__c * qli.CARGaz__c ) +
            (qli.TICGN__c * qli.CARGaz__c) +
            (qli.CTA__c * 12);
        }
        else{
            return 0.0;
        }
    }

    private Decimal formulaBudgetTTC(QuoteLineItem qli) {
        return formulaTVA(qli) + formulaBudgetHTTAn(qli);
    }

    private Decimal formulaCARNew(QuoteLineItem qli) {
        if(qli.TECH_RT__c == 'Elec_C1C2' || qli.TECH_RT__c == 'Elec_C3_C4'){
            return 
            qli.Conso_Pointe__c +
            qli.Conso_HPH__c +
            qli.Conso_HCH__c +
            qli.Conso_HPE__c +
            qli.Conso_HCE__c;
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' && (qli.TECH_MU_CU__c == 'CU' || qli.TECH_FTA__c == 'BT <= 36 kVA - LU EP') &&  !qli.pde__r.TECH_C5_4Postes__c){
            return qli.Conso_Base__c;        
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' && qli.TECH_MU_CU__c == 'MU' &&  !qli.pde__r.TECH_C5_4Postes__c){
            return qli.ConsoHP__c + qli.ConsoHC__c;
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' &&  qli.pde__r.TECH_C5_4Postes__c){
            return
            qli.Conso_HPH__c +
            qli.Conso_HCH__c +
            qli.Conso_HPE__c +
            qli.Conso_HCE__c;
        }
        // else if(qli.TECH_RT__c == 'PDE_Gaz'){
        //     return 
        //     (qli.AbonnementMois__c*12) + 
        //     (qli.PrixMolecule__c * qli.CARGaz__c) + 
        //     (qli.FraisTransportDistributionCapacite__c * qli.CARGaz__c);
        // }
        else{
            return 0.0;
        }
    }

    private Decimal formulaTVA(QuoteLineItem qli) {
        if(qli.TECH_RT__c == 'Elec_C1C2' || qli.TECH_RT__c == 'Elec_C3_C4'){
            return formulaBudgetHTTAn(qli) * valeurAnnuelle.TVA2__c;
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' && (qli.TECH_MU_CU__c == 'CU' || qli.TECH_FTA__c == 'BT <= 36 kVA - LU EP') &&  !qli.pde__r.TECH_C5_4Postes__c){
            return 
            (((qli.AbonnementMois__c + formulaCTAMensuel(qli) + formulaTURPEFixe(qli)) * 12 ) * valeurAnnuelle.TVA1__c ) +
            (formulaCARNew(qli) * (qli.CSPE__c +  qli.TECH_TCFE__c + qli.CeeMwh__c + qli.PrixBase__c + qli.Capa_Base__c + formulaTURPEVariable(qli))) * 
            valeurAnnuelle.TVA2__c;
            // (((qli.AbonnementMois__c + formulaCTAMensuel(qli)) * 12 ) * valeurAnnuelle.TVA1__c ) +
            // ((qli.Conso_Base__c * qli.PrixBase__c) + (qli.CeeMwh__c * formulaCARNew(qli)) + (qli.CSPE__c * formulaCARNew(qli)) + (qli.TECH_TCFE__c * formulaCARNew(qli))) * 
            // valeurAnnuelle.TVA2__c;
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' && qli.TECH_MU_CU__c == 'MU' &&  !qli.pde__r.TECH_C5_4Postes__c){
            return
            (((qli.AbonnementMois__c + formulaCTAMensuel(qli)  + formulaTURPEFixe(qli) ) * 12) * valeurAnnuelle.TVA1__c) +
            (
                (qli.ConsoHP__c * qli.PrixHP__c) + 
                (qli.ConsoHC__c * qli.PrixHC__c) + 
                (qli.ConsoHP__c * qli.Capa_HP__c) +
                (qli.ConsoHC__c * qli.Capa_HC__c) +
                formulaCARNew(qli) * (qli.CeeMwh__c + qli.CSPE__c + qli.TECH_TCFE__c + formulaTURPEVariable(qli))
            ) * valeurAnnuelle.TVA2__c;
            // (((qli.AbonnementMois__c + formulaCTAMensuel(qli)) * 12) * valeurAnnuelle.TVA1__c) +
            // ((qli.ConsoHP__c * qli.PrixHP__c) + (qli.ConsoHC__c * qli.PrixHC__c) + (qli.CeeMwh__c * formulaCARNew(qli)) + (qli.CSPE__c * formulaCARNew(qli)) + (qli.TECH_TCFE__c * formulaCARNew(qli))) *
            // valeurAnnuelle.TVA2__c;
        }
        else if (qli.TECH_RT__c == 'PDE_ElecC5' &&  qli.pde__r.TECH_C5_4Postes__c){
            return
            (((qli.AbonnementMois__c + formulaCTAMensuel(qli) + formulaTURPEFixe(qli)) * 12) * valeurAnnuelle.TVA1__c) +
            ((
                (qli.PrixHceMwh__c * qli.Conso_HCE__c) + 
                (qli.PrixHchMwh__c * qli.Conso_HCH__c) + 
                (qli.PrixHpeMwh__c * qli.Conso_HPE__c) + 
                (qli.PrixHphMwh__c * qli.Conso_HPH__c) +
                (qli.Capa_HCE__c * qli.Conso_HCE__c) + 
                (qli.Capa_HCH__c * qli.Conso_HCH__c) + 
                (qli.Capa_HPE__c * qli.Conso_HPE__c) + 
                (qli.Capa_HPH__c * qli.Conso_HPH__c) +
                formulaCARNew(qli) * (qli.CeeMwh__c + qli.CSPE__c + qli.TECH_TCFE__c + formulaTURPEVariable(qli))
                ) * valeurAnnuelle.TVA2__c);
            // (((qli.AbonnementMois__c + formulaCTAMensuel(qli)) * 12) * valeurAnnuelle.TVA1__c) +
            // (((qli.PrixHceMwh__c * qli.Conso_HCE__c) + (qli.PrixHchMwh__c * qli.Conso_HCH__c) + (qli.PrixHpeMwh__c * qli.Conso_HPE__c) + (qli.PrixHphMwh__c * qli.Conso_HPH__c) + (qli.CeeMwh__c * formulaCARNew(qli)) + (qli.CSPE__c * formulaCARNew(qli)) + (qli.TECH_TCFE__c * formulaCARNew(qli))) * valeurAnnuelle.TVA2__c);
        }
        else if(qli.TECH_RT__c == 'PDE_Gaz'){
            return 
            (((qli.AbonnementMois__c * 12) + (qli.CTA__c * 12)) * valeurAnnuelle.TVA1__c ) +
            (((qli.PrixMolecule__c * qli.CARGaz__c) +
            (qli.FraisTransportDistributionCapacite__c * qli.CARGaz__c ) +
            (qli.CeeMwh__c * qli.CARGaz__c)+
            (qli.TICGN__c * qli.CARGaz__c)) * valeurAnnuelle.TVA2__c);
        }
        else{
            return 0.0;
        }
    }

    private Decimal formulaTURPEFixe(QuoteLineItem qli) {
        if(qli.quote.TURPE__c == 'Non inclus'){
            for(TURPE__mdt turpe : listTURPE){
                if(turpe.Segment__c == qli.PDE__r.Segment__c && turpe.FTA__c == qli.TECH_FTA__c){
                    return
                    ((turpe.Composant_de_Comptage__c + 
                    turpe.Composant_de_Gestion__c +
                    (turpe.Composant_de_Soutirage_Part_Fixe__c ) * qli.Puissance_souscrite__c )
                    )/12;
                   }
            }
        }
        return 0.0;
    }

    private Decimal formulaTURPEVariable(QuoteLineItem qli) {
        if(qli.quote.TURPE__c == 'Non inclus'){
            for(TURPE__mdt turpe : listTURPE){
                if(turpe.Segment__c == qli.PDE__r.Segment__c && turpe.FTA__c == qli.TECH_FTA__c){
                    if (qli.PDE__r.RecordType.DeveloperName == 'PDE_ElecC5' && qli.TECH_MU_CU__c == 'MU' && !qli.PDE__r.TECH_C5_4Postes__c){
                        return
                        ((turpe.CSPV_HC__c * qli.ConsoHC__c) +
                        (turpe.CSPV_HP__c * qli.ConsoHP__c)) / 
                        formulaCARNew(qli);
                    }
                    else if(qli.TECH_RT__c == 'Elec_C1C2' || qli.TECH_RT__c == 'Elec_C3_C4'){
                        return 
                        ((turpe.CSPV_HPH__c * qli.Conso_HPH__c) +
                        (turpe.CSPV_HCH__c * qli.Conso_HCH__c) +
                        (turpe.CSPV_HPE__c * qli.Conso_HPE__c) +
                        (turpe.CSPV_HCE__c * qli.Conso_HCE__c) +
                        (turpe.CSPV_PTE__c * qli.Conso_Pointe__c)) /
                        formulaCARNew(qli);
                    }
                    else if (qli.PDE__r.RecordType.DeveloperName == 'PDE_ElecC5' && (qli.TECH_MU_CU__c == 'CU' || qli.TECH_FTA__c == 'BT <= 36 kVA - LU EP' || qli.TECH_MU_CU__c == 'MU') && !qli.PDE__r.TECH_C5_4Postes__c){
                        return 
                        (turpe.CSPV_Base__c * qli.Conso_Base__c) /
                        formulaCARNew(qli);
                    }
                    else if (qli.PDE__r.RecordType.DeveloperName == 'PDE_ElecC5' && (qli.TECH_MU_CU__c =='CU' || qli.TECH_MU_CU__c == 'MU') && qli.PDE__r.TECH_C5_4Postes__c){
                        return
                        ((turpe.CSPV_HPH__c * qli.Conso_HPH__c) +
                        (turpe.CSPV_HCH__c * qli.Conso_HCH__c) +
                        (turpe.CSPV_HPE__c * qli.Conso_HPE__c) +
                        (turpe.CSPV_HCE__c * qli.Conso_HCE__c)) / 
                        formulaCARNew(qli);
                    }
                    else{
                        return 0.0;
                    }
                }
            }
        }
        return 0.0;
    }

    private Decimal formulaBudgetHTTAn(QuoteLineItem qli){
        return
        formulaBudgetFourniture(qli) + formulaBudgetObligationsMWH(qli) + formulaBudgetAcheminementAnnuelHTT(qli) + formulaBudgetTaxesAnnuelHTVA(qli);
    }

    private Decimal formulaBudgetAcheminementAnnuelHTT(QuoteLineItem qli){
        return (formulaTURPEFixe(qli)  * 12) + (formulaTURPEVariable(qli) * formulaCARNew(qli));
    }

    private Decimal formulaBudgetTaxesAnnuelHTVA(QuoteLineItem qli){
        return (qli.CSPE__c * formulaCARNew(qli)) + (qli.TDCFE__c * formulaCARNew(qli)) + (qli.TCCFE__c * formulaCARNew(qli)) + (formulaCTAMensuel(qli) * 12) ;
    }

    private Decimal formulaCTAMensuel(QuoteLineItem qli){
        for(TURPE__mdt turpe : listTURPE){
            if(turpe.Segment__c == qli.PDE__r.Segment__c && turpe.FTA__c == qli.TECH_FTA__c){
                return
                (15.00/100) *
                (((turpe.Composant_de_Comptage__c + 
                turpe.Composant_de_Gestion__c +
                (turpe.Composant_de_Soutirage_Part_Fixe__c ) * qli.Puissance_souscrite__c )
                )/12);
                }
        }
        return 0.0;
    }

    private Decimal formulaCoutDeCapacite(QuoteLineItem qli){
        if(qli.TECH_RT__c == 'Elec_C1C2' || qli.TECH_RT__c == 'Elec_C3_C4'){
            return 
            ((qli.Capa_HPH__c * qli.Conso_HPH__c) +
            (qli.Capa_HCH__c * qli.Conso_HCH__c) +
            (qli.Capa_HPE__c * qli.Conso_HPE__c) +
            (qli.Capa_HCE__c * qli.Conso_HCE__c) +
            (qli.Capa_Pointes__c * qli.Conso_Pointe__c)) / formulaCARNew(qli);
        }
        else if(qli.TECH_RT__c == 'PDE_ElecC5' && (qli.TECH_MU_CU__c == 'CU' || qli.TECH_FTA__c == 'BT <= 36 kVA - LU EP') && !qli.pde__r.TECH_C5_4Postes__c ){
            return qli.Capa_Base__c;
        }
        else if(qli.TECH_RT__c == 'PDE_ElecC5' && qli.TECH_MU_CU__c == 'CU' && qli.pde__r.TECH_C5_4Postes__c ){
            return
            ((qli.Capa_HPH__c * qli.Conso_HPH__c) +
            (qli.Capa_HCH__c * qli.Conso_HCH__c) +
            (qli.Capa_HPE__c * qli.Conso_HPE__c) +
            (qli.Capa_HCE__c * qli.Conso_HCE__c)) / formulaCARNew(qli);
        }
        else if(qli.TECH_RT__c == 'PDE_ElecC5' && qli.TECH_MU_CU__c == 'MU' && !qli.pde__r.TECH_C5_4Postes__c ){
            return ((qli.Capa_HP__c * qli.ConsoHP__c) + (qli.Capa_HC__c * qli.ConsoHC__c))/formulaCARNew(qli);
        }
        else if(qli.TECH_RT__c == 'PDE_ElecC5' && qli.TECH_MU_CU__c == 'MU' && qli.pde__r.TECH_C5_4Postes__c ){
            return ((qli.Capa_HPH__c * qli.Conso_HPH__c) +
            (qli.Capa_HCH__c * qli.Conso_HCH__c) +
            (qli.Capa_HPE__c * qli.Conso_HPE__c) +
            (qli.Capa_HCE__c * qli.Conso_HCE__c)) / formulaCARNew(qli);
        }
        else {
            return 0.0;
        }
    }
}