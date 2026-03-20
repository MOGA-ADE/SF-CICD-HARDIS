import { LightningElement,api } from 'lwc';
export default class Lwc026_CheckContratsFournisseurFirstCard extends LightningElement {
    @api picklistFournisseurs = []
    @api picklistMois = []
    @api picklistAnnee = []
    @api searchDisabled
    field
    value
    
    onChangeSearchAppelFacturation(event){
        const getParamEvent = new CustomEvent("getparamsearchaf",{
            detail: {
                field : event.target.name,
                value : event.target.value
            }
        });
        this.dispatchEvent(getParamEvent);
    }

    searchAppelFacturation(){
        const searchEvent = new CustomEvent("searchaf");
        this.dispatchEvent(searchEvent);
    }

    
}