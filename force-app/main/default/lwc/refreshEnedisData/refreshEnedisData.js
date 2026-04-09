import { LightningElement, api, wire } from 'lwc';
import refreshSite from '@salesforce/apex/SGEManager.refreshSiteInformation';
import updateSite from '@salesforce/apex/SGEManager.updateSite';
import LightningModal from 'lightning/modal';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RefreshEnedisData extends LightningElement {
    _recordId;
    isStarted = false;
    isLoaded = false;
    errorMessage;
    result;

    // Getter du recordId
    @api get recordId() { return this._recordId; }

    set recordId(value) {
        this._recordId = value;

        // Dès qu'on reçoit une valeur non nulle et qu'on n'a pas encore commencé
        if (value && !this.isStarted) {
            this.isStarted = true;
            this.fetchEnedisData();
        }
    }

    // Getter pour vérifier si l'appel Mesures est en erreur
    get isMesureError() { return this.result && this.result.messageConsulterMesure !== 'OK'; }
    // Getter pour vérifier si l'appel Point technique est en erreur
    get isPointError() { return this.result && this.result.messageConsulterPoint !== 'OK'; }
    // Style dynamique pour le message Mesure
    get mesureClass() { return this.isMesureError ? 'slds-text-color_error' : 'slds-text-color_success'; }
    // Style dynamique pour le message Point
    get pointClass() { return this.isPointError ? 'slds-text-color_error' : 'slds-text-color_success'; }
    // Getter pour déterminer si le bouton de mise à jour doit être désactivé
    get isUpdateDisabled() {
        // Désactivé si :
        // 1. Les données ne sont pas encore là
        if (!this.result) return true;

        // 2. OU si les deux flux sont marqués comme non-mettables à jour
        // (Le bouton devient cliquable dès que l'un des deux passe à true)
        return !(this.result.mesuresUpdatable || this.result.techDataUpdatable);
    }

    // API
    // Méthode pour appeler l'Apex et récupérer les données
    fetchEnedisData() {
        this.isLoaded = false;
        refreshSite({ siteId: this._recordId })
            .then(data => {
                this.result = data;
                console.log("resutat = " + JSON.stringify(this.result));
                this.isLoaded = true;
            })
            .catch(error => {
                this.errorMessage = error.body?.message || 'Erreur SGE';
                this.isLoaded = true;
            });
    }

    // Méthode pour mettre à jour les données
    updateInfo() {
        console.log("AVANT APPEL + " + JSON.stringify(this.result));
        this.isLoaded = false;
        updateSite({ siteId: this.recordId, infoSite: this.result })
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