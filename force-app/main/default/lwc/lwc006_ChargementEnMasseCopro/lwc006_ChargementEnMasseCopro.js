import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent"; // Allow toast to be used
import insertCopro from "@salesforce/apex/ChargementEnMasseCoproController.insertCopro";
import retrieveCopros from "@salesforce/apex/ChargementEnMasseCoproController.retrieveCopros";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Account.Name";

export default class lwc006_ChargementEnMasseCopro extends LightningElement {
  @api recordId;
  listData = [];
  listCopro = [];
  columnHeader = ["ID", "NAME"];
  showSpinner = false;
  fileData;

  connectedCallback() {
    this.retrieveCopros();
  }

  @api retrieveCopros() {
    retrieveCopros({ recordId: this.recordId })
      .then((data) => {
        this.listCopro = data;
      })
      .catch((error) => {
        this.errorMsg = error;
        console.log("Erreur de chargement " + JSON.stringify(this.errorMsg));
      });
  }

  @wire(getRecord, { recordId: "$recordId", fields: [NAME_FIELD] })
  copro;

  get today() {
    const date = new Date();
    let day = date.getDate();
    let month = date.getMonth() + 1;
    let year = date.getFullYear();
    return `${day}-${month}-${year}`;
  }

  get name() {
    return getFieldValue(this.copro.data, NAME_FIELD);
  }

  /////////// Action part ///////////
  handleDragOver(event) {
    event.preventDefault();
  }

  handleDrop(event) {
    this.showSpinner = true;
    event.preventDefault();
    event.stopPropagation();
    const files = event.dataTransfer.files;
    this.readFile(files[0]);
  }

  readFile(file) {
    if (!file || !file.name.match(/\.(csv||CSV)$/)) {
      this.showSpinner = false;
      return alert("Merci d'utiliser un fichier au format CSV.");
    }

    let reader = new FileReader();
    reader.onloadstart = this.setStartInfo(file);
    reader.onload = this.showContent.bind(this, reader);
    reader.onloadend = this.showPanelInfo();
    reader.readAsText(file);
  }

  setStartInfo(file) {
    this.fileName = file.name;
  }

  showPanelInfo() {
    this.showSpinner = false;
  }

  showContent(reader) {
    var allTextLines;
    this.content = reader.result;
    allTextLines = this.content.split(/\r\n|\n|\r/);

    for (let i = 1; i < allTextLines.length; i++) {
      if (allTextLines[i] !== "") {
        this.listData = [...this.listData, allTextLines[i]];
      }
    }
    insertCopro({
      csvHeader: allTextLines[0].replace('"', ""),
      csvFileLines: this.listData,
      recordId: this.recordId
    })
      .then((result) => {
        this.toastMessage(
          "success",
          "Success : ",
          "Les copropriétés ont bien été enregistrés."
        );
        this.retrieveCopros();
        this.showSpinner = false;
        this.dispatchEvent(new CustomEvent("loadcopro"));
      })
      .catch((error) => {
        this.toastMessage("error", "Error : ", error.body.message);
        this.showSpinner = false;
      });
    this.listData = [];
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

  exportCopros() {
    let doc = "";
    this.columnHeader.forEach((element) => {
      doc += element + ";";
    });
    // Remove last ','
    doc.slice(0, -1);
    doc += "\n";
    // Add the data rows
    this.listCopro.forEach((record) => {
      doc += record.Id + ";" + record.Name + "\n";
    });
    let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
    let downloadElement = document.createElement("a");
    downloadElement.href = element;
    downloadElement.target = "_self";

    downloadElement.download = `Export ${this.name} ${this.today}.csv`;
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }
}