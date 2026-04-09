import { LightningElement,api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Lwc026_CheckContratsFournisseurThirdCard extends LightningElement {

    @api listAppelFacturationKO
    @api columnsContratsKO
    @api listAppelFacturationMissingFromCRM
    @api listAppelFacturationMissingFromFile
    @api columnsContratsMissing

    @api columnsContratsMissingFromCRM
    @api columnsContratsMissingFromFile


    @api getShowTableContratsMissingFromCRM
    @api getShowTableContratsMissingFromFile
    @api getShowSuccessValidation
    @api getShowTableContratsKO


    
    
    downloadContrats(event){
        console.log('event.currentTarget.dataset.name' ,event.currentTarget.dataset.name)
        const downloadContratsKO = new CustomEvent("downloadcontrats",{detail:{'contratsType':event.currentTarget.dataset.name}});
        this.dispatchEvent(downloadContratsKO);
    }

    returnFirstCard(){
        const returnFirstCardEvent = new CustomEvent("returnfirstcard");
        this.dispatchEvent(returnFirstCardEvent);
    }

    validAF(){
        const validAF = new CustomEvent("validaf");
        this.dispatchEvent(validAF);
    }

    @api
    displayToast(title,message,variant,mode){
        const showToastEvent = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode:mode
        });
        this.dispatchEvent(showToastEvent);
        this.returnFirstCard()
    }
}