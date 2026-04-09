import { LightningElement } from 'lwc';

export default class Lwcc002_AA_Step2 extends LightningElement {
    leadObject = {};
    fileUploaded = false;
    errorFile = false;

    get acceptedFormats() {
        return ['.pdf','.jpeg','.png','.jpg'];
    }
    
    handlePrevious() {
        const event = new CustomEvent('previous', {});
        this.dispatchEvent(event);
    }

    handleNext() {
        // check file error
        if (!this.fileUploaded) {
            this.errorFile = true;
            return;
        }

        // Check fields errors
        const allValid = [...this.template.querySelectorAll('lightning-input'),].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {
            // Ajout de la clé ELLISPHERE__Elli_Siret__c
            this.leadObject.ELLISPHERE__Elli_Siret__c = this.leadObject.Siret__c;
            const event = new CustomEvent('next', {detail: this.leadObject});
            this.dispatchEvent(event);
        }
    }

    handleChange(event) {
        this.leadObject[event.target.name] = event.target.value;
    }

    handleUploadFinished(e) {
        this.fileUploaded = true;
        this.errorFile = false;
        const event = new CustomEvent('contentversionid', {detail: e.detail.files[0].contentVersionId});
        this.dispatchEvent(event);
    }
}