import {LightningElement, api} from 'lwc';
import getRelatedQuotes from '@salesforce/apex/AP010_ShowRelatedRecordsController.getRelatedQuotes';

export default class Lwc018_ShowRelatedQuotes extends LightningElement {
    @api recordId;
    selectedQuoteId;
    relatedQuotes = [];
    
    get relatedQuoteSize(){
        return this.relatedQuotes.length;
    }

    get viewAllURL() {
        return `/lightning/r/Opportunity/${this.relatedQuotes[0]?.OpportunityId}/related/Quotes/view`;
    }

    get redirectToQuote() {
        return `/lightning/r/Quote/${this.selectedQuoteId}/view`;
    }

    connectedCallback(){
        getRelatedQuotes({recordId: this.recordId})
            .then( result =>{
                this.relatedQuotes = result;
            })
    }

    getQuoteId(event) {
        this.selectedQuoteId = event.currentTarget.dataset.id;
    }
}