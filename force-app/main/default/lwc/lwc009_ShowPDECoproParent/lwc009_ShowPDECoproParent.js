import { LightningElement, api } from "lwc";

export default class Lwc009_ShowPDECoproParent extends LightningElement {
  @api recordId;

  refreshListPDE() {
    this.template.querySelector("c-lwc008_-show-p-d-e-copro").getPdes();
  }
}