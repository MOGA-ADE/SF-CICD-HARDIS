import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import processValidateOffer from "@salesforce/apex/AP032_EngieAPIPriceController.processValidateOffer";
import LOGOS from "@salesforce/resourceUrl/Logos";

export default class Lwc028_EngieValidateOffer extends LightningElement {
  @api recordId;
  isLoading = false;
  logoUrl = `${LOGOS}/engie.png`;

  async handleValidateOffer() {
    this.isLoading = true;

    try {
      const resultMessage = await processValidateOffer({
        recordId: this.recordId
      });
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
}