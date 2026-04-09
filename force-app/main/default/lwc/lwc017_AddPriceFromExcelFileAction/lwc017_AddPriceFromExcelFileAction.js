import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import retrieveQuote from "@salesforce/apex/AP009_AddPriceFromExcelFileController.retrieveQuote";
import retrieveOPR from "@salesforce/apex/AP009_AddPriceFromExcelFileController.retrieveOPR";
import retrievePriceQLI from "@salesforce/apex/AP009_AddPriceFromExcelFileController.retrievePriceQLI";
import insertListQLI from "@salesforce/apex/AP009_AddPriceFromExcelFileController.insertListQLI";
import { getRecord } from "lightning/uiRecordApi";
import NAME_FIELD from "@salesforce/schema/Opportunity.Name";
import getPriceBookEntryGaz from '@salesforce/apex/AP009_AddPriceFromExcelFileController.getPriceBookEntryGaz';
import getPriceBookEntryElec from '@salesforce/apex/AP009_AddPriceFromExcelFileController.getPriceBookEntryElec';
import getValeurCSPE from '@salesforce/apex/AP008_AddPriceFTAFournisseurController.getValeurCSPE';



import { CloseActionScreenEvent } from 'lightning/actions';

export default class Lwc017_AddPriceFromExcelFileAction extends LightningElement {
  columnHeaderGaz = ["QuoteId", "PDEId", "Reference PDE", "Tarif", "Fournisseur", "Type Offre", "Date echeance PDE", "Debut de fourniture", "Fin de fourniture",
    "Prix abonnement", "Prix molecule", "Prix CEE", "CAR"];

  columnHeaderC1C2C4 = ["QuoteId", "PDEId", "Reference PDE", "Segment", "Fournisseur", "Type Offre", "Date echeance PDE", "Debut de fourniture", "Fin de fourniture",
    "Prix abonnement", "Prix Pointes", "Prix HPH", "Prix HCH", "Prix HPE", "Prix HCE", "Prix CEE", "Capa Pointes",
    "Capa HPH", "Capa HCH", "Capa HPE", "Capa HCE", "Conso Pointes", "Conso HPH", "Conso HCH", "Conso HPE", "Conso HCE", "CSPE", "Puissance", "CAR"];

  columnHeaderC5 = ["QuoteId", "PDEId", "Reference PDE", "Segment", "Fournisseur", "Type Offre", "Date echeance PDE", "Debut de fourniture", "Fin de fourniture",
    "Prix abonnement", "Prix Base", "Prix HP", "Prix HC", "Prix CEE", "Capa Base", "Capa HP", "Capa HC", "Conso Base", "Conso HP", "Conso HC", "CSPE", "Puissance", "CAR"];

  columnHeaderC54Postes = ["QuoteId", "PDEId", "Reference PDE", "Segment", "Fournisseur", "Type Offre", "Date echeance PDE", "Debut de fourniture", "Fin de fourniture",
    "Prix abonnement", "Prix HPH", "Prix HCH", "Prix HPE", "Prix HCE", "Prix CEE", "Capa HPH", "Capa HCH", "Capa HPE", "Capa HCE", "Conso HPH", "Conso HCH", "Conso HPE", "Conso HCE", "CSPE", "Puissance", "CAR"];

  listOPR = [];
  listQuote = [];
  listQLIToInsert = [];
  listQLIToExport = [];
  showSpinner = true;
  iSCreatingQLI = false;
  priceBookEntry;
  priceBookEntryElec;
  @api recordId;
  opportunity;
  fileUploaded = false;
  disableButton = true;
  importedFile;
  CSPE_PuissanceInfOuEgal36Kva;
  CSPE_PuissanceSup36OuEgal250;
  CSPE_PuissanceSup250;
  valeurCTAT1;
  valeurCTAT2;
  valeurCTAT3;
  valeurCTAT4;
  valeurFraisTransportDistributionCapaciteT1;
  valeurFraisTransportDistributionCapaciteT2;
  valeurFraisTransportDistributionCapaciteT3;
  valeurFraisTransportDistributionCapaciteT4;


  get today() {
    const date = new Date();
    let day = date.getDate();
    let month = date.getMonth() + 1;
    let year = date.getFullYear();
    return `${day}-${month}-${year}`;
  }

  @wire(getRecord, { recordId: "$recordId", fields: [NAME_FIELD] })
  retrieveQuoteAndPDE({ data }) {
    this.showSpinner = false;
    console.log('wire is executed');
    if (data) {
      this.opportunity = data;
      retrieveOPR({ recordId: this.recordId })
        .then(pdes => {
          this.listOPR = pdes;
        })
      retrieveQuote({ recordId: this.recordId })
        .then(quotes => {
          this.listQuote = quotes;
        })
      /*
      retrievePriceQLI({recordId: this.recordId}) // Ne pas faire de wire
            .then( qlis => {
              this.listQLIToExport = qlis;
              console.log('retrievePriceQLI just after load ', JSON.stringify(this.listQLIToExport));
            })
      */
    }
  }



  @wire(getValeurCSPE)
  customMetadataValues({ error, data }) {
    if (data) {
      this.CSPE_PuissanceInfOuEgal36Kva = data.CSPE_PuissanceInfOuEgal36Kva__c;
      this.CSPE_PuissanceSup36OuEgal250 = data.CSPE_PuissanceSup36OuEgal250__c;
      this.CSPE_PuissanceSup250 = data.CSPE_PuissanceSup250__c;
      this.valeurCTAT1 = data.CTA_T1__c;
      this.valeurCTAT2 = data.CTA_T2__c;
      this.valeurCTAT3 = data.CTA_T3__c;
      this.valeurCTAT4 = data.CTA_T4__c
      this.valeurFraisTransportDistributionCapaciteT1 = data.Frais_Transport_Distribution_Capacite_T1__c;
      this.valeurFraisTransportDistributionCapaciteT2 = data.Frais_Transport_Distribution_Capacite_T2__c;
      this.valeurFraisTransportDistributionCapaciteT3 = data.Frais_Transport_Distribution_Capacite_T3__c;
      this.valeurFraisTransportDistributionCapaciteT4 = data.Frais_Transport_Distribution_Capacite_T4__c;
    } else if (error) {
      console.error('Erreur lors de la récupération des valeurs de Custom Metadata: ', error);
    }
  }

  connectedCallback() {
    console.log('lwc017_AddPriceFromExcelFile');
  }
  //Renommer cette fonction en exportTemplateSansPrix
  exportTemplateSansPrix() {
    let template = this.listOPR[0].Opportunity__r.TemplateCotation__c;
    let doc = "";
    switch (template) {
      case 'Gaz':
        this.columnHeaderGaz.forEach((element) => {
          doc += element + ";";
        });
        break;
      case 'C1/C2/C3/C4':
        this.columnHeaderC1C2C4.forEach((element) => {
          doc += element + ";";
        });
        break;
      case 'C5':
        this.columnHeaderC5.forEach((element) => {
          doc += element + ";";
        });
        break;
      case 'C5 4 postes':
        this.columnHeaderC54Postes.forEach((element) => {
          doc += element + ";";
        });
        break;
      default:
        console.log('Template inconnu');
        break;
    }


    doc.slice(0, -1);
    doc += "\n";
    // Add the data 
    this.listOPR.forEach((opr) => {
      this.listQuote.forEach((quote) => {
        doc += quote.Id + ";" + opr.PDE__c + ";" + opr.PDE__r.TECH_num_compteur__c + ";";
        switch (template) {
          case 'Gaz':
            doc += opr.PDE__r.Tarif__c + ";" + quote.Fournisseur__c + ";" + quote.TypeOffre__c + ";" + opr.PDE__r.DateEcheance__c + ";;;;;;";
            doc += opr.PDE__r.CARGaz__c + "\n";
            break;
          case 'C1/C2/C3/C4':
            doc += opr.PDE__r.Segment__c + ";" + quote.Fournisseur__c + ";" + quote.TypeOffre__c + ";" + opr.PDE__r.DateEcheance__c + ";;;;;;;;;;;;;;;";
            doc += opr.PDE__r.Conso_Pointe__c + ";";
            doc += opr.PDE__r.Conso_HPH__c + ";";
            doc += opr.PDE__r.Conso_HCH__c + ";";
            doc += opr.PDE__r.Conso_HPE__c + ";";
            doc += opr.PDE__r.Conso_HCE__c + ";";
            if (opr.PDE__r.Puissance_souscrite__c <= 36) {
              doc += this.CSPE_PuissanceInfOuEgal36Kva + ";";
            }
            else if (opr.PDE__r.Puissance_souscrite__c > 36 && opr.PDE__r.Puissance_souscrite__c <= 250) {
              doc += this.CSPE_PuissanceSup36OuEgal250 + ";";
            }
            else {
              doc += this.CSPE_PuissanceSup250 + ";";
            }
            doc += opr.PDE__r.Puissance_souscrite__c + ";";
            doc += opr.PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c + "\n";
            break;
          case 'C5':
            doc += opr.PDE__r.Segment__c + ";" + quote.Fournisseur__c + ";" + quote.TypeOffre__c + ";" + opr.PDE__r.DateEcheance__c + ";;;;;;;;;;;";
            doc += opr.PDE__r.Conso_Base__c + ";";
            doc += opr.PDE__r.ConsoHP__c + ";";
            doc += opr.PDE__r.ConsoHC__c + ";";
            if (opr.PDE__r.Puissance_souscrite__c <= 36) {
              doc += this.CSPE_PuissanceInfOuEgal36Kva + ";";
            }
            else if (opr.PDE__r.Puissance_souscrite__c > 36 && opr.PDE__r.Puissance_souscrite__c <= 250) {
              doc += this.CSPE_PuissanceSup36OuEgal250 + ";";
            }
            else {
              doc += this.CSPE_PuissanceSup250 + ";";
            }
            doc += opr.PDE__r.Puissance_souscrite__c + ";";
            doc += opr.PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c + "\n";
            break;
          case 'C5 4 postes':
            doc += opr.PDE__r.Segment__c + ";" + quote.Fournisseur__c + ";" + quote.TypeOffre__c + ";" + opr.PDE__r.DateEcheance__c + ";;;;;;;;;;;;;";
            doc += opr.PDE__r.Conso_HPH__c + ";";
            doc += opr.PDE__r.Conso_HCH__c + ";";
            doc += opr.PDE__r.Conso_HPE__c + ";";
            doc += opr.PDE__r.Conso_HCE__c + ";";
            if (opr.PDE__r.Puissance_souscrite__c <= 36) {
              doc += this.CSPE_PuissanceInfOuEgal36Kva + ";";
            }
            else if (opr.PDE__r.Puissance_souscrite__c > 36 && opr.PDE__r.Puissance_souscrite__c <= 250) {
              doc += this.CSPE_PuissanceSup36OuEgal250 + ";";
            }
            else {
              doc += this.CSPE_PuissanceSup250 + ";";
            }
            doc += opr.PDE__r.Puissance_souscrite__c + ";";
            doc += opr.PDE__r.Consommation_Annuelle_de_R_f_rence_Elec__c + "\n";
            break;
          default:
            console.log('Template inconnu');
            break;
        }
      });
    });
    doc = doc.replaceAll(undefined, '');
    doc = doc.replaceAll(',', '.');

    let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
    let downloadElement = document.createElement("a");
    downloadElement.href = element;
    downloadElement.target = "_self";

    downloadElement.download = `Export ${this.opportunity.fields.Name.value} ${this.today}.csv`;
    document.body.appendChild(downloadElement);
    downloadElement.click();
  }

  //Renommer cette fonction en exportTemplateAvecPrix
  exportTemplateAvecPrix() {
    //Calquer cette fonction sur la fonction exportPrix pour la logique des type d'opportunité
    retrievePriceQLI({ recordId: this.recordId })
      .then(qlis => {
        this.listQLIToExport = qlis;
        console.log('retrievePriceQLI after load', JSON.stringify(this.listQLIToExport));

        console.log(this.listQLIToExport);
        let template = this.listQLIToExport[0].Quote.Opportunity.TemplateCotation__c;

        let doc = "";
        switch (template) {
          case 'Gaz':
            this.columnHeaderGaz.forEach((element) => {
              doc += element + ";";
            });
            break;
          case 'C1/C2/C3/C4':
            this.columnHeaderC1C2C4.forEach((element) => {
              doc += element + ";";
            });
            break;
          case 'C5':
            this.columnHeaderC5.forEach((element) => {
              doc += element + ";";
            });
            break;
          case 'C5 4 postes':
            this.columnHeaderC54Postes.forEach((element) => {
              doc += element + ";";
            });
            break;
          default:
            console.log('Template inconnu');
            break;
        }
        doc.slice(0, -1);
        doc += "\n";

        this.listQLIToExport.forEach((qli) => {
          doc += qli.QuoteId + ";" + qli.PDE__c + ";" + qli.TECH_IdentifiantPDE__c + ";";
          switch (template) {
            case 'Gaz':
              doc += qli.TECH_Tarif__c + ";" + qli.TECH_fournisseur__c + ";" + qli.TECH_TypeOffre__c + ";" + qli.PDE__r.DateEcheance__c + ";";
              doc += qli.DebutDeFourniture__c + ";" + qli.Nouvelle_Echeance__c + ";" + qli.AbonnementMois__c + ";" + qli.PrixMolecule__c + ";" + qli.CeeMwh__c + ";"
              doc += qli.CARGaz__c + "\n";
              break;
            case 'C1/C2/C3/C4':
              doc += qli.TECH_Segment__c + ";" + qli.TECH_fournisseur__c + ";" + qli.TECH_TypeOffre__c + ";" + qli.PDE__r.DateEcheance__c + ";";
              doc += qli.DebutDeFourniture__c + ";" + qli.Nouvelle_Echeance__c + ";" + qli.AbonnementMois__c + ";" + qli.PointesMWh__c + ";";
              doc += qli.PrixHphMwh__c + ";" + qli.PrixHchMwh__c + ";" + qli.PrixHpeMwh__c + ";" + qli.PrixHceMwh__c + ";";
              doc += qli.CeeMwh__c + ";" + qli.Capa_Pointes__c + ";" + qli.Capa_HPH__c + ";" + qli.Capa_HCH__c + ";" + qli.Capa_HPE__c + ";" + qli.Capa_HCE__c + ";";
              doc += qli.Conso_Pointe__c + ";";
              doc += qli.Conso_HPH__c + ";";
              doc += qli.Conso_HCH__c + ";";
              doc += qli.Conso_HPE__c + ";";
              doc += qli.Conso_HCE__c + ";";
              if (qli.Puissance_souscrite__c <= 36) {
                doc += this.CSPE_PuissanceInfOuEgal36Kva + ";";
              }
              else if (qli.Puissance_souscrite__c > 36 && qli.Puissance_souscrite__c <= 250) {
                doc += this.CSPE_PuissanceSup36OuEgal250 + ";";
              }
              else {
                doc += this.CSPE_PuissanceSup250 + ";";
              }
              doc += qli.Puissance_souscrite__c + ";";
              doc += qli.CAR_New__c + "\n";
              break;
            case 'C5':
              doc += qli.TECH_Segment__c + ";" + qli.TECH_fournisseur__c + ";" + qli.TECH_TypeOffre__c + ";" + qli.PDE__r.DateEcheance__c + ";";
              doc += qli.DebutDeFourniture__c + ";" + qli.Nouvelle_Echeance__c + ";" + qli.AbonnementMois__c + ";" + qli.PrixBase__c + ";";
              doc += qli.PrixHP__c + ";" + qli.PrixHC__c + ";" + qli.CeeMwh__c + ";";
              doc += qli.Capa_Base__c + ";" + qli.Capa_HP__c + ";" + qli.Capa_HC__c + ";";
              doc += qli.Conso_Base__c + ";";
              doc += qli.ConsoHP__c + ";";
              doc += qli.ConsoHC__c + ";";
              if (qli.Puissance_souscrite__c <= 36) {
                doc += this.CSPE_PuissanceInfOuEgal36Kva + ";";
              }
              else if (qli.Puissance_souscrite__c > 36 && qli.Puissance_souscrite__c <= 250) {
                doc += this.CSPE_PuissanceSup36OuEgal250 + ";";
              }
              else {
                doc += this.CSPE_PuissanceSup250 + ";";
              }
              doc += qli.Puissance_souscrite__c + ";";
              doc += qli.CAR_New__c + "\n";
              break;
            case 'C5 4 postes':
              doc += qli.TECH_Segment__c + ";" + qli.TECH_fournisseur__c + ";" + qli.TECH_TypeOffre__c + ";" + qli.PDE__r.DateEcheance__c + ";";
              doc += qli.DebutDeFourniture__c + ";" + qli.Nouvelle_Echeance__c + ";" + qli.AbonnementMois__c + ";";
              doc += qli.PrixHphMwh__c + ";" + qli.PrixHchMwh__c + ";" + qli.PrixHpeMwh__c + ";" + qli.PrixHceMwh__c + ";" + qli.CeeMwh__c + ";";
              doc += qli.Capa_HPH__c + ";" + qli.Capa_HCH__c + ";" + qli.Capa_HPE__c + ";" + qli.Capa_HCE__c + ";";
              doc += qli.Conso_HPH__c + ";";
              doc += qli.Conso_HCH__c + ";";
              doc += qli.Conso_HPE__c + ";";
              doc += qli.Conso_HCE__c + ";";
              if (qli.Puissance_souscrite__c <= 36) {
                doc += this.CSPE_PuissanceInfOuEgal36Kva + ";";
              }
              else if (qli.Puissance_souscrite__c > 36 && qli.Puissance_souscrite__c <= 250) {
                doc += this.CSPE_PuissanceSup36OuEgal250 + ";";
              }
              else {
                doc += this.CSPE_PuissanceSup250 + ";";
              }
              doc += qli.Puissance_souscrite__c + ";";
              doc += qli.CAR_New__c + "\n";
              break;
            default:
              console.log('Template inconnu');
              break;
          }
        });
        console.log('ready to download');
        doc = doc.replaceAll(undefined, '');
        doc = doc.replaceAll(',', '.');
        let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
        let downloadElement = document.createElement("a");
        downloadElement.href = element;
        downloadElement.target = "_self";

        downloadElement.download = `Export ${this.listQLIToExport[0].Quote.Opportunity.Name} Prix Quotes ${this.today}.csv`;
        document.body.appendChild(downloadElement);
        downloadElement.click();

      });

  }

  handleDragOver(event) {
    event.preventDefault();
  }

  handleDrop(event) {
    event.preventDefault();
    event.stopPropagation();
    this.importedFile = event.dataTransfer.files[0];
    this.fileUploaded = true;
    this.disableButton = false;
  }

  createQLI() {
    this.showSpinner = true;
    this.iSCreatingQLI = true;
    this.readFile(this.importedFile);
  }

  getFile(event) {
    this.importedFile = event.target.files[0];
    this.fileUploaded = true;
    this.disableButton = false;
  }

  readFile(file) {
    let template = this.listOPR[0].Opportunity__r.TemplateCotation__c;
    console.log('readFile');
    if (!file || !file.name.match(/\.(csv||CSV)$/)) {
      this.showSpinner = false;
      this.fileUploaded = false;
      this.disableButton = true;
      this.iSCreatingQLI = false;
      //Utiliser un toasat comme les autres erreurs
      const evt = new ShowToastEvent({
        title: 'Format incorrect',
        message: 'Le fichier doit être au format CSV',
        variant: 'error'
      });
      this.dispatchEvent(evt);
      return;
    }

    let reader = new FileReader();
    switch (template) {
      case 'Gaz':
        reader.onload = this.parseFileGaz.bind(this, reader);
        break;
      case 'C1/C2/C3/C4':
        reader.onload = this.parseFileC1C2C4.bind(this, reader);
        break;
      case 'C5':
        reader.onload = this.parseFileC5.bind(this, reader);
        break;
      case 'C5 4 postes':
        reader.onload = this.parseFileC54Postes.bind(this, reader);
        break;
      default:
        console.log('Template inconnu');
        break;
    }
    reader.readAsText(file);
  }

  parseFileGaz(reader) {
    console.log('Parse Gaz');
    getPriceBookEntryGaz()
      .then((pbe) => {
        this.priceBookEntry = pbe;
        let content = reader.result;
        let allTextLines = content.split(/\r\n|\n|\r/);
        console.log('allTextLines ', allTextLines);
        let headers = allTextLines[0].split(';');
        let indexQuoteId = headers.indexOf('QuoteId');
        let indexPDEId = headers.indexOf('PDEId');
        let indexTypeOffre = headers.indexOf('Type Offre');
        let indexDebutDeFourniture = headers.indexOf('Debut de fourniture');
        let indexFinDeFourniture = headers.indexOf('Fin de fourniture');
        let indexPrixAbonnement = headers.indexOf('Prix abonnement');
        let indexPrixMolecule = headers.indexOf('Prix molecule');
        let indexPrixCEE = headers.indexOf('Prix CEE');
        let indexCAR = headers.indexOf('CAR');
        let indexTarif = headers.indexOf('Tarif');
        let currentLine;

        for (let i = 1; i < allTextLines.length; i++) {
          if (allTextLines[i] !== "") {
            currentLine = allTextLines[i].split(';');
            if (!currentLine[indexQuoteId]
              || !currentLine[indexPDEId]
              || !currentLine[indexTypeOffre]
              || !currentLine[indexDebutDeFourniture]
              || !currentLine[indexFinDeFourniture]
              || !currentLine[indexPrixAbonnement]
              || !currentLine[indexPrixMolecule]
              || !currentLine[indexPrixCEE]
              || !currentLine[indexCAR]
              || currentLine.length !== this.columnHeaderGaz.length
            ) {
              console.log('currentLine ', currentLine);
              const evt = new ShowToastEvent({
                title: 'Création lignes de fournisseurs',
                message: 'Opération échouée ! Il manque un champ dans votre fichier ligne : ' + i,
                variant: 'error'
              });
              this.dispatchEvent(evt);
              this.closeAction();
              return;
            }
            // eslint-disable-next-line no-else-return
            else {
              let qli = {};
              qli.sobjectType = "QuoteLineItem";
              qli.Opportunit__c = this.recordId;
              qli.QuoteId = currentLine[indexQuoteId];
              qli.PDE__c = currentLine[indexPDEId];
              qli.TypeOffre__c = currentLine[indexTypeOffre];
              let jour = parseInt(currentLine[indexDebutDeFourniture].split('/')[0], 10);
              let mois = parseInt(currentLine[indexDebutDeFourniture].split('/')[1], 10) - 1;
              let annee = parseInt(currentLine[indexDebutDeFourniture].split('/')[2], 10);
              qli.DebutDeFourniture__c = new Date(annee, mois, jour, 4);
              jour = parseInt(currentLine[indexFinDeFourniture].split('/')[0], 10);
              mois = parseInt(currentLine[indexFinDeFourniture].split('/')[1], 10) - 1;
              annee = parseInt(currentLine[indexFinDeFourniture].split('/')[2], 10);
              qli.Nouvelle_Echeance__c = new Date(annee, mois, jour, 4);
              qli.AbonnementMois__c = parseFloat(currentLine[indexPrixAbonnement]);
              qli.PrixMolecule__c = parseFloat(currentLine[indexPrixMolecule]);
              qli.CeeMwh__c = parseFloat(currentLine[indexPrixCEE]);
              qli.CARGaz__c = parseFloat(currentLine[indexCAR]);
              qli.PricebookEntryId = this.priceBookEntry.Id;
              qli.Product2Id = this.priceBookEntry.Product2Id;
              qli.Quantity = 1;
              qli.UnitPrice = 0;

              //Faire des formules pour ces trois champs
              if (currentLine[indexTarif] === 'T1') {
                qli.CTA__c = this.valeurCTAT1;
                qli.FraisTransportDistributionCapacite__c = this.valeurFraisTransportDistributionCapaciteT1;
              }
              else if (currentLine[indexTarif] === 'T2') {
                qli.CTA__c = this.valeurCTAT2;
                qli.FraisTransportDistributionCapacite__c = this.valeurFraisTransportDistributionCapaciteT2;
              }
              else if (currentLine[indexTarif] === 'T3') {
                qli.CTA__c = this.valeurCTAT3;
                qli.FraisTransportDistributionCapacite__c = this.valeurFraisTransportDistributionCapaciteT3;
              }
              else if (currentLine[indexTarif] === 'T4') {
                qli.CTA__c = this.valeurCTAT4;
                qli.FraisTransportDistributionCapacite__c = this.valeurFraisTransportDistributionCapaciteT4;
              }
              else {
                qli.CTA__c = 1;
                qli.FraisTransportDistributionCapacite__c = 1;
              }
              this.listQLIToInsert.push(qli);
            }
          }
        }
        insertListQLI({
          qlis: this.listQLIToInsert,
          oppId: this.recordId
        })
          .then((success) => {
            console.log('insertListQLI');
            this.iSCreatingQLI = false;
            let variant = 'success';
            let message = 'Opération effectuée avec succès !';

            if (!success) {
              variant = 'error';
              message = 'Opération échouée !';
            }

            const evt = new ShowToastEvent({
              title: 'Création lignes de fournisseurs',
              message: message,
              variant: variant
            });

            this.dispatchEvent(evt);
            this.closeAction();
          }).catch((e) => {
            const evt = new ShowToastEvent({
              title: 'Erreur',
              message: 'Opération échouée ! ' + e,
              variant: 'error'
            });
            this.dispatchEvent(evt);
            this.closeAction();
          });
        this.listQLIToInsert = [];
      });
  }

  parseFileC1C2C4(reader) {
    console.log('Parse C1C2C3C4');
    getPriceBookEntryElec()
      .then((pbe) => {
        this.priceBookEntryElec = pbe;
        let content = reader.result;
        let allTextLines = content.split(/\r\n|\n|\r/);
        let headers = allTextLines[0].split(';');
        let indexQuoteId = headers.indexOf('QuoteId');
        let indexPDEId = headers.indexOf('PDEId');
        let indexTypeOffre = headers.indexOf('Type Offre');
        let indexDebutDeFourniture = headers.indexOf('Debut de fourniture');
        let indexFinDeFourniture = headers.indexOf('Fin de fourniture');
        let indexAbonnement = headers.indexOf('Prix abonnement');

        let indexPrixPointes = headers.indexOf('Prix Pointes');
        let indexPrixHPH = headers.indexOf('Prix HPH');
        let indexPrixHCH = headers.indexOf('Prix HCH');
        let indexPrixHPE = headers.indexOf('Prix HPE');
        let indexPrixHCE = headers.indexOf('Prix HCE');
        let indexPrixCEE = headers.indexOf('Prix CEE');

        let indexCapapointes = headers.indexOf('Capa Pointes');
        let indexCapaHPH = headers.indexOf('Capa HPH');
        let indexCapaHCH = headers.indexOf('Capa HCH');
        let indexCapaHPE = headers.indexOf('Capa HPE');
        let indexCapaHCE = headers.indexOf('Capa HCE');

        let indexConsopointes = headers.indexOf('Conso Pointes');
        let indexConsoHPH = headers.indexOf('Conso HPH');
        let indexConsoHCH = headers.indexOf('Conso HCH');
        let indexConsoHPE = headers.indexOf('Conso HPE');
        let indexConsoHCE = headers.indexOf('Conso HCE');

        let indexCSPE = headers.indexOf('CSPE');
        let indexPuissance = headers.indexOf('Puissance');

        let currentLine;

        for (let i = 1; i < allTextLines.length; i++) {
          if (allTextLines[i] !== "") {
            currentLine = allTextLines[i].split(';');
            let qli = {};
            qli.sobjectType = "QuoteLineItem";
            qli.Opportunit__c = this.recordId;
            qli.QuoteId = currentLine[indexQuoteId];
            qli.PDE__c = currentLine[indexPDEId];
            qli.TypeOffre__c = currentLine[indexTypeOffre];
            let jour = parseInt(currentLine[indexDebutDeFourniture].split('/')[0], 10);
            let mois = parseInt(currentLine[indexDebutDeFourniture].split('/')[1], 10) - 1;
            let annee = parseInt(currentLine[indexDebutDeFourniture].split('/')[2], 10);
            qli.DebutDeFourniture__c = new Date(annee, mois, jour, 4);
            jour = parseInt(currentLine[indexFinDeFourniture].split('/')[0], 10);
            mois = parseInt(currentLine[indexFinDeFourniture].split('/')[1], 10) - 1;
            annee = parseInt(currentLine[indexFinDeFourniture].split('/')[2], 10);
            qli.Nouvelle_Echeance__c = new Date(annee, mois, jour, 4);
            qli.AbonnementMois__c = parseFloat(currentLine[indexAbonnement]);
            qli.PointesMWh__c = currentLine[indexPrixPointes] != null ? parseFloat(currentLine[indexPrixPointes]) : 0;
            qli.PrixHphMwh__c = parseFloat(currentLine[indexPrixHPH]);
            qli.PrixHchMwh__c = parseFloat(currentLine[indexPrixHCH]);
            qli.PrixHpeMwh__c = parseFloat(currentLine[indexPrixHPE]);
            qli.PrixHceMwh__c = parseFloat(currentLine[indexPrixHCE]);

            qli.Capa_Pointes__c = currentLine[indexCapapointes] != null ? parseFloat(currentLine[indexCapapointes]) : 0;
            qli.Capa_HPH__c = parseFloat(currentLine[indexCapaHPH]);
            qli.Capa_HCH__c = parseFloat(currentLine[indexCapaHCH]);
            qli.Capa_HPE__c = parseFloat(currentLine[indexCapaHPE]);
            qli.Capa_HCE__c = parseFloat(currentLine[indexCapaHCE]);

            qli.Conso_Pointe__c = parseFloat(currentLine[indexConsopointes]);
            qli.Conso_HPH__c = parseFloat(currentLine[indexConsoHPH]);
            qli.Conso_HCH__c = parseFloat(currentLine[indexConsoHCH]);
            qli.Conso_HPE__c = parseFloat(currentLine[indexConsoHPE]);
            qli.Conso_HCE__c = parseFloat(currentLine[indexConsoHCE]);
            qli.Puissance_souscrite__c = parseFloat(currentLine[indexPuissance]);
            qli.CeeMwh__c = parseFloat(currentLine[indexPrixCEE]);
            // qli.CAR_New__c = parseFloat(currentLine[indexCAR]);
            qli.CSPE__c = parseFloat(currentLine[indexCSPE]);


            qli.PricebookEntryId = this.priceBookEntryElec.Id;
            qli.Product2Id = this.priceBookEntryElec.Product2Id;
            qli.Quantity = 1;
            qli.UnitPrice = 0;
            qli.Taxes__c = true;
            this.listQLIToInsert.push(qli);
          }
        }
        insertListQLI({
          qlis: this.listQLIToInsert,
          oppId: this.recordId
        })
          .then((success) => {

            this.iSCreatingQLI = false;
            let variant = 'success';
            let message = 'Opération effectuée avec succès !';

            if (!success) {
              variant = 'error';
              message = 'Opération échouée !';
            }

            const evt = new ShowToastEvent({
              title: 'Création lignes de fournisseurs',
              message: message,
              variant: variant
            });

            this.dispatchEvent(evt);
            this.closeAction();
          }).catch((e) => {
            const evt = new ShowToastEvent({
              title: 'Erreur',
              message: 'Opération échouée ! ' + e,
              variant: 'error'
            });
            this.dispatchEvent(evt);
            this.closeAction();
          });
        this.listQLIToInsert = [];
      })
  }

  parseFileC5(reader) {
    console.log('Parse C5');
    getPriceBookEntryElec()
      .then((pbe) => {
        this.priceBookEntryElec = pbe;
        let content = reader.result;
        let allTextLines = content.split(/\r\n|\n|\r/);
        let headers = allTextLines[0].split(';');
        let indexQuoteId = headers.indexOf('QuoteId');
        let indexPDEId = headers.indexOf('PDEId');
        let indexTypeOffre = headers.indexOf('Type Offre');
        let indexDebutDeFourniture = headers.indexOf('Debut de fourniture');
        let indexFinDeFourniture = headers.indexOf('Fin de fourniture');
        let indexAbonnement = headers.indexOf('Prix abonnement');

        let indexPrixBase = headers.indexOf('Prix Base');
        let indexPrixHP = headers.indexOf('Prix HP');
        let indexPrixHC = headers.indexOf('Prix HC');
        let indexPrixCEE = headers.indexOf('Prix CEE');


        let indexCapaBase = headers.indexOf('Capa Base');
        let indexCapaHP = headers.indexOf('Capa HP');
        let indexCapaHC = headers.indexOf('Capa HC');

        let indexConsoBase = headers.indexOf('Conso Base');
        let indexConsoHP = headers.indexOf('Conso HP');
        let indexConsoHC = headers.indexOf('Conso HC');

        let indexCSPE = headers.indexOf('CSPE');
        let indexPuissance = headers.indexOf('Puissance');
        let currentLine;

        for (let i = 1; i < allTextLines.length; i++) {
          if (allTextLines[i] !== "") {
            currentLine = allTextLines[i].split(';');
            let qli = {};
            qli.sobjectType = "QuoteLineItem";
            qli.Opportunit__c = this.recordId;
            qli.QuoteId = currentLine[indexQuoteId];
            qli.PDE__c = currentLine[indexPDEId];
            qli.TypeOffre__c = currentLine[indexTypeOffre];
            let jour = parseInt(currentLine[indexDebutDeFourniture].split('/')[0], 10);
            let mois = parseInt(currentLine[indexDebutDeFourniture].split('/')[1], 10) - 1;
            let annee = parseInt(currentLine[indexDebutDeFourniture].split('/')[2], 10);
            qli.DebutDeFourniture__c = new Date(annee, mois, jour, 4);
            jour = parseInt(currentLine[indexFinDeFourniture].split('/')[0], 10);
            mois = parseInt(currentLine[indexFinDeFourniture].split('/')[1], 10) - 1;
            annee = parseInt(currentLine[indexFinDeFourniture].split('/')[2], 10);
            qli.Nouvelle_Echeance__c = new Date(annee, mois, jour, 4);

            qli.AbonnementMois__c = parseFloat(currentLine[indexAbonnement]);
            qli.PrixBase__c = parseFloat(currentLine[indexPrixBase]);
            qli.PrixHP__c = parseFloat(currentLine[indexPrixHP]);
            qli.PrixHC__c = parseFloat(currentLine[indexPrixHC]);
            qli.CeeMwh__c = parseFloat(currentLine[indexPrixCEE]);

            qli.Capa_Base__c = parseFloat(currentLine[indexCapaBase]);
            qli.Capa_HP__c = parseFloat(currentLine[indexCapaHP]);
            qli.Capa_HC__c = parseFloat(currentLine[indexCapaHC]);

            qli.Conso_Base__c = parseFloat(currentLine[indexConsoBase]);
            qli.ConsoHP__c = parseFloat(currentLine[indexConsoHP]);
            qli.ConsoHC__c = parseFloat(currentLine[indexConsoHC]);

            qli.Puissance_souscrite__c = parseFloat(currentLine[indexPuissance]);
            qli.CSPE__c = parseFloat(currentLine[indexCSPE]);


            qli.PricebookEntryId = this.priceBookEntryElec.Id;
            qli.Product2Id = this.priceBookEntryElec.Product2Id;
            qli.Quantity = 1;
            qli.UnitPrice = 0;
            qli.Taxes__c = true;
            qli.TDCFE__c = 0.0;
            qli.TCCFE__c = 0.0;
            this.listQLIToInsert.push(qli);
          }
        }
        insertListQLI({
          qlis: this.listQLIToInsert,
          oppId: this.recordId
        })
          .then((success) => {

            this.iSCreatingQLI = false;
            let variant = 'success';
            let message = 'Opération effectuée avec succès !';

            if (!success) {
              variant = 'error';
              message = 'Opération échouée !';
            }

            const evt = new ShowToastEvent({
              title: 'Création lignes de fournisseurs',
              message: message,
              variant: variant
            });

            this.dispatchEvent(evt);
            this.closeAction();
          }).catch((e) => {
            const evt = new ShowToastEvent({
              title: 'Erreur',
              message: 'Opération échouée ! ' + e,
              variant: 'error'
            });
            this.dispatchEvent(evt);
            this.closeAction();
          });
        this.listQLIToInsert = [];
      })
  }

  parseFileC54Postes(reader) {
    console.log('Parse C5 4 Postes');
    getPriceBookEntryElec()
      .then((pbe) => {
        this.priceBookEntryElec = pbe;
        let content = reader.result;
        let allTextLines = content.split(/\r\n|\n|\r/);
        let headers = allTextLines[0].split(';');
        let indexQuoteId = headers.indexOf('QuoteId');
        let indexPDEId = headers.indexOf('PDEId');
        let indexTypeOffre = headers.indexOf('Type Offre');
        let indexDebutDeFourniture = headers.indexOf('Debut de fourniture');
        let indexFinDeFourniture = headers.indexOf('Fin de fourniture');
        let indexAbonnement = headers.indexOf('Prix abonnement');

        let indexPrixHPH = headers.indexOf('Prix HPH');
        let indexPrixHCH = headers.indexOf('Prix HCH');
        let indexPrixHPE = headers.indexOf('Prix HPE');
        let indexPrixHCE = headers.indexOf('Prix HCE');
        let indexPrixCEE = headers.indexOf('Prix CEE');

        let indexCapaHPH = headers.indexOf('Capa HPH');
        let indexCapaHCH = headers.indexOf('Capa HCH');
        let indexCapaHPE = headers.indexOf('Capa HPE');
        let indexCapaHCE = headers.indexOf('Capa HCE');

        let indexConsoHPH = headers.indexOf('Conso HPH');
        let indexConsoHCH = headers.indexOf('Conso HCH');
        let indexConsoHPE = headers.indexOf('Conso HPE');
        let indexConsoHCE = headers.indexOf('Conso HCE');

        let indexCSPE = headers.indexOf('CSPE');
        let indexPuissance = headers.indexOf('Puissance');
        let currentLine;

        for (let i = 1; i < allTextLines.length; i++) {
          if (allTextLines[i] !== "") {
            currentLine = allTextLines[i].split(';');
            let qli = {};
            qli.sobjectType = "QuoteLineItem";
            qli.Opportunit__c = this.recordId;
            qli.QuoteId = currentLine[indexQuoteId];
            qli.PDE__c = currentLine[indexPDEId];
            qli.TypeOffre__c = currentLine[indexTypeOffre];
            let jour = parseInt(currentLine[indexDebutDeFourniture].split('/')[0], 10);
            let mois = parseInt(currentLine[indexDebutDeFourniture].split('/')[1], 10) - 1;
            let annee = parseInt(currentLine[indexDebutDeFourniture].split('/')[2], 10);
            qli.DebutDeFourniture__c = new Date(annee, mois, jour, 4);
            jour = parseInt(currentLine[indexFinDeFourniture].split('/')[0], 10);
            mois = parseInt(currentLine[indexFinDeFourniture].split('/')[1], 10) - 1;
            annee = parseInt(currentLine[indexFinDeFourniture].split('/')[2], 10);
            qli.Nouvelle_Echeance__c = new Date(annee, mois, jour, 4);
            qli.AbonnementMois__c = parseFloat(currentLine[indexAbonnement]);
            qli.PrixHphMwh__c = parseFloat(currentLine[indexPrixHPH]);
            qli.PrixHchMwh__c = parseFloat(currentLine[indexPrixHCH]);
            qli.PrixHpeMwh__c = parseFloat(currentLine[indexPrixHPE]);
            qli.PrixHceMwh__c = parseFloat(currentLine[indexPrixHCE]);

            qli.Capa_HPH__c = parseFloat(currentLine[indexCapaHPH]);
            qli.Capa_HCH__c = parseFloat(currentLine[indexCapaHCH]);
            qli.Capa_HPE__c = parseFloat(currentLine[indexCapaHPE]);
            qli.Capa_HCE__c = parseFloat(currentLine[indexCapaHCE]);

            qli.Conso_HPH__c = parseFloat(currentLine[indexConsoHPH]);
            qli.Conso_HCH__c = parseFloat(currentLine[indexConsoHCH]);
            qli.Conso_HPE__c = parseFloat(currentLine[indexConsoHPE]);
            qli.Conso_HCE__c = parseFloat(currentLine[indexConsoHCE]);

            qli.Puissance_souscrite__c = parseFloat(currentLine[indexPuissance]);
            qli.CSPE__c = parseFloat(currentLine[indexCSPE]);
            qli.CeeMwh__c = parseFloat(currentLine[indexPrixCEE]);

            qli.PricebookEntryId = this.priceBookEntryElec.Id;
            qli.Product2Id = this.priceBookEntryElec.Product2Id;
            qli.Quantity = 1;
            qli.UnitPrice = 0;
            qli.Taxes__c = true;
            qli.TDCFE__c = 0.0;
            qli.TCCFE__c = 0.0;
            this.listQLIToInsert.push(qli);
          }
        }
        insertListQLI({
          qlis: this.listQLIToInsert,
          oppId: this.recordId
        })
          .then((success) => {

            this.iSCreatingQLI = false;
            let variant = 'success';
            let message = 'Opération effectuée avec succès !';

            if (!success) {
              variant = 'error';
              message = 'Opération échouée !';
            }

            const evt = new ShowToastEvent({
              title: 'Création lignes de fournisseurs',
              message: message,
              variant: variant
            });

            this.dispatchEvent(evt);
            this.closeAction();
          }).catch((e) => {
            const evt = new ShowToastEvent({
              title: 'Erreur',
              message: 'Opération échouée ! ' + e,
              variant: 'error'
            });
            this.dispatchEvent(evt);
            this.closeAction();
          });
        this.listQLIToInsert = [];
      })
  }

  closeAction() {
    this.dispatchEvent(new CloseActionScreenEvent());
  }

}