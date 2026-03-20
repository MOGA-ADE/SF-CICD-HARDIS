import { LightningElement,api } from 'lwc';

export default class Lwc026_CheckContratsFournisseurSecondCard extends LightningElement {
    @api searchFound
    @api checkDisabled
    @api acceptedFileType = []

    listAppelFacturationFromFile = []

    returnFirstCard(){
        const returnFirstCardEvent = new CustomEvent("returnfirstcard");
        this.dispatchEvent(returnFirstCardEvent);
    }

    handleDragOver(event) {
      event.preventDefault();
    }
  
    handleDrop(event){
      //Vérifie l'extension du fichier et envoie le contenu au parent ne fait aucun traitement
      event.preventDefault();
      event.stopPropagation();
      let file = event.dataTransfer.files[0];
      let fileType = file.name.split('.').pop();

      if (!file || !this.acceptedFileType.includes(fileType)) {
        return alert("Merci d'utiliser un fichier au format CSV.");
      }
      const eventFileDropped = new CustomEvent("filedropped",{
        detail: file
      });
      this.dispatchEvent(eventFileDropped);
    }

    checkAppelFacturationFile(){
      const eventCheckAF = new CustomEvent("checkaf");
      this.dispatchEvent(eventCheckAF);
    }
}