import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
//import XLSX from '@salesforce/resourceUrl/sheetjs';

import getSignataire from '@salesforce/apex/csv_pdeLoader_Controller.getSignataire';
import getPDEElecForEnergisme from '@salesforce/apex/csv_pdeLoader_Controller.getPDEElecForEnergisme';
import getPDEGazForEnergisme from '@salesforce/apex/csv_pdeLoader_Controller.getPDEGazForEnergisme';
import getPDEElecForEnergismeExcel from '@salesforce/apex/csv_pdeLoader_Controller.getPDEElecForEnergismeExcel';
import getPDEGazForEnergismeExcel from '@salesforce/apex/csv_pdeLoader_Controller.getPDEGazForEnergismeExcel';
import LastName from '@salesforce/schema/Contact.LastName';

export default class Lwc023_GenerateEnergismeJSON extends LightningElement {
    @api recordId;
    currentPageReference = null;

    @track signataires = [];
    @track signataireOptions = [];
    @track selectedSignataire = null;
    @track selectedFileType = null;
    @track fileTypeOptions = [
        { label: 'Electricité (C4/C3/C2/C1)', value: 'elec' },
        { label: 'Gaz naturel', value: 'gaz' },
        { label: 'Electricité et gaz naturel (incluant les C5)', value: 'elec_gaz' }
    ];

    @track showFileTypeSelection = false;
    @track isLoading = false;
    error = null;

    @wire(CurrentPageReference)
    getPageReferenceParameters(currentPageReference) {
        if (currentPageReference && !this.recordId) {
            this.recordId = currentPageReference.state.recordId;
        }
    }

    connectedCallback() {
        console.log('recordId ', this.recordId);
        if (this.recordId) {
            this.loadSignataires();
        } else {
            this.showNotification(
                'Error',
                'No Account ID found. Please ensure this action is triggered on an Account record.',
                'error'
            );
        }
    }
        

    loadSignataires() {
        this.isLoading = true;
        getSignataire({ accountId: this.recordId })
            .then((data) => {
                console.log('signataires : ', data);
                this.signataires = data;
                this.signataireOptions = data.map((signataire) => ({
                    label: signataire.Name,
                    value: signataire.Id,
                }));
                this.isLoading = false;
            })
            .catch((error) => {
                this.error = error.body.message;
                this.isLoading = false;
                this.showNotification('Erreur', 'Erreur lors du chargement des signataires : ' + error.body.message, 'error');
            });
    }

    handleSelection(event) {
        this.selectedSignataire = event.detail.value;
    }

    handleNext() {
        if (!this.selectedSignataire) {
            this.showNotification('Avertissement', 'Veuillez sélectionner un signataire avant de continuer.', 'warning');
            return;
        }
        this.showFileTypeSelection = true;
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
    

    handleFileTypeSelection(event) {
        this.selectedFileType = event.detail.value;
    }

    async handleConfirm() {
        if (!this.selectedFileType) {
            this.showNotification('Avertissement', 'Veuillez sélectionner un type de fichier avant de confirmer.', 'warning');
            return;
        }

        this.isLoading = true;

        try {
            if (this.selectedFileType === 'elec') {
                const elecData = await this.getPDEElecData();
                this.downloadData(elecData, 'Electricite');
                
                const elecDataExcel = await this.getPDEElecDataExcel();
                this.downloadDataCSV(elecDataExcel, 'Electricite Csv');
                
            } else if (this.selectedFileType === 'gaz') {
                const gazData = await this.getPDEGazData();
                this.downloadData(gazData, 'Gaz');

                const gazDataExcel = await this.getPDEGazDataExcel();
                console.log("gazDataExcel: ", gazDataExcel);
                this.downloadDataCSV(gazDataExcel, 'Gaz Csv');
            } else if (this.selectedFileType === 'elec_gaz') {
                const elecData = await this.getPDEElecData();
                this.downloadData(elecData, 'Electricite');

                const gazData = await this.getPDEGazData();
                this.downloadData(gazData, 'Gaz');

                const elecDataExcel = await this.getPDEElecDataExcel();
                this.downloadDataCSV(elecDataExcel, 'Electricite Csv');

                const gazDataExcel = await this.getPDEGazDataExcel();
                this.downloadDataCSV(gazDataExcel, 'Gaz Csv');
            }
            this.showNotification('Succès', 'Fichiers téléchargés avec succès.', 'success');
        } catch (error) {
            console.error('Error during file download:', error);
            this.showNotification('Erreur', 'Une erreur s\'est produite lors du téléchargement des fichiers : ' + error.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async getPDEElecData() {
        try {
            const includeC5 = this.selectedFileType === 'elec_gaz';
            const data = await getPDEElecForEnergisme({ accountId: this.recordId, includeC5: includeC5 });
            if (!data) {
                this.showNotification('Info', 'Aucune donnée pde elec trouvée.', 'info');
            }
            return data;
        } catch (error) {
            this.showNotification('Erreur', 'Une erreur s\'est produite lors du téléchargement des fichiers pde elec: ' + error.message, 'error');
            throw error;
        }
    }

    async getPDEElecDataExcel() {
        try {
            const includeC5 = this.selectedFileType === 'elec_gaz';
            // Récupérez les informations du signataire sélectionné
            const selecteddata = this.signataires.find(
                (signataire) => signataire.Id === this.selectedSignataire
            );

            if (!selecteddata) {
                throw new Error('Signataire introuvable.');
            }

            // Construisez l'objet contact
            const contact = {
                Id: selecteddata.Id,
                Name: selecteddata.Name,
                Email: selecteddata.Email,
                FirstName: selecteddata.FirstName,
                LastName: selecteddata.LastName,
                Salutation: selecteddata.Salutation
            };

            console.log('selected data : ', contact);
            // contactEmail: contact.Email, contactFN: contact.FirstName, contactLN: contact.LastName, contactS: contact.Salutation
            const data = await getPDEElecForEnergismeExcel({ accountId: this.recordId,  contactId: contact.Id, contactFN: contact.FirstName, contactLN: contact.LastName, contactS: contact.Salutation, contactEmail: contact.Email, includeC5: includeC5});
            if (!data) {
                console.log('data load : ', data);
                this.showNotification('Info', 'Aucune donnée pde elec csv trouvée.', 'info');
            }
            return data;
        } catch (error) {
            this.showNotification('Erreur', 'Une erreur s\'est produite lors du téléchargement des fichiers pde elec csv: : ' + error.message, 'error');
            throw error;
        }
    }

    async getPDEGazData() {
        try {
            const data = await getPDEGazForEnergisme({ accountId: this.recordId });
            if (!data) {
                this.showNotification('Info', 'Aucune donnée pde gaz trouvée.', 'info');
            }
            return data;
        } catch (error) {
            this.showNotification('Erreur', 'Une erreur s\'est produite lors du téléchargement des fichiers pde gaz: ' + error.message, 'error');
            throw error;
        }
    }

    async getPDEGazDataExcel() {
        try {

            // Récupérez les informations du signataire sélectionné
            const selecteddata = this.signataires.find(
                (signataire) => signataire.Id === this.selectedSignataire
            );

            if (!selecteddata) {
                throw new Error('Signataire introuvable.');
            }

            // Construisez l'objet contact
            const contact = {
                Id: selecteddata.Id,
                Name: selecteddata.Name,
                Email: selecteddata.Email
            };

            console.log('selected data : ', contact);
            const data = await getPDEGazForEnergismeExcel({ accountId: this.recordId,  contactId: contact.Id, contactName: contact.Name, contactEmail: contact.Email});
            if (!data) {
                console.log('data load : ', data);
                this.showNotification('Info', 'Aucune donnée de pde gaz csv trouvée.', 'info');
            }
            return data;
        } catch (error) {
            this.showNotification('Erreur', 'Une erreur s\'est produite lors du téléchargement des fichiers pde gaz csv: ' + error.message, 'error');
            throw error;
        }
    }


    downloadData(data, type) {
        if (data && Object.keys(data).length > 0) {
            const fileContent = "data:text/JSON;charset=utf-8," + encodeURIComponent(Object.values(data)[0]);
            const downloadElement = document.createElement("a");
            downloadElement.href = fileContent;
            downloadElement.target = "_self";
            downloadElement.download = `Export_Energisme${type}_${Object.keys(data)[0]} .json`;
            document.body.appendChild(downloadElement);
            downloadElement.click();
        } else {
            this.toastMessage("Vide", `PDE ${type} :`, `Aucun PDE ${type} associé à cet enregistrement.`);
        }
    }

    downloadDataExcel(data, type) {
        if (data && Object.keys(data).length > 0) {
            // Extraire la clé et les données JSON
            const entityName = Object.keys(data)[0];
            const jsonData = JSON.parse(Object.values(data)[0]);
    
            // Construire un tableau à partir des données JSON
            const rows = jsonData.map((item) => ({
                Partner: item.Partner || '',
                PCE: item.PCE || '',
                'Code postal': item['code postal'] || '',
                'Raison sociale': item['Raison sociale'] || '',
                'Nom du titulaire': item['Nom du titulaire'] || '',
                'Adresse E-mail du titulaire': item['Adresse E-mail du titulaire'] || '',
                'Date signature Mandat': item['Date signature Mandat'] || '',
                'Date Début Mandat': item['Date Début Mandat'] || '',
                'Date Fin Mandat': item['Date Fin Mandat'] || '',
            }));
    
            // Utilisation de SheetJS pour générer un fichier Excel
            const worksheet = XLSX.utils.json_to_sheet(rows); // Convertir en feuille Excel
            const workbook = XLSX.utils.book_new();
            XLSX.utils.book_append_sheet(workbook, worksheet, 'Data');
    
            // Générer un fichier Excel et le télécharger
            const fileName = `Export_${type}_${entityName}_PDE_Template_${type}_Energisme.xlsx`;
            XLSX.writeFile(workbook, fileName);
        } else {
            this.showNotification('Info', `Aucun PDE ${type} associé à cet enregistrement.`, 'info');
        }
    }

    downloadDataCSV(data, type) {
        if (data && Object.keys(data).length > 0) {
            const jsonData = JSON.parse(Object.values(data)[0]);
    
            if (jsonData.length === 0) {
                this.showNotification("Info", `Aucune donnée trouvée pour le type : ${type}.`, "info");
                return;
            }
    
            // Récupérer les en-têtes et formater les colonnes
            const headers = Object.keys(jsonData[0]).map(header => 
                header.replace(/_/g, ' ').replace(/(?:^|\s)\S/g, a => a.toUpperCase())
            );
    
            const csvRows = [];
            csvRows.push(headers.join(';')); // Utiliser ";" comme séparateur
    
            // Ajouter les lignes de données
            jsonData.forEach(row => {
                const csvRow = headers.map((header, index) => {
                    const key = Object.keys(row)[index];
                    const value = row[key] !== null && row[key] !== undefined ? row[key] : '';
                    return `"${value.toString().replace(/"/g, '""')}"`; // Échapper les guillemets
                });
                csvRows.push(csvRow.join(';')); // Séparateur ";"
            });
    
            // Générer le contenu CSV avec BOM pour Excel
            const csvContent = '\uFEFF' + csvRows.join('\n');
    
            // Créer un fichier téléchargeable
            const fileContent = "data:text/csv;charset=utf-8," + encodeURIComponent(csvContent);
            const downloadElement = document.createElement("a");
            downloadElement.href = fileContent;
            downloadElement.target = "_self";
            downloadElement.download = `Export_${type}_${Object.keys(data)[0]}.csv`;
            document.body.appendChild(downloadElement);
            downloadElement.click();
            document.body.removeChild(downloadElement);
        } else {
            this.showNotification("Info", `Aucune donnée trouvée pour le type : ${type}.`, "info");
        }
    }

    showNotification(title, message, variant) {
        const evt = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(evt);
    }
}