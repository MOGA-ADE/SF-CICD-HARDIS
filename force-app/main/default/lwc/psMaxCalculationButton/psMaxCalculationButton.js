import { LightningElement , api, wire} from 'lwc';
import calculatePsMaxForAYear from "@salesforce/apex/SGEManager.calculatePsMaxForAYear";
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import PDE_REF_FIELD from '@salesforce/schema/PDE__c.ReferencePointEnergie_Refonte__c';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { updateRecord } from "lightning/uiRecordApi";
import ID_FIELD from "@salesforce/schema/PDE__c.Id";
import RESULTAT_FIELD from "@salesforce/schema/PDE__c.ResultatCalculPsMax__c";
import PSACTIVE_FIELD from "@salesforce/schema/PDE__c.PSMaxActive__c";
import PSCAPACITIVE_FIELD from "@salesforce/schema/PDE__c.PSMaxCapacitive__c";
import PSINDUCTIVE_FIELD from "@salesforce/schema/PDE__c.PSMaxInductive__c";
import DEBUT_FIELD from "@salesforce/schema/PDE__c.DateDebutCourbePsMax__c";
import FIN_FIELD from "@salesforce/schema/PDE__c.DateFinCourbePsMax__c";
import CALCULDATE_FIELD from "@salesforce/schema/PDE__c.DateCalculPsMax__c";
import WITHOUTERRORDATE_FIELD from "@salesforce/schema/PDE__c.DateCalculPsMaxSansErreur__c";
import CALCULPSMAXOK_FIELD from "@salesforce/schema/PDE__c.Calcul_PS_Max_OK__c";
import { CloseActionScreenEvent } from "lightning/actions";

export default class PsMaxCalculationButton extends LightningElement {
    @api recordId;
    error;
    site;
    result;dateDebut;dateFin;psMaxActive;psMaxCapacitive;psMaxInductive;dateWithoutError;dateCalcul;
    loaded = false;

    @wire(getRecord, {
        recordId: "$recordId",
        fields: [PDE_REF_FIELD],
      })
      wiredPDE(result) {
        if (result.data) {
            console.log(JSON.stringify(result.data));
            //this.site = result.data.fields.ReferencePointEnergie_Refonte__c.value;)
            this.site = {"id" : this.recordId, [PDE_REF_FIELD.fieldApiName] : result.data.fields.ReferencePointEnergie_Refonte__c.value}
        }
        else if (result.error) {
            this.error = result.error.body.message;
        }
    }


    @wire (calculatePsMaxForAYear,{site: '$site'})
	wiredPSMax(result){
		if(result.data) {
		  this.site = result.data;
      this.result = result.data.ResultatCalculPsMax__c;
      this.dateDebut = result.data.DateDebutCourbePsMax__c;
      this.dateFin = result.data.DateFinCourbePsMax__c;
      this.psMaxActive =result.data.PSMaxActive__c;
      this.psMaxCapacitive =result.data.PSMaxCapacitive__c;
      this.psMaxInductive =result.data.PSMaxInductive__c;
      this.dateWithoutError = result.data.DateCalculPsMaxSansErreur__c;
      this.dateCalcul = result.data.DateCalculPsMax__c;
      this.resultCalcul = result.data.Calcul_PS_Max_OK__c;
			this.error = undefined;
      this.loaded = true;
		} else if (result.error) {
			this.site =undefined;
			this.error = result.error.body.message;
      this.loaded = true;
		}
	}

    updatePDE() {
        const fields = {};
        fields[ID_FIELD.fieldApiName] = this.recordId;
        fields[RESULTAT_FIELD.fieldApiName] = this.result;
        fields[DEBUT_FIELD.fieldApiName] = this.dateDebut;
        fields[FIN_FIELD.fieldApiName] = this.dateFin;
        fields[PSACTIVE_FIELD.fieldApiName] = this.psMaxActive;
        fields[PSCAPACITIVE_FIELD.fieldApiName] = this.psMaxCapacitive;
        fields[PSINDUCTIVE_FIELD.fieldApiName] = this.psMaxInductive;
        fields[CALCULDATE_FIELD.fieldApiName] = this.dateCalcul;
        fields[WITHOUTERRORDATE_FIELD.fieldApiName] = this.dateWithoutError;
        fields[CALCULPSMAXOK_FIELD.fieldApiName] = this.resultCalcul;
        const recordInput = {fields}
        updateRecord(recordInput)
        .then(() => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Success",
              message: "Les données ont été mise à jour",
              variant: "success",
            }),
          );
          this.dispatchEvent(new CloseActionScreenEvent());
        })
        .catch((error) => {
          this.dispatchEvent(
            new ShowToastEvent({
              title: "Error lors de la mise à jour",
              message: error.body.message,
              variant: "error",
            }),
          );
        });
    }
    
}