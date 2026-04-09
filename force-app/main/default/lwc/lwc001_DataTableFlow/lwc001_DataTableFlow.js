import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
import getSobjectTypeName from '@salesforce/apex/Utils.getSobjectTypeName';

export default class Lwc001_DataTableFlow extends LightningElement {
    @api input;                 // tableau complet passé par le Flow
    @api selected;              // tableau retourné au Flow
    @api flowName;              // nom du flow appelant
    @api selectedRowsCount = 0; // nombre d’éléments sélectionnés
    searchTerm = '';
    filteredData = [];
    delayTimeout;
    sObjecTypeName;
    sortBy;
    sortDirection;
    selectedIdSet = new Set();  // Stocke les Id des lignes sélectionnées, quel que soit le filtre actuel.

    /* *** COLONNES *** */
    columnsPDE = [
        { label: 'Nom du site', fieldName: 'Name', sortable: true, wrapText: true },
        { label: 'Numéro PDE', fieldName: 'TECH_num_compteur__c', sortable: true },
        { label: 'Type PDE', fieldName: 'TypePDE__c', sortable: true },
        { label: 'CAR', fieldName: 'TECH_CAR__c', sortable: true },
        { label: 'Adresse de consommation', fieldName: 'Adresse_de_consommation__c', sortable: true, wrapText: true },
        { label: 'Fournisseur Actuel', fieldName: 'Fournisseur__c', sortable: true },
        { label: 'Contrat Actif ?', fieldName: 'Contrat_actif__c', type: 'boolean', sortable: true }
    ];

    columnsPDEActualiserDepuisSGE = [
        { label: 'Nom du site', fieldName: 'Name', sortable: true, wrapText: true },
        { label: 'Numéro PDE', fieldName: 'TECH_num_compteur__c', sortable: true },
        { label: 'Type PDE', fieldName: 'TypePDE__c', sortable: true },
        { label: 'CAR', fieldName: 'Consommation_Annuelle_de_R_f_rence_Elec__c', sortable: true },
        { label: 'Adresse de consommation', fieldName: 'Adresse_de_consommation__c', sortable: true, wrapText: true },
        { label: "Date de signature de l'ACD", fieldName: 'Date_signature_ACD__c', sortable: true, wrapText: true },
        { label: 'Date de la dernière MAJ Enedis', fieldName: 'Date_MAJ_Enedis__c', sortable: true, wrapText: true }
    ];

    /**
     * Liste d’Id à transmettre à lightning‑datatable pour (dé)cocher les cases.
     * Toujours dérivée du Set global – garantit la persistance de la sélection.
     */
    get selectedIds() {
        return Array.from(this.selectedIdSet);
    }

    get columns() {
        switch (this.sObjecTypeName) {
            case 'PDE__c':
                return (this.flowName === 'Actualiser_PDE_depuis_un_compte')
                    ? this.columnsPDEActualiserDepuisSGE
                    : this.columnsPDE;
            default:
                return this.columnsPDE;
        }
    }

    connectedCallback() {
        // Copie complète des données pour affichage initial
        this.filteredData = this.input ? [...this.input] : [];

        // Initialise le Set si des lignes sont déjà sélectionnées (ex : retour dans l’écran)
        if (this.selected && this.selected.length) {
            this.selected.forEach(rec => this.selectedIdSet.add(rec.Id));
            this.selectedRowsCount = this.selected.length;
        }

        // Récupère le type d’objet (pour choisir les colonnes)
        if (this.input && this.input.length) {
            getSobjectTypeName({ id: this.input[0].Id })
                .then(name => { this.sObjecTypeName = name; })
                .catch(error => { console.error('Error fetching sObject type name:', error); });
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.debounceFilter();
    }

    debounceFilter() {
        clearTimeout(this.delayTimeout);
        this.delayTimeout = setTimeout(() => { this.filterData(); }, 300);
    }

    filterData() {
        if (this.searchTerm) {
            const searchTermLower = this.searchTerm.toLowerCase();
            this.filteredData = this.input.filter(record =>
                Object.values(record).some(value =>
                    value !== null && value !== undefined && String(value).toLowerCase().includes(searchTermLower)
                )
            );
        } else {
            this.filteredData = [...this.input];
        }
    }

    selectedRows(event) {
        const visibleSelectedIds = new Set(event.detail.selectedRows.map(r => r.Id));

        // Synchronise le Set global pour toutes les lignes actuellement visibles
        this.filteredData.forEach(rec => {
            if (visibleSelectedIds.has(rec.Id)) {
                this.selectedIdSet.add(rec.Id);
            } else {
                this.selectedIdSet.delete(rec.Id);
            }
        });

        // Reconstruit le tableau complet des enregistrements sélectionnés
        this.selected = this.input.filter(rec => this.selectedIdSet.has(rec.Id));
        this.selectedRowsCount = this.selected.length;

        /* --- Notify Flow --- */
        this.dispatchEvent(new FlowAttributeChangeEvent('selected', this.selected));
        this.dispatchEvent(new FlowAttributeChangeEvent('selectedRowsCount', this.selectedRowsCount));
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        const parseData = JSON.parse(JSON.stringify(this.filteredData));
        const keyValue = record => record[fieldname];
        const isReverse = direction === 'asc' ? 1 : -1;

        parseData.sort((x, y) => {
            x = keyValue(x) ?? ''; // gère les null
            y = keyValue(y) ?? '';
            return isReverse * ((x > y) - (y > x));
        });

        this.filteredData = parseData;
    }
}