import { LightningElement, api, track } from "lwc";
import retrievePDE from "@salesforce/apex/ShowPDECoproController.retrievePDE";
import deletePDERowAction from "@salesforce/apex/ShowPDECoproController.deletePDERowAction";
import isCommunity from "@salesforce/apex/Utils.isCommunity";
import { ShowToastEvent } from "lightning/platformShowToastEvent"; // Allow toast to be used

export default class Lwc008_ShowPDECopro extends LightningElement {
  @api recordId;
  listPDE = [];
  listPDEId = [];
  isCommunity = false;
  @track sortBy;
  @track sortDirection;
  @track columns = [
    {label: "Nom du site",fieldName: "PDEUrl",type: "url",typeAttributes: { label: { fieldName: "name" } },sortable: "true"},
    {label: "Contrat actif",fieldName: "Contrat_actif__c", type:"boolean", sortable: "true"},
    {label: "Siret payeur", fieldName: "siretPayeur", sortable: "true"},
    {label: "Numéro PDE",fieldName: "numeroPDE", sortable: "true"},
    {label: "Type PDE", fieldName: "typePDE", sortable: "true"},
    {label: "CAR", fieldName: "car", sortable: "true"},
    {label: "Date d'échéance",fieldName: "dateEcheance", type:"date",sortable: "true"}
  ];
  setSelectedRows = [];

  getSelectedIdAction(event) {
    console.log('EVENT SELECTEDROWS ',event.detail.selectedRows);
    const selectedPDE = event.detail.selectedRows;
    this.listPDEId = [];
    selectedPDE.forEach((pde) => {
      let id = pde.id;
      this.listPDEId.push(id);
    });
  }

  connectedCallback() {
    isCommunity().then( response => {
      this.isCommunity = response
      this.getPdes();
    })
    this.getPdes();
  }

  @api getPdes() {
    retrievePDE({ recordId: this.recordId })
      .then((data) => {
        let tempRecs = [];
        data.forEach((pde) => {
          let tempRec = {};
          tempRec.id = pde.Id;
          tempRec.name = pde.Name;
          tempRec.PDEUrl = this.isCommunity ? "/partenaire/s/pde/" + pde.Id :  "/" + pde.Id;
          tempRec.coproURL = this.isCommunity ? "/partenaire/s/account/" +  pde.EntiteJuridique__c : "/" +  pde.EntiteJuridique__c ;
          tempRec.coproName = pde.EntiteJuridique__r.Name;
          tempRec.siretPayeur = pde.Siret_payeur__c;
          tempRec.Contrat_actif__c = pde.Contrat_actif__c;
          tempRec.numeroPDE = pde.TECH_num_compteur__c;
          tempRec.typePDE = pde.TypePDE__c;
          tempRec.dateEcheance = pde.DateEcheance__c;
          tempRec.car = pde.TypePDE__c === 'Gaz' ? pde.CARGaz__c : pde.Consommation_Annuelle_de_R_f_rence_Elec__c;
          tempRecs.push(tempRec);
        });
        this.listPDE = tempRecs;
      })
      .catch((error) => {
        this.errorMsg = error;
        console.log("Erreur de chargement " + JSON.stringify(this.errorMsg));
      });
  }

  deletePDERowAction() {
    deletePDERowAction({ listPDEId: this.listPDEId })
      .then((succes) => {
        if (succes) {
          this.selectedPDE = [];
          this.toastMessage("success", "Succès", "Les PDE ont été supprimés.");
          this.setSelectedRows = [];
          this.getPdes();
        } else {
          this.toastMessage(
            "warning",
            "Attention",
            "Pas d'élements à supprimer"
          );
        }
      })
      .catch((error) => {
        this.errorMsg = error;
        this.toastMessage(
          "error",
          "Erreur",
          "Les PDE n'ont pas été supprimés. \n " + this.errorMsg
        );
      });
  }

  handleSortPDE(event) {
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortAccountData(event.detail.fieldName, event.detail.sortDirection);
  }

  sortAccountData(fieldname, direction) {
    let parseData = JSON.parse(JSON.stringify(this.listPDE));

    let keyValue = (a) => {
      return a[fieldname];
    };

    let isReverse = direction === "asc" ? 1 : -1;

    parseData.sort((x, y) => {
      x = keyValue(x) ? keyValue(x) : "";
      y = keyValue(y) ? keyValue(y) : "";

      return isReverse * ((x > y) - (y > x));
    });

    this.listPDE = parseData;
  }
  toastMessage(type, label, errorMessage) {
    const event = new ShowToastEvent({
      title: label,
      errorMessage,
      message: errorMessage,
      variant: type,
      duration: 5000,
      mode: "pester"
    });
    this.dispatchEvent(event);
  }
}