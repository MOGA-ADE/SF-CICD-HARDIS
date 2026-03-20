import { LightningElement, api, wire } from 'lwc';
import hasSyndicDuplicate from '@salesforce/apex/AP036_leadSyndicDuplicateWarning.hasSyndicDuplicate';

export default class Lwc033LeadSyndicDuplicateWarning extends LightningElement {
    @api recordId;
    isDuplicate = false;

    @wire(hasSyndicDuplicate, { leadId: '$recordId' })
    wiredDuplicate({ error, data }) {
        if (data !== undefined) {
            this.isDuplicate = data;
            console.log('DUPLICATE RESULT =', data);
        } else if (error) {
            console.error('ERREUR APEX', error);
        }
    }
}