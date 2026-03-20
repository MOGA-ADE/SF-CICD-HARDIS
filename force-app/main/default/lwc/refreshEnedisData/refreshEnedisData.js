import { LightningElement, api, wire} from 'lwc';
import refreshSite from '@salesforce/apex/SGEManager.refreshSiteInformation';
import updateSite from '@salesforce/apex/SGEManager.updateSite';
import LightningModal from 'lightning/modal';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RefreshEnedisData extends LightningElement {
    @api recordId;
    //content;
    //body;
    errorMessage;
    result;
    isLoaded = false;

    @wire(refreshSite, {siteId: '$recordId'})
    getCertsHeldFunction (result) {
        
        console.log("resutat = " +JSON.stringify(result));
        if (result.data) {
           this.result = result.data;
           this.isLoaded = true;     
        }
        else if (result.error) {
            this.errorMessage = result.error.body.message;
            this.isLoaded = true;
        }
        
    }

    updateInfo() {
        console.log("AVANT APPEL + "+JSON.stringify(this.result));
        this.isLoaded = false;
        updateSite({siteId: this.recordId, infoSite: this.result})
                .then((result) => {
                    const event = new ShowToastEvent({
                        title: 'Succès',
                        message: 'Le point de livraison à été mis à jours avec les données SGE',
                        variant: 'success',
                        mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.isLoaded = true;
                    this.dispatchEvent(new CloseActionScreenEvent());
                })
                .catch((error) => {
                    this.errorMessage = error.body.message;
                    this.isLoaded = true;
                });
                
    }
}