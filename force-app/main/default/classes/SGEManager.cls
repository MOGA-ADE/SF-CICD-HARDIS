global class SGEManager {

    public static Config_Enedis__c config = Config_Enedis__c.getInstance();
    public static Map<String, Mapping_FTA__mdt> mappingFTA =  Mapping_FTA__mdt.getAll();
    public static Map<String,Id> recordTypeMap;
    public static List<String> segments = new List<String>{'C1','C2','C3','C4','C5'};
    public static final String SUCCESS_MESSAGE = 'OK';
    public static final String NAMESPACE_ENVELOPE = 'http://schemas.xmlsoap.org/soap/envelope/';
    public static final String NAMESPACE_TECH = 'http://www.enedis.fr/sge/b2b/technique/v1.0';
    public static final String NAMESPACE_MESURE = 'http://www.enedis.fr/sge/b2b/services/consultermesures/v1.1';
    public static final String NAMESPACE_DONNEETECH = 'http://www.enedis.fr/sge/b2b/services/consulterdonneestechniquescontractuelles/v1.0';
    public static final String NAMESPACE_M023_FINES = 'https://sge-b2b.enedis.fr/services/commandehistoriquedonneesmesuresfines/v1';
    public static final String type = 'TOUT';
    
    //Static block that initialize record type used for each segment
    static {
        recordTypeMap = new Map<String,Id>();
        Map<String, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.PDE__c.getRecordTypeInfosByDeveloperName();
        for (String seg : segments) {
            if (seg == 'C1' || seg == 'C2')
                recordTypeMap.put(seg,rtMap.get('Elec_C1C2').getRecordTypeId());
            else if (seg == 'C3')
                recordTypeMap.put(seg,rtMap.get('Elec_C3_C4').getRecordTypeId());
            else if (seg == 'C4')
                recordTypeMap.put(seg,rtMap.get('Elec_C3_C4').getRecordTypeId());
            else     
                recordTypeMap.put(seg,rtMap.get('PDE_ElecC5').getRecordTypeId());
        }
    }

    /*
     * Methode used in Visual Flow in order to refresh all informations on a Point d'energie record
     * The methode call ConsulterMesure and ConsultationDonnéeTechnique web service (Enedis)
     * The method perform an update on the record 
     *     @List<PDE__c> siteId : represent the Salesforce a list of Point d'energie. 
     *                        @InvocableMethod are design to manage list but the Flow will always send one PDE
     *     Return List<WrapPDEInfoEnedis> : A wrapper that contains all informations from the ws
     */
    @InvocableMethod(label='Refresh site')
    public static List<WrapPDEInfoEnedis> refreshSiteInFlow (List<PDE__c> listPDE) {
        WrapPDEInfoEnedis result = new WrapPDEInfoEnedis();
        PDE__c pde = listPDE.get(0);
        result.siteName = pde.Name;
        try {
            callConsulterMesure(pde.ReferencePointEnergie_Refonte__c,result);
            consulterPoint(pde.ReferencePointEnergie_Refonte__c,result);
            updateSite(pde.Id,result);
            result.messageUpdate = SUCCESS_MESSAGE;
            AP034_TURPEOptimisationController.invokeTURPEIfEligible(pde.Id);
        }catch (Exception e) {
            result.messageUpdate = e.getMessage();
        }
        
        return new List<WrapPDEInfoEnedis>{result};
    }

    /*
     * Methode used in LWC in order to refresh all informations on a Point d'energie record
     * The methode call ConsulterMesure and ConsultationDonnéeTechnique web service (Enedis)
     *     @Id siteId : represent the Salesforce Id of a Point d'energie
     *     Return WrapPDEInfoEnedis : A wrapper that contains all informations from the ws
     */
    @AuraEnabled
    public static WrapPDEInfoEnedis refreshSiteInformation(Id siteId) {
        WrapPDEInfoEnedis result = new WrapPDEInfoEnedis();
        try {
            PDE__c pde = [SELECT ReferencePointEnergie_Refonte__c, Date_signature_ACD__c FROM PDE__c WHERE id =:siteId AND ACD_valide__c =:true];
            callConsulterMesure(pde.ReferencePointEnergie_Refonte__c, result);
            consulterPoint(pde.ReferencePointEnergie_Refonte__c, result);
            AP034_TURPEOptimisationController.invokeTURPEIfEligible(pde.Id);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' (Line: '+e.getLineNumber()+')');
        }
        return result;
    }


    /*
     * Future method used by Mulesoft in order to refresh all informations on a Point d'energie record
     * The methode call ConsulterMesure and ConsultationDonnéeTechnique web service (Enedis)
     *     @Id siteId : represent the Salesforce Id of a Point d'energie
     *     Return WrapPDEInfoEnedis : A wrapper that contains all informations from the ws
     */
    @future(callout=true)
    public static void refreshSiteInformationFuture(Id siteId) {
        WrapPDEInfoEnedis result = new WrapPDEInfoEnedis();
        

        try {
            PDE__c pde = [SELECT Name,ReferencePointEnergie_Refonte__c FROM PDE__c WHERE id =:siteId AND ACD_valide__c =:true];
            result.siteName = pde.Name;
            callConsulterMesure(pde.ReferencePointEnergie_Refonte__c,result);
            System.debug('callConsulterMesure Success');
            consulterPoint(pde.ReferencePointEnergie_Refonte__c,result);
            System.debug('consulterPoint Success');
            updateSite(siteId,result);
            result.messageUpdate = SUCCESS_MESSAGE;
            pde = [SELECT Id, NumeroVoie__c, voie__c,ReferencePointEnergie_Refonte__c,Date_signature_ACD__c, OwnerId FROM PDE__c WHERE id =:siteId AND ACD_valide__c =:true];
            string numeroVoie = pde.NumeroVoie__c ?? ''; 
            string voie = pde.voie__c ?? '';
            pde.Name = numeroVoie + ' ' + voie;
            update pde;
            Datetime ActionsDate = Datetime.now().addHours(+1);
            AP034_TURPEOptimisationController.invokeTURPEIfEligible(pde.Id);

        }catch (Exception e) {
            System.debug('Compteur non reconnu, conversion en compteur GAZ');
            Id PDERecordTypeGaz = [SELECT Id FROM RecordType WHERE SobjectType = 'PDE__c' and DeveloperName = 'PDE_Gaz' LIMIT 1].Id;
            PDE__c updatePDE = [SELECT Id, ReferencePointEnergie_Refonte__c FROM PDE__c WHERE Id = :siteId LIMIT 1];
            updatePDE.PCE_Refonte__c = updatePDE.ReferencePointEnergie_Refonte__c;
            updatePDE.ReferencePointEnergie_Refonte__c = null;
            updatePDE.RecordTypeId = PDERecordTypeGaz;
            update updatePDE;
        }
    }

    /*
     * Methode that perform the callout to ConsulterMesure
     *     @string prm : represent the identification of the Point d'energie in Enedis
     *     @WrapPDEInfoEnedis infoSite : Object used do the mapping betweeen the 2 systems
     *                                   Get information on consommations et status of the call
     */
    public static void callConsulterMesure (String prm, WrapPDEInfoEnedis infoSite) {
        System.debug('config Endpoint_ConsulterMesure__c: ' + config.Endpoint_ConsulterMesure__c);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setClientCertificateName(config.CertificateName__c);
        req.setEndpoint(config.Endpoint_ConsulterMesure__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml');
        req.setTimeout(Integer.valueOf(config.timeout__c));
        string body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://www.enedis.fr/sge/b2b/technique/v1.0" xmlns:v11="http://www.enedis.fr/sge/b2b/services/consultermesures/v1.1">'
            +'<soapenv:Header>'
            +'<v1:entete>'
            +'<version>1.1</version>'
            +'<infoFonctionnelles>'
            +'<pointId>'+prm+'</pointId>'
            +'</infoFonctionnelles>'
            +'<infoDemandeur>'
            +'<loginDemandeur>mathilde.huber@alliancedesenergies.fr</loginDemandeur>'
            +'</infoDemandeur>'
            +'</v1:entete>'
            +'</soapenv:Header>'
            +'<soapenv:Body>'
            +'<v11:consulterMesures>'
            +'<pointId>'+prm+'</pointId>'
            +'<loginDemandeur>mathilde.huber@alliancedesenergies.fr</loginDemandeur>'
            +'<contratId>4834000</contratId>'
            +'<autorisationClient>true</autorisationClient>'
            +'</v11:consulterMesures>'
            +'</soapenv:Body>'
            +'</soapenv:Envelope>';
        
        req.setBody(body);
        HttpResponse res = h.send(req); 
        if(!Test.isRunningTest()){
            ApiLogger.publish('SGEManager.callConsulterMesure', 'SGE', req.getEndpoint(), req.getBody(), res.getBody(), res.getStatusCode(), req.getMethod(), null);
        }
        infoSite.bodyM = res.getBody();
        infoSite.messageConsulterMesure = checkReponseStatus(res);
        if (infoSite.messageConsulterMesure == SUCCESS_MESSAGE) {
            System.debug('infoSite ' +infoSite);
            getConsoByPoste(infoSite,res);
        }
    }
    
    /*
     * Methode that return the max date regardless the "poste" in ConsulterMesure callout reponse
	 */
    public static Date getMaxDate (List<Dom.XMLNode> allMesures) {
        Date maxDate;
        for (Dom.XMLNode mesure : allMesures) {
            for (Dom.XMLNode m : mesure.getChildElement('mesuresDatees',  null).getChildren()) {
                Date dateMesureEnd = Date.valueOf(m.getChildElement('dateFin',null).getText());
                if (maxDate == null || maxDate < dateMesureEnd)
                    maxDate = dateMesureEnd;
            }
        }
        return maxDate;
    }
    
    /*
     * Methode used to parse the result of a ConsulterMesure callout
     *     @HttpResponse response : represent the response of a callout
     *     @WrapPDEInfoEnedis info : use to map the consommation and the status of the callout
     */
    public static void getConsoByPoste (WrapPDEInfoEnedis info, HttpResponse response) {
        Dom.Document doc = response.getBodyDocument();
        Dom.XMLNode xmlDoc = doc.getRootElement();
        Dom.XMLNode nodeBody = xmlDoc.getChildElement('Body',NAMESPACE_ENVELOPE).getChildElement('consulterMesuresResponse',NAMESPACE_MESURE);
        Dom.XMLNode[] serieMesures = nodeBody.getChildElement('seriesMesuresDateesGrilleTurpe','') != null ? nodeBody.getChildElement('seriesMesuresDateesGrilleTurpe','').getChildren() : (nodeBody.getChildElement('seriesMesuresDateesGrilleTurpe',null) != null ? nodeBody.getChildElement('seriesMesuresDateesGrilleTurpe',null).getChildren():(nodeBody.getChildElement('seriesMesuresDateesGrilleFrn','') != null ? nodeBody.getChildElement('seriesMesuresDateesGrilleFrn','').getChildren() : nodeBody.getChildElement('seriesMesuresDateesGrilleFrn',null).getChildren()));
        Date dateFrom;
        Date dateTo;
        
        Map<String,Dom.XMLNode> mapConso = new Map<String,Dom.XMLNode>();
        for (Dom.XMLNode mesure : serieMesures) {
            String poste =  mesure.getChildElement('classeTemporelle',null).getAttributeValue('code',null);
            if (mapConso.containsKey(poste)) {
                Dom.XMLNode[] oldMesure = mapConso.get(poste).getChildElement('mesuresDatees',  null).getChildren();
                mesure.getChildElement('mesuresDatees',  null).getChildren().addAll(oldMesure);
                
                mapConso.put(poste,mesure);
            } else {
                mapConso.put(poste,mesure);
            }
        }
        dateTo = getMaxDate(mapConso.values());
        
        for (Dom.XMLNode mesure : mapConso.values()) {
            Decimal conso = 0;
            Date datePosteFrom;
            Date datePosteTo;
            String poste =  mesure.getChildElement('classeTemporelle',null).getAttributeValue('code',null);
            for (Dom.XMLNode m : mesure.getChildElement('mesuresDatees',  null).getChildren()) {
                System.debug('XML ' + m.getText());
                Date dateMesureStart = Date.valueOf(m.getChildElement('dateDebut',null).getText());
                Date dateMesureEnd = Date.valueOf(m.getChildElement('dateFin',null).getText());
                if (dateMesureStart.daysBetween(dateTo) > 366)
                    continue;
                else {
                    dateFrom = dateFrom == null || dateFrom > dateMesureStart ? dateMesureStart :dateFrom;
                    conso = conso + Decimal.valueof(m.getChildElement('valeur', null).getText());
                }
                
            }
            System.debug('poste = '+poste);
            System.debug('conso '+conso );
            switch on poste {
                when 'BASE' {
                    info.consoBase = conso;
                }
                when 'HP', 'BCHP' {
                    info.consoHP = conso;
                }
                when 'HC', 'BCHC' {
                    info.consoHC = conso;
                }
                when 'Pointe' {
                    info.consoPointe = conso;                 
                }
                when 'P', 'HPH' {
                    info.consoHPH = conso;
                }
                when 'HCH' {
                    info.consoHCH= conso;
                }
                when 'HPE', 'HPB' {
                    info.consoHPE = conso;
                }
                when 'HCE', 'HCB' {
                    info.consoHCE = conso;
                }
                when else {

                }
            }
        }
        System.debug('conso.consoHC '+info.consoHC );
        System.debug('info.consoHP '+info.consoHP );
        info.dateConsoStart = dateFrom;
        info.dateConsoEnd = dateTo; 
        info.lessThan12months = dateFrom.daysBetween(dateTo) < 365;     
        info.calculateCAR();
        info.mesuresUpdatable = true;
    }

    /*
     * Methode that perform the callout to ConsulterDonnéesTechniques
     *     @string prm : represent the identification of the Point d'energie in Enedis
     *     @WrapPDEInfoEnedis info : Object used do the mapping betweeen the 2 systems
     *                                   Get information on consommations et status of the call
     */
    public static void consulterPoint (String prm, WrapPDEInfoEnedis info) {
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setClientCertificateName(config.CertificateName__c);
        req.setEndpoint(config.Endpoint_ConsulterDonneeTech__c);
        req.setMethod('POST');
        req.setTimeout(Integer.valueOf(config.timeout__c));
        req.setHeader('Content-Type', 'text/xml');
        string body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:v1="http://www.enedis.fr/sge/b2b/technique/v1.0" xmlns:v10="http://www.enedis.fr/sge/b2b/services/consulterdonneestechniquescontractuelles/v1.0">'
        +'<soapenv:Header>'
        +'<v1:entete>'
        +'<version>1.1</version>'
        +'<infoDemandeur>'
        +'<loginDemandeur>mathilde.huber@alliancedesenergies.fr</loginDemandeur>'
        +'</infoDemandeur>'
        +'</v1:entete>'
        +'</soapenv:Header>'
        +'<soapenv:Body>'
        +'<v10:consulterDonneesTechniquesContractuelles>'
        +'<pointId>'+prm+'</pointId>'
        +'<loginUtilisateur>mathilde.huber@alliancedesenergies.fr</loginUtilisateur>'
        +'<autorisationClient>true</autorisationClient>'   
        +'</v10:consulterDonneesTechniquesContractuelles>'
        +'</soapenv:Body>'
        +'</soapenv:Envelope>';

        req.setBody(body);
        HttpResponse res = h.send(req);
        if(!Test.isRunningTest()){
            ApiLogger.publish('SGEManager.consulterPoint', 'SGE', req.getEndpoint(), req.getBody(), res.getBody(), res.getStatusCode(), req.getMethod(), null);
        }
        info.bodyT = res.getBody();
        info.messageConsulterPoint = checkReponseStatus(res);
        if (res.getStatusCode() == 200)
            readTechnicalInfo(info, res);
            System.debug('info read tech' +info);
    }

    /*
     * Methode used to parse the result of a ConsulterDonnéesTechniques callout
     *     @HttpResponse response : represent the response of a callout
     *     @WrapPDEInfoEnedis info : use to map the information of sites and the status of the callout
     */
    public static void readTechnicalInfo (WrapPDEInfoEnedis info, HttpResponse response) {
        Dom.Document doc = response.getBodyDocument();
        Dom.XMLNode xmlDoc = doc.getRootElement();
        Dom.XMLNode nodeInfo = xmlDoc.getChildElement('Body',NAMESPACE_ENVELOPE).getChildElement('consulterDonneesTechniquesContractuellesResponse', NAMESPACE_DONNEETECH).getChildElement('point', null);
        Dom.XMLNode nodeStrutureTarifaire = nodeInfo.getChildElement('situationContractuelle', null)?.getChildElement('structureTarifaire',null);
        Dom.XMLNode infoGenerale = nodeInfo.getChildElement('donneesGenerales',null);
        Dom.XMLNode nodePsSoutirage = nodeInfo.getChildElement('situationAlimentation', null)?.getChildElement('alimentationPrincipale', null)?.getChildElement('puissanceRaccordementSoutirage', null);

        info.ville = infoGenerale.getChildElement('adresseInstallation', null).getChildElement('commune', null).getChildElement('libelle', null).getText();
        info.adresse = infoGenerale.getChildElement('adresseInstallation', null).getChildElement('numeroEtNomVoie',null).getText();
        info.codePostal = infoGenerale.getChildElement('adresseInstallation', null).getChildElement('codePostal',null).getText();
        info.segment = infoGenerale.getChildElement('segment',null).getChildElement('libelle', null).getText();
        info.etatContractuel = infoGenerale.getChildElement('etatContractuel',null).getChildElement('libelle', null).getText();
        
        // Ajout de la date de dernière modification de la FTA
        String dateModificationFTABrute = infoGenerale.getChildElement('dateDerniereModificationFormuleTarifaireAcheminement', null)?.getText();

        if (String.isNotBlank(dateModificationFTABrute)) {
            String dateModificationFTASeule = dateModificationFTABrute.substring(0, 10);
            info.dateDerniereModificationFTA = Date.valueOf(dateModificationFTASeule);
        }

        // Ajout de la puissance de soutirage
        String psValueStr = nodePsSoutirage?.getChildElement('valeur', null)?.getText();
        if (String.isNotBlank(psValueStr)) { info.psSoutirage = Decimal.valueOf(psValueStr); }

        if (nodeStrutureTarifaire != null) {
            if (nodeStrutureTarifaire.getChildElement('calendrierFrn',null) != null) {
                info.FTA = nodeStrutureTarifaire.getChildElement('formuleTarifaireAcheminement', null).getAttributeValue('code', null);
                String psMax = nodeStrutureTarifaire.getChildElement('puissanceSouscriteMax', null).getChildElement('valeur', null).getText();
                info.CalendrierFrn = nodeStrutureTarifaire.getChildElement('calendrierFrn',null).getChildElement('libelle',null).getText();
                String codefournisseur = nodeStrutureTarifaire.getChildElement('calendrierFrn',null).getAttributeValue('code', null);
                System.debug('codefournisseur '+codefournisseur);
                System.debug('psMax '+psMax);
                info.psMoyenne = Decimal.valueOf(psMax);
            } else {
                info.FTA = nodeStrutureTarifaire.getChildElement('formuleTarifaireAcheminement',null).getAttributeValue('code', null);
                for (Dom.XMLNode d : nodeStrutureTarifaire.getChildElement('denivelePuissances',null).getChildElement('classesTemporelles', null).getChildren()) {
                    if (d.getName() == null)
                        continue;
                    
                    String poste = d.getAttribute('code', null);
                    Decimal ps = Decimal.valueOf(d.getChildElement('puissance', null).getChildElement('valeur', null).getText());
                    switch on poste {
                        when 'HPH' {
                            info.psHPH = ps;
                        }
                        when 'HCH' {
                            info.psHCH = ps;
                        }
                        when 'HPE' {
                            info.psHPE = ps;
                        }
                        when 'HCE' {
                            info.psHCE = ps;                
                        }
                        when else {
                            info.psPointe = ps;
                        }
                    }
                    Decimal psSum = info.psHPH + info.psHCH + info.psHPE + info.psHCE + info.psPointe;
                    Decimal divider = Math.signum(info.psHPH) + Math.signum(info.psHCH) + Math.signum(info.psHPE) + Math.signum(info.psHCE) + Math.signum(info.psPointe);
                    info.psMoyenne =psSum/divider; 
                }
            }
        } else {
            info.FTA = nodeInfo.getChildElement('situationAlimentation',null).getChildElement('alimentationPrincipale', null).getChildElement('domaineTension', null).getAttributeValue('code', null);
            String psMax = nodeInfo.getChildElement('situationAlimentation',null).getChildElement('alimentationPrincipale', null).getChildElement('puissanceRaccordementSoutirage', null).getChildElement('valeur', null).getText();
            info.psBase = Decimal.valueOf(psMax);
            info.psHP = Decimal.valueOf(psMax);
            info.psHC = Decimal.valueOf(psMax);
        }
        info.techDataUpdatable = true;
        System.debug('info Puissance info.psHP '+info.psHP);
        System.debug('info Puissance info.psHC '+info.psHC);
        System.debug('info To check '+info);
    }

    /*
     * Méthode pour commander l'historique des courbes de charge (M023)
     * @param prm : Identifiant du point
     * @param dateDebut : Date de début (Y-m-d)
     * @param dateFin : Date de fin (Y-m-d)
     * @return String : L'identifiant de l'affaire SGE pour le suivi
     */
    @AuraEnabled
    public static String commandeCourbeDeCharge(Id siteId) {
        PDE__c pde = [SELECT ReferencePointEnergie_Refonte__c FROM PDE__c WHERE Id = :siteId LIMIT 1];
        String prm = pde.ReferencePointEnergie_Refonte__c;
        
        // Dates : maximum 24 mois pour le flux R63 [cite: 155]
        Date dateFin = Date.today();
        Date dateDebut = dateFin.addMonths(-12);

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setClientCertificateName(config.CertificateName__c);
        req.setEndpoint(config.Endpoint_M023_Fines__c);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'text/xml');
        req.setTimeout(Integer.valueOf(config.timeout__c));

        String body = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" '
            + 'xmlns:v1="' + NAMESPACE_M023_FINES + '">'
            + '<soapenv:Header></soapenv:Header>'
            + '<soapenv:Body>'
            + '<v1:demandePublicationMesuresFines>'
                + '<donneesGenerales>'
                    + '<initiateurLogin>mathilde.huber@alliancedesenergies.fr</initiateurLogin>'
                    + '<contratId>4834000</contratId>'
                + '</donneesGenerales>'
                + '<demande>'
                    + '<format>JSON</format>'
                    + '<pointIds><pointId>' + prm + '</pointId></pointIds>'
                    + '<mesuresTypeCode>COURBES</mesuresTypeCode>'
                    + '<mesuresCorrigees>false</mesuresCorrigees>'
                    + '<dateDebut>' + String.valueOf(dateDebut) + '</dateDebut>'
                    + '<dateFin>' + String.valueOf(dateFin) + '</dateFin>'
                    + '<sens>SOUTIRAGE</sens>'
                    + '<cadreAcces>ACCORD_CLIENT</cadreAcces>'
                + '</demande>'
            + '</v1:demandePublicationMesuresFines>'
            + '</soapenv:Body>'
            + '</soapenv:Envelope>';

        req.setBody(body);
        HttpResponse res = h.send(req);

        // Logging pour historique
        if(!Test.isRunningTest()){
            ApiLogger.publish('SGEManager.commandeCourbeDeCharge', 'SGE', req.getEndpoint(), req.getBody(), res.getBody(), res.getStatusCode(), req.getMethod(), null);
        }

        Dom.Document doc = res.getBodyDocument();
        Dom.XMLNode root = doc.getRootElement();
        Dom.XMLNode bodyNode = root.getChildElement('Body', 'http://schemas.xmlsoap.org/soap/envelope/');

        // CAS DE SUCCÈS (Code 200)
        if (res.getStatusCode() == 200) {
            // 1. On cherche la balise affaireId avec le namespace v1
            Dom.XMLNode affaireNode = bodyNode.getChildElement('affaireId', NAMESPACE_M023_FINES);

            String affaireId = 'Inconnu';

            if (affaireNode != null) {
                affaireId = affaireNode.getText();
                PDE__c updatePDE = new PDE__c(Id = siteId, Numero_Affaire_SGE__c = affaireId);
                update updatePDE;
            }
        
            return 'Demande reçu par Enedis et sera traité avec l\'affaire Id : ' + affaireId;
        }

        // CAS D'ERREUR (Code 500 ou autre) - On parse le XML d'erreur fourni
        String xmlError = '';
        Dom.XMLNode faultNode = bodyNode.getChildElement('Fault', 'http://schemas.xmlsoap.org/soap/envelope/');
        if (faultNode != null) {
            Dom.XMLNode detailNode = faultNode.getChildElement('detail', null);
            if (detailNode != null) {
                Dom.XMLNode erreurNode = detailNode.getChildElement('erreur', null);
                if (erreurNode != null) {
                    Dom.XMLNode resNode = erreurNode.getChildElement('resultat', null);
                    Dom.XMLNode descNode = erreurNode.getChildElement('description', null);
                    xmlError = (resNode != null ? resNode.getText() : '') + (descNode != null ? ' (' + descNode.getText() + ')' : '');
                }
            }
        }

        if (String.isBlank(xmlError)) {
            xmlError = 'Erreur technique HTTP ' + res.getStatusCode();
        }

        xmlError = xmlError.replace('Ã¨', 'è').replace('Ã©', 'é').replace('Ã', 'à').replace('Ãª', 'ê');

        return 'Erreur lors de la demande : ' + xmlError;
    }
    
    /*
     * Methode that perform an update of a Point d'energie with all the information collected from Enedis
     *     @ID siteId : represent the Salesforce Id of a Point d'energie
     *     @WrapPDEInfoEnedis infoSite : Object used do the mapping betweeen the 2 systems
     *                                   Get information on Enedis and status of the callouts
     */
    @AuraEnabled
    public static void updateSite (Id siteId, WrapPDEInfoEnedis infoSite) {
        PDE__c site = new PDE__c (id = siteId);
        System.debug('infoSite '+infoSite);
        System.debug('la valeur de  '+ infoSite.mesuresUpdatable );
        if(infoSite.mesuresUpdatable) {
            site.Conso_Base__c = (infoSite.consoBase != 0 ? infoSite.consoBase/1000 : infoSite.consoBase).setScale(2);
            site.ConsoHP__c = (infoSite.consoHP != 0 ? infoSite.consoHP/1000 : infoSite.consoHP).setScale(2);
            site.ConsoHC__c = (infoSite.consoHC != 0 ? infoSite.consoHC/1000 : infoSite.consoHC).setScale(2);
            site.Conso_HPH__c = (infoSite.consoHPH != 0 ? infoSite.consoHPH/1000 : infoSite.consoHPH).setScale(2);
            site.Conso_HCH__c = (infoSite.consoHCH != 0 ? infoSite.consoHCH/1000 : infoSite.consoHCH).setScale(2);
            site.Conso_HCE__c = (infoSite.consoHCE != 0 ? infoSite.consoHCE/1000 : infoSite.consoHCE).setScale(2);
            site.Conso_HPE__c = (infoSite.consoHPE != 0 ? infoSite.consoHPE/1000 : infoSite.consoHPE).setScale(2);
            site.Conso_Pointe__c = (infoSite.consoPointe != 0 ? infoSite.consoPointe/1000 : infoSite.consoPointe).setScale(2);
            site.Consommation_Annuelle_de_R_f_rence_Elec__c = (infoSite.carSite != 0 ? infoSite.carSite/1000 : infoSite.carSite).setScale(2);
            site.Date_debut_Releve__c = infoSite.dateConsoStart;
            site.Date_fin_Releve__c = infoSite.dateConsoEnd;
            site.Date_MAJ_Enedis__c = System.Today();
        }
        if (infoSite.techDataUpdatable) {
           Pattern myPattern = Pattern.compile('^(\\d+([\\-\\s\\/]?\\d+)?)');
            matcher myMatcher = myPattern.matcher(infoSite.adresse);    
            if(myMatcher.find()){
                site.NumeroVoie__c = myMatcher.group(0);
                site.voie__c = infoSite.adresse.replace(myMatcher.group(0),'');
            }
            else{
                site.voie__c = infoSite.adresse;
            }
            site.Code_Postal__c = infoSite.codePostal;
            site.Ville__c = infoSite.ville;
            site.Segment__c = infoSite.segment;
            site.FTA__c = getFTALabel(infoSite.FTA); 
            site.Etat_contractuel__c = infoSite.etatContractuel;
            site.Date_derniere_modification_FTA__c = infoSite.dateDerniereModificationFTA;
            site.Puissance_souscrite__c = infoSite.psMoyenne?.round();
            site.Puissance_raccordement_soutirage__c = infoSite.psSoutirage;
            site.RecordTypeId = recordTypeMap.get(infoSite.segment);
            System.debug('CalendrierFrn ' + infoSite.CalendrierFrn);
            site.Calendrier_fournisseur__c = infoSite.CalendrierFrn;
            if(infoSite.lessThan12months == null){
                site.X12_mois_consommation_SGE__c = false;
            }
            else{
                site.X12_mois_consommation_SGE__c = !infoSite.lessThan12months;
            }
        }
        try {  
            update site;
            infoSite.messageUpdate = SUCCESS_MESSAGE;
        } catch (DmlException e) {
            infoSite.messageUpdate =  e.getMessage();
            throw new AuraHandledException(e.getMessage());
        } 
    }

    /*
     * Methode used to parse the FTA from Enedis
     *     @String fta: fta provided by Enedis
     *     return String = corresponding FTA in Salesforce
     */
    public static String getFTALabel (String fta) {
        if (mappingFTA.containsKey(fta))
            return mappingFTA.get(fta).SF_FTA__c;
        else 
            return 'Aucun';
    }
    
    /*
     * Methode used to check if the callout is in success
     *     @HttpResponse response : represent the response of a callout
     *     return String = OK if is a success, error message otherwise
     */
    public static String checkReponseStatus (HttpResponse response) {
        System.debug('checkReponseStatus');
        Dom.Document doc = response.getBodyDocument();
        Dom.XMLNode xmlDoc = doc.getRootElement();
        Dom.XMLNode body = xmlDoc.getChildElement('Body', NAMESPACE_ENVELOPE);
        Dom.XMLNode nodeResultat;

        if (response.getStatusCode() == 200) {

            Dom.XMLNode acquittement = xmlDoc.getChildElement('Header',NAMESPACE_ENVELOPE).getChildElement('acquittement',NAMESPACE_ENVELOPE) != null ? xmlDoc.getChildElement('Header',NAMESPACE_ENVELOPE).getChildElement('acquittement',NAMESPACE_ENVELOPE) : xmlDoc.getChildElement('Header',NAMESPACE_ENVELOPE).getChildElement('acquittement',NAMESPACE_TECH); 
            nodeResultat = acquittement.getChildElement('resultat','') != null ? acquittement.getChildElement('resultat','') : acquittement.getChildElement('resultat',null);
            if (nodeResultat.getAttribute('code', null) == 'SGT200') {
                return SUCCESS_MESSAGE;
            } else { 
                return nodeResultat.getText();        
            } 
        } else {
            Dom.XMLNode fault = body.getChildElement('Fault', NAMESPACE_ENVELOPE);
            if (fault != null) {
                Dom.XMLNode detail = fault.getChildElement('detail', null);
                if (detail != null) {
                    for (Dom.XMLNode child : detail.getChildren()) {
                        if (child.getName() == 'erreur') {
                            Dom.XMLNode res = child.getChildElement('resultat', null);
                            return (res != null) ?  res.getText() + '. Erreur Code ' + res.getAttribute('code', null) : 'Erreur inconnue';
                        }
                    }
                }
            }
            return 'Erreur HTTP ' + response.getStatusCode() + ' : ' + response.getStatus();
        }
    }

    // Deprecated
    @AuraEnabled (cacheable=true)
    public static PDE__c calculatePsMaxForAYear(PDE__c site) { 
        return null;
    }
}