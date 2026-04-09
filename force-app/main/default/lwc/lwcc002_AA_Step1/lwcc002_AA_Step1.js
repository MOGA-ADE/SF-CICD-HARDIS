import { LightningElement } from 'lwc';
import veryCode from '@salesforce/apex/AP013_EspaceApporteurAffairesController.verifyCodePartenaire';

export default class Lwcc002_AA_Step1 extends LightningElement {
    codeValue = '';
    error = false;
    isLoading = false;
    leadObject = {};

    get isDisabled() { return this.codeValue === ''}
    
    handleChangeCode(event) {
        this.codeValue = event.target.value;
    }

    handleAuth() {
        this.error = false;
        this.isLoading = true;
        veryCode({codePartenaire: this.codeValue})
        .then(account => {
            this.isLoading = false;
            this.leadObject.Apporteur_affaires__c = account.Id;
            this.leadObject.OwnerId = 'Responsable_Leads__c' in account ? account.Responsable_Leads__c : account.OwnerId;

            const event = new CustomEvent('next', {detail: this.leadObject});
            this.dispatchEvent(event);
        })
        .catch(e => {
            this.isLoading = false;
            this.error = true;
        })

    }
}