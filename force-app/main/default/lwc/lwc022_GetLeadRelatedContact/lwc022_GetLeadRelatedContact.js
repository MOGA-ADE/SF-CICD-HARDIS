import { LightningElement, api } from 'lwc';

export default class Lwc022_GetLeadRelatedContact extends LightningElement {
    @api listContact;
    @api error;
}