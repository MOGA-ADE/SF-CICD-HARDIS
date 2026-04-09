import {LightningElement, api} from 'lwc';
import getRelatedPDEElec from '@salesforce/apex/AP011_ShowRelatedPDEController.getRelatedPDEGaz';

export default class Lwcc021_ShowRelatedPDEGaz extends LightningElement {
    @api recordId;
    selectedPDEId;
    relatedPDE = [];
    numberOfelement = '';
    showViewAll = false;
    columns = [
        {label: "Nom du site",fieldName: "PDEurl",type: "url",typeAttributes: { label: { fieldName: "Name" }, target: "_blank" },sortable: "true"},
        {label: "Contrat actif",fieldName: "Contrat_actif__c", type:"boolean", sortable: "true"},
        {label: "Siret payeur", fieldName: "Siret_payeur__c", sortable: "true"},
        {label: "Numéro PCE",fieldName: "PCE_Refonte__c",sortable: "true"},
        {label: "Type PDE", fieldName: "TypePDE__c", sortable: "true"},
        {label: "Date d'échéance",fieldName: "DateEcheance__c",type: "date",sortable: "true"},
        {label: "Adresse de consommation",fieldName: "Adresse_de_consommation__c",sortable: "true"},
        {label: "CAR", fieldName: "CARGaz__c", sortable: "true"}
      ];


    get viewAllURL() {
        return `/partenaire/s/account/related/${this.recordId}/PDE__r`;
    }

    connectedCallback(){
        getRelatedPDEElec({recordId: this.recordId})
        .then((data) => {
            let tempRecs = [];
            data.forEach((PDE) => {
                let tempRec = {};
                tempRec.PDEurl = "/partenaire/s/pde/" + PDE.Id;
                tempRec.Name = PDE.Name;
                tempRec.Siret_payeur__c =  PDE.Siret_payeur__c;
                tempRec.PCE_Refonte__c = PDE.PCE_Refonte__c;
                tempRec.TypePDE__c = PDE.TypePDE__c;
                tempRec.Contrat_actif__c = PDE.Contrat_actif__c;
                tempRec.DateEcheance__c = PDE.DateEcheance__c;
                tempRec.Adresse_de_consommation__c = PDE.Adresse_de_consommation__c;
                tempRec.Consommation_Annuelle_de_R_f_rence_Elec__c = PDE.Consommation_Annuelle_de_R_f_rence_Elec__c;
                tempRecs.push(tempRec);
            })  
            if(tempRecs.length > 10) {
                tempRecs.pop();
                this.numberOfelement = '10+';
                this.showViewAll = true;
            } else {
                this.numberOfelement = tempRecs.length.toString();
            }
            this.relatedPDE = tempRecs;
        })
        .catch((error) => {
          this.errorMsg = error;
          console.log("Erreur de chargement " + JSON.stringify(this.errorMsg));
        });
    }

    downloadCSVGaz(){
        window.open("https://alliancedesenergies.my.site.com/partenaire/resource/Templates/Template_Import/Template_IMPORT_PDE_GAZ.xlsx", "_blank");
        
    }
}