import {LightningElement, api,track} from 'lwc';
import getRelatedQLIs from '@salesforce/apex/AP010_ShowRelatedRecordsController.getRelatedQLIs';

export default class Lwc019_ShowRelatedQLIs extends LightningElement {
    @api recordId;
    selectedQLIId;
    @track relatedQLIs = [];
    isLoading = true;
    
    get relatedQLIsize(){
        return this.relatedQLIs.length;
    }

    get viewAllURL() {
        return `/lightning/r/Opportunity/${this.relatedQLIs[0]?.Opportunit__c}/related/l_ments_de_devis__r/view`;
    }

    get redirectToQLI() {
        return `/lightning/r/QuoteLineItem/${this.selectedQLIId}/view`;
    }

    connectedCallback(){
        getRelatedQLIs({recordId: this.recordId})
            .then( result =>{
                result.forEach((qli)=>{
                    let newQLI = {};
                    let anneDebut = new Date(qli.DebutDeFourniture__c).getFullYear() || "";
                    let anneFin = new Date(qli.Nouvelle_Echeance__c).getFullYear() || "";
                    newQLI.Id = qli.Id;
                    newQLI.DebutDeFourniture__c =  anneDebut + " / " + anneFin;
                    newQLI.Opportunit__c = qli.Opportunit__c;  
                    newQLI.TECH_IdentifiantPDE__c = qli.TECH_IdentifiantPDE__c; 
                    newQLI.Nouvelle_Echeance__c = qli.Nouvelle_Echeance__c; 
                    newQLI.TECH_fournisseur__c = qli.TECH_fournisseur__c;  
                    newQLI.Budget_TTC__c = qli.Budget_TTC__c; 
                    newQLI.car = qli.TECH_TypePDL__c === 'PDE_Gaz' ? qli.CARGaz__c : qli.CAR_New__c; 
                    newQLI.TypeOffre__c = qli.Quote.TypeOffre__c;
                    newQLI.TECH_QLI_Remplie__c = qli.TECH_QLI_Remplie__c;
                    this.relatedQLIs.push(newQLI);
                });
                this.isLoading = false;
            });
    }

    getQLIId(event) {
        this.selectedQLIId = event.currentTarget.dataset.id;
    }
}