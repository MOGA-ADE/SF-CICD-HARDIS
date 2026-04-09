import { LightningElement, api } from "lwc";

export default class Lwc011_ShowCoproParent extends LightningElement {
  @api recordId;

  refreshListCopro() {
    this.template.querySelector("c-lwc010_-show-copro").retrieveCopros();
    this.template.querySelector("c-lwc006_-chargement-en-masse-copro").retrieveCopros();
  }
}