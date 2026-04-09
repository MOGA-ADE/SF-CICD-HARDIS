import { LightningElement,wire } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi'
import PICKLIST_FOURNISSEUR_VALUE from '@salesforce/schema/Opportunity.Liste_fournisseurs__c'
import PICKLIST_ENTITE_FACTURATION_VALUE from '@salesforce/schema/Contract.Entite_facturation__c'
import searchAppelFacturation from '@salesforce/apex/AP023_CheckContratsFournisseurController.getAppelFacturation';
import updateAppelFacturation from '@salesforce/apex/AP023_CheckContratsFournisseurController.updateAppelFacturation';

export default class Lwc026_CheckContratsFournisseurParent extends LightningElement {
    picklistFournisseurs = []
    picklistEntiteFacturation = []
    picklistFournisseursPrincipaux = []
    picklistMois = [
        {label: 'Janvier', value: '01'},
        {label: 'Février', value: '02'},
        {label: 'Mars', value: '03'},
        {label: 'Avril', value: '04'},
        {label: 'Mai', value: '05'},
        {label: 'Juin', value: '06'},
        {label: 'Juillet', value: '07'},
        {label: 'Août', value: '08'},
        {label: 'Septembre', value: '09'},
        {label: 'Octobre', value: '10'},
        {label: 'Novembre', value: '11'},
        {label: 'Décembre', value: '12'}
      ]
    picklistAnnee = [
        {label: '2024', value: '2024'},
        {label: '2025', value: '2025'},
        {label: '2026', value: '2026'},
        {label: '2027', value: '2027'},
        {label: '2028', value: '2028'}
      ]
      acceptedFileType = ['csv','CSV']
    
    showFirstCard = true
    showSecondCard = false
    showThird = false
    searchDisabled = true
    checkDisabled = true
    searchFound = true
    selectedFournisseur
    selectedMonth
    selectedMonthName
    selectedYear
    montantTotal = 0
    // showSpinner = false

    listAppelFacturation = []
    listAppelFacturationFromFile = []
    listAppelFacturationOK = []
    listAppelFacturationKO = []
    listAppelFacturationMissingFromCRM = []
    listAppelFacturationMissingFromFile = []

    fournisseurValuesPromise;
    entiteFacturationPromise;

    columnsContratsKO = [
      { label: 'Contrat', fieldName: 'contract', type: 'text', cellAttributes: { class: {fieldName: `formatContract`}}},
      { label: 'Raison Sociale', fieldName: 'raisonSociale', type: 'text'},
      { label: 'Chargé d\'affaire', fieldName: 'chargeAffaireName', type: 'text'},
      { label: 'Montant sur le CRM', fieldName: 'montantCRM', type: 'currency', cellAttributes: { class: {fieldName: `formatmontantCRM`}, currencyCode: 'EUR', alignment: 'left' } },
      { label: 'Montant sur le Fichier', fieldName: 'montantFile', type: 'currency', cellAttributes: { class: {fieldName: `formatmontantFile`}, currencyCode: 'EUR', alignment: 'left'}},
      { label: 'Différence', fieldName: 'montantDiff', type: 'currency', cellAttributes: { class: {fieldName: `format`}, currencyCode: 'EUR', alignment: 'left'}}
  ];

  columnsContratsMissing = [
    { label: 'Contrat', fieldName: 'contract', type: 'text'},
    { label: 'Montant', fieldName: 'montant', type: 'currency', cellAttributes: { currencyCode: 'EUR', alignment: 'left' }}
  ];
  
  columnsContratsMissingFromCRM = [
    { label: 'Contrat', fieldName: 'contract', type: 'text'},
    { label: 'Raison Sociale', fieldName: 'raisonSociale', type: 'text'},
    { label: 'SIRET', fieldName: 'siret', type: 'text'},
    { label: 'Montant', fieldName: 'montant', type: 'currency', cellAttributes: { currencyCode: 'EUR', alignment: 'left' }}
  ];

  columnsContratsMissingFromFile = [
    { label: 'Contrat', fieldName: 'contract', type: 'text'},
    { label: 'Raison Sociale', fieldName: 'raisonSociale', type: 'text'},
    { label: 'SIRET', fieldName: 'siret', type: 'text'},
    { label: 'Chargé d\'affaire', fieldName: 'chargeAffaireName', type: 'text'},
    { label: 'Montant', fieldName: 'montant', type: 'currency', cellAttributes: { currencyCode: 'EUR', alignment: 'left' }}
  ];


    // @wire(getPicklistValues, {
    //   recordTypeId: '012000000000000AAA',
    //   fieldApiName: PICKLIST_FOURNISSEUR_VALUE,
    // })

    // @wire(getPicklistValues, {
    //   recordTypeId: '012000000000000AAA',
    //   fieldApiName: PICKLIST_FOURNISSEUR_VALUE,
    // })

    @wire( getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: PICKLIST_FOURNISSEUR_VALUE } )
    wiredFournisseurValues( { error, data } ) {
        if ( data ) {
          this.picklistFournisseursPrincipaux = [...data.values]
            this.fournisseurValuesPromise.resolve();
        } else if ( error ) {
            console.error( 'Error in Industry picklist field', JSON.stringify( error ) );
            this.fournisseurValuesPromise.reject(error);
        }
    }

    @wire( getPicklistValues, { recordTypeId: '012000000000000AAA', fieldApiName: PICKLIST_ENTITE_FACTURATION_VALUE} )
    wiredEntiteFacturation( { error, data } ) {
        if ( data ) {
          this.picklistEntiteFacturation = [...data.values]
          this.entiteFacturationPromise.resolve();
        } else if ( error ) {
            console.error( JSON.stringify( error ) );
            this.entiteFacturationPromise.reject(error);
        }
    }

    connectedCallback() {
      this.fournisseurValuesPromise = this.createWirePromise();
      this.entiteFacturationPromise = this.createWirePromise();

      Promise.all([this.fournisseurValuesPromise.promise, this.entiteFacturationPromise.promise])
        .then(() => {
          this.isDataLoaded = true;
          const combinedList = [...this.picklistFournisseursPrincipaux,...this.picklistEntiteFacturation];
          const uniqueList = Array.from(new Set(combinedList.map(item => item.value)))
            .map(value => {
              return combinedList.find(item => item.value === value);
            });
          this.picklistFournisseurs = uniqueList.sort((a, b) => a.label.localeCompare(b.label));
        }).catch(error => {
            console.error('Error loading wire methods:', error);
        });
    }

    createWirePromise() {
      let resolve, reject;
      const promise = new Promise((res, rej) => {
          resolve = res;
          reject = rej;
      });
      return { promise, resolve, reject };
    }

    handleParamSearchAppelFacturation(event){
      switch (event.detail.field) {  
        case 'Fournisseur':
          this.selectedFournisseur = event.detail.value;
          break;
        case 'Mois':
          this.selectedMonth = event.detail.value;
          this.selectedMonthName = this.picklistMois.find(option => option.value === this.selectedMonth).label        
          break;
        case 'Année':
          this.selectedYear = event.detail.value;
          break;
          default:
            break;
      }
      if(this.selectedFournisseur && this.selectedMonth && this.selectedYear){
        this.searchDisabled = false
      }
    }

searchAppelFacturation() {
  searchAppelFacturation({ fournisseur: this.selectedFournisseur, mois: this.selectedMonth,annee: this.selectedYear })
    .then((AppelFacturations) => {
      if(AppelFacturations.length === 0){
        this.montantTotal = 0
        this.searchFound = false
      }
      else{
        this.montantTotal = 0;
        let montantPerContract = {};
        
        for(const AF of AppelFacturations){
          const contratName = AF.Contrat__r?.Name;
          const montant = parseFloat(AF.Montant__c) || 0;
          const raisonSociale = AF.Contrat__r?.Account?.Name;
          const chargeAffaireName = AF.Contrat__r?.Charge_affaire__r?.Name;
          const siret = AF.Contrat__r?.Siret_payeur__c;

          if (contratName in montantPerContract) {
            // Si le contrat existe déjà, on additionne les montants
            montantPerContract[contratName].montant += montant;
          } else {
            // Sinon, on crée une nouvelle entrée
            montantPerContract[contratName] = {
              contract: contratName,
              montant: montant,
              raisonSociale: raisonSociale,
              chargeAffaireName: chargeAffaireName,
              siret: siret
            };
          }

          // Total général
          this.montantTotal += montant;
        }

        // Conversion de l’objet en tableau
        this.listAppelFacturation = Object.keys(montantPerContract).map((key) => ({
          contract: key,
          montant: parseFloat(montantPerContract[key].montant.toFixed(2)),
          raisonSociale: montantPerContract[key].raisonSociale,
          chargeAffaireName: montantPerContract[key].chargeAffaireName,
          siret: montantPerContract[key].siret
        }));

        this.numberOfContrats = this.listAppelFacturation.length;
        this.searchFound = true;

        // Gestion du Path
        let firstPath = this.template.querySelector(`[data-id="path-1"]`);
        let secondPath = this.template.querySelector(`[data-id="path-2"]`);
        firstPath.classList.remove('slds-is-current', 'slds-is-active');
        firstPath.classList.add('slds-is-complete');
        secondPath.classList.add('slds-is-current', 'slds-is-active');

        this.showSecondCard = true;
        this.showFirstCard = false;
      }
    })
    .catch((error) => {
      console.log("Erreur de chargement " + JSON.stringify(error));
    });
}

  
    setStartInfo(file) {
      this.fileName = file.name;
    }

    handleFileDropped(event){
      let file = event.detail
      let reader = new FileReader();
      reader.onloadstart = this.setStartInfo(file);
      reader.onload = this.showContent.bind(this, reader);
      reader.readAsText(file);
    }

    showContent(reader) {
      let currentLine;
      let allTextLines;
      this.content = reader.result;
      this.content = this.content.replaceAll(',','.')
      allTextLines = this.content.split(/\r\n|\n|\r/);
      let montantPerContract = {}
    
      for (let i = 1; i < allTextLines.length; i++) {
        if (allTextLines[i] !== "") {
          currentLine = allTextLines[i].split(';');
          let contractName = currentLine[0];
          let montant = parseFloat(currentLine[1]);
          let raisonSociale = currentLine[2];
          let siret = currentLine[3];

          if (contractName in montantPerContract) {
            montantPerContract[contractName].montant += montant

          } else {
            montantPerContract[contractName] = {
              contract : contractName,
              siret : siret,
              raisonSociale: raisonSociale,
              montant : montant
            }
          }
        }
      }
      this.listAppelFacturationFromFile = Object.keys(montantPerContract).map((key) => ({
        contract:key,
        montant:parseFloat(montantPerContract[key].montant.toFixed(2)),
        siret : montantPerContract[key].siret ,
        raisonSociale: montantPerContract[key].raisonSociale
      }));
      this.checkDisabled = false
    }   

    checkAppelFacturationFile(){
      let montantDiff = 0;
      for(let AF of this.listAppelFacturation){
        if(this.listAppelFacturationFromFile.find(x => x.contract === AF.contract) !== undefined ){ 
          if(this.listAppelFacturationFromFile.find(x => x.contract === AF.contract).montant === AF.montant){
            this.listAppelFacturationOK.push({contract: AF.contract, montant: AF.montant})
          }else{
            montantDiff = parseFloat((this.listAppelFacturationFromFile.find(x => x.contract === AF.contract).montant - AF.montant).toFixed(2))
            if(Math.abs(montantDiff)>0.5){
              this.listAppelFacturationKO.push({
                contract: AF.contract,
                montantCRM: AF.montant,
                raisonSociale: AF.raisonSociale,
                chargeAffaireName: AF.chargeAffaireName,
                montantFile: this.listAppelFacturationFromFile.find(x => x.contract === AF.contract).montant,
                format:  montantDiff > 0 ? 'slds-text-color_success slds-text-title_bold' : 'slds-text-color_error slds-text-title_bold',
                montantDiff: montantDiff
              })
            }
          }
        }
        else{
          // this.listAppelFacturationMissingFromFile.push({contract: AF.contract, montant: AF.montant});
          this.listAppelFacturationMissingFromFile.push({
            contract: AF.contract,
            raisonSociale: AF.raisonSociale,
            siret:AF.siret,
            chargeAffaireName: AF.chargeAffaireName,
            montant: AF.montant
          });
        }
      }

      for(let AF of this.listAppelFacturationFromFile){
        if(this.listAppelFacturation.find(x => x.contract === AF.contract) === undefined){
          // this.listAppelFacturationMissingFromCRM.push({contract: AF.contract, montant: AF.montant})
          this.listAppelFacturationMissingFromCRM.push({
            contract: AF.contract,
            raisonSociale: AF.raisonSociale,
            siret:AF.siret,
            montant: AF.montant
          })
        }
      }

      let secondPath = this.template.querySelector(`[data-id="path-2"]`);
      let thirdPath = this.template.querySelector(`[data-id="path-3"]`);
      secondPath.classList.remove('slds-is-current', 'slds-is-active');
      secondPath.classList.add('slds-is-complete');
      thirdPath.classList.add('slds-is-current', 'slds-is-active');
      this.showThirdCard = true
      this.showSecondCard = false

    }

    returnFirstCard(){
      
      this.listAppelFacturation = []
      this.listAppelFacturationFromFile = []
      this.listAppelFacturationOK = []
      this.listAppelFacturationKO = []
      this.listAppelFacturationMissingFromCRM = []
      this.listAppelFacturationMissingFromFile = []
      this.montantTotal = 0
      
      let firstPath = this.template.querySelector(`[data-id="path-1"]`)
      let secondPath = this.template.querySelector(`[data-id="path-2"]`)
      let thirdPath = this.template.querySelector(`[data-id="path-3"]`)
      
      firstPath.classList.add('slds-is-current', 'slds-is-active')
      firstPath.classList.remove('slds-is-complete')
      secondPath.classList.remove('slds-is-current', 'slds-is-active')
      secondPath.classList.remove('slds-is-complete')
      thirdPath.classList.remove('slds-is-current', 'slds-is-active')
      thirdPath.classList.remove('slds-is-complete')
      
      this.selectedFournisseur = null
      this.selectedMonth = null
      this.selectedMonthName = null
      this.selectedYear = null
      this.montantTotal = null
      this.searchDisabled = true
      this.checkDisabled = true
      this.searchFound = true

      
      this.showFirstCard = true
      this.showThirdCard = false
      this.showSecondCard = false
    }

    downloadContrats(event){
      switch(event.detail.contratsType){
        case 'ContratsKO' :
          this.downloadContratsKO()
          break;
        case 'ContratsMissingFromCRM' :
          this.downloadContratsContratsMissingFromCRM()
          break;
        case 'ContratsMissingFromFile' :
          this.downloadContratsContratsMissingFromFile()
          break;
        default:
          console.log('Tableau inconnu')
      }
    }

    downloadContratsKO(){
      let doc = "";
      this.columnsContratsKO.forEach((element) => {
        doc += element.label + ";";
      });
      // Remove last ','
      doc.slice(0, -1);
      doc += "\n";
      // Add the data rows
      this.listAppelFacturationKO.forEach((record) => {
        doc += record.contract + ";" + record.raisonSociale + ";" + record.chargeAffaireName + ";" + record.montantCRM + ";" + record.montantFile + ";" + record.montantDiff + "\n"
      });
      let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
      let downloadElement = document.createElement("a");
      downloadElement.href = element;
      downloadElement.target = "_self";

      downloadElement.download = `Export Contrats KO ${this.selectedFournisseur} ${this.selectedMonth} ${this.selectedYear}.csv`;
      document.body.appendChild(downloadElement);
      downloadElement.click();
    }

    downloadContratsContratsMissingFromCRM(){
      let doc = "";
      this.columnsContratsMissingFromCRM.forEach((element) => {
        doc += element.label + ";";
      });
      // Remove last ','
      doc.slice(0, -1);
      doc += "\n";
      // Add the data rows
      this.listAppelFacturationMissingFromCRM.forEach((record) => {
        doc += record.contract + ";" + record.raisonSociale + ";" + record.siret + ";" + record.montant + "\n"
      });
      let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
      let downloadElement = document.createElement("a");
      downloadElement.href = element;
      downloadElement.target = "_self";

      downloadElement.download = `Export Contrats Manquant dans le CRM ${this.selectedFournisseur} ${this.selectedMonth} ${this.selectedYear}.csv`;
      document.body.appendChild(downloadElement);
      downloadElement.click();
    }

    downloadContratsContratsMissingFromFile(){
      let doc = "";
      this.columnsContratsMissingFromFile.forEach((element) => {
        doc += element.label + ";";
      });
      // Remove last ','
      doc.slice(0, -1);
      doc += "\n";
      // Add the data rows
      this.listAppelFacturationMissingFromFile.forEach((record) => {
        doc += record.contract + ";" + record.raisonSociale + ";" + record.siret + ";" + record.chargeAffaireName + ";" + record.montant + "\n"
      });
      let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
      let downloadElement = document.createElement("a");
      downloadElement.href = element;
      downloadElement.target = "_self";

      downloadElement.download = `Export Contrats Manquant dans le fichier ${this.selectedFournisseur} ${this.selectedMonth} ${this.selectedYear}.csv`;
      document.body.appendChild(downloadElement);
      downloadElement.click();
    }

    downloadTemplate(){
      let doc = "Numero de contrat;Montant;Raison sociale;SIRET\n";
      let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
      let downloadElement = document.createElement("a");
      downloadElement.href = element;
      downloadElement.target = "_self";

      downloadElement.download = `TemplateContratCRM.csv`;
      document.body.appendChild(downloadElement);
      downloadElement.click();
    }

    validAF() {
      updateAppelFacturation({ fournisseur: this.selectedFournisseur, mois: this.selectedMonth,annee: this.selectedYear })
        .then((data) => {
          const childComponent = this.template.querySelector('c-lwc026_-check-contrats-fournisseur-third-card');          if(data){
            if(data){
              childComponent.displayToast(
                'Succès',
                'Les appels à facturation ont bien été mis à jour',
                'success',
                'sticky'
              );
            }
            else{
              childComponent.displayToast(
                'Erreur',
                'Les appels à facturation n\'ont bien été mis à jour',
                'error',
                'sticky'
              );
            }
        }})
        .catch((error) => {
          console.log("Erreur de chargement " + JSON.stringify(error));
        });
    }

    get getShowFirstCard(){
      return this.showFirstCard;
    }
    get getShowSecondCard(){
      return this.showSecondCard;
    }
    get getShowThirdCard(){
      return this.showThirdCard;
    }

    get getShowTableContratsKO(){
      return this.listAppelFacturationKO.length !== 0
    }

    get getShowTableContratsMissingFromCRM(){
      return this.listAppelFacturationMissingFromCRM.length !== 0
    }

    get getShowTableContratsMissingFromFile(){
      return this.listAppelFacturationMissingFromFile.length !== 0
    }

    get getShowSuccessValidation(){
      return  (this.listAppelFacturationKO.length === 0 && 
              this.listAppelFacturationMissingFromCRM.length === 0 &&
              this.listAppelFacturationMissingFromFile.length === 0)
    }
}