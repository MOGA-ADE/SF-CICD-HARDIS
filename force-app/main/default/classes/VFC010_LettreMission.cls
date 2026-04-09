public without sharing class VFC010_LettreMission {
    public static String accountName { get; set; }
    public static String clientAddresse { get; set; }
    public static Decimal pourcentageRemuneration { get; set; }
    public static Decimal montantEconomie { get; set; }
    public static String formatMontantEconomie { get; set; }
    public static Decimal montantRemuneration { get; set; }
    public static String formatMontantRemuneration { get; set; }
    public static String todayDate { get{ return Date.today().format().toString();} set; }

    public VFC010_LettreMission() {
        Id oppId = ApexPages.currentPage().getParameters().get('id');
        Id accountId = ApexPages.currentPage().getParameters().get('accountId');
        Account clientAccount;

        // Règle métier confirmée: erreur si les deux sont fournis
        if (oppId != null && accountId != null) {
            throw new AuraHandledException('Veuillez fournir soit un opportunityId (id) soit un accountId, pas les deux.');
        }

        Id clientAccountId;
        Quote quoteTURPE;

        if (accountId != null) {
            // Mode Account direct: on utilise le compte fourni
            clientAccountId = accountId;
            clientAccount = [
                SELECT  Name,
                        BillingStreet,
                        BillingCity,
                        BillingPostalCode,
                        recordType.Name,
                        Numero_voie__c,
                        Voie__c,
                        Ville__c,
                        Code_postal__c
                FROM Account
                WHERE Id = :clientAccountId
                LIMIT 1
            ];
            if(clientAccount.recordType.Name == 'Copropriété'){
                clientAddresse = String.valueOf(clientAccount.Numero_voie__c) + ' ' +
                    String.valueOf(clientAccount.Voie__c) + ' ' +
                    String.valueOf(clientAccount.Ville__c) + ' ' +
                    String.valueOf(clientAccount.Code_postal__c);
            }
            else{
                clientAddresse = String.valueOf(clientAccount.BillingStreet) + ' ' +
                    String.valueOf(clientAccount.BillingCity) + ' ' +
                    String.valueOf(clientAccount.BillingPostalCode);
            }


            accountName = clientAccount.Name;
            pourcentageRemuneration = Double.valueOf(ApexPages.currentPage().getParameters().get('pourcentageRemuneration'));
            if(pourcentageRemuneration > 50){
                pourcentageRemuneration = 50;
            }
            else if(pourcentageRemuneration < 40){
                pourcentageRemuneration = 40;
            }
            montantEconomie = Double.valueOf(ApexPages.currentPage().getParameters().get('montantEconomie'));
        } else if (oppId != null) {
            // Mode Opportunity: on récupère l'account (avec logique Copropriété → Syndic)
            Opportunity opp = [
                SELECT Id, AccountId, Account.RecordType.Name, Account.Syndic__c
                FROM Opportunity
                WHERE Id = :oppId
                LIMIT 1
            ];
            clientAccountId = (opp.Account.RecordType.Name == 'Coproprieté') ? opp.Account.Syndic__c : opp.AccountId;

            // Récupération des données TURPE basées sur l'opportunité
            List<Quote> quotes = VFC007_ComparatifPDFController.getInfosTurpe(oppId);
            if (!quotes.isEmpty()) {
                quoteTURPE = quotes[0];
            }

            // Récupération des informations du compte client
            clientAccount = [
                SELECT Name, BillingStreet, BillingCity, BillingPostalCode
                FROM Account
                WHERE Id = :clientAccountId
                LIMIT 1
            ];

            clientAddresse = String.valueOf(clientAccount.BillingStreet) + ' ' +
                            String.valueOf(clientAccount.BillingCity) + ' ' +
                            String.valueOf(clientAccount.BillingPostalCode);
            accountName = clientAccount.Name;

            pourcentageRemuneration = quoteTURPE.MargeInterventionPEPS__c;
            montantEconomie = quoteTURPE.SumEconomieIdentifiee__c;
        } else {
            throw new AuraHandledException('Aucun identifiant fourni. Fournissez un opportunityId (id) ou un accountId.');
        }
        formatMontantEconomie = formatMontantEconomie(montantEconomie);
        montantRemuneration = (montantEconomie * (pourcentageRemuneration / 100)).setScale(2);
        formatMontantRemuneration = formatMontantEconomie(montantRemuneration);

    }

    /*
    * LWC Methods
    */
    @AuraEnabled
    public static String generateLettreMissionUrl(Id opportunityId) {
        String baseUrl = Site.getBaseUrl();
        String siteContext = (URL.getCurrentRequestUrl().getPath().contains('/s/')) ? '/s' : '';

        PageReference pdfPage = Page.LettreMissionTURPE;
        pdfPage.getParameters().put('id', opportunityId);

        // Create chatter message
        FeedItem feed = new FeedItem();
        feed.ParentId = opportunityId;

        feed.Body = 'L\'utilisateur ' + UserInfo.getName()
            + ' a téléchargé la lettre de mission';

        insert feed;
        
        return baseUrl + siteContext + pdfPage.getUrl();
    }

    @AuraEnabled
    public static String generateLettreMissionUrlFromAccount(Id accountId, Double pourcentageRemuneration, Double montantEconomie) {
        String baseUrl = Site.getBaseUrl();
        String siteContext = (URL.getCurrentRequestUrl().getPath().contains('/s/')) ? '/s' : '';

        PageReference pdfPage = Page.LettreMissionTURPE;
        pdfPage.getParameters().put('accountId', accountId);
        pdfPage.getParameters().put('pourcentageRemuneration', String.valueOf(pourcentageRemuneration));
        pdfPage.getParameters().put('montantEconomie', String.valueOf(montantEconomie));
        // Create chatter message
        FeedItem feed = new FeedItem();
        feed.ParentId = accountId;
        feed.Body = 'L\'utilisateur ' + UserInfo.getName()
            + ' a téléchargé la lettre de mission';

        insert feed;
        
        return baseUrl + siteContext + pdfPage.getUrl();
    }
    
    public String formatMontantEconomie(Decimal montant) {
        if(montant == null) return '';
        String formatted = montant.format();
        return formatted;
    }

}