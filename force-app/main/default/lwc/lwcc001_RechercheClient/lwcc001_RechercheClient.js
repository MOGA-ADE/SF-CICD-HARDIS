import { LightningElement, track } from 'lwc';
import getListCodeNaf from '@salesforce/apex/DM000_QueryManager.getListCodeNaf';

export default class Lwcc001_RechercheClient extends LightningElement {
    @track codeNafList = [];
    nameValue = '';
    codeNafValue = '';
    isLoading = true;
    
    get isDisabled(){
        return this.nameValue === '' && this.codeNafValue === ''; 
    }

    connectedCallback(){
        getListCodeNaf()
        .then((response)=>{
            response.forEach(elt => {
                this.codeNafList.push({
                    label : elt.Name,
                    value : elt.Name,
                    description : elt.Description__c,
                });
            });
            this.isLoading = false;
        })
        .catch();
    }

    handleChangeRaisonSociale(event){
       this.nameValue = event.target.value;
       this.codeNafValue = '';
    }

    handleChangeCodeNaf(event){
        this.codeNafValue = event.target.value;
        this.nameValue = '';
    }

    handleSearch(){
        const searchEvent = new CustomEvent('search', { detail: {raisonSociale : this.nameValue, codeNaf : this.codeNafValue} });
        this.dispatchEvent(searchEvent);
    }
    
}