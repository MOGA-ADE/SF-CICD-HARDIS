public without sharing class AP034_TURPEOptimisationService {

    private static final Integer CACHE_TTL = 82800; // 23h
    private static final Map<String, String> ENDPOINT_MAP = new Map<String, String>{
        'OPTIM_TURPE'        => 'https://api-gateway.homeys.io/api/open/v1/client/onboarding/pdl?optimturpe=true',
        'RENOUVELLEMENT'    => 'https://api-gateway.homeys.io/api/open/v1/source/meter/courtage/optimturpe/analyse',
        'OPTIM_TURPE_RENEW' => 'https://api-gateway.homeys.io/api/open/v1/source/meter/courtage/optimturpe/analyse'
    };

    /**
     * Représente la structure normalisée des données TURPE extraites depuis
     * la réponse JSON Homeys. Permet de centraliser toutes les valeurs attendues.
     */
    public class TurpeDataExtractor {
        public String idSource;
        public String idSourceExecution;
        public String idAnalyse;
        public String idBuilding;
        public Date dateFrom;
        public Date dateTo;
        public String status;
        public String errorMessage;
        public Map<String, Decimal> actuelleDenivele;
        public Map<String, Decimal> meilleureDenivele;
        public Decimal actuelleTurpeCSF;
        public Decimal actuelleTurpeCSV;
        public Decimal actuelleTurpeCMDPS;
        public Decimal actuelleHTVACta;
        public Decimal meilleureTurpeCSF;
        public Decimal meilleureTurpeCSV;
        public Decimal meilleureTurpeCMDPS;
        public Decimal meilleureHTVACta;
        public Decimal HCEActuel;
        public Decimal HCHActuel;
        public Decimal HPEActuel;
        public Decimal HPHActuel;
        public Decimal POINTEActuel;
        public Decimal HCEOptimal;
        public Decimal HCHOptimal;
        public Decimal HPEOptimal;
        public Decimal HPHOptimal;
        public Decimal POINTEOptimal;
        public Decimal PartFixeCSActuel;
        public Decimal PartFixeCSOptimal;
        public Decimal PartVariableCSActuel;
        public Decimal PartVariableCSOptimal;
        public Decimal TaxeCTAActuel;
        public Decimal TaxeCTAOptimal;
    }

    /**
     * Wrapper simple utilisé pour encapsuler les paramètres nécessaires
     * à la construction du payload JSON.
     */
    public class RequestWrapper {
        public String recordId;
        public String sourceId;
        public RequestWrapper(String recordId, String sourceId) {
            this.recordId = recordId;
            this.sourceId = sourceId;
        }
    }

    /**
     * Wrapper de réponse pour harmoniser la gestion des retours HTTP
     * et simplifier le contrôle des statuts.
     */
    public class ResponseWrapper {
        public Integer statusCode;
        public String body;
        public Boolean isSuccess;
        public ResponseWrapper(Integer statusCode, String body) {
            this.statusCode = statusCode;
            this.body = body;
            this.isSuccess = (statusCode >= 200 && statusCode < 300);
        }
    }

    /**
    * Entrée du Flow contenant les lignes TURPE à traiter.
    */
    public class FlowInput {
        @InvocableVariable public List<WrapTURPEDisplayRow> wrapTURPE;
        @InvocableVariable public String emailToNotify;
    }

    /**
    * Traite les données envoyées par le Flow :
    * - récupère les QLI
    * - prépare les mises à jour QLI à partir des PDE
    * - déclenche les appels TURPE en Queueable si nécessaire.
    */
    @InvocableMethod(label='Appel HOMEYS - TURPE')
    public static void invokeTURPECallFromFlow(List<FlowInput> inputs) {
        // Collecte des QLI à traiter + capture du dernier email non vide fourni par le Flow
        Set<Id> qliIds = new Set<Id>();
        List<WrapTURPEDisplayRow> allWraps = new List<WrapTURPEDisplayRow>();
        String flowEmailToNotify;
        for (FlowInput input : inputs) {
            if (input != null && String.isNotBlank(input.emailToNotify)) {
                flowEmailToNotify = input.emailToNotify;
            }
            if (input == null || input.wrapTURPE == null) continue;
            allWraps.addAll(input.wrapTURPE);
            for (WrapTURPEDisplayRow wrap : input.wrapTURPE) {
                // on ne collecte des QLI QUE si c’est une action QLI
                if (wrap.ActionType != null
                    && wrap.ActionType.startsWith('QLI')
                    && wrap.RecordId != null) {
                    qliIds.add(wrap.RecordId);
                }
            }
        }

        // Chargement des QLI
        Map<Id, QuoteLineItem> qliMap = qliIds.isEmpty()
            ? new Map<Id, QuoteLineItem>()
            : new Map<Id, QuoteLineItem>([
                SELECT Id,
                    QuoteId,
                    PDE__c,
                    PDE__r.IdSource__c,
                    PDE__r.IdAnalyse__c,
                    PDE__r.IdBuilding__c,
                    PDE__r.HCEActuel__c,
                    PDE__r.HPEActuel__c,
                    PDE__r.HCHActuel__c,
                    PDE__r.HPHActuel__c,
                    PDE__r.POINTEActuel__c,
                    PDE__r.HCEOptimal__c,
                    PDE__r.HPEOptimal__c,
                    PDE__r.HCHOptimal__c,
                    PDE__r.HPHOptimal__c,
                    PDE__r.POINTEOptimal__c,
                    PDE__r.PartFixeCSActuel__c,
                    PDE__r.PartVariableCSActuel__c,
                    PDE__r.DepassementActuel__c,
                    PDE__r.TaxeCTAActuel__c,
                    PDE__r.PartFixeCSOptimal__c,
                    PDE__r.PartVariableCSOptimal__c,
                    PDE__r.DepassementOptimal__c,
                    PDE__r.TaxeCTAOptimal__c,
                    PDE__r.BudgetTotalActuel__c,
                    PDE__r.BudgetTotalOptimal__c,
                    PDE__r.EconomieIdentifie__c,
                    PDE__r.TECH_OptimisationFieldsMissing__c,
                    PDE__r.AppelEnCours__c
                FROM QuoteLineItem
                WHERE Id IN :qliIds
            ]);

        Map<Id, QuoteLineItem> qlisToUpdate = new Map<Id, QuoteLineItem>();
        QueueableJobChain chain = new QueueableJobChain();
        Boolean shouldRunAsync = false;

        if (!AP034_TURPEOptimisationService.hasValidHomeysToken()) {
            chain.chainLast(new AP034_HomeysTokenQueueable(chain));
        }

        // Persistance de l'email fourni par le Flow selon le contexte (PDE_* -> PDE.Email__c, QLI_* -> Quote.Email)
        // Cette étape est faite avant l'envoi des appels, pour être disponible au moment du callback.
        if (String.isNotBlank(flowEmailToNotify)) {
            try {
                // Pour les entrées QLI_ : écrire Email sur la Quote parente
                if (!qliIds.isEmpty()) {
                    //On récupère le quoteId
                    Id quoteId = qliMap.get(qliIds.iterator().next()).QuoteId;
                    update new Quote(Id = quoteId, Email = flowEmailToNotify);
                }
                //Si QLI n'est pas vide alors il s'agit forcément d'un appel pour un PDE
                else {
                    // Pour les entrées PDE_ : écrire Email__c sur PDE__c.Id = wrap.RecordId
                    for (WrapTURPEDisplayRow wrap : allWraps) {
                        if (wrap.ActionType != null && wrap.ActionType.startsWith('PDE_') && wrap.RecordId != null) {
                            // Mise à jour directe de l'email sur le PDE
                            //Inutile de mettre dans une liste car on ne peut appeler les PDE que unitairement
                            PDE__c p = new PDE__c(Id = wrap.RecordId, Email__c = flowEmailToNotify);
                            update p;
                        }
                    }
                }

            } catch (Exception e) {
                insert new Log__c(
                    Type__c       = 'HOMEYS_TURPE_EMAIL_CAPTURE',
                    ApexMethod__c = 'AP034_TURPEOptimisationService.invokeTURPECallFromFlow',
                    Erreur__c     = e.getMessage()
                );
            }
        }

        for (WrapTURPEDisplayRow wrap : allWraps) {

            // CAS PDE → QUEUEABLE DIRECT 
            if (wrap.ActionType != null && wrap.ActionType.startsWith('PDE_')) {
                chain.chainLast(
                    new AP034_TURPEOptimisationQueueable(
                        chain,
                        wrap.ActionType,
                        wrap.RecordId,
                        wrap.IdSource,
                        wrap.IdAnalyse,
                        wrap.IdBuilding
                    )
                );

                shouldRunAsync = true;
                continue;
            }

            // CAS QLI → logique EXISTANTE
            QuoteLineItem qli = qliMap.get(wrap.RecordId);

            if (qli == null) {
                continue;
            }

            PDE__c pde = qli.PDE__r;

            // QLI RENOUVELLEMENT
            if (wrap.ActionType == 'QLI_RENOUVELLEMENT') {
                // Cas 1 : PDE complète → MAJ directe QLI
                if (pde != null
                    && String.isNotBlank(pde.IdAnalyse__c)
                    && !pde.TECH_OptimisationFieldsMissing__c) {
                    qlisToUpdate.put(qli.Id, new QuoteLineItem(
                        Id = qli.Id,
                        IdAnalyse__c = pde.IdAnalyse__c,
                        HCEActuel__c = pde.HCEActuel__c,
                        HPEActuel__c = pde.HPEActuel__c,
                        HCHActuel__c = pde.HCHActuel__c,
                        HPHActuel__c = pde.HPHActuel__c,
                        POINTEActuel__c = pde.POINTEActuel__c,
                        HCEOptimal__c = pde.HCEOptimal__c,
                        HPEOptimal__c = pde.HPEOptimal__c,
                        HCHOptimal__c = pde.HCHOptimal__c,
                        HPHOptimal__c = pde.HPHOptimal__c,
                        POINTEOptimal__c = pde.POINTEOptimal__c,
                        PartFixeCSActuel__c = pde.PartFixeCSActuel__c,
                        PartVariableCSActuel__c = pde.PartVariableCSActuel__c,
                        DepassementActuel__c = pde.DepassementActuel__c,
                        TaxeCTAActuel__c = pde.TaxeCTAActuel__c,
                        PartFixeCSOptimal__c = pde.PartFixeCSOptimal__c,
                        PartVariableCSOptimal__c = pde.PartVariableCSOptimal__c,
                        DepassementOptimal__c = pde.DepassementOptimal__c,
                        TaxeCTAOptimal__c = pde.TaxeCTAOptimal__c,
                        BudgetTotalActuel__c = pde.BudgetTotalActuel__c,
                        BudgetTotalOptimal__c = pde.BudgetTotalOptimal__c,
                        EconomieIdentifie__c = pde.EconomieIdentifie__c
                    ));
                    continue;
                }

                // Cas 2 : PDE incomplète → Queueable
                if (pde != null
                    && String.isNotBlank(pde.IdAnalyse__c)
                    && pde.TECH_OptimisationFieldsMissing__c
                    && !pde.AppelEnCours__c) {
                    chain.chainLast(
                        new AP034_TURPEOptimisationQueueable(
                            chain,
                            'QLI_RENOUVELLEMENT',
                            wrap.RecordId,
                            pde.IdSource__c,
                            pde.IdAnalyse__c,
                            pde.IdBuilding__c
                        )
                    );
                    shouldRunAsync = true;
                    continue;
                }
            }

            chain.chainLast(
                new AP034_TURPEOptimisationQueueable(
                    chain,
                    wrap.ActionType,
                    wrap.RecordId,
                    wrap.IdSource,
                    wrap.IdAnalyse,
                    wrap.IdBuilding
                )
            );
            shouldRunAsync = true;
        }

        if (!qlisToUpdate.isEmpty()) {
            update qlisToUpdate.values();
        }

        if (shouldRunAsync) {
            chain.runNext();
        }
    }

    public static void invokeTURPECallFromApex(
        String actionType,
        String recordId,
        String idSource,
        String idAnalyse,
        String idBuilding
    ) {
        QueueableJobChain chain = new QueueableJobChain();
        chain.chainLast(
            new AP034_TURPEOptimisationQueueable(
                chain, actionType, recordId, idSource, idAnalyse, idBuilding
            )
        );
        chain.runNext();
    }

    /**
     * Récupère la configuration Homeys stockée dans le Custom Metadata.
     * Retourne null en cas de problème d’accès.
     */
    public static Homeys_Auth_Config__mdt getStaticHomeysConfig() {
        try {
            Homeys_Auth_Config__mdt conf = [
                SELECT URL_token__c, x_api_key__c, username__c, password__c
                FROM Homeys_Auth_Config__mdt
                LIMIT 1
            ];
            return conf;
        } catch (Exception e) {
            return null;
        }
    }

    private static HomeysToken__c getHomeysTokenMetadata() {
        try {
            return [
                SELECT Id, Token__c, IssuedAt__c, ExpiresAt__c
                FROM HomeysToken__c
                LIMIT 1
            ];
        } catch (Exception e) {
            return null;
        }
    }

    public static Boolean hasValidHomeysToken() {
        HomeysToken__c token = getHomeysTokenMetadata();
        return token != null
            && String.isNotBlank(token.Token__c)
            && token.ExpiresAt__c != null
            && DateTime.now() < token.ExpiresAt__c;
    }

    private static void storeHomeysToken(String jwtToken, Datetime issuedAt) {
        if (String.isBlank(jwtToken) || issuedAt == null) {
            return;
        }

        Datetime expiresAt = issuedAt.addSeconds(CACHE_TTL);

        HomeysToken__c rec;
        List<HomeysToken__c> existing =
            [SELECT Id FROM HomeysToken__c LIMIT 1];

        if (existing.isEmpty()) {
            rec = new HomeysToken__c();
        } else {
            rec = existing[0];
        }

        rec.Token__c      = jwtToken;
        rec.IssuedAt__c  = issuedAt;
        rec.ExpiresAt__c = expiresAt;

        upsert rec;
    }

    public static String getHomeysJWT() {
        try {
            Homeys_Auth_Config__mdt staticConfig = getStaticHomeysConfig();

            if (staticConfig == null) {
                return null;
            }

            HomeysToken__c dbToken = getHomeysTokenMetadata();

            if (dbToken != null &&
                String.isNotBlank(dbToken.Token__c) &&
                dbToken.ExpiresAt__c != null) {

                Boolean isValid = DateTime.now() < dbToken.ExpiresAt__c;

                if (isValid) {
                    return dbToken.Token__c;
                }
            }

            return generateNewToken(staticConfig);

        } catch (Exception e) {
            return null;
        }
    }

    public static String generateNewToken(Homeys_Auth_Config__mdt staticConfig) {
        try {
            HttpRequest request = new HttpRequest();
            request.setEndpoint(staticConfig.URL_token__c);
            request.setMethod('POST');
            request.setTimeout(60000);
            request.setHeader('x-api-key', staticConfig.x_api_key__c);
            request.setHeader('Content-Type', 'application/json');

            request.setBody(JSON.serialize(new Map<String, String>{
                'username' => staticConfig.username__c,
                'password' => staticConfig.password__c
            }));

            HttpResponse response = new Http().send(request);

            if (response.getStatusCode() == 200) {

                Map<String, Object> responseMap =
                    (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                String jwtToken = (String) responseMap.get('token');

                if (String.isBlank(jwtToken)) {
                    return null;
                }

                Datetime issuedAt = DateTime.now();
                storeHomeysToken(jwtToken, issuedAt);
                return jwtToken;
            }
            return null;

        } catch (Exception e) {
            return null;
        }
    }


    /**
     * Construit le payload JSON envoyé à Homeys.
     * Le contenu dépend du type d'action (Optimisation vs Renouvellement)
     * et du type d'objet (PDE ou QLI).
     */
    public static String prepareOptimisationPayload(
        String actionType,
        String recordId,
        String idSourceFromApex
    ) {
        try {
            Map<String, Object> jsonPayload = new Map<String, Object>();

            Boolean isOptimisation   = actionType.contains('OPTIMISATION');
            Boolean isRenouvellement = actionType.contains('RENOUVELLEMENT');
            Boolean isPDE            = actionType.startsWith('PDE');
            Boolean isQLI            = actionType.startsWith('QLI');

            // CAS RENOUVELLEMENT
            if (isRenouvellement) {
                jsonPayload.put(
                    'source',
                    new Map<String, Object>{ '_id_source' => idSourceFromApex }
                );

                String result = JSON.serialize(jsonPayload);
                return result;
            }

            // CAS OPTIMISATION (1er appel)
            if (isOptimisation && idSourceFromApex == null) {
                String idsSourceValue;
                String firstName = '';
                String lastName  = '';
                String email     = '';
                String street    = '';
                String city      = '';
                String zipCode   = '';
                String country   = '';
                String companyName  = '';
                String companySiret = '';

                if (isPDE) {
                    PDE__c p = [
                        SELECT ReferencePointEnergie_Refonte__c,
                            SignataireACD__r.FirstName,
                            SignataireACD__r.LastName,
                            SignataireACD__r.Email,
                            SignataireACD__r.Account.Name,
                            SignataireACD__r.Account.Siret__c,
                            SignataireACD__r.Account.BillingStreet,
                            SignataireACD__r.Account.BillingCity,
                            SignataireACD__r.Account.BillingPostalCode,
                            SignataireACD__r.Account.BillingCountry
                        FROM PDE__c
                        WHERE Id = :recordId
                    ];

                    idsSourceValue = p.ReferencePointEnergie_Refonte__c;
                    firstName      = p.SignataireACD__r.FirstName;
                    lastName       = p.SignataireACD__r.LastName;
                    email          = p.SignataireACD__r.Email;
                    street         = p.SignataireACD__r.Account.BillingStreet;
                    city           = p.SignataireACD__r.Account.BillingCity;
                    zipCode        = p.SignataireACD__r.Account.BillingPostalCode;
                    country        = p.SignataireACD__r.Account.BillingCountry;
                    companyName    = p.SignataireACD__r.Account.Name;
                    companySiret   = p.SignataireACD__r.Account.Siret__c;
                }

                if (isQLI) {
                    QuoteLineItem q = [
                        SELECT PDE__r.ReferencePointEnergie_Refonte__c,
                            PDE__r.SignataireACD__r.FirstName,
                            PDE__r.SignataireACD__r.LastName,
                            PDE__r.SignataireACD__r.Email,
                            PDE__r.SignataireACD__r.Account.Name,
                            PDE__r.SignataireACD__r.Account.Siret__c,
                            PDE__r.SignataireACD__r.Account.BillingCity,
                            PDE__r.SignataireACD__r.Account.BillingCountry,
                            PDE__r.SignataireACD__r.Account.BillingStreet,
                            PDE__r.SignataireACD__r.Account.BillingPostalCode
                        FROM QuoteLineItem
                        WHERE Id = :recordId
                        LIMIT 1
                    ];

                    idsSourceValue = q.PDE__r.ReferencePointEnergie_Refonte__c;
                    firstName      = q.PDE__r.SignataireACD__r.FirstName;
                    lastName       = q.PDE__r.SignataireACD__r.LastName;
                    email          = q.PDE__r.SignataireACD__r.Email;
                    street         = q.PDE__r.SignataireACD__r.Account.BillingStreet;
                    city           = q.PDE__r.SignataireACD__r.Account.BillingCity;
                    zipCode        = q.PDE__r.SignataireACD__r.Account.BillingPostalCode;
                    country        = q.PDE__r.SignataireACD__r.Account.BillingCountry;
                    companyName    = q.PDE__r.SignataireACD__r.Account.Name;
                    companySiret   = q.PDE__r.SignataireACD__r.Account.Siret__c;
                }

                jsonPayload.put(
                    'idsource',
                    String.isNotBlank(idsSourceValue)
                        ? idsSourceValue
                        : 'no-id-provided'
                );

                jsonPayload.put('titulaire', new Map<String, Object>{
                    'user' => new Map<String, Object>{
                        'firstname' => firstName,
                        'lastname'  => lastName,
                        'username'  => email
                    },
                    'company' => new Map<String, Object>{
                        'name' => companyName,
                        'address' => new Map<String, Object>{
                            'street'   => street,
                            'city'     => city,
                            'zipcode'  => zipCode,
                            'country'  => country,
                            'citycode' => '',
                            'inline'   => ''
                        },
                        'idcompany' => companySiret,
                        'type'      => 'entreprise',
                        'legalForm' => 'SARL'
                    }
                });

                String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
                String callbackUrl = baseUrl + '/services/apexrest/callback/TURPEWebhook';

                jsonPayload.put('callback', new Map<String, Object>{
                    'noAuthUrl' => callbackUrl
                });

                String result = JSON.serialize(jsonPayload);
                return result;
            }
            return null;

        } catch (Exception e) {
            return null;
        }
    }

    public static String prepareOptimisationRenewPayload(
        String idBuilding,
        String idSource,
        Date dateFrom,
        Date dateTo
    ) {
        Map<String, Object> payload = new Map<String, Object>{
            '_id_building' => idBuilding,
            'inputs' => new Map<String, Object>{
                'source' => new Map<String, Object>{
                    '_id_source' => idSource
                },
                'data' => new Map<String, Object>{
                    'date_from' => String.valueOf(dateFrom),
                    'date_to'   => String.valueOf(dateTo)
                }
            }
        };

        String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
        String callbackUrl = baseUrl + '/services/apexrest/callback/TURPEWebhook';

        payload.put(
            'callback',
            new Map<String, Object>{
                'noAuthUrl' => callbackUrl
            }
        );

        String result = JSON.serialize(payload);
        return result;
    }


    /**
     * Point d'entrée public pour exécuter un callout Homeys.
     * Route automatiquement vers le bon endpoint selon l'action demandée.
     */
    public static void executeCallout(String actionType, String recordId, String idSource, String idAnalyse, String idBuilding) {
        switch on actionType {

            when 'PDE_OPTIMISATION' {
                callEndpoint('PDE_OPTIMISATION', 'POST', recordId, idSource, idAnalyse, idBuilding);
            }

            when 'QLI_OPTIMISATION' {
                callEndpoint('QLI_OPTIMISATION', 'POST', recordId, idSource, idAnalyse, idBuilding);
            }

            when 'PDE_RENOUVELLEMENT' {
                callEndpoint('PDE_RENOUVELLEMENT', 'GET', recordId, idSource, idAnalyse, idBuilding);
            }

            when 'QLI_RENOUVELLEMENT' {
                callEndpoint('QLI_RENOUVELLEMENT', 'GET', recordId, idSource, idAnalyse, idBuilding);
            }

            when 'PDE_OPTIMISATION_RENEW' {
                callEndpoint('PDE_OPTIMISATION_RENEW', 'POST', recordId, idSource, idAnalyse, idBuilding);
            }

            when 'QLI_OPTIMISATION_RENEW' {
                callEndpoint('QLI_OPTIMISATION_RENEW', 'POST', recordId, idSource, idAnalyse, idBuilding);
            }
        }
    }

    /**
    * Envoie la requête HTTP vers Homeys et traite la réponse
    * selon le type d’action demandé.
    */
    public static void callEndpoint(
        String actionType,
        String method,
        String recordId,
        String idSource,
        String idAnalyse,
        String idBuilding
    ) {
        String token = getHomeysJWT();
        if (String.isBlank(token)) {
            return;
        }

        String url;
        String body;

        if (actionType == 'PDE_OPTIMISATION'
        || actionType == 'QLI_OPTIMISATION') {
            url  = ENDPOINT_MAP.get('OPTIM_TURPE');
            body = prepareOptimisationPayload(actionType, recordId, idSource);

            if (String.isBlank(body)) return;
        }
        else if (actionType == 'PDE_OPTIMISATION_RENEW'
            || actionType == 'QLI_OPTIMISATION_RENEW') {

            String idSourceLocal;
            Date dateFrom;
            Date dateTo;

            if (actionType.startsWith('PDE')) {
                PDE__c pde = [
                    SELECT IdBuilding__c, IdSource__c, DateAnalyseFrom__c, DateAnalyseTo__c
                    FROM PDE__c WHERE Id = :recordId LIMIT 1
                ];
                idBuilding    = pde.IdBuilding__c;
                idSourceLocal = pde.IdSource__c;
                dateFrom      = pde.DateAnalyseFrom__c;
                dateTo        = pde.DateAnalyseTo__c;
            } else {
                QuoteLineItem qli = [
                    SELECT
                        IdBuilding__c,
                        IdSource__c,
                        DateAnalyseFrom__c,
                        DateAnalyseTo__c,
                        PDE__r.IdBuilding__c,
                        PDE__r.IdSource__c,
                        PDE__r.DateAnalyseFrom__c,
                        PDE__r.DateAnalyseTo__c
                    FROM QuoteLineItem
                    WHERE Id = :recordId
                    LIMIT 1
                ];

                // Priorité QLI → fallback PDE
                Boolean qliHasAll =
                    String.isNotBlank(qli.IdBuilding__c) &&
                    String.isNotBlank(qli.IdSource__c);

                Boolean pdeHasAll =
                    qli.PDE__r != null &&
                    String.isNotBlank(qli.PDE__r.IdBuilding__c) &&
                    String.isNotBlank(qli.PDE__r.IdSource__c);

                if (qliHasAll) {
                    idBuilding    = qli.IdBuilding__c;
                    idSourceLocal = qli.IdSource__c;
                    dateFrom      = qli.DateAnalyseFrom__c;
                    dateTo        = qli.DateAnalyseTo__c;
                } else if (pdeHasAll) {
                    idBuilding    = qli.PDE__r.IdBuilding__c;
                    idSourceLocal = qli.PDE__r.IdSource__c;
                    dateFrom      = qli.PDE__r.DateAnalyseFrom__c;
                    dateTo        = qli.PDE__r.DateAnalyseTo__c;
                } else {
                    return;
                }
            }

            if (String.isBlank(idBuilding)
            || String.isBlank(idSourceLocal)
            || dateFrom == null
            || dateTo == null) {
                return;
            }

            url  = ENDPOINT_MAP.get('OPTIM_TURPE_RENEW');
            body = prepareOptimisationRenewPayload(
                idBuilding, idSourceLocal, dateFrom, dateTo
            );
        }
        else {
            idAnalyse = actionType.startsWith('PDE')
                ? [SELECT IdAnalyse__c FROM PDE__c WHERE Id = :recordId LIMIT 1].IdAnalyse__c
                : [SELECT IdAnalyse__c FROM QuoteLineItem WHERE Id = :recordId LIMIT 1].IdAnalyse__c;

            if (String.isBlank(idAnalyse)) return;

            url  = ENDPOINT_MAP.get('RENOUVELLEMENT') + '/' + idAnalyse;
            body = null;
        }

        HttpResponse response = callHomeysApi(url, body, token, method);
        Integer statusCode = response.getStatusCode();

        // Gestion des erreurs Homeys
        if (statusCode != 200 && statusCode != 201) {
            insert new Log__c(
                Type__c        = 'HOMEYS_TURPE',
                Endpoint__c    = url,
                StatusCode__c  = statusCode,
                ApexMethod__c  = 'AP034_TURPEOptimisationService.callEndpoint',
                Verb__c        = method,
                RequestBody__c = body,
                Erreur__c      = response.getBody(),
                RecordId__c    = recordId
            );
            return;
        }

        if (actionType.contains('_OPTIMISATION')
            && !actionType.contains('_RENEW')) {
            handleOptimisationResponse(actionType, recordId, response);
        }
        else if (actionType.contains('_OPTIMISATION_RENEW')) {
            handleOptimisationRenewResponse(actionType, recordId, response);
        }
        else if (actionType.contains('RENOUVELLEMENT')) {
            handleRenouvellementResponse(actionType, recordId, response);
        }
    }

    /**
    * Traite la réponse Homeys d’une première optimisation TURPE.
    * Met à jour les identifiants techniques (IdSource, IdAnalyse, IdBuilding)
    * ainsi que les dates d’appel sur la PDE ou la QLI cible.
    */
    public static void handleOptimisationResponse(
        String endpoint,
        String recordId,
        HttpResponse response
    ) {
        Map<String, Object> root =
            (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        if (root == null || !root.containsKey('data')) {
            return;
        }

        Map<String, Object> data =
            (Map<String, Object>) root.get('data');

        String idSource   = (String) data.get('_id_source');
        String idAnalyse  = (String) data.get('_id_analyse_optimturpe');
        String idBuilding = (String) data.get('_id_building');

        Date today = Date.today();

        // CAS PDE
        if (endpoint.startsWith('PDE')) {
            update new PDE__c(
                Id                  = recordId,
                IdSource__c         = idSource,
                IdAnalyse__c        = idAnalyse,
                IdBuilding__c       = idBuilding,
                DateAppel__c        = today,
                DatePremierAppel__c = today,
                AppelEnCours__c     = true
            );
            return;
        }

        // CAS QLI
        QuoteLineItem qli = [
            SELECT Id, PDE__c
            FROM QuoteLineItem
            WHERE Id = :recordId
            LIMIT 1
        ];

        // MAJ QLI
        update new QuoteLineItem(
            Id                  = qli.Id,
            IdSource__c         = idSource,
            IdAnalyse__c        = idAnalyse,
            IdBuilding__c       = idBuilding,
            DateAppel__c        = today,
            DatePremierAppel__c = today,
            AppelEnCours__c     = true
        );

        // MAJ PDE associé (spécifique QLI_OPTIMISATION)
        if (qli.PDE__c != null) {
            update new PDE__c(
                Id                  = qli.PDE__c,
                IdSource__c         = idSource,
                IdAnalyse__c        = idAnalyse,
                IdBuilding__c       = idBuilding,
                DateAppel__c        = today,
                DatePremierAppel__c = today,
                AppelEnCours__c     = true
            );
        }
    }


    /**
    * Traite la réponse Homeys d’une optimisation TURPE de type RENEW.
    * Récupère les identifiants depuis la réponse API et met à jour
    * la PDE ou la QLI concernée avec les nouvelles références.
    */
    public static void handleOptimisationRenewResponse(
        String endpoint,
        String recordId,
        HttpResponse response
    ) {
        // Extraction TURPE
        TurpeDataExtractor turpeData = extractTurpeData(response.getBody());

        // Parsing JSON brut
        Map<String, Object> root =
            (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

        if (root == null || !root.containsKey('data')) {
            return;
        }

        Map<String, Object> dataJson =
            (Map<String, Object>) root.get('data');

        String idAnalyse  = (String) dataJson.get('_id');
        String idBuilding = (String) dataJson.get('_id_building');
        String idSource;

        Date dateFrom;
        Date dateTo;

        Map<String, Object> inputs =
            dataJson.containsKey('inputs')
                ? (Map<String, Object>) dataJson.get('inputs')
                : null;

        Map<String, Object> source =
            inputs != null
                ? (Map<String, Object>) inputs.get('source')
                : null;

        Map<String, Object> dataInputs =
            inputs != null
                ? (Map<String, Object>) inputs.get('data')
                : null;

        if (source != null) {
            idSource = (String) source.get('_id_source');
        }

        if (dataInputs != null) {
            if (dataInputs.get('date_from') != null) {
                dateFrom = Date.valueOf((String) dataInputs.get('date_from'));
            }
            if (dataInputs.get('date_to') != null) {
                dateTo = Date.valueOf((String) dataInputs.get('date_to'));
            }
        }

        Date today = Date.today();

        // CAS PDE
        if (endpoint.startsWith('PDE')) {

            PDE__c pde = new PDE__c(
                Id                  = recordId,
                IdAnalyse__c        = idAnalyse,
                IdBuilding__c       = idBuilding,
                IdSource__c         = idSource,
                DatePremierAppel__c = today,
                DateAppel__c        = today,
                DateAnalyseFrom__c  = dateFrom,
                DateAnalyseTo__c    = dateTo
            );

            mapTurpeFields(pde, turpeData);
            update pde;
            return;
        }

        // CAS QLI
        QuoteLineItem qli = [
            SELECT Id,
                PDE__c,
                PDE__r.IdAnalyse__c
            FROM QuoteLineItem
            WHERE Id = :recordId
            LIMIT 1
        ];

        // Mise à jour QLI (toujours)
        QuoteLineItem qliUpdate = new QuoteLineItem(
            Id                  = recordId,
            IdAnalyse__c        = idAnalyse,
            IdBuilding__c       = idBuilding,
            IdSource__c         = idSource,
            DatePremierAppel__c = today,
            DateAppel__c        = today,
            DateAnalyseFrom__c  = dateFrom,
            DateAnalyseTo__c    = dateTo
        );

        mapTurpeFields(qliUpdate, turpeData);
        update qliUpdate;
    }


    /**
    * Traitement métier du retour Homeys pour un appel Renouvellement.
    * Mappe toutes les valeurs TURPE retournées et met à jour
    * les champs nécessaires (DateAppel, AppelEnCours).
    */
    public static void handleRenouvellementResponse(
        String endpoint,
        String recordId,
        HttpResponse response) {

            try {
                // Extraction TURPE (existant)
                TurpeDataExtractor turpeData = extractTurpeData(response.getBody());
                Date today = Date.today();

                // Parsing JSON brut pour IDs & dates
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

                if (root == null || !root.containsKey('data')) {
                    return;
                }

                Map<String, Object> dataJson = (Map<String, Object>) root.get('data');

                String idAnalyse   = (String) dataJson.get('_id');
                String idBuilding  = (String) dataJson.get('_id_building');
                String idSource;

                Date dateFrom;
                Date dateTo;

                Map<String, Object> inputs =
                    dataJson.containsKey('inputs') ? (Map<String, Object>) dataJson.get('inputs') : null;

                Map<String, Object> source = inputs != null ? (Map<String, Object>) inputs.get('source'): null;
                Map<String, Object> dataInputs = inputs != null ? (Map<String, Object>) inputs.get('data') : null;

                if (source != null) {
                    idSource = (String) source.get('_id_source');
                }

                if (dataInputs != null) {
                    if (dataInputs.get('date_from') != null) {
                        dateFrom = Date.valueOf((String) dataInputs.get('date_from'));
                    }
                    if (dataInputs.get('date_to') != null) {
                        dateTo = Date.valueOf((String) dataInputs.get('date_to'));
                    }
                }

                // CAS PDE
                if (endpoint.startsWith('PDE')) {

                    PDE__c pde = new PDE__c(
                        Id                   = recordId,
                        IdAnalyse__c         = idAnalyse,
                        IdBuilding__c        = idBuilding,
                        IdSource__c          = idSource,
                        DateAppel__c         = today,
                        DateAnalyseFrom__c   = dateFrom,
                        DateAnalyseTo__c     = dateTo
                    );

                    mapTurpeFields(pde, turpeData);

                    update pde;
                    return;
                }

                // CAS QLI
                QuoteLineItem qli = [
                    SELECT Id,
                        PDE__c,
                        PDE__r.IdAnalyse__c
                    FROM QuoteLineItem
                    WHERE Id = :recordId
                    LIMIT 1
                ];

                Boolean shouldUpdatePDE = false;

                // Si le PDE n’a PAS encore d’IdAnalyse
                if (qli.PDE__c != null && String.isBlank(qli.PDE__r.IdAnalyse__c)) {
                    shouldUpdatePDE = true;
                }

                // Mise à jour QLI (TOUJOURS)
                QuoteLineItem qliUpdate = new QuoteLineItem(
                    Id                 = recordId,
                    IdAnalyse__c       = idAnalyse,
                    IdBuilding__c      = idBuilding,
                    DateAppel__c       = today,
                    DateAnalyseFrom__c = dateFrom,
                    DateAnalyseTo__c   = dateTo
                );

                mapTurpeFields(qliUpdate, turpeData);
                update qliUpdate;

                // Mise à jour PDE SI NÉCESSAIRE
                if (shouldUpdatePDE) {

                    PDE__c pdeUpdate = new PDE__c(
                        Id                  = qli.PDE__c,
                        IdAnalyse__c        = idAnalyse,
                        IdBuilding__c       = idBuilding,
                        IdSource__c         = idSource,
                        DateAppel__c        = today,
                        DatePremierAppel__c = today,
                        DateAnalyseFrom__c  = dateFrom,
                        DateAnalyseTo__c    = dateTo
                    );

                    mapTurpeFields(pdeUpdate, turpeData);
                    update pdeUpdate;
                }
            } catch (Exception e) {
                    System.debug('Erreur : ' + e.getMessage() + '\n' + e.getStackTraceString());
                    throw e;
            }
        }

    /**
     * Exécute un callout générique vers Homeys.
     * Configure les headers, le token et le body JSON.
     */
    private static HttpResponse callHomeysApi(
        String endpointUrl,
        String requestBody,
        String token,
        String method
    ) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod(method);
        req.setTimeout(60000);
        req.setHeader('Authorization', 'Bearer ' + token);

        Homeys_Auth_Config__mdt staticConfig = getStaticHomeysConfig();

        if (staticConfig != null && String.isNotBlank(staticConfig.x_api_key__c)) {
            req.setHeader('x-api-key', staticConfig.x_api_key__c);
        }

        if (method == 'POST') {
            req.setHeader('Content-Type', 'application/json');
            req.setBody(requestBody);
        }

        return new Http().send(req);
    }

    /**
    * Mappe les données TURPE extraites vers un SObject cible.
    * Utilisé par les appels Renouvellement pour PDE et QLI.
    */
    private static void mapTurpeFields(SObject target, TurpeDataExtractor d) {
        target.put('DateAppel__c', Date.today());
        target.put('AppelEnCours__c', false);
        target.put('Message_retour_optimisation_TURPE__c', d.errorMessage);


        // Champs TURPE Actuels & Optimaux
        target.put('HCEActuel__c', d.HCEActuel);
        target.put('HCEOptimal__c', d.HCEOptimal);
        target.put('HCHActuel__c', d.HCHActuel);
        target.put('HCHOptimal__c', d.HCHOptimal);
        target.put('HPEActuel__c', d.HPEActuel);
        target.put('HPEOptimal__c', d.HPEOptimal);
        target.put('HPHActuel__c', d.HPHActuel);
        target.put('HPHOptimal__c', d.HPHOptimal);
        target.put('POINTEActuel__c', d.POINTEActuel);
        target.put('POINTEOptimal__c', d.POINTEOptimal);

        target.put('PartFixeCSActuel__c', d.PartFixeCSActuel);
        target.put('PartVariableCSActuel__c', d.PartVariableCSActuel);
        target.put('DepassementActuel__c', d.actuelleTurpeCMDPS);
        target.put('TaxeCTAActuel__c', d.TaxeCTAActuel);

        target.put('PartFixeCSOptimal__c', d.PartFixeCSOptimal);
        target.put('PartVariableCSOptimal__c', d.PartVariableCSOptimal);
        target.put('DepassementOptimal__c', d.meilleureTurpeCMDPS);
        target.put('TaxeCTAOptimal__c', d.TaxeCTAOptimal);

        Decimal budgetActuel =
                (d.TaxeCTAActuel != null ? d.TaxeCTAActuel : 0) +
                (d.PartFixeCSActuel != null ? d.PartFixeCSActuel : 0) +
                (d.PartVariableCSActuel != null ? d.PartVariableCSActuel : 0) +
                (d.actuelleTurpeCMDPS != null ? d.actuelleTurpeCMDPS : 0);

        Decimal budgetOptimal =
            (d.TaxeCTAOptimal != null ? d.TaxeCTAOptimal : 0) +
            (d.PartFixeCSOptimal != null ? d.PartFixeCSOptimal : 0) +
            (d.PartVariableCSOptimal != null ? d.PartVariableCSOptimal : 0) +
            (d.meilleureTurpeCMDPS != null ? d.meilleureTurpeCMDPS : 0);


        if(budgetActuel == 0){
            target.put('BudgetTotalActuel__c', null);
        }else{
            target.put('BudgetTotalActuel__c', budgetActuel);
        }
        if(budgetOptimal == 0){
            target.put('BudgetTotalOptimal__c', null);
        }
        else{
            target.put('BudgetTotalOptimal__c', budgetOptimal);
        }

        if(budgetActuel == budgetOptimal && budgetOptimal == 0){
            target.put('EconomieIdentifie__c', null);
        }
        else{
            target.put('EconomieIdentifie__c', budgetActuel - budgetOptimal);
        }
    }

    /**
    * Analyse la réponse JSON Homeys et extrait toutes les valeurs
    * TURPE dans une structure typée (TurpeDataExtractor).
    * Compatible GET /optimturpe/analyse/{_id_analyse}
    */
    public static TurpeDataExtractor extractTurpeData(String jsonBody) {
        try {
            System.debug('extractTurpeData');
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);

            if (payload == null || !payload.containsKey('data')) return null;

            Map<String, Object> data = (Map<String, Object>) payload.get('data');

            if (data == null) return null;

            TurpeDataExtractor result = new TurpeDataExtractor();
            result.idAnalyse = (String) data.get('_id');
            result.idBuilding = (String) data.get('_id_building');
            result.status = (String) data.get('status');
            Map<String, Object> inputs = (Map<String, Object>) data.get('inputs');
            Map<String, Object> inputData = inputs != null ? (Map<String, Object>) inputs.get('data') : null;
            Map<String, Object> sourceInputs = inputs != null ? (Map<String, Object>) inputs.get('source') : null;

            if (inputData != null) {
                if (inputData.get('date_from') != null)
                    result.dateFrom = Date.valueOf((String) inputData.get('date_from'));
                if (inputData.get('date_to') != null)
                    result.dateTo = Date.valueOf((String) inputData.get('date_to'));
            }

            if (sourceInputs != null) {
                result.idSource = (String) sourceInputs.get('_id_source');
            }

            if(result.status <> 'SUCCESS'){
                System.debug('Impossible d\'effectué une optimisatin TURPE, on efface l\'ancienne optimisation');
                result.errorMessage =  (String)((Map<String, Object>)data.get('error')).get('message');
                System.debug('ErrorMessage '+result.errorMessage);
                result.HCEOptimal = null;
                result.HCHOptimal = null;
                result.HPEOptimal = null;
                result.HPHOptimal = null;
                result.POINTEOptimal = null;
                result.PartFixeCSOptimal = null;
                result.PartVariableCSOptimal = null;
                result.meilleureTurpeCMDPS = null;
                result.TaxeCTAOptimal = null;
                result.PartVariableCSActuel = null;
                result.PartFixeCSActuel = null;
                result.actuelleTurpeCMDPS = null;
                result.TaxeCTAActuel = null;
            }
            else{
                if (!data.containsKey('outputs')) return result;

                Map<String, Object> outputs = (Map<String, Object>) data.get('outputs');

                if (outputs == null) return result;

                Map<String, Object> actuelle = (Map<String, Object>) outputs.get('actuelle');
                Map<String, Object> meilleure = (Map<String, Object>) outputs.get('meilleure');

                if (actuelle != null) {
                    Map<String, Object> structure = (Map<String, Object>) actuelle.get('structure_tarifaire');
                    Map<String, Object> puissance = (Map<String, Object>) structure.get('puissance_souscrite_soutirage');
                    Map<String, Object> denivele = (Map<String, Object>) puissance.get('denivele');

                    result.HCEActuel = getDecimalValue(denivele, 'HCB');
                    result.HCHActuel = getDecimalValue(denivele, 'HCH');
                    result.HPEActuel = getDecimalValue(denivele, 'HPB');
                    result.HPHActuel = getDecimalValue(denivele, 'HPH');
                    result.POINTEActuel = getDecimalValue(denivele, 'PTE');

                    Map<String, Object> periode = (Map<String, Object>) ((Map<String, Object>) actuelle.get('data')).get('periode');

                    result.PartFixeCSActuel = getNestedDecimalValue(periode, 'prixHTT_elecsoutirage_turpeCSF.sum');
                    result.PartVariableCSActuel = getNestedDecimalValue(periode, 'prixHTT_elecsoutirage_turpeCSV.sum');
                    result.actuelleTurpeCMDPS = getNestedDecimalValue(periode, 'prixHTT_elecsoutirage_turpeCMDPS.sum');
                    result.TaxeCTAActuel = getNestedDecimalValue(periode, 'prixHTVA_elecsoutirage_cta.sum');
                }

                if (meilleure != null) {
                    Map<String, Object> structure = (Map<String, Object>) meilleure.get('structure_tarifaire');
                    Map<String, Object> puissance = (Map<String, Object>) structure.get('puissance_souscrite_soutirage');
                    Map<String, Object> denivele = (Map<String, Object>) puissance.get('denivele');

                    result.HCEOptimal = getDecimalValue(denivele, 'HCB');
                    result.HCHOptimal = getDecimalValue(denivele, 'HCH');
                    result.HPEOptimal = getDecimalValue(denivele, 'HPB');
                    result.HPHOptimal = getDecimalValue(denivele, 'HPH');
                    result.POINTEOptimal = getDecimalValue(denivele, 'PTE');

                    Map<String, Object> periode = (Map<String, Object>) ((Map<String, Object>) meilleure.get('data')).get('periode');

                    result.PartFixeCSOptimal = getNestedDecimalValue(periode, 'prixHTT_elecsoutirage_turpeCSF.sum');
                    result.PartVariableCSOptimal = getNestedDecimalValue(periode, 'prixHTT_elecsoutirage_turpeCSV.sum');
                    result.meilleureTurpeCMDPS = getNestedDecimalValue(periode, 'prixHTT_elecsoutirage_turpeCMDPS.sum');
                    result.TaxeCTAOptimal = getNestedDecimalValue(periode, 'prixHTVA_elecsoutirage_cta.sum');
                }
            }
            System.debug('RESULTAT DE LEXTRACTION DE LOPTIMISATION DE TURPE ');
            System.debug(result);
            return result;

        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Récupère un Decimal à partir d’une Map JSON simple.
     * Retourne 0 si la valeur est absente ou non convertible.
     */
    private static Decimal getDecimalValue(Map<String, Object> dataMap, String key) {
        if (dataMap != null && dataMap.containsKey(key)) {
            Object value = dataMap.get(key);
            if (value != null) {
                return Decimal.valueOf(String.valueOf(value));
            }
        }
        return 0;
    }

    /**
     * Récupère un Decimal à partir d’un chemin JSON imbriqué.
     * Gère proprement les erreurs et les valeurs manquantes.
     */
    private static Decimal getNestedDecimalValue(Map<String, Object> parentMap, String path) {
        try {
            String[] keys = path.split('\\.');
            Map<String, Object> currentMap = parentMap;
            
            for (Integer i = 0; i < keys.size() - 1; i++) {
                if (currentMap != null && currentMap.containsKey(keys[i])) {
                    currentMap = (Map<String, Object>) currentMap.get(keys[i]);
                } else {
                    return 0;
                }
            }
            
            if (currentMap != null && currentMap.containsKey(keys[keys.size() - 1])) {
                Object value = currentMap.get(keys[keys.size() - 1]);
                if (value != null) {
                    return Decimal.valueOf(String.valueOf(value));
                }
            }
            return 0;
        } catch (Exception e) {
            return 0;
        }
    }
}