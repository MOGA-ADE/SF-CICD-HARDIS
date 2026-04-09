public without sharing class SM003_GestionQuoteLineItem {
    @AuraEnabled
    public static List<QuoteLineElement> quoteLineElements {get;set;}

    @AuraEnabled
    public static List<QuoteLineElement> getQuoteLineItems(String theRecordId, String theObjectApiName) {
        Quote quoteRecord = new Quote();
        QuoteLineItem quoteLineItemRecord = new QuoteLineItem();
        List<Quote> quotes = new List<Quote>();
        List<QuoteLineItem> quoteLineItems = new List<QuoteLineItem>();
        Set<String> quoteIds = new Set<String>();
        quoteLineElements = new List<QuoteLineElement>();
        
        if(theObjectApiName == 'Opportunity'){
            quotes = DM000_QueryManager.getQuoteByOpportunity(theRecordId);

            for(Quote q : quotes){
                quoteIds.add(q.Id);
            }

            quoteLineItems = DM000_QueryManager.getQuoteLineItemByQuote(quoteIds);
            System.debug('*** quoteLineItems *** : ' + quoteLineItems.size());

            for(QuoteLineItem qli : quoteLineItems){
                quoteLineElements.add(new QuoteLineElement(qli));
            }
        }else if(theObjectApiName == 'Quote'){
            quoteRecord = DM000_QueryManager.getQuoteById(theRecordId);
            quotes = DM000_QueryManager.getQuoteByOpportunity(quoteRecord.OpportunityId);

            for(Quote q : quotes){
                quoteIds.add(q.Id);
            }

            quoteLineItems = DM000_QueryManager.getQuoteLineItemByQuote(quoteIds);

            for(QuoteLineItem qli : quoteLineItems){
                quoteLineElements.add(new QuoteLineElement(qli));
            }
        }else if(theObjectApiName == 'QuoteLineItem'){
            quoteLineItemRecord = DM000_QueryManager.getQuoteLineItemById(theRecordId);
            quoteRecord = DM000_QueryManager.getQuoteById(quoteLineItemRecord.QuoteId);
            quotes = DM000_QueryManager.getQuoteByOpportunity(quoteRecord.OpportunityId);

            for(Quote q : quotes){
                quoteIds.add(q.Id);
            }

            quoteLineItems = DM000_QueryManager.getQuoteLineItemByQuote(quoteIds);

            for(QuoteLineItem qli : quoteLineItems){
                if(qli.Id != theRecordId){
                    quoteLineElements.add(new QuoteLineElement(qli));
                }
            }
        }
        System.debug('*** quoteLineElements *** : ' + quoteLineElements.size());

        if(quoteLineElements != null && !quoteLineElements.isEmpty()){
            return quoteLineElements;
        }else{
            return null;
        }
    }

    public class QuoteLineElement{
        @AuraEnabled public String quoteLineElementId {get;set;}
        @AuraEnabled public String quoteLineElementQuoteId {get;set;}
        @AuraEnabled public String quoteLineElementNumber {get;set;}
        @AuraEnabled public String reference {get;set;}
        @AuraEnabled public String type {get;set;}
        @AuraEnabled public String typeImage {get;set;}
        @AuraEnabled public String abonnement {get;set;}
        @AuraEnabled public String budgetF {get;set;}
        @AuraEnabled public String budgetAO {get;set;}
        @AuraEnabled public String budgetO {get;set;}
        @AuraEnabled public String CAR {get;set;}
        @AuraEnabled public String fournisseur {get;set;}
        @AuraEnabled public String quoteLineElementUrl {get;set;}

        public quoteLineElement(QuoteLineItem qli){
            this.quoteLineElementId = qli.Id;
            this.quoteLineElementQuoteId = qli.QuoteId;
            this.quoteLineElementNumber = qli.LineNumber;
            
            if(qli.pde__r.TypePDE__c == 'Gaz'){
                this.reference = String.valueOf(qli.pde__r.PCE_Refonte__c);
                this.CAR =  String.valueOf(qli.CARGaz__c);
                this.type = 'Gaz';
                this.typeImage = GetResourceURL('GazIcon');
                this.abonnement = String.valueOf(qli.AbonnementMois__c);
                this.budgetF = String.valueOf(qli.BudgetFourniture__c);
                this.budgetO = String.valueOf(qli.BudgetObligationsMWH__c);
                this.budgetAO = string.valueOf(qli.BudgetHTTan__c);
            }else{
                this.reference = String.valueOf(qli.pde__r.ReferencePointEnergie_Refonte__c);
                this.type = 'Electricité';
                this.typeImage = GetResourceURL('ElecIcon');
                this.abonnement = String.valueOf(qli.AbonnementMois__c);
                this.budgetF = String.valueOf(qli.BudgetFourniture__c);
                this.budgetO = String.valueOf(qli.BudgetObligationsMWH__c);
                this.budgetAO = string.valueOf(qli.BudgetHTTan__c);
                this.CAR =  String.valueOf(qli.CAR_New__c);
            }            
            this.quoteLineElementUrl = '/'+ qli.Id;
        }

        public quoteLineElement(){}
    }
    
    // Pass the resource name
    public static String GetResourceURL(String resourceName){
        // return '';
        // Fetching the resource
        List<StaticResource> resourceList= [SELECT Name, NamespacePrefix, SystemModStamp FROM StaticResource WHERE Name = :resourceName];
        
        // Checking if the result is returned or not
        if(resourceList.size() == 1){
            
            // Getting namespace
            String namespace = resourceList[0].NamespacePrefix;
            // Resource URL
            return '/resource/' + resourceList[0].SystemModStamp.getTime() + '/' + (namespace != null && namespace != '' ? namespace + '__' : '') + resourceName; 
        }
        else return '';
    }
}