import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import getAccountFiles from "@salesforce/apex/AP032_EngieAPIPriceController.getAccountFiles";
import processPriceRequest from "@salesforce/apex/AP032_EngieAPIPriceController.processPriceRequest";
import LOGOS from "@salesforce/resourceUrl/Logos";

const FILE_COLUMNS = [
  { label: "Nom du fichier", fieldName: "Title", type: "text" },
  { label: "Taille", fieldName: "Size", type: "text" },
  { label: "Dernière modification", fieldName: "LastModifiedDate", type: "date", 
    typeAttributes: {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit"
    }
  },
  { label: "Propriétaire", fieldName: "OwnerName", type: "text" }
];

export default class Lwc028_EngiePrice extends LightningElement {
  @api recordId;
  isLoading = false;
  files = [];
  error;
  margin = "";
  validityDuration = 2;
  isGreenEnergy = false;
  selectedFileId = null;
  fileColumns = FILE_COLUMNS;
  logoUrl = `${LOGOS}/engie.png`;

  validityDurationOptions = [
    { label: "1 jour", value: 1 },
    { label: "2 jours", value: 2 },
    { label: "3 jours", value: 3 }
  ];

  get isPriceRequestDisabled() {
    // The button is disabled if the margin is empty or contains only whitespace,
    // or if no file has been selected (selectedFileId is null).
    return !this.margin || !this.margin.trim() || !this.selectedFileId;
  }

  @wire(getAccountFiles, { quoteId: "$recordId" })
  wiredFiles({ error, data }) {
    this.isLoading = true;
    if (data) {
      // Formatte les données pour la datatable
      this.files = data.map((file) => ({
        ContentDocumentId: file.ContentDocumentId,
        Title: `${file.ContentDocument.Title}.${file.ContentDocument.FileExtension}`,
        Size: this.formatFileSize(file.ContentDocument.ContentSize),
        LastModifiedDate: file.ContentDocument.LastModifiedDate,
        OwnerName: file.ContentDocument.Owner.Name
      }));
      this.error = undefined;
      this.isLoading = false;
    } else if (error) {
      this.error = error;
      this.files = [];
      this.isLoading = false;
      this.showToast("Erreur", "Impossible de charger les fichiers.", "error");
    }
  }

  // Gère les changements sur les champs de saisie
  handleInputChange(event) {
    const { name, value, checked } = event.target;

    if (name === "margin") {
      this.margin = value;
    } else if (name === "validityDuration") {
      this.validityDuration = parseInt(value, 10);
    } else if (name === "isGreenEnergy") {
      this.isGreenEnergy = checked;
    }
  }

  // Gère la sélection d'un fichier dans la table
  handleRowSelection(event) {
    const selectedRows = event.detail.selectedRows;
    this.selectedFileId =
      selectedRows.length > 0 ? selectedRows[0].ContentDocumentId : null;
  }

  // Gère le clic sur le bouton "Demande de prix"
  async handlePriceRequestClick() {
    this.isLoading = true;

    const wrapper = {
      margin: this.margin,
      validityDuration: this.validityDuration,
      isGreenEnergy: this.isGreenEnergy,
      selectedFileId: this.selectedFileId,
      quoteId: this.recordId
    };

    try {
      const resultMessage = await processPriceRequest({ data: wrapper });
      this.showToast(
        resultMessage.title,
        resultMessage.message,
        resultMessage.variant
      );
      if (resultMessage.variant === "success") {
        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        this.dispatchEvent(new CloseActionScreenEvent());
      }
    } catch (error) {
      const errorMessage = error.body
        ? error.body.message
        : "Une erreur inconnue est survenue.";
      this.showToast("Erreur", errorMessage, "error");
    } finally {
      this.isLoading = false;
    }
  }

  // Affiche une notification toast
  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  // Formate la taille du fichier en Ko, Mo, Go
  formatFileSize(bytes) {
    if (!bytes || bytes === 0) return "0 octets";
    
    const k = 1024;
    const sizes = ["octets", "Ko", "Mo", "Go"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
  }
}