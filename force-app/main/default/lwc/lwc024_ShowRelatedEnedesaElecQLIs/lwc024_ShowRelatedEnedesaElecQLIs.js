import {LightningElement, api, wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import GRAND_TOTAL from '@salesforce/schema/Quote.GrandTotal';
import getRelatedQuotes from '@salesforce/apex/AP010_ShowRelatedRecordsController.getRelatedEndesaElecQLIs';


export default class Lwc024_ShowRelatedEnedesaElecQLIs extends LightningElement {
    @api recordId;
    selectedQLIId;
    relatedQLIs = [];
    
    get relatedQLISize(){
        return this.relatedQLIs.length;
    }

    get quoteOfferNumber() {
        return this.relatedQLIs[0]?.Quote?.Numero_Offre_API_Endesa_Elec__c;
    }

    get redirectToQLI() {
        return `/lightning/r/QuoteLineItem/${this.selectedQLIId}/view`;
    }

    // Use LDS for forcing the refresh of the view
    @wire (getRecord,{recordId: '$recordId', fields: [GRAND_TOTAL]}) 
    getRelatedQuote({error,data}){
        if (data) {
            getRelatedQuotes({recordId: data.id})
            .then( result =>{
                this.relatedQLIs = result;
            })
        } else if (error) {
            console.log('error', error);
        }
    }

    getQLIId(event) {
        this.selectedQLIId = event.currentTarget.dataset.id;
    }
}