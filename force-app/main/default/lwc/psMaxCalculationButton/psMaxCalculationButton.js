import { LightningElement, api } from 'lwc';
import commandeCourbeDeCharge from "@salesforce/apex/SGEManager.commandeCourbeDeCharge";


export default class PsMaxCalculationButton extends LightningElement {
  @api recordId;
  result;
  isError = false;
  loaded = true;

  handleLancerAppel() {
    this.loaded = false;
    this.result = undefined;
    this.isError = false;
    commandeCourbeDeCharge({ siteId: this.recordId })
      .then(response => {
        this.loaded = true;
        this.result = response;
        this.isError = response.startsWith('Erreur');
      })
      .catch(err => {
        this.loaded = true;
        this.isError = true;
        this.result = "Erreur technique : 'Impossible de joindre Salesforce.'";
      });
  }
}