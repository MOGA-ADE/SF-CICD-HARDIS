import { LightningElement, api } from 'lwc';

export default class Lwcc002_AA_Step3 extends LightningElement {
    leadObject = {};
    isLoading = false;

    handlePrevious() {
        const event = new CustomEvent('previous', {});
        this.dispatchEvent(event);
    }

    handleNext() {
        // Check fields errors
        const allValid = [...this.template.querySelectorAll('lightning-input'),].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {
            this.isLoading = true;
            const event = new CustomEvent('submit', {detail: this.leadObject});
            this.dispatchEvent(event);
        } 
    }

    handleChange(event) {
        this.leadObject[event.target.name] = event.target.value;
    }
}