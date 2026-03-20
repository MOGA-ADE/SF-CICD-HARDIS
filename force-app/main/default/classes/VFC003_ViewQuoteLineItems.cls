public without sharing class VFC003_ViewQuoteLineItems {
    @AuraEnabled(cacheable=false)
    public static List<QuoteLineElementsByFournisseur> getQuoteLineItemList(String theRecordId, String theObjectApiName) {
        List<SM003_GestionQuoteLineItem.QuoteLineElement> results = new List<SM003_GestionQuoteLineItem.QuoteLineElement>();
        Set<String> fournisseurs = new Set<String>();
        List<QuoteLineElementsByFournisseur> finalResults = new List<QuoteLineElementsByFournisseur>();

        results = SM003_GestionQuoteLineItem.getQuoteLineItems(theRecordId, theObjectApiName);

        if(results != null && !results.isEmpty()){
            for(SM003_GestionQuoteLineItem.QuoteLineElement result : results){
                If(String.isNotBlank(result.fournisseur)){
                    fournisseurs.add(result.fournisseur);
                }/*else{
                    fournisseurs.add('Aucun fournisseur');
                }*/
            }
    
            for(String fournisseur : fournisseurs){
                QuoteLineElementsByFournisseur qlisByF = new QuoteLineElementsByFournisseur();
                List<SM003_GestionQuoteLineItem.QuoteLineElement> qliList = new List<SM003_GestionQuoteLineItem.QuoteLineElement>();

                for(SM003_GestionQuoteLineItem.QuoteLineElement result : results){
                    if(fournisseur == result.fournisseur){
                        qliList.add(result);
                    }else if(fournisseur == 'Aucun fournisseur' && String.isBlank(result.fournisseur)){
                        qliList.add(result);
                    }
                }
                qlisByF.quoteLineElementFournisseur = fournisseur;
                qlisByF.quoteLineElementList = qliList;
                finalResults.add(qlisByF);
            }

            return finalResults;
        }else {
            return null;
        }
    }

    public class QuoteLineElementsByFournisseur{
        @AuraEnabled public String quoteLineElementFournisseur {get;set;}
        @AuraEnabled public SM003_GestionQuoteLineItem.QuoteLineElement[] quoteLineElementList {get;set;}
    }
}