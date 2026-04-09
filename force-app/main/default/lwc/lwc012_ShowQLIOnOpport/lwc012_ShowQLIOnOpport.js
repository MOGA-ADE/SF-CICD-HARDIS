import { LightningElement, api, track } from "lwc";
import retrieveQLI from "@salesforce/apex/ShowQLIOnOpportController.retrieveQLI";

export default class Lwc012_ShowQLIOnOpport extends LightningElement {
  @api recordId;
  listQLI = [];
  @track sortBy;
  @track sortDirection;
  @track columnsElec = [
    {
      label: "Durée de l'offre",
      fieldName: "QLIUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "QuoteNumber" },
        target: "_blank"
      },
      sortable: "true"
    },
    {
      label: "Fournisseur",
      fieldName: "fournisseur",
      sortable: "true"
    },
    {
      label: "Référence PDE",
      fieldName: "PDE",
      sortable: "true"
    },
    {
      label: "Type d'offre",
      fieldName: "type_offre",
      sortable: "true"
    },
    {
      label: "Rémunération",
      fieldName: "UnitPrice",
      sortable: "true",
      type: "currency"
    },
    {
      label: "Devis",
      fieldName: "QuoteURL",
      type: "url",
      typeAttributes: {
        label: { fieldName: "QuoteName" },
        target: "_blank"
      },
      sortable: "true"
    }
  ];
  @track columnsGaz = [
    {
      label: "Durée de l'offre",
      fieldName: "QLIUrl",
      type: "url",
      typeAttributes: {
        label: { fieldName: "QuoteNumber" },
        target: "_blank"
      },
      sortable: "true"
    },
    {
      label: "Fournisseur",
      fieldName: "fournisseur",
      sortable: "true"
    },
    {
      label: "PCE",
      fieldName: "PCE",
      sortable: "true"
    },
    {
      label: "Type d'offre",
      fieldName: "type_offre",
      sortable: "true"
    },
    {
      label: "Rémunération",
      fieldName: "UnitPrice",
      sortable: "true",
      type: "currency"
    },
    {
      label: "Devis",
      fieldName: "QuoteURL",
      type: "url",
      typeAttributes: {
        label: { fieldName: "QuoteName" },
        target: "_blank"
      },
      sortable: "true"
    }
  ];
  @track isGaz;
  @track isEmpty = false;

  connectedCallback() {
    this.retrieveQLIs();
  }

  @api retrieveQLIs() {
    retrieveQLI({ recordId: this.recordId })
      .then((data) => {
        let tempRecs = [];
        data.forEach((qli) => {
          this.isEmpty = true;
          let anneDebut = new Date(qli.DebutDeFourniture__c).getFullYear() || "";
          let anneFin = new Date(qli.NouvelleEcheance__c).getFullYear() || "";
          let tempRec = {};
          this.isGaz = qli.TECH_RT__c === "PDE_Gaz";
          tempRec.QLIUrl = "/" + qli.Id;
          tempRec.QuoteNumber = anneDebut + " / " + anneFin;
          tempRec.fournisseur = qli.TECH_fournisseur__c;
          tempRec.PCE = qli.PDE__r?.PCE_Refonte__c;
          tempRec.PDE = qli.PDE__r?.ReferencePointEnergie_Refonte__c;
          tempRec.type_offre = qli.TECH_TypeOffre__c;
          tempRec.QuoteURL = "/" + qli.QuoteId;
          tempRec.QuoteName = qli.Quote.Name;
          tempRec.datedebut = qli.DebutDeFourniture__c;
          tempRec.datefin = qli.NouvelleEcheance__c;
          tempRec.UnitPrice = qli.UnitPrice;
          tempRecs.push(tempRec);
        });
        this.listQLI = tempRecs;
      })
      .catch((error) => {
        this.errorMsg = error;
        console.log("Erreur de chargement " + JSON.stringify(this.errorMsg));
      });
  }

  handleSortQLI(event) {
    console.log("handleSortQLI");
    this.sortBy = event.detail.fieldName;
    this.sortDirection = event.detail.sortDirection;
    this.sortQLI(event.detail.fieldName, event.detail.sortDirection);
  }

  sortQLI(fieldname, direction) {
    let parseData = JSON.parse(JSON.stringify(this.listQLI));
    let keyValue = (a) => {
      return a[fieldname];
    };

    let isReverse = direction === "asc" ? 1 : -1;

    parseData.sort((x, y) => {
      x = keyValue(x) ? keyValue(x) : "";
      y = keyValue(y) ? keyValue(y) : "";

      return isReverse * ((x > y) - (y > x));
    });

    this.listQLI = parseData;
  }
}