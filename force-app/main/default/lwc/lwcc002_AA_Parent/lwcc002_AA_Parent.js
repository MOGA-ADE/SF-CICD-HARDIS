import { LightningElement } from 'lwc';
import logoURL from '@salesforce/resourceUrl/siteApporteurAffaires';
import insertLead from '@salesforce/apex/AP013_EspaceApporteurAffairesController.insertLead';

export default class Lwcc002_AA_Parent extends LightningElement {
    activeStep = 1
    contentVersionId;
    leadObject = {
        sObjectType : "Lead",
        ELLISPHERE__Elli_TCH_CountryCode__c : "FRA",
        LeadSource: "Apporteur Affaires"
    }

    get bgkADEURL() { return `background: url('${logoURL}/logos/ade.png') no-repeat center center`; }
    get bgkPEPSURL() { return `background: url('${logoURL}/logos/peps.png') no-repeat center center`; }
    get progressBarStep() { return `progressBar step${this.activeStep}`; }
    get step1Visible() { return this.activeStep === 1; }
    get step2Visible() { return this.activeStep === 2; }
    get step3Visible() { return this.activeStep === 3; }
    get step4Visible() { return this.activeStep === 4; }

    handleNextStep(event) {
        this.leadObject = {...this.leadObject, ...event.detail};
        this.activeStep++;
    }

    handlePreviousStep() {
        this.activeStep--;
    }

    handleContentVersionIdChange(event) {
        this.contentVersionId = event.detail;
    }

    handleSubmitLead(event) {
        this.leadObject = {...this.leadObject, ...event.detail};
        insertLead({lead : this.leadObject, contentVersionId: this.contentVersionId})
            .then(success => {
                if (success) this.activeStep++;
            })
        .catch(e =>console.log(e))
    }
}