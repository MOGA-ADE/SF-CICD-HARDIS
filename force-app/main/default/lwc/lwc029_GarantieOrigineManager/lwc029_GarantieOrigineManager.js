import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import initGO from '@salesforce/apex/AP032_QuoteGOController.initGO';
import saveGOQuotes from '@salesforce/apex/AP032_QuoteGOController.saveGOQuotes';
import deleteGOQuote from '@salesforce/apex/AP032_QuoteGOController.deleteGOQuote';
import GOAssets from '@salesforce/resourceUrl/GOAssets';

export default class Lwc029_GarantieOrigineManager extends LightningElement {
    _recordId;
    @track loading = true;

    @api mode = 'full';   // 'full' ou 'view' : Sert à définir si l’utilisateur a le droit d’éditer les GO ou seulement de les consulter
    @api modeAppel = 'gestion'; // 'gestion' | 'popup' | 'direct' (Contexte d'appel UI du composant)

    @api
    set recordId(value) {
        this._recordId = value;
        if (value) {
            this.loadInit();
        }
    }
    get recordId() {
        return this._recordId;
    }
    
    get isFull() {
        return this.mode === 'full';
    }

    get showDatatable() {
        return this.isFull || this.quotes.length > 0;
    }

    get useQuickActionPanel() {
        return this.modeAppel === 'gestion';
    }

    // Données
    @track quotes = [];
    @track quotesElec = [];
    @track quotesGaz = [];
    @track draftValues = [];

    // Picklists/options
    origineOptions = [];
    technoOptionsByType = { Quote_Elec: [], Quote_Gaz: [] };
    pricingByKey = {};
    margeByKey   = {};

    // Colonnes
    columns = [];

    // Défauts
    defaults = {
        consoTotal: 0,
        minStartElec: null,
        maxEndElec: null,
        minStartGaz: null,
        maxEndGaz: null
    };
    recordTypeIds = { Quote_Elec: null, Quote_Gaz: null };

    // Icons
    elecIcon = GOAssets + '/icons/elec.png';
    gazIcon  = GOAssets + '/icons/biogas.png';

    /**
     * Injection CSS spécifique au modal
     */
    renderedCallback() {
        if (this._styleInjected) return;
        this._styleInjected = true;

        const style = document.createElement('style');
        style.innerText = `
            .slds-modal__container {
                width: 95% !important;
                max-width: 1400px !important;
                min-width: 900px !important;
                margin: 0 auto !important;
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * Initialisation du composant
     */
    connectedCallback() {
        if (!this._recordId) {
            try {
                const urlParams = new URL(window.location.href).searchParams;
                this._recordId = urlParams.get('recordId');
            } catch (err) {
                console.error('Impossible de récupérer le recordId depuis l’URL', err);
            }
        }

        if (this._recordId) {
            this.loadInit();
        }
    }

    // ---------- Utils ----------

    /**
     * Génère un Id temporaire pour une nouvelle ligne
     */
    generateTmpId() {
        return 'tmp-' + Math.random().toString(36).substring(2, 9) + '-' + Date.now();
    }

    /**
     * Trie une liste de quotes par budget croissant
     */
    sortByBudget(list) {
        return [...list].sort((a, b) => (a.BudgetGarantieOrigine__c || 0) - (b.BudgetGarantieOrigine__c || 0));
    }

    /**
     * Retourne les options de technologie en fonction du RecordType
     */
    getTechOptionsForDevName(recordTypeDevName) {
        const raw = this.technoOptionsByType[recordTypeDevName] || [];
        return raw.map(v => ({ label: v, value: v }));
    }

    /**
     * Normalise une valeur de clé (accents, espaces, case)
     */
    normalizeKeyPart(str) {
        return (str || '')
            .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
            .replace(/\s+/g, '')
            .toLowerCase();
    }

    /**
     * Enrichit les quotes avec les options Origine et Technologie selon le contexte
     */
    decorateRowsWithOptions(quotes) {
        return quotes.map(quote => {
            const devName = quote.RecordType?.DeveloperName ||
                (quote.RecordTypeId === this.recordTypeIds.Quote_Elec ? 'Quote_Elec' :
                 quote.RecordTypeId === this.recordTypeIds.Quote_Gaz  ? 'Quote_Gaz'  : null);

            // Technologie
            let techOptions = this.getTechOptionsForDevName(devName || 'Quote_Elec');
            if (this.modeAppel === 'direct') {
                techOptions = [{ label: 'Tout confondu', value: 'Tout confondu' }];
                if (quote.TechnologieGarantieOrigine__cantieOrigine__c && !techOptions.find(t => t.vTechnologieGarantieOrigine__c.TechnologieGarantieOrigine__c)) {
                    techOptions = [...techOptions, { label: quote.TechnologieGarantieOrigine__c, value: quote.TechnologieGarantieOrigine__c }];
                }
            }

            // Origine
            let origineOptions = this.origineOptions;
            if (this.modeAppel === 'direct') {
                origineOptions = [
                    { label: 'Européenne', value: 'Européenne' },
                    { label: 'Française', value: 'Française' }
                ];
                if (quote.OrigineGarantieOrigine__c && !origineOptions.find(o => o.value === quote.OrigineGarantieOrigine__c)) {
                    origineOptions = [...origineOptions, { label: quote.OrigineGarantieOrigine__c, value: quote.OrigineGarantieOrigine__c }];
                }
            }

            return {
                ...quote,
                TechOptions__ui: techOptions,
                OrigineOptions__ui: origineOptions
            };
        });
    }

    // ---------- Init ----------

    /**
     * Charge les données initiales via Apex
     */
    async loadInit() {
        try {
            this.loading = true;
            const data = await initGO({ opportunityId: this.recordId });

            this.origineOptions = (data.origineOptions || []).map(v => ({ label: v, value: v }));
            this.technoOptionsByType = data.technologieOptionsByType || this.technoOptionsByType;
            this.defaults = {
                consoTotal: data.consoTotal || 0,
                minStartElec: data.minStartElec || null,
                maxEndElec: data.maxEndElec || null,
                minStartGaz: data.minStartGaz || null,
                maxEndGaz: data.maxEndGaz || null
            };
            this.recordTypeIds = data.recordTypeIds || this.recordTypeIds;

            // Normalisation des clés pricing/marge
            this.pricingByKey = {};
            this.margeByKey   = {};

            if (data.pricingByKey) {
                Object.entries(data.pricingByKey).forEach(([rawKey, value]) => {
                    const [origine, techno] = rawKey.split('|');
                    const key = `${this.normalizeKeyPart(origine)}|${this.normalizeKeyPart(techno)}`;
                    this.pricingByKey[key] = value;
                });
            }
            if (data.margeByKey) {
                Object.entries(data.margeByKey).forEach(([rawKey, value]) => {
                    const [origine, techno] = rawKey.split('|');
                    const key = `${this.normalizeKeyPart(origine)}|${this.normalizeKeyPart(techno)}`;
                    this.margeByKey[key] = value;
                });
            }

            const baseQuotes = (data.quotes || []).map(q => ({
                ...q,
                Type__ui: q.RecordType?.Name || '',
            }));

            const decoratedQuotes = this.decorateRowsWithOptions(baseQuotes);
            this.quotes = this.sortByBudget(decoratedQuotes);
            this.splitByType();
            this.buildColumns();
        } catch (err) {
            this.showError(err);
        } finally {
            this.loading = false;
        }
    }

    /**
     * Sépare les quotes Électricité et Gaz
     */
    splitByType() {
        this.quotesElec = this.quotes.filter(q => q.RecordType?.DeveloperName === 'Quote_Elec');
        this.quotesGaz  = this.quotes.filter(q => q.RecordType?.DeveloperName === 'Quote_Gaz');
        this.quotesElec.forEach(q => q.Type__ui = 'Électricité');
        this.quotesGaz.forEach(q => q.Type__ui = 'Gaz');
    }

    /**
     * Construit les colonnes du datatable
     */
    buildColumns() {
        const isFull = this.mode === 'full';

        const origineCol = isFull
            ? {
                label: 'Origine',
                fieldName: 'OrigineGarantieOrigine__cantieOrigine__c',
                type: 'picklist',
                editable: true,
                typeAttributes: {
                    placeholder: 'Sélectionner',
                    options: { fieldName: 'OrigineOptions__ui' },
                    value: { fieldName: 'OrigineGarantieOrigine__c' },
                    context: { fieldName: 'Id' },
                    contextName: 'Id',
                    fieldName: 'OrigineGarantieOrigine__c'
                }
            }
            : { label: 'Origine', fieldName: 'OrigineGarantieOrigine__c', type: 'text', editable: false };

        const technoCol = isFull
            ? {
                label: 'Technologie',
                fieldName: 'TechnologieGarantieOrigine__c',
                type: 'picklist',
                editable: true,
                typeAttributes: {
                    placeholder: 'Sélectionner',
                    options: { fieldName: 'TechOptions__ui' },
                    value: { fieldName: 'TechnologieGarantieOrigine__c' },
                    context: { fieldName: 'Id' },
                    contextName: 'Id',
                    fieldName: 'TechnologieGarantieOrigine__c'
                }
            }
            : { label: 'Technologie', fieldName: 'TechnologieGarantieOrigine__c', type: 'text', editable: false };

        const baseCols = [
            origineCol,
            technoCol,
            { label: 'Début couverture', fieldName: 'DebutCouvertureGarantieOrigine__c', type: 'date-local', editable: isFull },
            { label: 'Fin couverture',   fieldName: 'FinCouvertureGarantieOrigine__c',   type: 'date-local', editable: isFull },
            { label: 'Conso ann. (MWh)', fieldName: 'ConsoAnnuelleGarantieOrigine__c', type: 'number', editable: isFull },
            { label: 'Prix (€/MWh)',     fieldName: 'PrixGarantieOrigine__c', type: 'currency', editable: isFull },
            { label: 'Marge (€HT/MWh)', fieldName: 'MargeGarantieOrigine__c', type: 'currency', editable: true, typeAttributes: { step: '0.01' } },
            { label: 'Budget (€HT/an)',  fieldName: 'BudgetGarantieOrigine__c', type: 'currency', editable: false,
              cellAttributes: { class: 'slds-text-color_success slds-text-title_bold' } }
        ];

        if (isFull) {
            baseCols.push({
                type: 'button-icon',
                fixedWidth: 50,
                typeAttributes: {
                    iconName: 'utility:delete',
                    name: 'delete',
                    title: 'Supprimer',
                    variant: 'bare',
                    alternativeText: 'Supprimer'
                }
            });
        }

        this.columns = baseCols;
    }

    /**
     * Ajoute une ligne Électricité
     */
    handleAddElec = () => this.addRow('Quote_Elec', 'Électricité');

    /**
     * Ajoute une ligne Gaz
     */
    handleAddGaz  = () => this.addRow('Quote_Gaz',  'Gaz');

    /**
     * Ajoute une nouvelle ligne (Quote)
     */
    addRow(recordTypeDevName, labelType) {
        if (this.mode !== 'full') return;

        const minStart = recordTypeDevName === 'Quote_Elec' ? this.defaults.minStartElec : this.defaults.minStartGaz;
        const maxEnd   = recordTypeDevName === 'Quote_Elec' ? this.defaults.maxEndElec   : this.defaults.maxEndGaz;

        const dateDebutCouverture = new Date(minStart);
        const dateFinCouverture   = new Date(maxEnd);

        let newQuote = {
            Id: this.generateTmpId(),
            OpportunityId: this.recordId,
            RecordTypeId: this.recordTypeIds[recordTypeDevName] || null,
            RecordType: { DeveloperName: recordTypeDevName, Name: labelType },
            Type__ui: labelType,
            IsGarantieOrigine__c: true,
            Name: `Garantie d'origine (${labelType}) : ${dateDebutCouverture.toLocaleDateString('fr-FR')} - ${dateFinCouverture.toLocaleDateString('fr-FR')}`,
            OrigineGarantieOrigine__c: '',
            TechnologieGarantieOrigine__c: '',
            DebutCouvertureGarantieOrigine__c: minStart || null,
            FinCouvertureGarantieOrigine__c:   maxEnd   || null,
            Date_de_fin_de_contrat__c: maxEnd || null,
            ConsoAnnuelleGarantieOrigine__c: this.defaults.consoTotal || 0,
            PrixGarantieOrigine__c: 0,
            MargeGarantieOrigine__c: 0,
            BudgetGarantieOrigine__c: 0
        };

        newQuote = this.decorateRowsWithOptions([newQuote])[0];

        this.quotes = [...this.quotes, newQuote];
        this.splitByType();
    }

    /**
     * Gère la modification de cellule
     */
    handleCellChange(event) {
        const changes = event.detail.draftValues || [];
        if (!changes.length) return;

        const byId = new Map(this.quotes.map(q => [q.Id, q]));

        changes.forEach(change => {
            const quote = byId.get(change.Id);
            if (!quote) return;

            const merged = { ...quote, ...change };

            if (('OrigineGarantieOrigine__c' in change) || ('TechnologieGarantieOrigine__c' in change)) {
                const origineNorm = this.normalizeKeyPart(merged.OrigineGarantieOrigine__c);
                const technoNorm  = this.normalizeKeyPart(merged.TechnologieGarantieOrigine__c);
                const key = `${origineNorm}|${technoNorm}`;

                if (this.pricingByKey[key] != null) {
                    merged.PrixGarantieOrigine__c = this.pricingByKey[key];
                }
                if (this.margeByKey[key] != null) {
                    merged.MargeGarantieOrigine__c = this.margeByKey[key];
                }
            }

            const conso = Number(merged.ConsoAnnuelleGarantieOrigine__c || 0);
            const prix  = Number(merged.PrixGarantieOrigine__c || 0);
            const marge = Number(merged.MargeGarantieOrigine__c || 0);

            merged.BudgetGarantieOrigine__c = (!isNaN(conso) && !isNaN(prix) && !isNaN(marge))
                ? conso * (prix + marge)
                : 0;

            byId.set(change.Id, merged);
        });

        this.quotes = this.quotes.map(q => byId.get(q.Id) || q);
        this.splitByType();
    }


    /**
     * Sauvegarde des quotes via Apex
     */
    async handleSave(event) {
        try {
            this.loading = true;
            const payload = event?.detail?.draftValues?.length ? event.detail.draftValues : this.quotes;

            const clean = payload.map(q => ({
                Id: q.Id && !q.Id.startsWith('tmp-') ? q.Id : null,
                OpportunityId: q.OpportunityId,
                RecordTypeId: q.RecordTypeId,
                IsGarantieOrigine__c: true,
                OrigineGarantieOrigine__c: q.OrigineGarantieOrigine__c,
                TechnologieGarantieOrigine__c: q.TechnologieGarantieOrigine__c,
                DebutCouvertureGarantieOrigine__c: q.DebutCouvertureGarantieOrigine__c,
                FinCouvertureGarantieOrigine__c: q.FinCouvertureGarantieOrigine__c,
                ConsoAnnuelleGarantieOrigine__c: q.ConsoAnnuelleGarantieOrigine__c,
                PrixGarantieOrigine__c: parseFloat(q.PrixGarantieOrigine__c || 0),
                MargeGarantieOrigine__c: parseFloat(q.MargeGarantieOrigine__c || 0),
                Name: q.Name,
                Date_de_fin_de_contrat__c: q.Date_de_fin_de_contrat__c
            }));

            const updated = await saveGOQuotes({ quotes: clean });
            this.showToast('Succès', 'Garanties mises à jour', 'success');
            this.draftValues = [];

            const withOptions = this.decorateRowsWithOptions(updated.map(q => ({
                ...q,
                Type__ui: q.RecordType?.DeveloperName === 'Quote_Elec' ? 'Électricité' : 'Gaz'
            })));
            this.quotes = this.sortByBudget(withOptions);
            this.splitByType();
        } catch (err) {
            this.showError(err);
        } finally {
            this.loading = false;
        }
    }

    /**
     * Gère les actions de ligne (supprimer)
     */
    handleRowAction(event) {
        if (this.mode !== 'full') return;
        const actionName = event.detail?.action?.name;
        const row = event.detail?.row;
        if (actionName === 'delete') {
            this.deleteRow(row);
        }
    }

    /**
     * Supprime une ligne
     */
    deleteRow(row) {
        if (!row.Id || row.Id.startsWith('tmp-')) {
            this.quotes = this.quotes.filter(q => q.Id !== row.Id);
            this.splitByType();
            return;
        }
        this.loading = true;
        deleteGOQuote({ quoteId: row.Id })
            .then(() => {
                this.showToast('Succès', 'Ligne supprimée', 'success');
                return this.loadInit();
            })
            .catch(err => {
                this.showError(err);
            })
            .finally(() => { this.loading = false; });
    }

    /**
     * Affiche un toast
     */
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    /**
     * Affiche une erreur sous forme de toast
     */
    showError(err) {
        const message = err?.body?.message || err?.message || 'Erreur inconnue lors de l’enregistrement.';
        this.showToast('Erreur', message, 'error');
    }
}