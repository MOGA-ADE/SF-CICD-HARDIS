/* eslint-disable guard-for-in */
import { LightningElement, wire, api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuoteWrappers from '@salesforce/apex/AP008_AddPriceFTAFournisseurController.getQuoteWrappers';
import getOPRDetails from '@salesforce/apex/AP008_AddPriceFTAFournisseurController.getOPRDetails';
import getPriceBookEntry from '@salesforce/apex/AP008_AddPriceFTAFournisseurController.getPriceBookEntry';
import insertQLI from '@salesforce/apex/AP008_AddPriceFTAFournisseurController.insertListQLI';

export default class Lwc016_AddPriceFTAPerFournisseurAction extends LightningElement {
    
    @api recordId;
    oprList;
    quoteList;
    pricesOutput = {};
    listQLI = [];
    showSpinner = true;
    iSCreatingQLI = false;
    priceBookEntry;

    @wire(getQuoteWrappers, {oppId: '$recordId'})
    quoteWrappers({ error, data }) {
        this.showSpinner = false;
        if (data) {
            this.quoteList = data;
            getOPRDetails({oppId: this.recordId})
                .then(oprDetails => {
                    this.oprList = oprDetails;
                })
        }
    }

    connectedCallback() {
        getPriceBookEntry()
            .then((pbe) => {
                this.priceBookEntry = pbe;
            })
    }

    changeInput(event) {
        const quoteId = event.target.dataset.quoteid;
        const fta = event.target.dataset.fta;
        const inputName = event.target.dataset.inputname;
        const clickedInput = event.target.dataset.inputname;
        const inputElement = event.target;

        if (!this.pricesOutput[quoteId]) this.pricesOutput[quoteId] = {};

        if (inputName === 'DebutDeFourniture__c' || inputName === 'Nouvelle_Echeance__c' || inputName === 'DureeEngagement__c') {
            if (!this.pricesOutput[quoteId][inputName]) this.pricesOutput[quoteId][inputName] = null;
            this.pricesOutput[quoteId][inputName] = event.target.value;
        } else {
            if (!this.pricesOutput[quoteId][fta]) this.pricesOutput[quoteId][fta] = {};
            this.pricesOutput[quoteId][fta][inputName] = event.target.value;
        }
    
        const dateInput = this.template.querySelector('[data-inputname="Nouvelle_Echeance__c"][data-quoteid="'+quoteId+'"]');
        const numberInput = this.template.querySelector('[data-inputname="DureeEngagement__c"][data-quoteid="'+quoteId+'"]');
        if (inputElement.value === null || inputElement.value === '') {
            if (clickedInput === 'Nouvelle_Echeance__c') {
                numberInput.disabled = false;
            } else if (clickedInput === 'DureeEngagement__c') {
                dateInput.disabled = false;
            }
        } else {
            if (clickedInput === 'Nouvelle_Echeance__c') {
                numberInput.disabled = true;
            } else if (clickedInput === 'DureeEngagement__c') {
                dateInput.disabled = true;
            }
        }
        
    }

    createQLI() {
        this.showSpinner = true;
        this.iSCreatingQLI = true;
        let dateEcheancePDE;
        for(const quoteId in this.pricesOutput){
            for(const fta in this.pricesOutput[quoteId]){
                // eslint-disable-next-line no-loop-func
                this.oprList.forEach(opr => {
                    if(opr.PDE__r.FTA__c === fta) {
                        const oldValues = (this.quoteList.find(tmpFTA => tmpFTA.id === quoteId).ftas.find(tmpValue => tmpValue.name === fta));
                        let qli = {};
                        qli.sobjectType = "QuoteLineItem";
                        qli.Opportunit__c = this.recordId;
                        qli.QuoteId = quoteId;
                        qli.PDE__c = opr.PDE__c;
                        qli.Quantity = 1;
                        qli.UnitPrice = 0;
                        qli.Taxes__c = true;
                        qli.Product2Id = this.priceBookEntry.Product2Id;
                        qli.PricebookEntryId = this.priceBookEntry.Id;
                        qli.Puissance_souscrite__c = opr.PDE__r.Puissance_souscrite__c;
                        qli.Conso_Base__c = opr.PDE__r.Conso_Base__c;
                        qli.ConsoHC__c = opr.PDE__r.ConsoHC__c;
                        qli.Conso_HCE__c = opr.PDE__r.Conso_HCE__c;
                        qli.Conso_HCH__c = opr.PDE__r.Conso_HCH__c;
                        qli.ConsoHP__c = opr.PDE__r.ConsoHP__c;
                        qli.Conso_HPE__c = opr.PDE__r.Conso_HPE__c;
                        qli.Conso_HPH__c = opr.PDE__r.Conso_HPH__c;
                        qli.Conso_Pointe__c = opr.PDE__r.Conso_Pointe__c;
                        qli.CSPE__c =  this.pricesOutput[quoteId][fta].CSPE__c != null ? parseFloat(this.pricesOutput[quoteId][fta].CSPE__c) : oldValues.oldValueCSPE;
                        
                        if(opr.PDE__r.Calendrier_fournisseur__c === 'HP/HC' || opr.PDE__r.Calendrier_fournisseur__c === 'Heures Pleines/Creuses'){
                            qli.TECH_CalendrierFournisseur__c = 'HP/HC';
                          }
                          else if(opr.PDE__r.Calendrier_fournisseur__c === 'Base' || opr.PDE__r.Calendrier_fournisseur__c !== ''){
                            qli.TECH_CalendrierFournisseur__c = 'Base';
                          }

                        dateEcheancePDE = new Date(opr.PDE__r.DateEcheance__c);
                        qli.DebutDeFourniture__c = new Date(dateEcheancePDE.setDate(dateEcheancePDE.getDate() + 1));
                        if(this.pricesOutput[quoteId].DureeEngagement__c === undefined || this.pricesOutput[quoteId].DureeEngagement__c === ''){
                            qli.Nouvelle_Echeance__c = this.pricesOutput[quoteId].Nouvelle_Echeance__c;
                        }
                        else{
                            qli.Nouvelle_Echeance__c = new Date(dateEcheancePDE.setMonth(dateEcheancePDE.getMonth() + parseInt(this.pricesOutput[quoteId].DureeEngagement__c,10)));
                            qli.DureeEngagement__c = parseInt(this.pricesOutput[quoteId].DureeEngagement__c,10);
                        }
                        
                        qli.AbonnementMois__c = this.pricesOutput[quoteId][fta].AbonnementMois__c != null ? parseFloat(this.pricesOutput[quoteId][fta].AbonnementMois__c) : oldValues.oldValueAbonnement;
                        qli.CeeMwh__c = this.pricesOutput[quoteId][fta].CeeMwh__c != null ? parseFloat(this.pricesOutput[quoteId][fta].CeeMwh__c) : oldValues.oldValueCEE;
                        qli.TDCFE__c = this.pricesOutput[quoteId][fta].TDCFE__c != null ? parseFloat(this.pricesOutput[quoteId][fta].TDCFE__c) : oldValues.oldValueTDCFE;
                        qli.TCCFE__c = this.pricesOutput[quoteId][fta].TCCFE__c != null ? parseFloat(this.pricesOutput[quoteId][fta].TCCFE__c) : oldValues.oldValueTCCFE;
                        qli.Capa_HP__c = this.pricesOutput[quoteId][fta].Capa_HP__c != null ? parseFloat(this.pricesOutput[quoteId][fta].Capa_HP__c) : oldValues.oldValueCapaciteHP;
                        qli.Capa_HC__c = this.pricesOutput[quoteId][fta].Capa_HC__c != null ? parseFloat(this.pricesOutput[quoteId][fta].Capa_HC__c) : oldValues.oldValueCapaciteHC;
                        qli.Capa_HPH__c = this.pricesOutput[quoteId][fta].Capa_HPH__c != null ? parseFloat(this.pricesOutput[quoteId][fta].Capa_HPH__c) : oldValues.oldValueCapaciteHPH;
                        qli.Capa_HCH__c = this.pricesOutput[quoteId][fta].Capa_HCH__c != null ? parseFloat(this.pricesOutput[quoteId][fta].Capa_HCH__c) : oldValues.oldValueCapaciteHCH;
                        qli.Capa_HPE__c = this.pricesOutput[quoteId][fta].Capa_HPE__c != null ? parseFloat(this.pricesOutput[quoteId][fta].Capa_HPE__c) : oldValues.oldValueCapaciteHPE;
                        qli.Capa_HCE__c = this.pricesOutput[quoteId][fta].Capa_HCE__c != null ? parseFloat(this.pricesOutput[quoteId][fta].Capa_HCE__c) : oldValues.oldValueCapaciteHCE;
                        qli.Capa_Base__c = this.pricesOutput[quoteId][fta].Capa_Base__c != null ? parseFloat(this.pricesOutput[quoteId][fta].Capa_Base__c) : oldValues.oldValueCapaciteBase;
                        qli.PrixHP__c = this.pricesOutput[quoteId][fta].PrixHP__c != null ? parseFloat(this.pricesOutput[quoteId][fta].PrixHP__c) : oldValues.oldValuePrixHP;
                        qli.PrixHC__c = this.pricesOutput[quoteId][fta].PrixHC__c != null ? parseFloat(this.pricesOutput[quoteId][fta].PrixHC__c) : oldValues.oldValuePrixHC;
                        qli.PrixHphMwh__c = this.pricesOutput[quoteId][fta].PrixHphMwh__c != null ? parseFloat(this.pricesOutput[quoteId][fta].PrixHphMwh__c) : oldValues.oldValuePrixHPH;
                        qli.PrixHchMwh__c = this.pricesOutput[quoteId][fta].PrixHchMwh__c != null ? parseFloat(this.pricesOutput[quoteId][fta].PrixHchMwh__c) : oldValues.oldValuePrixHCH;
                        qli.PrixHpeMwh__c = this.pricesOutput[quoteId][fta].PrixHpeMwh__c != null ? parseFloat(this.pricesOutput[quoteId][fta].PrixHpeMwh__c) : oldValues.oldValuePrixHPE;
                        qli.PrixHceMwh__c = this.pricesOutput[quoteId][fta].PrixHceMwh__c != null ? parseFloat(this.pricesOutput[quoteId][fta].PrixHceMwh__c) : oldValues.oldValuePrixHCE;
                        qli.PrixBase__c = this.pricesOutput[quoteId][fta].PrixBase__c != null ? parseFloat(this.pricesOutput[quoteId][fta].PrixBase__c) : oldValues.oldValuePrixBase;
                        qli.PointesMWh__c = this.pricesOutput[quoteId][fta].PointesMWh__c != null ? parseFloat(this.pricesOutput[quoteId][fta].PointesMWh__c) : oldValues.oldValuePointe;
                        qli.Capa_Pointes__c = this.pricesOutput[quoteId][fta].Capa_Pointes__c != null ? parseFloat(this.pricesOutput[quoteId][fta].Capa_Pointes__c) : oldValues.oldValueCapacitePointe;
                        this.listQLI.push(qli);
                    }
                })
            }
        }

                
        insertQLI({qlis : this.listQLI})
            .then( success => {
                this.showSpinner = false;
                this.iSCreatingQLI = false;
                let variant = 'success';
                let message = 'Opération effectuée avec succès !';

                if (!success) {
                    variant = 'error';
                    message = 'Opération échouée !';
                }
                
                const evt = new ShowToastEvent({
                    title: 'Création lignes de fournisseurs',
                    message: message,
                    variant: variant
                });

                this.dispatchEvent(evt);
                this.closeAction();
            })
            .catch((e) => {
                const evt = new ShowToastEvent({
                    title: 'Création lignes de fournisseurs',
                    message: e.body.pageErrors[0].message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
                this.closeAction();
            });
    }

    closeAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}