import { LightningElement, api } from 'lwc';
import getQuoteList from '@salesforce/apex/AP004_ShowOppOnDemandeCotationController.getQuoteList';

export default class Lwc014_ShowQuoteOnDemandeCotation extends LightningElement {

    @api recordId;

    columnsList = [
        {label: 'Nom opportunité', fieldName: 'OppName', sortable: true},
        {label: 'Fournisseur', fieldName: 'Fournisseur__c', sortable: true},
        {label: 'Type d\'offre', fieldName: 'TypeOffre__c', sortable: true},
        {label: 'Rémunération', fieldName: 'TotalPrice', type: 'currency', sortable: true, cellAttributes: { alignment: 'left' }},
    ];

    dataList;
    cardTitle = 'Offre fournisseur';

    connectedCallback(){
        getQuoteList({'demandeCotationId' : this.recordId})
            .then((quotes) => {
                if (quotes.length > 0) {
                    let dataList = [];
                    quotes.forEach(quote => {
                        let data = {};

                        data.OppName = quote.Opportunity.Name;
                        data.Fournisseur__c = quote.Fournisseur__c;
                        data.TypeOffre__c = quote.TypeOffre__c;
                        data.TotalPrice = quote.TotalPrice != undefined ? quote.TotalPrice: '--';

                        dataList.push(data);
                    });
                    this.dataList = dataList;
                }
            });
    }
}