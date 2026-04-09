import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CloseActionScreenEvent } from 'lightning/actions';
import getDemandeCotation from '@salesforce/apex/AP007_CloneDemandeCotationController.getDemandeCotation';
import cloneDemandeCotation from '@salesforce/apex/AP007_CloneDemandeCotationController.cloneDemandeCotation';

export default class Lwc015_CloneDemandeCotationAction extends NavigationMixin(LightningElement) {

    @api recordId;
    showSpinner = true;
    cotationName;
    cotationRDV;

    @wire(getDemandeCotation, {demandeCotationId: '$recordId'})
    getCotationName({ error, data }) {
        this.showSpinner = false;
        if (data) {
            this.cotationName = data.Name;
            this.cotationRDV = data.Date_RDV_reactualisation__c;
            console.log(this.cotationRDV);
        }
    }

    changeName(e){
        this.cotationName = e.target.value;
    }

    changeRDV(e){
        this.cotationRDV = e.target.value;
    }

    cloneRecord(){
        this.showSpinner = true;
        cloneDemandeCotation({demandeCotationId: this.recordId, newName: this.cotationName, newDateRDV: this.cotationRDV})
            .then((cotation) => {
                this.navigateToRecordPage(cotation.Id);
            })
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    navigateToRecordPage(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                objectApiName: 'DemandeCotation__c',
                actionName: 'view'
            }
        });
    }
}