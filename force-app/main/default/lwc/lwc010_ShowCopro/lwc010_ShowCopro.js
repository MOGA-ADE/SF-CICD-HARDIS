import { LightningElement, api, track, wire } from "lwc";
import retrieveCopro from "@salesforce/apex/ShowCoproController.retrieveCopro";
import deleteCoproRowAction from "@salesforce/apex/ShowCoproController.deleteCoproRowAction";
import isCommunity from "@salesforce/apex/Utils.isCommunity";
import { ShowToastEvent } from "lightning/platformShowToastEvent"; // Allow toast to be used 

export default class Lwc010_ShowCopro extends LightningElement {
  @api recordId;
  listCopro = [];
  listCoproId = [];
  isCommunity = false;
  @track sortBy;
  @track sortDirection;
  @track columns = [
    {
      label: "Nom de la copropriété",
      fieldName: "coproURL",
      type: "url",
      typeAttributes: { label: { fieldName: "coproName" } },
      sortable: "true"
    },
    {
      label: "Gestionnaire de la copropriété",
      fieldName: "gestionnaireCoproURL",
      type: "url",
      typeAttributes: {
        label: { fieldName: "gestionnaireCoproName" },
        target: "_blank"
      },
      sortable: "true"
    },
    {
      label: "Statut de la copropriété",
      fieldName: "coproStatut",
      sortable: "true"
    },
    {
      label: "Numéro de téléphone",
      fieldName: "numero",
      sortable: "true"
    }
  ];
  setSelectedRows = [];

  getSelectedIdAction(event) {
    const selectedCopro = event.detail.selectedRows;
    this.listCoproId = [];

    selectedCopro.forEach((copro) => {
      let id = copro.Id;
      this.listCoproId.push(id);
    });
  }

  connectedCallback() {
    isCommunity().then( response => {
      this.isCommunity = response
      this.retrieveCopros();
    })
    this.retrieveCopros();
  }


  @api retrieveCopros() {
    retrieveCopro({ syndicId: this.recordId })
      .then((data) => {
        let tempRecs = [];
        data.forEach((copro) => {
          console.log('copro : ' + JSON.stringify(copro));
          let tempRec = {};
          tempRec.Id = copro.Id;
          tempRec.coproURL = this.isCommunity ? "/partenaire/s/account/" + copro.Id : "/" + copro.Id ;
          tempRec.coproName = copro.Name;
          tempRec.coproStatut = copro.Statut__c;
          if (copro.AccountContactRelations != undefined) {
            tempRec.gestionnaireCoproURL = "/" + copro.AccountContactRelations[0].ContactId;
            tempRec.gestionnaireCoproName = copro.AccountContactRelations[0].ContactName__c;
            tempRec.numero = copro.AccountContactRelations[0].numero_de_telephone__c;

          }
          tempRecs.push(tempRec);
        });
        this.listCopro = tempRecs;
      })
      .catch((error) => {
        this.errorMsg = error;
        console.log("Erreur de chargement " + JSON.stringify(this.errorMsg));
      });
  }

  deleteCoproRowAction() {
      deleteCoproRowAction({ listCoproId: this.listCoproId })
        .then((succes) => {
          if (succes) {
            this.selectedCopro = [];
            this.toastMessage("success", "Succès", "Les copropriétés ont été supprimés.");
            this.setSelectedRows = [];
            this.retrieveCopros();
            this.dispatchEvent(new CustomEvent('loadcopro'));
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
            "Les copro n'ont pas été supprimés. \n " + this.errorMsg
          );
        });
  }

  handleSortCopro(event) {
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortAccountData(event.detail.fieldName, event.detail.sortDirection);
  }

  sortAccountData(fieldname, direction) {
    let parseData = JSON.parse(JSON.stringify(this.listCopro));

    let keyValue = (a) => {
      return a[fieldname];
    };

    let isReverse = direction === "asc" ? 1 : -1;

    parseData.sort((x, y) => {
      x = keyValue(x) ? keyValue(x) : "";
      y = keyValue(y) ? keyValue(y) : "";

      return isReverse * ((x > y) - (y > x));
    });

    this.listCopro = parseData;
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