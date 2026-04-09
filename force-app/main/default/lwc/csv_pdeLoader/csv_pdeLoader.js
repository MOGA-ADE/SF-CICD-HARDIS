import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent} from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue  } from 'lightning/uiRecordApi';
import { loadStyle } from 'lightning/platformResourceLoader';
import customCSS from '@salesforce/resourceUrl/toastCSS';
import NAME_FIELD from '@salesforce/schema/Account.Name';
import insertPdeGaz from '@salesforce/apex/csv_pdeLoader_Controller.insertPdeGaz';
import insertPdeElec from '@salesforce/apex/csv_pdeLoader_Controller.insertPdeElec';
import getPDEList from '@salesforce/apex/csv_pdeLoader_Controller.getPDEList';
import getPDERecodTypeIds from '@salesforce/apex/csv_pdeLoader_Controller.getPDERecodTypeIds';
import updatePDE from '@salesforce/apex/csv_pdeLoader_Controller.updatePDE';
export default class Csv_pdeLoader extends LightningElement {


    @track isCSSLoaded = false;

    renderedCallback() {

        if (this.isCSSLoaded) return;
        this.isCSSLoaded = true;
        loadStyle(this, customCSS).then(() => {
            console.log('css loaded successfully');
        }).catch(error => {
            console.log('error to load css');
        });
    }

    @api recordId;
    listData = [];
    listPDE = [];
    listPDEToUpdate = [];
    showSpinner = false;
    isShowDrag = true;
    isGaz;
    columnHeader = ["Id","SIRET PAYEUR","RAE","PCE","NOM DU SITE OU DE LA COPROPRIETE ","SITE DE CONSOMMATION",
                    "NUMERO VOIE","VOIE","CODE POSTAL","COMMUNE","FOURNISSEUR ACTUEL","SEGMENT","FTA",
                    "PUISSANCE SOUSCRITE","CONSO BASE","CONSO HP","CONSO HC","CONSO PTE","CONSO HPH",
                    "CONSO HCH","CONSO HPE","CONSO HCE","TARIF","PROFIL","CAR","DATE ECHEANCE CONTRAT","DATE SIGNATURE ACD"];
    mapRecordTypeId = {}

    get today() {
        const date = new Date();
        let day = date.getDate();
        let month = date.getMonth() + 1;
        let year = date.getFullYear();
        return `${day}-${month}-${year}`;
    }

    @wire(getRecord, {recordId: '$recordId', fields: [NAME_FIELD]})
    account;

    get accountName() {
        return getFieldValue(this.account.data, NAME_FIELD);
    }

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        event.preventDefault();
        event.stopPropagation();
        this.showSpinner = true;
        const files=event.dataTransfer.files;
        this.isGaz = JSON.stringify(event.target.id).includes('GAZ');
        this.readFile(files[0]);
    }

    handleDropUpdate(event) {
    event.preventDefault();
    event.stopPropagation();
    this.showSpinner = true;

    const files = event.dataTransfer.files;

    getPDERecodTypeIds()
        .then(result => {
            this.mapRecordTypeId = result;
            console.log('RecordTypeIds chargés :', this.mapRecordTypeId);
            this.readUpdateFile(files[0]); 
        })
        .catch(error => {
            console.error('Erreur récupération RecordTypeIds:', error);
            this.showSpinner = false;
        });
    }


    /*
    handleDropUpdate(event) {
        event.preventDefault();
        event.stopPropagation();
        this.showSpinner = true;
        getPDERecodTypeIds().then(
            result => {
                this.mapRecordTypeId = result;
                console.log(this.mapRecordTypeId);
        });
        const files=event.dataTransfer.files;
        this.readUpdateFile(files[0]);
    }
    */

    readFile(file) {
        if(!file || !file.name.match(/\.(csv||CSV)$/)){
            this.showSpinner = false;
            alert("Merci d'utiliser un fichier au format CSV.");
        }
        else{
            let reader = new FileReader();
            reader.onloadstart = this.setStartInfo(file)
            reader.onload = this.duplicateRule.bind(this, reader);
            reader.readAsText(file, 'UTF-8');
            console.log('Lignes : ',reader.result.split(/\r\n|\n|\r/));
        }       
    }

    duplicateRule(reader) {
        let allTextLines = reader.result.split(/\r\n|\n|\r/);
        allTextLines = allTextLines.filter(line => line.trim().length > 0 && !/^;+$/.test(line));
    
        // Obtenir les en-têtes et identifier les colonnes RAE/PCE
        const headers = allTextLines[0].split(';');
        const indexRAE = headers.indexOf('RAE');
        const indexPCE = headers.indexOf('PCE');
    
        // Vérification des doublons
        const uniqueValues = new Set();
        const duplicates = [];
    
        for (let i = 1; i < allTextLines.length; i++) {
            const row = allTextLines[i].split(';');
            const valueToCheck = indexRAE !== -1 ? row[indexRAE] : row[indexPCE]; // RAE ou PCE
    
            if (uniqueValues.has(valueToCheck)) {
                duplicates.push(valueToCheck);
            } else {
                uniqueValues.add(valueToCheck);
            }
        }
    
        if (duplicates.length > 0) {
            alert(`Doublons détectés dans le fichier : ${duplicates.join(', ')}. Veuillez corriger le fichier.`);
            this.showSpinner = false;
            return;
        }
    
        // Si pas de doublons, continuer le traitement
        this.showContent(reader);
    }
    
    setStartInfo(file) {
        this.fileName = file.name;
    }
    
    showContent(reader) {
        var allTextLines;
        this.content = reader.result;
        allTextLines = this.content.split(/\r\n|\n|\r/);
        allTextLines = allTextLines.filter(line => line.trim().length > 0 && !/^;+$/.test(line));
        
        for (let i = 1; i<allTextLines.length; i++) {
            if(allTextLines[i] !== ""){
                this.listData = [...this.listData, allTextLines[i]];
            }
        }
        if(this.isGaz){
            insertPdeGaz({csvHeader: allTextLines[0].replace('"',''), csvFileLines : this.listData, recordId : this.recordId,insertCopro : false}) 
            .then(() => {
                this.toastMessage('success', 'Success : ', "Les points d'énergie ont bien été enregistrés.");
                this.showSpinner = false;
            })
            .catch(error => {
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
                /*
                this.toastMessage('error', 'Error : ', error.body.message);
                this.showSpinner = false;
                */
            })
            this.listData = [];  
        }
        else{
            insertPdeElec({csvHeader: allTextLines[0].replace('"',''),csvFileLines : this.listData, recordId : this.recordId,insertCopro : false}) 
            .then(() => {
                this.toastMessage('success', 'Success : ', "Les points d'énergie ont bien été enregistrés.");
                this.showSpinner = false;
            
            })
            .catch(error => {
            this.toastMessage('error', 'Error : ', error.body.message);
            this.showSpinner = false;
        })

        this.listData = [];

        }       
    }
    
    toastMessage(type, label, errorMessage) {
        const event = new ShowToastEvent({
            title:label,errorMessage,
            message:errorMessage,
            variant:type,
            duration : 5000,
            mode:'pester'
        });
        this.dispatchEvent(event);
    }

    getAllPdes() {
        getPDEList({AccountId : this.recordId})
            .then(result => {
                this.listPDE = result;
                this.exportAllPde();
            })
    }

    exportAllPde() {
        let doc = "";
        this.columnHeader.forEach((element) => {
          doc += element + ";";
        });
        doc.slice(0, -1);
        doc += "\n";
        // Add the data rows
        this.listPDE.forEach((pde) => {
            let dateEcheanceWithFrenchFormat = '';
            let dateSignatureACDWithFrenchFormat = '';

            if(pde.DateEcheance__c){
                let jour  = pde.DateEcheance__c.split('-')[2];
                let mois  = pde.DateEcheance__c.split('-')[1];
                let annee = pde.DateEcheance__c.split('-')[0];
                dateEcheanceWithFrenchFormat = `${jour}/${mois}/${annee}`;
            }

            if(pde.Date_signature_ACD__c){
                let jour  = pde.Date_signature_ACD__c.split('-')[2];
                let mois  = pde.Date_signature_ACD__c.split('-')[1];
                let annee = pde.Date_signature_ACD__c.split('-')[0];
                dateSignatureACDWithFrenchFormat = `${jour}/${mois}/${annee}`;
            }
            doc += pde.Id + ";" + pde.Siret_payeur__c + ";" + pde.ReferencePointEnergie_Refonte__c + ";" + pde.PCE_Refonte__c + ";";
            doc += pde.Name + ";" + pde.SiteConsommation__c + ";" + pde.NumeroVoie__c + ";" + pde.voie__c + ";" + pde.Code_Postal__c + ";";
            doc += pde.Ville__c + ";" + pde.Fournisseur__c + ";" + pde.Segment__c + ";" + pde.FTA__c + ";" + pde.Puissance_souscrite__c + ";";
            doc += pde.Conso_Base__c + ";" + pde.ConsoHP__c + ";" + pde.ConsoHC__c + ";" + pde.Conso_Pointe__c + ";" + pde.Conso_HPH__c + ";";
            doc += pde.Conso_HCH__c + ";" + pde.Conso_HPE__c + ";" + pde.Conso_HCE__c + ";" + pde.Tarif__c + ";" + pde.Profil__c + ";" + pde.CARGaz__c + ";" + dateEcheanceWithFrenchFormat +";" + dateSignatureACDWithFrenchFormat + "\n";
        });

        doc = doc.replaceAll(undefined, '');
        doc = doc.replaceAll(',', '.');
        let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
        let downloadElement = document.createElement("a");
        downloadElement.href = element;
        downloadElement.target = "_self";
      
        downloadElement.download = `Export ${this.accountName} PDE ${this.today}.csv`;
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }

    readUpdateFile(file) {
        if(!file || !file.name.match(/\.(csv||CSV)$/)){
            this.showSpinner = false;
            alert("Merci d'utiliser un fichier au format CSV.");
        }
        else{
            let reader = new FileReader();
            reader.onloadstart = this.setStartInfo(file)
            reader.onload = this.updateAllPde.bind(this, reader);
            reader.readAsText(file,'UTF-8');
        }       
    }

    updateAllPde(reader){
        this.content = reader.result;
        let lines = this.content.split(/(?:\r\n|\n)+/).filter(function(el) {return el.length != 0});
        lines.shift(); // remove header line
        lines = lines.filter( line => line.search(/[A-Za-z0-9]/g) !== -1); // remove ;;;; lines
        let indexId = this.columnHeader.indexOf('Id');
        let indexSiretPayeur = this.columnHeader.indexOf('SIRET PAYEUR');
        let indexRAE = this.columnHeader.indexOf('RAE');
        let indexNomDuSite = this.columnHeader.indexOf('NOM DU SITE OU DE LA COPROPRIETE');
        let indexSiteDeConso = this.columnHeader.indexOf('SITE DE CONSOMMATION');
        let indexNumeroVoie = this.columnHeader.indexOf('NUMERO VOIE');
        let indexVoie = this.columnHeader.indexOf('VOIE');
        let indexCodePostal = this.columnHeader.indexOf('CODE POSTAL');
        let indexCommune = this.columnHeader.indexOf('COMMUNE');
        let indexFounisseurActuel = this.columnHeader.indexOf('FOURNISSEUR ACTUEL');
        let indexSegment = this.columnHeader.indexOf('SEGMENT');
        let indexFTA = this.columnHeader.indexOf('FTA');
        let indexPuissanceSouscrite = this.columnHeader.indexOf('PUISSANCE SOUSCRITE');
        let indexConsoBase = this.columnHeader.indexOf('CONSO BASE');
        let indexConsoHP = this.columnHeader.indexOf('CONSO HP');
        let indexConsoHC = this.columnHeader.indexOf('CONSO HC');
        let indexConsoPTE = this.columnHeader.indexOf('CONSO PTE');
        let indexConsoHPH = this.columnHeader.indexOf('CONSO HPH');
        let indexConsoHCH = this.columnHeader.indexOf('CONSO HCH');
        let indexConsoHPE = this.columnHeader.indexOf('CONSO HPE');
        let indexConsoHCE = this.columnHeader.indexOf('CONSO HCE');
        let indexPCE = this.columnHeader.indexOf('PCE');
        let indexTarif = this.columnHeader.indexOf('TARIF');
        let indexProfil = this.columnHeader.indexOf('PROFIL');
        let indexCar = this.columnHeader.indexOf('CAR');
        let indexDateEchanceContrat = this.columnHeader.indexOf("DATE ECHEANCE CONTRAT");
        let indexDateSignatureACD = this.columnHeader.indexOf("DATE SIGNATURE ACD");

        lines.forEach(line => {
            line = line.replaceAll('.',',');
            let splittedLine = line.split(';');
            let pde = {};
            pde.sobjectType = 'PDE__c';
            pde.Id = splittedLine[indexId];
            pde.Siret_payeur__c = splittedLine[indexSiretPayeur];
            pde.ReferencePointEnergie_Refonte__c = splittedLine[indexRAE]
            pde.PCE_Refonte__c = splittedLine[indexPCE];
            pde.Name = splittedLine[indexNomDuSite];
            pde.SiteConsommation__c = splittedLine[indexSiteDeConso];
            pde.NumeroVoie__c = splittedLine[indexNumeroVoie];
            pde.voie__c = splittedLine[indexVoie];
            pde.Code_Postal__c = splittedLine[indexCodePostal];
            pde.Ville__c = splittedLine[indexCommune];
            pde.Fournisseur__c = splittedLine[indexFounisseurActuel];
            pde.Segment__c = splittedLine[indexSegment];
            pde.FTA__c = splittedLine[indexFTA];
            pde.Puissance_souscrite__c = splittedLine[indexPuissanceSouscrite];
            pde.Conso_Base__c = splittedLine[indexConsoBase];
            pde.ConsoHP__c = splittedLine[indexConsoHP];
            pde.ConsoHC__c = splittedLine[indexConsoHC];
            pde.Conso_Pointe__c = splittedLine[indexConsoPTE];
            pde.Conso_HPH__c = splittedLine[indexConsoHPH];
            pde.Conso_HCH__c = splittedLine[indexConsoHCH];
            pde.Conso_HPE__c = splittedLine[indexConsoHPE];
            pde.Conso_HCE__c = splittedLine[indexConsoHCE];
            pde.Tarif__c = splittedLine[indexTarif];
            pde.Profil__c = splittedLine[indexProfil];
            pde.CARGaz__c = splittedLine[indexCar];
            let jour  = parseInt(splittedLine[indexDateEchanceContrat].split('/')[0], 10);
            let mois  = parseInt(splittedLine[indexDateEchanceContrat].split('/')[1], 10) - 1;
            let annee = parseInt(splittedLine[indexDateEchanceContrat].split('/')[2], 10);
            pde.DateEcheance__c = new Date(annee,mois,jour,4,0);
            jour  = parseInt(splittedLine[indexDateSignatureACD].split('/')[0], 10);
            mois  = parseInt(splittedLine[indexDateSignatureACD].split('/')[1], 10) - 1;
            annee = parseInt(splittedLine[indexDateSignatureACD].split('/')[2], 10);
            pde.Date_signature_ACD__c = new Date(annee,mois,jour,4,0);
            if(pde.Segment__c === 'C1' || pde.Segment__c === 'C2'){
                pde.RecordTypeId = this.mapRecordTypeId["Elec C1 à C2"];
            }
            else if(pde.Segment__c === 'C3' || pde.Segment__c === 'C4'){
                pde.RecordTypeId = this.mapRecordTypeId["Elec C3 à C4"];
            }
            else if (pde.Segment__c === 'C5'){
                pde.RecordTypeId = this.mapRecordTypeId["Elec C5"];
            }
            this.listPDEToUpdate.push(pde);
        });
        console.log('this.listPDEToUpdate ',this.listPDEToUpdate)
        updatePDE({pdes : this.listPDEToUpdate})
            .then( success => {
                this.showSpinner = false;
                this.iSCreatingQLI = false;
                let variant = 'success';
                let message = 'Opération effectuée avec succès !';

                if (!success) {
                    variant = 'error';
                    message = 'Opération échouée !';
                }
                
                const evt = new ShowToastEvent({
                    title: 'Mise à jour des PDE',
                    message: message,
                    variant: variant
                });

                this.dispatchEvent(evt);
            })
            .catch((e) => {
                console.log(e);
                const evt = new ShowToastEvent({
                    title: 'Mise à jour des PDEs',
                    message: e.body.pageErrors[0].message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            });
            this.listPDEToUpdate = [];
        } 
}