global with sharing class AP021_GrilleFournisseur {
    @invocableMethod(callout=true label='GET prix grille')


    public static List<FlowOutput> GET_Prix(List<FlowInput> params){
        FlowInput input = params.get(0);
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs  = new List<FlowOutput>();
        Boolean success = false;
        Double coutCapacite = Enchere_de_capacite__mdt.getInstance('Enchere_de_capacite').Montant__c;
 
        switch on input.fournisseur {
            when 'TotalEnergies' {
                output = caculatePriceTotal(input.recordId,input.dureeOffre,coutCapacite);
            }
            when 'Vattenfall'{
                output = calculatePriceVattenfall(input.recordId,coutCapacite,input.dureeOffre);
            }
            when 'Dyneff'{
                output = calculatePriceDyneff(input.recordId,coutCapacite);
            }
            when 'EDF Entreprises'{
                output = calculatePriceTRV(input.recordId,coutCapacite);
            }
            when 'Ekwateur' {
                output = calculatePriceEkwateur(input.recordId,coutCapacite,input.margeMwh);
            }
            when 'Engie'{
                output = calculatePriceEngiePro(input.recordId, input.dureeOffre);
            }
            when 'Ilek'{
                output = calculatePriceIlek(input.recordId,coutCapacite);
            }
            when 'GEG'{
                output = calculatePriceGEG(input.recordId,input.dureeOffre,coutCapacite,input.margeMwh);
            }
            when 'Hellio'{
                output = calculatePriceHellio(input.recordId,input.dureeOffre,coutCapacite,input.margeMwh);
            }
            when else {
                output.success = false;
                output.message = 'PAS DE GRILLE POUR CE FOURNISSEUR';
            }
        }

        outputs.add(output);
        return outputs;
    }

    private static FlowOutput caculatePriceTotal(String recordId, String dureeEngagement,Double coutCapacite){
        FlowOutput output = new FlowOutput();
        Grille_Total__mdt prixGrille = null;
        Quote quoteToUpdate = new Quote(Id = recordId);
        Boolean allSuccess = false;
        String dateDebut, month, labelCode;
        List<QuoteLineItem> QLIToUpdate = new List<QuoteLineItem>();
        Quote quote = [SELECT Id, Fournisseur__c From Quote where Id=:recordId];

        for(QuoteLineItem qli : [SELECT Id,
                                        CAR_New__c,
                                        CARGaz__c,
                                        DebutDeFourniture__c,
                                        Puissance_souscrite__c,
                                        TECH_Segment__c,
                                        TECH_FTA__c,
                                        TECH_Profil__c,
                                        TECH_Tarif__c,
                                        TECH_TypePDL__c,
                                        TECH_CalendrierFournisseur__c
                                 FROM QuoteLineItem 
                                 WHERE QuoteId =: recordId]){

            month = qli.DebutDeFourniture__c.month() < 10 ? '0' + qli.DebutDeFourniture__c.month() : qli.DebutDeFourniture__c.month()+'' ;
            dateDebut = month + '_' + qli.DebutDeFourniture__c.year();
            if(qli.TECH_TypePDL__c != 'PDE_Gaz'){
                if(qli.TECH_CalendrierFournisseur__c.contains('Base') && qli.TECH_Segment__c == 'C5'){
                    labelCode = 'C5_Base'+'_' + dateDebut + '_' + dureeEngagement;
                } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC') && qli.TECH_Segment__c == 'C5'){
                    labelCode = 'C5_HPHC' + '_' + dateDebut + '_' + dureeEngagement;
                } else {
                    labelCode = qli.TECH_Segment__c + '_' + dateDebut + '_' + dureeEngagement;
                }
            } else if (qli.TECH_Tarif__c == 'T1' || qli.TECH_Tarif__c == 'T2'){
                labelCode = 'T1T2'+'_' + dateDebut + '_' + dureeEngagement;
            }

            prixGrille = Grille_Total__mdt.getInstance(labelCode);
            if(prixGrille != null){
                if(qli.TECH_TypePDL__c != 'PDE_Gaz'){
                    qli.AbonnementMois__c = prixGrille.Abonnement_an__c/12;
                    qli.PrixBase__c = (prixGrille.Prix_C5_Base_kWh__c * 1000).setScale(2);
                    qli.PrixHP__c = (prixGrille.Prix_C5_HP_kWh__c * 1000).setScale(2);
                    qli.PrixHC__c = (prixGrille.Prix_C5_HC_kWh__c * 1000).setScale(2);
                    qli.PrixHphMwh__c = (prixGrille.Prix_HPH_kWh__c * 1000).setScale(2);
                    qli.PrixHchMwh__c = (prixGrille.Prix_HCH_kWh__c * 1000).setScale(2);
                    qli.PrixHpeMwh__c = (prixGrille.Prix_HPE_kWh__c * 1000).setScale(2);
                    qli.PrixHceMwh__c = (prixGrille.Prix_HCE_kWh__c * 1000).setScale(2);
                    
                    if(qli.TECH_FTA__c == 'BT > 36 kVA - LU'){
                        qli.PointesMWh__c = (prixGrille.Prix_HPH_kWh__c * 1000).setScale(2);
                        qli.Capa_Pointes__c = (prixGrille.Capacite_HPH_kW_MWh__c * coutCapacite).setScale(2);
                    }
    
                    qli.Capa_Base__c = (prixGrille.Capacite_C5_Base_kW_MWh__c * coutCapacite).setScale(2);
                    qli.Capa_HP__c = (prixGrille.Capacite_C5_HP_kW_MWh__c * coutCapacite).setScale(2);
                    qli.Capa_HC__c = (prixGrille.Capacite_C5_HC_kW_MWh__c * coutCapacite).setScale(2);
                    qli.Capa_HPH__c = (prixGrille.Capacite_HPH_kW_MWh__c * coutCapacite).setScale(2);
                    qli.Capa_HCH__c = (prixGrille.Capacite_HCH_kW_MWh__c * coutCapacite).setScale(2);
                    qli.Capa_HPE__c = (prixGrille.Capacite_HPE_kW_MWh__c * coutCapacite).setScale(2);
                    qli.Capa_HCE__c = (prixGrille.Capacite_HCE_kW_MWh__c * coutCapacite).setScale(2);
                }
                else{
                    qli.AbonnementMois__c = (Double)prixGrille.get('Abonnement_Mois_' + qli.TECH_Profil__c + '__c');
                    qli.PrixMolecule__c = (Double)prixGrille.get('Prix_proportionnel_kWh_' + qli.TECH_Profil__c + '__c') * 1000;
                }
                qli.dureeEngagement__c = Integer.valueOf(dureeEngagement);
                QLIToUpdate.add(qli);
            }
        }


        if (prixGrille.Date_de_Validite__c != null){

        quoteToUpdate.Date_Validite_Offre__c = Datetime.newInstance(prixGrille.Date_de_Validite__c, Time.newInstance(17, 0, 0, 0));
        update quoteToUpdate;

        }

        if(!QLIToUpdate.isEmpty()){
            QLIToUpdate = calculCommission(recordId, QLIToUpdate,quote.Fournisseur__c);
            for (Database.SaveResult sr : Database.update(QLIToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors().get(0).getMessage();
                    return output;
                }
            }

            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
            return output;
        }

        output.success = false;
        output.message = 'Aucune QLI n\'est compatible avec la grille Total';
        return output;
    }

    private static FlowOutput calculatePriceVattenfall(String recordId, Double coutCapacite, String dureeOffre){
        FlowOutput output = new FlowOutput();
        Grille_Vattenfall__mdt prixGrille = null;
        Quote quoteToUpdate = new Quote(Id = recordId);

        Boolean allSuccess = false;
        String dateDebut, month, labelCode;
        Quote quote = [SELECT CEE__c,Fournisseur__c FROM Quote WHERE Id=:recordId];
        Boolean CEESoumis = quote.CEE__c == 'Soumis';
        List<QuoteLineItem> QLIToUpdate = new List<QuoteLineItem>();
        for(QuoteLineItem qli : [SELECT Id,
                                        DebutDeFourniture__c,
                                        Nouvelle_Echeance__c,
                                        Puissance_souscrite__c,
                                        TECH_Segment__c,
                                        TECH_FTA__c,
                                        TECH_Tarif__c,
                                        TECH_CalendrierFournisseur__c
                                 FROM QuoteLineItem 
                                 WHERE QuoteId =: recordId
                                 AND TECH_Segment__c = 'C5']){
            if(qli.TECH_CalendrierFournisseur__c.contains('Base')){
                labelCode = 'Base_' + qli.Puissance_souscrite__c + '_' + dureeOffre;
            } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){
                labelCode = 'HPHC_' + qli.Puissance_souscrite__c + '_' + dureeOffre;
            } else {
                labelCode = '';
            }   
            prixGrille = Grille_Vattenfall__mdt.getInstance(labelCode);
            
            if(prixGrille != null && qli.DebutDeFourniture__c <= prixGrille.Date_debut_maximale__c  && qli.Nouvelle_Echeance__c <= prixGrille.Date_fin_maximale__c){
                qli.AbonnementMois__c = prixGrille.Abonnement_Mois__c;
                qli.dureeEngagement__c = Integer.valueOf(dureeOffre);
                
                qli.PrixBase__c = prixGrille.Prix_Base_MWh__c;
                qli.PrixHP__c = prixGrille.Prix_HP_MWh__c;
                qli.PrixHC__c = prixGrille.Prix_HC_MWh__c;

                qli.Capa_Base__c = prixGrille.Prix_capacite_base__c;
                qli.Capa_HP__c = prixGrille.Prix_capacite_HP__c;
                qli.Capa_HC__c = prixGrille.Prix_capacite_HC__c;
                
                qli.CeeMwh__c = CEESoumis ? prixGrille.Prix_CEE__c : 0;


                if(qli.TECH_CalendrierFournisseur__c.contains('Base')){
                    qli.PrixHceMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHchMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHpeMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHphMwh__c = prixGrille.Prix_Base_MWh__c;
                    
                    qli.Capa_HCE__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HCH__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HPE__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HPH__c = prixGrille.Prix_capacite_base__c;
                }
                
                else if(qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){

                    qli.PrixHceMwh__c = prixGrille.Prix_HC_MWh__c;
                    qli.PrixHchMwh__c = prixGrille.Prix_HC_MWh__c;
                    qli.PrixHpeMwh__c = prixGrille.Prix_HP_MWh__c;
                    qli.PrixHphMwh__c = prixGrille.Prix_HP_MWh__c;
                    
                    qli.Capa_HCE__c = prixGrille.Prix_capacite_HC__c;
                    qli.Capa_HCH__c = prixGrille.Prix_capacite_HC__c;
                    qli.Capa_HPE__c = prixGrille.Prix_capacite_HP__c;
                    qli.Capa_HPH__c = prixGrille.Prix_capacite_HP__c;
                }
                
                QLIToUpdate.add(qli);
            }
        }
        
        if (prixGrille.Date_de_Validite__c != null){

        quoteToUpdate.Date_Validite_Offre__c = Datetime.newInstance(prixGrille.Date_de_Validite__c, Time.newInstance(17, 0, 0, 0));
        update quoteToUpdate;

        }

        if(!QLIToUpdate.isEmpty()){
            QLIToUpdate = calculCommission(recordId, QLIToUpdate,quote.Fournisseur__c, dureeOffre);
            for (Database.SaveResult sr : Database.update(QLIToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors().get(0).getMessage();
                    return output;
                }
            }

            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
            return output;
        }

        output.success = false;
        output.message = 'Aucune QLI n\'est compatible avec la grille Vattenfall';
        return output;
    }

    private static FlowOutput calculatePriceDyneff(String recordId,Double coutCapacite){
        FlowOutput output = new FlowOutput();
        Grille_Dyneff__mdt prixGrille = null;
        Boolean allSuccess = false;
        String dateDebut, month, labelCode;
        List<QuoteLineItem> QLIToUpdate = new List<QuoteLineItem>();
        Quote quote = [SELECT CEE__c FROM Quote WHERE Id=:recordId];
        Boolean CEESoumis = quote.CEE__c == 'Soumis';
        for(QuoteLineItem qli : [SELECT Id,
                                        DebutDeFourniture__c,
                                        Nouvelle_Echeance__c,
                                        Puissance_souscrite__c,
                                        TECH_Segment__c,
                                        TECH_FTA__c,
                                        TECH_Tarif__c,
                                        TECH_CalendrierFournisseur__c
                                 FROM QuoteLineItem 
                                 WHERE QuoteId =: recordId
                                 AND TECH_Segment__c = 'C5']){
            
            if(qli.TECH_CalendrierFournisseur__c.contains('Base')){
                labelCode = 'Base_' + qli.Puissance_souscrite__c;
            } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){
                labelCode = 'HPHC_' + qli.Puissance_souscrite__c;
            } else {
                labelCode = '';
            }
            prixGrille = Grille_Dyneff__mdt.getInstance(labelCode);

            if(prixGrille != null && qli.Nouvelle_Echeance__c <= prixGrille.Date_fin_maximale__c){
                qli.AbonnementMois__c = prixGrille.Abonnement_Mois__c;
                qli.dureeEngagement__c = Integer.valueOf(24);
                qli.PrixBase__c = prixGrille.Prix_Base_MWh__c;
                qli.PrixHC__c = prixGrille.Prix_HC_MWh__c;
                qli.PrixHP__c = prixGrille.Prix_HP_MWh__c;
                
                qli.CeeMwh__c = CEESoumis ? prixGrille.Prix_CEE__c : 0;
                qli.Capa_Base__c = (prixGrille.Prix_capacite_base__c * coutCapacite).setScale(2);
                qli.Capa_HC__c = (prixGrille.Prix_capacite_HC__c * coutCapacite).setScale(2);
                qli.Capa_HP__c = (prixGrille.Prix_capacite_HP__c * coutCapacite).setScale(2);

                if(qli.TECH_CalendrierFournisseur__c.contains('Base')){

                    qli.PrixHceMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHchMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHpeMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHphMwh__c = prixGrille.Prix_Base_MWh__c;

                    qli.Capa_HCE__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HCH__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HPE__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HPH__c = prixGrille.Prix_capacite_base__c;

                }
                else if(qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){
                    qli.PrixHceMwh__c = prixGrille.Prix_HC_MWh__c;
                    qli.PrixHchMwh__c = prixGrille.Prix_HC_MWh__c;
                    qli.PrixHpeMwh__c = prixGrille.Prix_HP_MWh__c;
                    qli.PrixHphMwh__c = prixGrille.Prix_HP_MWh__c;

                    qli.Capa_HCE__c = prixGrille.Prix_capacite_HC__c;
                    qli.Capa_HCH__c = prixGrille.Prix_capacite_HC__c;
                    qli.Capa_HPE__c = prixGrille.Prix_capacite_HP__c;
                    qli.Capa_HPH__c = prixGrille.Prix_capacite_HP__c;
                }
                QLIToUpdate.add(qli);
            }
        }

        if(!QLIToUpdate.isEmpty()){
            for (Database.SaveResult sr : Database.update(QLIToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors().get(0).getMessage();
                    return output;
                }
            }

            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
            return output;
        }

        output.success = false;
        output.message = 'Aucune QLI n\'est compatible avec la grille Dyneff';
        return output;
    }

    private static FlowOutput calculatePriceTRV(String recordId,Double coutCapacite){
        FlowOutput output = new FlowOutput();
        Grille_TRV__mdt prixGrille = null;
        Boolean allSuccess = false;
        String dateDebut, month, labelCode;
        Quote quote = [SELECT CEE__c FROM Quote WHERE Id=:recordId];
        Boolean CEESoumis = quote.CEE__c == 'Soumis';
        List<QuoteLineItem> QLIToUpdate = new List<QuoteLineItem>();
        for(QuoteLineItem qli : [SELECT Id,
                                        DebutDeFourniture__c,
                                        Nouvelle_Echeance__c,
                                        Puissance_souscrite__c,
                                        TECH_Segment__c,
                                        TECH_FTA__c,
                                        TECH_Tarif__c,
                                        TECH_CalendrierFournisseur__c
                                 FROM QuoteLineItem 
                                 WHERE QuoteId =: recordId
                                 AND TECH_Segment__c = 'C5']){
            
            if(qli.TECH_CalendrierFournisseur__c.contains('Base')){
                labelCode = 'Base_' + qli.Puissance_souscrite__c;
            } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){
                labelCode = 'HPHC_' + qli.Puissance_souscrite__c;
            } else {
                labelCode = '';
            }
            prixGrille = Grille_TRV__mdt.getInstance(labelCode);

            if(prixGrille != null){
                qli.AbonnementMois__c = prixGrille.Abonnement_Mois__c;
                qli.PrixBase__c = prixGrille.Prix_Base_MWh__c;
                qli.PrixHC__c = prixGrille.Prix_HC_MWh__c;
                qli.PrixHP__c = prixGrille.Prix_HP_MWh__c;
                
                qli.CeeMwh__c = CEESoumis ? prixGrille.Prix_CEE__c : 0;
                qli.Capa_Base__c = (prixGrille.Prix_capacite_base__c * coutCapacite).setScale(2);
                qli.Capa_HC__c = (prixGrille.Prix_capacite_HC__c * coutCapacite).setScale(2);
                qli.Capa_HP__c = (prixGrille.Prix_capacite_HP__c * coutCapacite).setScale(2);


                if(qli.TECH_CalendrierFournisseur__c.contains('Base')){

                    qli.PrixHceMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHchMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHpeMwh__c = prixGrille.Prix_Base_MWh__c;
                    qli.PrixHphMwh__c = prixGrille.Prix_Base_MWh__c;

                    qli.Capa_HCE__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HCH__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HPE__c = prixGrille.Prix_capacite_base__c;
                    qli.Capa_HPH__c = prixGrille.Prix_capacite_base__c;

                }
                else if(qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){
                    qli.PrixHceMwh__c = prixGrille.Prix_HC_MWh__c;
                    qli.PrixHchMwh__c = prixGrille.Prix_HC_MWh__c;
                    qli.PrixHpeMwh__c = prixGrille.Prix_HP_MWh__c;
                    qli.PrixHphMwh__c = prixGrille.Prix_HP_MWh__c;

                    qli.Capa_HCE__c = prixGrille.Prix_capacite_HC__c;
                    qli.Capa_HCH__c = prixGrille.Prix_capacite_HC__c;
                    qli.Capa_HPE__c = prixGrille.Prix_capacite_HP__c;
                    qli.Capa_HPH__c = prixGrille.Prix_capacite_HP__c;
                }

                qli.dureeEngagement__c = Integer.valueOf(24);
                QLIToUpdate.add(qli);
            }
        }

        if(!QLIToUpdate.isEmpty()){
            for (Database.SaveResult sr : Database.update(QLIToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors().get(0).getMessage();
                    return output;
                }
            }

            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
            return output;
        }

        output.success = false;
        output.message = 'Aucune QLI n\'est compatible avec la grille TRV';
        return output;
    }

    private static FlowOutput calculatePriceEkwateur(String recordId, Double coutCapacite,Double margeMwh){
        FlowOutput output = new FlowOutput();
        Grille_Ekwateur__mdt prixGrille2025,prixGrille2026,prixGrille2027,prixGrille2028,dateMinMaxGrille;
        Quote quoteToUpdate = new Quote(Id = recordId);
        Boolean allSuccess = false;
        String dateDebut, month, labelCode;
        Integer nombreMois2025 = 0;   
        Integer nombreMois2026 = 0;
        Integer nombreMois2027 = 0;
        Integer nombreMois2028 = 0;
        Decimal prixBasePondere,prixHPPondere,prixHCPondere;
        Quote quote = [SELECT CEE__c,Maximum_date_de_fin__c,Minimum_date_de_debut__c,Opportunity.RecordType.Name,Fournisseur__c FROM Quote WHERE Id=:recordId];         

        // Détermination du label en fonction du RecordType de l'Opportunity
        if (quote.Opportunity.RecordType.Name.contains('Gaz')) {
            labelCode = 'T1T2T3';
        } else if (quote.Opportunity.RecordType.Name.contains('C5')) {
            labelCode = 'C5';
        } else if (quote.Opportunity.RecordType.Name.contains('C1C2C3C4')) {
            labelCode = 'C4';
        } else {
            labelCode = '';
        }

        //Vérification date min max de la quote par rapport à la grille
        dateMinMaxGrille = [SELECT Id, Date_debut_min1__c,Date_fin__c,Date_debut_max1__c,Date_debut_min2__c, Date_debut_max2__c,Date_debut_min3__c, Date_debut_max3__c,Date_de_Validite__c  FROM Grille_Ekwateur__mdt WHERE DeveloperName like :labelCode+'%' LIMIT 1];
        if(
            (
                (quote.Minimum_date_de_debut__c < dateMinMaxGrille.Date_debut_min1__c || quote.Minimum_date_de_debut__c > dateMinMaxGrille.Date_debut_max1__c) &&
                (quote.Minimum_date_de_debut__c < dateMinMaxGrille.Date_debut_min2__c || quote.Minimum_date_de_debut__c > dateMinMaxGrille.Date_debut_max2__c)&&
                (quote.Minimum_date_de_debut__c < dateMinMaxGrille.Date_debut_min3__c || quote.Minimum_date_de_debut__c > dateMinMaxGrille.Date_debut_max3__c)
            ) ||
            (quote.Maximum_date_de_fin__c > dateMinMaxGrille.Date_fin__c)){
            output.success = false;
            output.message = 'Erreur : Date de démarrage autorisée entre ' 
                            + dateMinMaxGrille.Date_debut_min1__c.format() + ' et ' + dateMinMaxGrille.Date_debut_max1__c.format() +' ou  entre '
                            + dateMinMaxGrille.Date_debut_min2__c.format() + ' et ' + dateMinMaxGrille.Date_debut_max2__c.format() +' ou  entre '
                            + dateMinMaxGrille.Date_debut_min3__c.format()+ ' et ' + dateMinMaxGrille.Date_debut_max3__c.format() +'. Date de fin maximale : '
                            + dateMinMaxGrille.Date_fin__c.format();
            return output;
        }

        //Vérification si on a des compteurs T4 ou C1/C2/C3/C4
        List<QuoteLineItem> QLIs = [SELECT  Id,
                                            DebutDeFourniture__c,
                                            Nouvelle_Echeance__c,
                                            Puissance_souscrite__c,
                                            TECH_Segment__c,
                                            TECH_FTA__c,
                                            TECH_Tarif__c,
                                            TECH_CalendrierFournisseur__c,
                                            TECH_Profil__c 
                                    FROM QuoteLineItem 
                                    WHERE QuoteId = :recordId];
        for (QuoteLineItem qli : QLIs) {
            if (qli.TECH_Tarif__c == 'T4') {
                output.success = false;
                output.message = 'Erreur : Une QLI a un TECH_Tarif__c de valeur "T4".';
                return output;
            }
            if (qli.TECH_Segment__c == 'C1' || qli.TECH_Segment__c == 'C2' || qli.TECH_Segment__c == 'C3') {
                output.success = false;
                output.message = 'Erreur : Une QLI a un TECH_Segment__c de valeur "C1", "C2", "C3".';
                return output;
            }
            if (qli.Nouvelle_Echeance__c != dateMinMaxGrille.Date_fin__c) {
                output.success = false;
                output.message = 'Le champ nouvelle échéance doit être égal à la date de fin maximale de la grille : '
                                + dateMinMaxGrille.Date_fin__c.format() +'.';
                return output;
            }
        }

        List<QuoteLineItem> QLIToUpdate = new List<QuoteLineItem>();

        for(QuoteLineItem qli : [SELECT Id,
                                        CAR_New__c,
                                        CARGaz__c,
                                        DebutDeFourniture__c,
                                        Nouvelle_Echeance__c,
                                        Puissance_souscrite__c,
                                        TECH_Segment__c,
                                        TECH_FTA__c,
                                        TECH_Tarif__c,
                                        TECH_CalendrierFournisseur__c,
                                        TECH_Profil__c
                                 FROM QuoteLineItem 
                                 WHERE QuoteId =: recordId 
                                 AND (
                                        ( 
                                            (DebutDeFourniture__c >=: dateMinMaxGrille.Date_debut_min1__c) AND (DebutDeFourniture__c <=: dateMinMaxGrille.Date_debut_max1__c) AND (Nouvelle_Echeance__c <=: dateMinMaxGrille.Date_fin__c)
                                        ) 
                                        OR
                                        (
                                            (DebutDeFourniture__c >=: dateMinMaxGrille.Date_debut_min2__c) AND (DebutDeFourniture__c <=: dateMinMaxGrille.Date_debut_max2__c) AND (Nouvelle_Echeance__c <=: dateMinMaxGrille.Date_fin__c)
                                        ) 
                                        OR
                                        (
                                            (DebutDeFourniture__c >=: dateMinMaxGrille.Date_debut_min3__c) AND (DebutDeFourniture__c <=: dateMinMaxGrille.Date_debut_max3__c) AND (Nouvelle_Echeance__c <=: dateMinMaxGrille.Date_fin__c)
                                     )
                                 )]){            
            Date startDate = qli.DebutDeFourniture__c;
            Date endDate = qli.Nouvelle_Echeance__c;
            
            
            System.debug('startDate '+startDate);
            System.debug('endDate '+endDate);

            if (startDate != null && endDate != null) {
                while (startDate <= endDate) {
                    Integer currentYear = startDate.year(); 
                    if (currentYear == 2025) {
                        nombreMois2025++;
                    } else if (currentYear == 2026) {
                        nombreMois2026++;
                    } else if (currentYear == 2027) {
                        nombreMois2027++;
                    }else if (currentYear == 2028) {
                        nombreMois2028++;
                    }
                    startDate = startDate.addMonths(1);
                }
            }
 

            prixGrille2026 = Grille_Ekwateur__mdt.getinstance(labelCode + '_2026_'+margeMwh.intValue());
            prixGrille2027 = Grille_Ekwateur__mdt.getinstance(labelCode + '_2027_'+margeMwh.intValue());
            prixGrille2028 = Grille_Ekwateur__mdt.getinstance(labelCode + '_2028_'+margeMwh.intValue());
            qli.dureeEngagement__c = qli.DebutDeFourniture__c.monthsBetween(qli.Nouvelle_Echeance__c.addDays(1));


            if(labelCode.contains('C5')){
                //Prix base attention cas special LU EP a traiter
                qli.AbonnementMois__c = prixGrille2026.Abonnement_Mois__c;
                if(qli.TECH_FTA__c == 'BT <= 36 kVA - LU EP'){
                    prixBasePondere = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_Base_EP__c,prixGrille2027.Prix_Base_EP__c,prixGrille2028.Prix_Base_EP__c); 
                } else {
                   prixBasePondere = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_Base__c,prixGrille2027.Prix_Base__c,prixGrille2028.Prix_Base__c);
                }

                qli.PrixBase__c = prixBasePondere;

                prixHPPondere = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_HP__c,prixGrille2027.Prix_HP__c,prixGrille2028.Prix_HP__c);
                prixHCPondere = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_HC__c,prixGrille2027.Prix_HC__c,prixGrille2028.Prix_HC__c);
                qli.PrixHP__c = prixHPPondere;
                qli.PrixHC__c = prixHCPondere;
                
                qli.CeeMwh__c = 0;
                qli.Capa_Base__c = 0;
                qli.Capa_HC__c = 0;
                qli.Capa_HP__c = 0;

              if(qli.TECH_CalendrierFournisseur__c.contains('Base')){

                qli.PrixHceMwh__c = prixBasePondere;
                qli.PrixHchMwh__c = prixBasePondere;
                qli.PrixHpeMwh__c = prixBasePondere;
                qli.PrixHphMwh__c = prixBasePondere;

                qli.Capa_HCE__c = 0;
                qli.Capa_HCH__c = 0;
                qli.Capa_HPE__c = 0;
                qli.Capa_HPH__c = 0;

              }
              else if(qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){

                qli.PrixHceMwh__c = prixHCPondere;
                qli.PrixHchMwh__c = prixHCPondere;
                qli.PrixHpeMwh__c = prixHPPondere;
                qli.PrixHphMwh__c = prixHPPondere;

                qli.Capa_HCE__c = 0;
                qli.Capa_HCH__c = 0;
                qli.Capa_HPE__c = 0;
                qli.Capa_HPH__c = 0;
              }
            }

            else if(labelCode.contains('C4')){

                qli.AbonnementMois__c = prixGrille2026.Abonnement_Mois__c;
                qli.CeeMwh__c = 0;
                qli.PrixHphMwh__c = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_HPH__c,prixGrille2027.Prix_HPH__c,prixGrille2028.Prix_HPH__c);
                qli.PrixHchMwh__c = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_HCH__c,prixGrille2027.Prix_HCH__c,prixGrille2028.Prix_HCH__c);
                qli.PrixHpeMwh__c = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_HPE__c,prixGrille2027.Prix_HPE__c,prixGrille2028.Prix_HPE__c);
                qli.PrixHceMwh__c = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_HCE__c,prixGrille2027.Prix_HCE__c,prixGrille2028.Prix_HCE__c);



                
                if(qli.tech_FTA__c == 'BT > 36 kVA - LU'){
                    qli.PointesMWh__c = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,prixGrille2026.Prix_HPH__c,prixGrille2027.Prix_HPH__c,prixGrille2028.Prix_HPH__c);
                }
                else{
                    qli.PointesMWh__c = 0;
                }
                
                qli.Capa_Pointes__c = 0;
                qli.Capa_HCE__c = 0;
                qli.Capa_HCH__c = 0;
                qli.Capa_HPE__c = 0;
                qli.Capa_HPH__c = 0;
            }

            else if(labelCode.contains('T1T2T3') && qli.TECH_Profil__c <> null){
                qli.AbonnementMois__c = prixGrille2026.Abonnement_Mois__c;
                qli.PrixMolecule__c = calculPrixPondere(nombreMois2026,nombreMois2027,nombreMois2028,(Decimal)prixGrille2026.get('Prix_molecule_' + qli.TECH_Profil__c + '__c'),(Decimal)prixGrille2027.get('Prix_molecule_' + qli.TECH_Profil__c + '__c'),(Decimal)prixGrille2028.get('Prix_molecule_' + qli.TECH_Profil__c + '__c'));
            }
            
            nombreMois2025 = 0;
            nombreMois2026 = 0;
            nombreMois2027 = 0;
            nombreMois2028 = 0;

            QLIToUpdate.add(qli);

        }
        
        if (dateMinMaxGrille.Date_de_Validite__c != null){

            quoteToUpdate.Date_Validite_Offre__c = Datetime.newInstance(dateMinMaxGrille.Date_de_Validite__c, Time.newInstance(17, 0, 0, 0));
            update quoteToUpdate;

        }
        if(!QLIToUpdate.isEmpty()){
            QLIToUpdate = calculCommission(recordId, QLIToUpdate,quote.Fournisseur__c, margeMwh);

            for (Database.SaveResult sr : Database.update(QLIToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors().get(0).getMessage();
                    return output;
                }
            }

            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
            return output;
        }

        output.success = false;
        output.message = 'Aucune QLI n\'est compatible avec la grille Ekwateur';
        return output;
    }

    private static FlowOutput calculatePriceEngiePro(String recordId,String dureeOffre) {
        FlowOutput output = new FlowOutput();
        List<QuoteLineItem> listQLIToUpdate = new List<QuoteLineItem>();
            String labelCode = '';
            String labelCodeSansRemise = '';
            String dureeEngagement = '';
            Grille_Engie_PRO__mdt prixGrille, prixGrilleSansRemise;
            Quote quoteToUpdate = new Quote(Id = recordId);

        
        // Récupération du quote
        Quote quoteEngiePro = [SELECT CEE__c,Minimum_date_de_debut__c,Fournisseur__c FROM Quote WHERE Id = :recordId];
        Boolean CEESoumis = quoteEngiePro.CEE__c == 'Soumis';

        if (quoteEngiePro.Minimum_date_de_debut__c > Date.today().addYears(1)) {
            output.success = false;
            output.message = 'Date de démarrage trop lointaine';
            return output;
        }

        if (dureeOffre == null) {
            output.success = false;
            output.message = 'Durée et type de l\'offre ne sont pas renseignés';
            return output;
        }
        
        // Récupération des QLI associées au quote
        List<QuoteLineItem> qlis = [
            SELECT Id, DebutDeFourniture__c, CAR_New__c,CARGaz__c, TECH_Segment__c,
                   TECH_CalendrierFournisseur__c, TECH_FTA__c,TECH_TypePDL__c, puissance_souscrite__c
            FROM QuoteLineItem 
            WHERE QuoteId = :recordId
        ];
    
        for (QuoteLineItem qli : qlis) {
            // On ignore les QLI avec une date de début > 1 an
            if (qli.DebutDeFourniture__c > Date.today().addYears(1)) {
                continue;
            }
    
            if (dureeOffre.contains('variable') && (qli.TECH_Segment__c == 'C4')) {
                throw new IllegalArgumentException(
            'Offre invalide : une offre VARIABLE ne peut pas être sur un segment autre que C5.'
                );
            }

    
            // Détermination du label en fonction du segment
            if (qli.TECH_TypePDL__c == 'PDE_Gaz') {
                if (qli.CARGaz__c > 4 && qli.CARGaz__c < 30) {
                    labelCode = 'GAZ_Sup4MegInf30Meg' + '_' + dureeOffre;
                    if (dureeOffre.contains('36_fixe')) { 
                        labelCodeSansRemise = 'GAZ_Sup4MegInf30Meg_36_fixe';

                    }
                } else if (qli.CARGaz__c > 30) {
                    labelCode = 'GAZ_Sup30Meg' + '_' + dureeOffre;
                    if (dureeOffre.contains('36_fixe')) { 
                        labelCodeSansRemise = 'GAZ_Sup30Meg_36_fixe';

                    }
                }
            } else if (qli.TECH_Segment__c == 'C5') {
                if (qli.TECH_CalendrierFournisseur__c.contains('Base')) {
                    labelCode = 'C5_Base'+ '_' + dureeOffre;
                    if (dureeOffre.contains('36_fixe')) { 
                        labelCodeSansRemise = 'C5_Base_36_fixe';    
                    }
                } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')) {
                    labelCode = 'C5_HPHC'+ '_' + dureeOffre;
                    if (dureeOffre.contains('36_fixe')) { 
                        labelCodeSansRemise = 'C5_HPHC_36_fixe';

                    }
                }
            } else if (qli.TECH_Segment__c == 'C4' && qli.puissance_souscrite__c < 250) {
                labelCode = 'C4'+ '_' + dureeOffre;
                if (dureeOffre.contains('36_fixe')) { 
                    labelCodeSansRemise = 'C4_36_fixe';

                }
            }
            

            if (dureeOffre.contains('36_fixe')) { 
                        prixGrilleSansRemise = Grille_Engie_PRO__mdt.getInstance(labelCodeSansRemise);

            }
            prixGrille = Grille_Engie_PRO__mdt.getInstance(labelCode);

            if (prixGrille == null) {
                continue;
            }
            // Remplissage des champs QLI
            qli.AbonnementMois__c = prixGrille.Prix_Abonnement__c;
            if (dureeOffre.contains('36_fixe')) {
                qli.PrixMolecule__c = (((prixGrille.Prix_Molecule__c*12)+(prixGrilleSansRemise.Prix_Molecule__c* 24))/36).setScale(2);
            }else {
                qli.PrixMolecule__c = prixGrille.Prix_Molecule__c;
            }

            if (dureeOffre.contains('12_fixe')||dureeOffre.contains('12_variable')) {
                dureeEngagement= '12'; 
                qli.dureeEngagement__c = Integer.valueOf(dureeEngagement);

            }else if (dureeOffre.contains('24_fixe')) { 
                dureeEngagement= '24';
                qli.dureeEngagement__c = Integer.valueOf(dureeEngagement);

            }else if (dureeOffre.contains('36_fixe')) {
                dureeEngagement= '36';
                qli.dureeEngagement__c = Integer.valueOf(dureeEngagement);  
            }
    
            Decimal capa = prixGrille.Prix_CAPA__c;

            qli.Capa_Base__c = capa;
            qli.Capa_HP__c = capa;
            qli.Capa_HC__c = capa;

            qli.Capa_HPH__c = capa;
            qli.Capa_HCH__c = capa;
            qli.Capa_HPE__c = capa;
            qli.Capa_HCE__c = capa;
            
            qli.Capa_Pointes__c = capa;

            if (dureeOffre.contains('36_fixe')) { 
            qli.PrixBase__c = (((prixGrille.Prix_Base__c*12)+(prixGrilleSansRemise.Prix_Base__c* 24))/36).setScale(2);
            qli.PrixHP__c = (((prixGrille.Prix_HP__c*12)+(prixGrilleSansRemise.Prix_HP__c* 24))/36).setScale(2);
            qli.PrixHC__c = (((prixGrille.Prix_HC__c*12)+(prixGrilleSansRemise.Prix_HC__c* 24))/36).setScale(2);
            }else {
            qli.PrixBase__c = prixGrille.Prix_Base__c;
            qli.PrixHP__c = prixGrille.Prix_HP__c;
            qli.PrixHC__c = prixGrille.Prix_HC__c;
            }
            qli.CeeMwh__c = CEESoumis ? prixGrille.CEE__c : 0 ;
    
            // Segments spécifiques
            if (qli.TECH_Segment__c == 'C4') {
                if (dureeOffre.contains('36_fixe')) { 
                    qli.PrixHphMwh__c = (((prixGrille.Prix_HPH__c*12)+(prixGrilleSansRemise.Prix_HPH__c* 24))/36).setScale(2);
                    qli.PrixHchMwh__c = (((prixGrille.Prix_HCH__c*12)+(prixGrilleSansRemise.Prix_HCH__c* 24))/36).setScale(2);
                    qli.PrixHpeMwh__c = (((prixGrille.Prix_HPE__c*12)+(prixGrilleSansRemise.Prix_HPE__c* 24))/36).setScale(2);
                    qli.PrixHceMwh__c = (((prixGrille.Prix_HCE__c*12)+(prixGrilleSansRemise.Prix_HCE__c* 24))/36).setScale(2);
                }else {
                qli.PrixHphMwh__c = prixGrille.Prix_HPH__c;
                qli.PrixHchMwh__c = prixGrille.Prix_HCH__c;
                qli.PrixHpeMwh__c = prixGrille.Prix_HPE__c;
                qli.PrixHceMwh__c = prixGrille.Prix_HCE__c;

                }

                if (qli.TECH_FTA__c.contains('LU')) {
                    qli.PointesMWh__c = prixGrille.Prix_HPH__c;
                }
            } else if (qli.TECH_Segment__c == 'C5') {
                if (qli.TECH_CalendrierFournisseur__c.contains('Base')) {
                    qli.PrixHphMwh__c =  qli.PrixBase__c;
                    qli.PrixHchMwh__c =  qli.PrixBase__c;
                    qli.PrixHpeMwh__c =  qli.PrixBase__c;
                    qli.PrixHceMwh__c =  qli.PrixBase__c;

                } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')) {
                    qli.PrixHphMwh__c = qli.PrixHP__c;
                    qli.PrixHchMwh__c = qli.PrixHC__c;
                    qli.PrixHpeMwh__c = qli.PrixHP__c;
                    qli.PrixHceMwh__c = qli.PrixHC__c;
                }
            }
            listQLIToUpdate.add(qli);
        }
        if (prixGrille.Date_de_Validite__c != null){

        quoteToUpdate.Date_Validite_Offre__c = Datetime.newInstance(prixGrille.Date_de_Validite__c, Time.newInstance(17, 0, 0, 0)); 
        update quoteToUpdate;

        }
        
        if(!listQLIToUpdate.isEmpty()){
            listQLIToUpdate = calculCommission(recordId, listQLIToUpdate,quoteEngiePro.Fournisseur__c, dureeEngagement);

            for (Database.SaveResult sr : Database.update(listQLIToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors().get(0).getMessage();
                    return output;
                }
            }

            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
            return output;
        }

        output.success = false;
        output.message = 'Aucune QLI n\'est compatible avec la grille Engie PRO';
        return output;
    }

    private static FlowOutput calculatePriceIlek(String recordId, Double coutCapacite) {
        FlowOutput output = new FlowOutput();
        Quote quoteToUpdate = new Quote(Id = recordId);

        Grille_Ilek__mdt prixGrille = null;
        // Récupération du quote
        Quote quoteIlek = [
            SELECT Minimum_date_de_debut__c, Fournisseur__c
            FROM Quote
            WHERE Id = :recordId
            LIMIT 1
        ];
    
        if (quoteIlek.Minimum_date_de_debut__c > Date.today().addMonths(6)) {
            output.success = false;
            output.message = 'Date de démarrage trop lointaine';
            return output;
        }
    
        List<QuoteLineItem> QLIToUpdate = new List<QuoteLineItem>();
    
        List<QuoteLineItem> qliList = [
            SELECT Id,
                   DebutDeFourniture__c,
                   Nouvelle_Echeance__c,
                   Puissance_souscrite__c,
                   TECH_Segment__c,
                   TECH_FTA__c,
                   TECH_Tarif__c,
                   TECH_CalendrierFournisseur__c
            FROM QuoteLineItem
            WHERE QuoteId = :recordId
            AND TECH_Segment__c = 'C5'
        ];
    
        for (QuoteLineItem qli : qliList) {
            String calendrier = qli.TECH_CalendrierFournisseur__c;
            String labelCode = '';
    
            if (calendrier.contains('Base')) {
                labelCode = 'BASE_';
            } else if (calendrier.contains('HP/HC')) {
                labelCode = 'HPHC_';
            }
    
            labelCode += qli.Puissance_souscrite__c;
            prixGrille = Grille_Ilek__mdt.getInstance(labelCode);
    
            if (prixGrille != null) {
                qli.AbonnementMois__c = prixGrille.Prix_abonnement__c;
                qli.dureeEngagement__c = 24;
    
                qli.PrixBase__c = prixGrille.Prix_Base_KWh__c * 1000;
                qli.PrixHP__c = prixGrille.Prix_HP_KWh__c * 1000;
                qli.PrixHC__c = prixGrille.Prix_HC_KWh__c * 1000;
    
                // Initialisation des capacités
                qli.CeeMwh__c = 0;
                qli.Capa_Base__c = 0;
                qli.Capa_HP__c = 0;
                qli.Capa_HC__c = 0;
                qli.Capa_HPH__c = 0;
                qli.Capa_HCH__c = 0;
                qli.Capa_HPE__c = 0;
                qli.Capa_HCE__c = 0;
                qli.Capa_Pointes__c = 0;
    
                // Attribution des prix horaires
                if (calendrier.contains('Base')) {
                    Decimal basePrice = prixGrille.Prix_Base_KWh__c * 1000;
                    qli.PrixHphMwh__c = basePrice;
                    qli.PrixHchMwh__c = basePrice;
                    qli.PrixHpeMwh__c = basePrice;
                    qli.PrixHceMwh__c = basePrice;
                } else if (calendrier.contains('HP/HC')) {
                    qli.PrixHphMwh__c = prixGrille.Prix_HP_KWh__c * 1000;
                    qli.PrixHchMwh__c = prixGrille.Prix_HC_KWh__c * 1000;
                    qli.PrixHpeMwh__c = prixGrille.Prix_HP_KWh__c * 1000;
                    qli.PrixHceMwh__c = prixGrille.Prix_HC_KWh__c * 1000;
                }
    
                QLIToUpdate.add(qli);
            }
        }

        
        if (prixGrille.Date_de_Validite__c != null){

        quoteToUpdate.Date_Validite_Offre__c = Datetime.newInstance(prixGrille.Date_de_Validite__c, Time.newInstance(17, 0, 0, 0));
        update quoteToUpdate;

        }
    
        if (!QLIToUpdate.isEmpty()) {
            QLIToUpdate = calculCommission(recordId, QLIToUpdate,quoteIlek.Fournisseur__c);
            for (Database.SaveResult sr : Database.update(QLIToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors()[0].getMessage();
                    return output;
                }
            }
    
            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
            return output;
        }
    
        output.success = false;
        output.message = 'Aucune QLI n\'est compatible avec la grille Ilek';
        return output;
    }

    private static FlowOutput calculatePriceGEG(String recordId, String dureeEngagement, Double coutCapacite, Double margeMwh) {
        FlowOutput output = new FlowOutput();
        Quote quoteToUpdate = new Quote(Id = recordId);

    
        // Capacités préconfigurées par segment
        final Map<String, Map<String, Decimal>> capacites = new Map<String, Map<String, Double>>{
            'C5' => new Map<String, Decimal>{
                'Base' => 0.263,
                'HP'   => 0.336,
                'HC'   => 0.055
            },
            'C4' => new Map<String, Decimal>{
                'HPH' => 0.591,
                'HCH' => 0.038
            },
            'C2' => new Map<String, Decimal>{
                'Pointe' => 1.1162,
                'HPH'    => 0.520
            }
        };
    
        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();
        Quote quote = [SELECT CEE__c,Fournisseur__c FROM Quote WHERE Id=:recordId];
        Boolean CEESoumis = quote.CEE__c == 'Soumis';
        Grille_GEG__mdt prixGrille = null;

        for (QuoteLineItem qli : [
            SELECT Id, DebutDeFourniture__c, Nouvelle_Echeance__c, Puissance_souscrite__c,
                   TECH_Segment__c, TECH_FTA__c, TECH_Tarif__c, TECH_CalendrierFournisseur__c,
                   CAR_New__c,CARGaz__c, PDE__r.X12_mois_consommation_SGE__c
            FROM QuoteLineItem
            WHERE QuoteId = :recordId
              AND TECH_Segment__c IN ('C5', 'C4', 'C2')
              AND CAR_New__c >= 30 AND CAR_New__c <= 1000
              AND Puissance_souscrite__c <= 500
              AND PDE__r.X12_mois_consommation_SGE__c = true
        ]) {
            String month = qli.DebutDeFourniture__c.month() < 10 ? '0' + qli.DebutDeFourniture__c.month() : qli.DebutDeFourniture__c.month()+'';
            String dateDebut = month + '_' + qli.DebutDeFourniture__c.year();
            String labelCode = qli.TECH_Segment__c + '_' + dateDebut + '_' + dureeEngagement;
    
            prixGrille = Grille_GEG__mdt.getInstance(labelCode);
            if (prixGrille == null) continue;
    
            // Mise à jour des champs communs
            qli.AbonnementMois__c = 0;
            qli.dureeEngagement__c = Integer.valueOf(dureeEngagement);
    
            qli.PrixBase__c = prixGrille.Prix_Base__c + margeMwh;
            qli.PrixHP__c = prixGrille.Prix_HP__c + margeMwh;
            qli.PrixHC__c = prixGrille.Prix_HC__c + margeMwh;
            qli.CeeMwh__c = CEESoumis ? prixGrille.CeeMwh__c : 0;
    
            // Réinitialisation des capacités
            qli.Capa_Base__c = 0;
            qli.Capa_HP__c = 0;
            qli.Capa_HC__c = 0;
            qli.Capa_HPH__c = 0;
            qli.Capa_HCH__c = 0;
            qli.Capa_HPE__c = 0;
            qli.Capa_HCE__c = 0;
            qli.Capa_Pointes__c = 0;
    
            String segment = qli.TECH_Segment__c;
    
            if (segment == 'C5') {
                qli.Capa_Base__c = (capacites.get('C5').get('Base') * coutCapacite).setScale(2);
                qli.Capa_HP__c = (capacites.get('C5').get('Base') * coutCapacite).setScale(2);
                qli.Capa_HC__c = (capacites.get('C5').get('Base') * coutCapacite).setScale(2);
                qli.Capa_HPH__c = (capacites.get('C5').get('Base') * coutCapacite).setScale(2);
                qli.Capa_HCH__c = (capacites.get('C5').get('Base') * coutCapacite).setScale(2);
                qli.Capa_HPE__c = (capacites.get('C5').get('Base') * coutCapacite).setScale(2);
                qli.Capa_HCE__c = (capacites.get('C5').get('Base') * coutCapacite).setScale(2);

                if (qli.TECH_CalendrierFournisseur__c.contains('Base')) {
                    Decimal base = prixGrille.Prix_Base__c;
                    qli.PrixHphMwh__c = base + margeMwh;
                    qli.PrixHchMwh__c = base + margeMwh;
                    qli.PrixHpeMwh__c = base + margeMwh;
                    qli.PrixHceMwh__c = base + margeMwh;
                } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')) {    
                    qli.PrixHphMwh__c = prixGrille.Prix_HP__c + margeMwh;
                    qli.PrixHpeMwh__c = prixGrille.Prix_HP__c + margeMwh;
                    qli.PrixHchMwh__c = prixGrille.Prix_HC__c + margeMwh;
                    qli.PrixHceMwh__c = prixGrille.Prix_HC__c + margeMwh;

                    qli.Capa_HP__c = (capacites.get('C5').get('HP') * coutCapacite).setScale(2);
                    qli.Capa_HC__c = (capacites.get('C5').get('HC') * coutCapacite).setScale(2);
                    qli.Capa_HPH__c = (capacites.get('C5').get('HP') * coutCapacite).setScale(2);
                    qli.Capa_HCH__c = (capacites.get('C5').get('HC') * coutCapacite).setScale(2);
                    qli.Capa_HPE__c = (capacites.get('C5').get('HP') * coutCapacite).setScale(2);
                    qli.Capa_HCE__c = (capacites.get('C5').get('HC') * coutCapacite).setScale(2);
                }
    
            } else {
                if (segment == 'C4') {
                    qli.Capa_HPH__c = (capacites.get('C4').get('HPH') * coutCapacite).setScale(2);
                    qli.Capa_HCH__c = (capacites.get('C4').get('HCH') * coutCapacite).setScale(2);
                    if(qli.TECH_FTA__c == 'BT > 36 kVA - LU'){
                        qli.Capa_Pointes__c = (capacites.get('C4').get('HPH') * coutCapacite).setScale(2);
                        qli.PointesMWh__c = prixGrille.Prix_HPH__c  + margeMwh;
                    }
                }
                if (segment == 'C2') {
                    qli.Capa_Pointes__c = (capacites.get('C2').get('Pointe') * coutCapacite).setScale(2);
                    qli.Capa_HPH__c = (capacites.get('C2').get('HPH') * coutCapacite).setScale(2);
                    qli.PointesMWh__c = prixGrille.Prix_Pointe__c + margeMwh;
                }
    
                qli.PrixHphMwh__c = prixGrille.Prix_HPH__c + margeMwh;
                qli.PrixHchMwh__c = prixGrille.Prix_HCH__c + margeMwh;
                qli.PrixHpeMwh__c = prixGrille.Prix_HPE__c + margeMwh;
                qli.PrixHceMwh__c = prixGrille.Prix_HCE__c + margeMwh;
            }
    
            qliToUpdate.add(qli);
        }

        
        if (prixGrille.Date_de_Validite__c != null){

        quoteToUpdate.Date_Validite_Offre__c = Datetime.newInstance(prixGrille.Date_de_Validite__c, Time.newInstance(17, 0, 0, 0));
        update quoteToUpdate;
        }
    
        if (!qliToUpdate.isEmpty()) {
            Double margeADE = margeMwh * 0.7;
            calculCommission(recordId,qliToUpdate,quote.Fournisseur__c,margeADE);
            for (Database.SaveResult sr : Database.update(qliToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors()[0].getMessage();
                    return output;
                }
            }
            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
        } else {
            output.success = false;
            output.message = 'Aucune QLI n\'est compatible avec la grille GEG';
        }
    
        return output;
    }

    private static FlowOutput calculatePriceHellio(String recordId, String dureeEngagement, Double coutCapacite, Double margeMwh) {
        FlowOutput output = new FlowOutput();
    
        List<QuoteLineItem> qliToUpdate = new List<QuoteLineItem>();
        Quote quote = [SELECT CEE__c,Minimum_date_de_debut__c,Fournisseur__c FROM Quote WHERE Id=:recordId];
        if (quote.Minimum_date_de_debut__c > Date.today().addYears(1)) {
            output.success = false;
            output.message = 'Date de démarrage trop lointaine';
            return output;
        }
        Boolean CEESoumis = quote.CEE__c == 'Soumis';

        for (QuoteLineItem qli : [
            SELECT Id, DebutDeFourniture__c, Nouvelle_Echeance__c, Puissance_souscrite__c,
                   TECH_Segment__c, TECH_FTA__c, TECH_Tarif__c, TECH_CalendrierFournisseur__c,
                   CAR_New__c,CARGaz__c, PDE__r.X12_mois_consommation_SGE__c
            FROM QuoteLineItem
            WHERE QuoteId = :recordId
              AND TECH_Segment__c IN ('C4', 'C2')
              AND CAR_New__c >= 50 AND CAR_New__c <= 300
              AND Puissance_souscrite__c <= 250
              AND PDE__r.X12_mois_consommation_SGE__c = true
        ]) {
            String month = qli.DebutDeFourniture__c.month() < 10 ? '0' + qli.DebutDeFourniture__c.month() : qli.DebutDeFourniture__c.month()+'';
            String dateDebut = month + '_' + qli.DebutDeFourniture__c.year();
            String labelCode = qli.TECH_Segment__c + '_' + dateDebut + '_' + dureeEngagement;
    
            Grille_Hellio__mdt prixGrille = Grille_Hellio__mdt.getInstance(labelCode);
            if (prixGrille == null) continue;
    
            // Mise à jour des champs communs
            qli.AbonnementMois__c = 0;
            qli.dureeEngagement__c = qli.DebutDeFourniture__c.monthsBetween(qli.Nouvelle_Echeance__c.addDays(1));

            
            qli.CeeMwh__c = CEESoumis ? prixGrille.CEE__c : 0;
    
            // Réinitialisation des capacités
            qli.Capa_Base__c = 0;
            qli.Capa_HP__c = 0;
            qli.Capa_HC__c = 0;
            qli.Capa_HPH__c = 0;
            qli.Capa_HCH__c = 0;
            qli.Capa_HPE__c = 0;
            qli.Capa_HCE__c = 0;
            qli.Capa_Pointes__c = 0;

            String segment = qli.TECH_Segment__c;
 
            if (segment == 'C4') {
                qli.Capa_HPH__c = (prixGrille.Prix_Capa_HPH__c * coutCapacite).setScale(2);
                qli.Capa_HCH__c = (prixGrille.Prix_Capa_HCH__c * coutCapacite).setScale(2);
                qli.Capa_HPE__c = (prixGrille.Prix_Capa_HPE__c * coutCapacite).setScale(2);
                qli.Capa_HCE__c = (prixGrille.Prix_Capa_HCE__c * coutCapacite).setScale(2);

                if(qli.TECH_FTA__c == 'BT > 36 kVA - LU'){
                    qli.Capa_Pointes__c = (prixGrille.Prix_Capa_HPH__c * coutCapacite).setScale(2);
                    qli.PointesMWh__c = prixGrille.Prix_HPH__c + margeMwh;
                }
            }
            else if (segment == 'C2') {
                qli.Capa_HPH__c = (prixGrille.Prix_Capa_HPH__c * coutCapacite).setScale(2);
                qli.Capa_HCH__c = (prixGrille.Prix_Capa_HCH__c * coutCapacite).setScale(2);
                qli.Capa_HPE__c = (prixGrille.Prix_Capa_HPE__c * coutCapacite).setScale(2);
                qli.Capa_HCE__c = (prixGrille.Prix_Capa_HCE__c * coutCapacite).setScale(2);

                qli.Capa_Pointes__c = (prixGrille.Prix_Capa_Pointe__c * coutCapacite).setScale(2);
                qli.PointesMWh__c = prixGrille.Prix_Pointe__c + margeMwh;
            }

            qli.PrixHphMwh__c = prixGrille.Prix_HPH__c + margeMwh;
            qli.PrixHchMwh__c = prixGrille.Prix_HCH__c + margeMwh;
            qli.PrixHpeMwh__c = prixGrille.Prix_HPE__c + margeMwh;
            qli.PrixHceMwh__c = prixGrille.Prix_HCE__c + margeMwh;
            qliToUpdate.add(qli);
        }
    
        if (!qliToUpdate.isEmpty()) {
            //On appelle la fonction calculCommission sans le paramètre dureeEngagement car la durée pouvant être FIN_26 ou FIN_27 ou FIN_28 le nombre de mois varie en fonction du compteur
            qliToUpdate = calculCommission(recordId,qliToUpdate,quote.Fournisseur__c,margeMwh/2);
            for (Database.SaveResult sr : Database.update(qliToUpdate)) {
                if (!sr.isSuccess()) {
                    output.success = false;
                    output.message = sr.getErrors()[0].getMessage();
                    return output;
                }
            }
            output.success = true;
            output.message = 'Les QLI compatibles ont été mises à jour';
        } else {
            output.success = false;
            output.message = 'Aucune QLI n\'est compatible avec la grille Hellio';
        }
    
        return output;
    }

    private static Decimal calculPrixPondere(Integer NombreMois2026, Integer NombreMois2027, Integer NombreMois2028, Decimal Prix2026, Decimal Prix2027, Decimal Prix2028){
        return  (((Prix2026 * NombreMois2026) + (Prix2027 * NombreMois2027) + (Prix2028 * NombreMois2028)) / ( NombreMois2026 + NombreMois2027 + NombreMois2028)).setScale(2);
    }

    private static list<QuoteLineItem> calculCommission(Id recordId,list<QuoteLineItem> listQLI,String fournisseur){
        Quote quote = [SELECT Opportunity.RecordType.Name FROM Quote where id=: recordId];
        String labelCode;
        Grille_remuneration__mdt remunerationGrille = null;
        Double nombreAnnee;

        switch on fournisseur {
            when 'TotalEnergies'{
                if(quote.Opportunity.RecordType.Name.contains('Gaz')){
                    for(QuoteLineItem qli : listQLI){
                        if(qli.CARGaz__c >= 0 && qli.CARGaz__c < 11 ){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('TotalEnergies_Palier1_'+String.valueOf(qli.DureeEngagement__c));
                            System.debug('TotalEnergies_Palier1');
                        } else if (qli.CARGaz__c >= 11 && qli.CARGaz__c < 30){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('TotalEnergies_Palier2_'+String.valueOf(qli.DureeEngagement__c));
                            System.debug('TotalEnergies_Palier2');
                        } else if (qli.CARGaz__c >= 30 && qli.CARGaz__c < 50){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('TotalEnergies_Palier3_'+String.valueOf(qli.DureeEngagement__c));
                            System.debug('TotalEnergies_Palier3');
                        } else if (qli.CARGaz__c >= 50 && qli.CARGaz__c < 100){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('TotalEnergies_Palier4_'+String.valueOf(qli.DureeEngagement__c));
                            System.debug('TotalEnergies_Palier4');
                        } else if (qli.CARGaz__c >= 100 && qli.CARGaz__c < 200){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('TotalEnergies_Palier5_'+String.valueOf(qli.DureeEngagement__c));
                            System.debug('TotalEnergies_Palier5');
                        } else if (qli.CARGaz__c >= 200 && qli.CARGaz__c <= 299){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('TotalEnergies_Palier6_'+String.valueOf(qli.DureeEngagement__c));
                            System.debug('TotalEnergies_Palier6');
                        }
                        qli.UnitPrice = remunerationGrille == null ? 0 : remunerationGrille.Remuneration__c; 
                    }    
                } else {
                    for(QuoteLineItem qli : listQLI){
                        if(qli.TECH_Segment__c == 'C4'){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('TotalEnergies_C4_'+String.valueOf(qli.DureeEngagement__c));
                        }
                        else {
                            remunerationGrille = Grille_remuneration__mdt.getInstance('TotalEnergies_'+qli.Puissance_souscrite__c+'_'+String.valueOf(qli.DureeEngagement__c));    
                        }
                        qli.UnitPrice = remunerationGrille == null ? 0 : remunerationGrille.Remuneration__c;
                    }
                }
            }
            when 'Ilek'{
                Decimal montant = Grille_remuneration__mdt.getInstance('Ilek') == null ? 0 : Grille_remuneration__mdt.getInstance('Ilek').Remuneration__c;
                for(QuoteLineItem qli : listQLI){
                    qli.UnitPrice = montant;
                }
            }
            when else {
                System.debug('Pas de calcul possible pour ce fournisseur');
            }
        }

        return listQLI;
    }

    private static list<QuoteLineItem> calculCommission(Id recordId,list<QuoteLineItem> listQLI,String fournisseur,Double margeMwhADE){
        Quote quote = [SELECT Opportunity.RecordType.Name FROM Quote where id=: recordId];
        Grille_remuneration__mdt remunerationGrille = null;
        String labelCode;
        Double nombreAnnee;

        switch on fournisseur {
            when 'Hellio' {
                if(quote.Opportunity.RecordType.Name.contains('Gaz')){
                    for(QuoteLineItem qli : listQLI){
                        nombreAnnee = qli.DureeEngagement__c /12; 
                        qli.UnitPrice = qli.CARGaz__c * margeMwhADE * nombreAnnee;
                    } 
                } else{
                    for(QuoteLineItem qli : listQLI){
                        nombreAnnee = qli.DureeEngagement__c /12; 
                        qli.UnitPrice = qli.CAR_New__c * margeMwhADE * nombreAnnee;
                    } 
                }
            }
            when 'GEG'{
                for(QuoteLineItem qli : listQLI){
                    nombreAnnee = qli.DureeEngagement__c /12; 
                    qli.UnitPrice = qli.CAR_New__c * margeMwhADE * nombreAnnee;
                }
            }
            when 'Ekwateur' {
                if(quote.Opportunity.RecordType.Name.contains('Gaz')){
                    for(QuoteLineItem qli : listQLI){
                        labelCode = 'Ekwateur_GAZ'+'_'+margeMwhADE.intValue();
                        nombreAnnee = qli.DureeEngagement__c /12; 
                        remunerationGrille = Grille_remuneration__mdt.getInstance(labelCode);
                        qli.UnitPrice = remunerationGrille == null ? 0 : (qli.CARGaz__c * (remunerationGrille.Remuneration__c/2) * nombreAnnee).setScale(2);
                    } 
                } else{
                    for(QuoteLineItem qli : listQLI){
                        labelCode = 'Ekwateur_ELEC'+'_'+margeMwhADE.intValue();
                        nombreAnnee = qli.DureeEngagement__c /12; 
                        remunerationGrille = Grille_remuneration__mdt.getInstance(labelCode);
                        qli.UnitPrice = remunerationGrille == null ? 0 : (qli.CAR_New__c * (remunerationGrille.Remuneration__c/2) * nombreAnnee).setScale(2);
                    } 
                }
            }
            when else {
                System.debug('Pas de calcul possible pour ce fournisseur');
            }            
        }
        return listQLI;
    }

    private static list<QuoteLineItem> calculCommission(Id recordId,list<QuoteLineItem> listQLI,String fournisseur,String dureeOffre){
        Quote quote = [SELECT Opportunity.RecordType.Name FROM Quote where id=: recordId];

        String labelCode;
        Grille_remuneration__mdt remunerationGrille = null;
        System.debug('Calcul commission pour le fournisseur ' + fournisseur + ' et la durée d\'offre ' + dureeOffre);

        switch on fournisseur {

            when 'Vattenfall'{
                for(QuoteLineItem qli : listQLI){
                    if(qli.TECH_CalendrierFournisseur__c.contains('Base')){
                        labelCode = 'Vattenfall_Base_'+qli.Puissance_souscrite__c+'_'+dureeOffre;
                    } else if (qli.TECH_CalendrierFournisseur__c.contains('HP/HC')){
                        labelCode = 'Vattenfall_HPHC_'+qli.Puissance_souscrite__c+'_'+dureeOffre;
                    }
                    remunerationGrille = Grille_remuneration__mdt.getInstance(labelCode);
                    qli.UnitPrice = remunerationGrille == null ? 0 : remunerationGrille.Remuneration__c;

                }
            }
            when 'Engie'{
                if(quote.Opportunity.RecordType.Name.contains('Gaz')){
                    for(QuoteLineItem qli : listQLI){
                        if(qli.CARGaz__c >= 6 && qli.CARGaz__c < 29 ){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('Engie_Palier1');
                        } else if (qli.CARGaz__c >= 30 && qli.CARGaz__c < 49){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('Engie_Palier2');
                        } else if (qli.CARGaz__c >= 50 && qli.CARGaz__c < 99){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('Engie_Palier3');
                        } else if (qli.CARGaz__c >= 100 && qli.CARGaz__c < 199){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('Engie_Palier4');
                        } else if (qli.CARGaz__c >= 200){
                            remunerationGrille = Grille_remuneration__mdt.getInstance('Engie_Palier5');
                        }
                        qli.UnitPrice = remunerationGrille == null ? 0 : remunerationGrille.Remuneration__c;
                    }  
                }
                else {
                    for(QuoteLineItem qli : listQLI){
                        labelCode = 'Engie_'+Integer.valueOf(qli.Puissance_souscrite__c)+'_'+dureeOffre;
                        remunerationGrille = Grille_remuneration__mdt.getInstance(labelCode);
                        System.debug('prixGrille ' + (remunerationGrille != null ? String.valueOf(remunerationGrille.Remuneration__c) : 'null'));
                        qli.UnitPrice = remunerationGrille == null ? 0 : remunerationGrille.Remuneration__c;
                    }
                }
            }
            
            when else {
                System.debug('Pas de calcul possible pour ce fournisseur');
            }
        }

        return listQLI;
    }

    String nom;
    Date dateDeVente;

    AP021_GrilleFournisseur maVariable = new AP021_GrilleFournisseur();


    public class FlowInput {
        @invocableVariable public Id recordId;
        @invocableVariable public String fournisseur;
        @invocableVariable public String dureeOffre;
        @InvocableVariable public Double margeMwh;
    }

    public class FlowOutput {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
    }
}