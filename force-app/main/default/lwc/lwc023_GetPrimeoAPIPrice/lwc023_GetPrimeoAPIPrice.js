import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import checkQLIValidity from '@salesforce/apex/AP015_GetPrimeoPriceController.checkQLIValidity';
import getPrices from '@salesforce/apex/AP015_GetPrimeoPriceController.getPrices';
import validOffer from '@salesforce/apex/AP015_GetPrimeoPriceController.validOffer';

export default class Lwc023_GetPrimeoAPIPrice extends LightningElement {
    @api recordId;
    qliToCheck;
    marge;
    greenEnergy = false;
    showSpinner = false;

    get isTypeOffreOK() {
        return  this.qliToCheck?.TECH_TypeOffre__c != undefined && 
                (this.qliToCheck?.TECH_TypeOffre__c == 'ARENH AVEC ÉCRÊTEMENT' || this.qliToCheck?.TECH_TypeOffre__c == 'PRIX FIXE');
    }

    get isDebutFournitureOK() {
        return this.qliToCheck?.DebutDeFourniture__c != undefined;
    }

    get isNouvelleEcheanceOK() {
        return this.qliToCheck?.Nouvelle_Echeance__c != undefined;
    }

    get isPrerequisOK() {
        return this.isTypeOffreOK && this.isDebutFournitureOK && this.isNouvelleEcheanceOK;
    }

    get isMargeOK() {
        return this.marge != undefined && this.marge != '';
    }

    get isLastDatePriceOK() {
        return this.qliToCheck?.PrimeoApiPriceDate__c != undefined;
    }

    get isGreenEnergy() {
        return this.qliToCheck?.PrimeoApiCurrentGreenEnergy__c ? 'Oui' : 'Non';
    }

    get offerAlreadyCreatedAndValid() {
        const todayDate = new Date();
        const offerDate = new Date(this.qliToCheck?.PrimeoApiCurrentOppDate__c);
        const todayTime = `${todayDate.getDay()}-${todayDate.getMonth()}-${todayDate.getFullYear()}`;
        const offerTime = `${offerDate.getDay()}-${offerDate.getMonth()}-${offerDate.getFullYear()}`;

        return this.qliToCheck?.PrimeoApiCurrentOppURL__c != undefined && todayTime == offerTime;
    }

    connectedCallback() {
        checkQLIValidity({ recordId: this.recordId})
            .then((record) => {
                this.qliToCheck = record;
            })
            .catch((e) => console.log(e))
    }


    handleChangeMarge(e) {
        this.marge = e.target.value;
    }

    handleChangeGreenEnergy(e) {
        this.greenEnergy = e.target.checked;
    }

    handleGetPrices(){
        this.showSpinner = true;
        getPrices({recordId: this.recordId, greenEnergy: this.greenEnergy, marge: this.marge})
            .then((e) => {
                this.showSpinner = false;
                this.showNotification(e);
                setTimeout(() => {
                    window.location.reload(); 
                }, 3000);
            })
    }

    handleValidOffer() {
        this.showSpinner = true;
        validOffer({recordId: this.recordId})
            .then((e) => {
                this.showSpinner = false;
                this.showNotification(e);
                setTimeout(() => {
                    window.location.reload(); 
                }, 3000);
            })
    }

    showNotification(e) {
        const evt = new ShowToastEvent({title: e.title, message: e.message, variant: e.type});
        this.dispatchEvent(evt);
    }
}