import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getInfosComparatif from '@salesforce/apex/VFC007_ComparatifPDFController.getInfosComparatif';
import getInfosOpportunity from '@salesforce/apex/VFC007_ComparatifPDFController.getInfosOpportunity';
import getGOQuotes from '@salesforce/apex/AP032_QuoteGOController.getGOQuotes';
import generatePDFUrl from '@salesforce/apex/VFC007_ComparatifPDFController.generatePDFUrl';
import generateLettreMissionUrl from '@salesforce/apex/VFC010_LettreMission.generateLettreMissionUrl';
import generateResumePDFUrl from '@salesforce/apex/VFC008_ResumeComparatifPDFController.generateResumePDFUrl';
import getInfosTurpe from '@salesforce/apex/VFC007_ComparatifPDFController.getInfosTurpe';
import getPEPSConfig from '@salesforce/apex/VFC007_ComparatifPDFController.getPEPSConfig';
import applyPEPSMargin from '@salesforce/apex/VFC007_ComparatifPDFController.applyPEPSMargin';

const coproColumns = [
    { label: 'Nom de la copropriété', fieldName: 'name' },
    { label: 'Lien du comparatif détaillé', fieldName: 'comparatifLink', type: 'url', typeAttributes: { label: 'Ouvrir le PDF', target: '_blank' } },
];

export default class Lwc025_ComparatifSettings extends LightningElement {
    @api recordId;

    // Mode contrôlé automatiquement par l’URL / type de page :
    // - 'popup' si Quick Action (standard__recordAction via le bouton 'Génrer comparatif' de la record page de l'opp)
    // - 'direct link' (via le bouton 'Télécharger' de la record page des demandes de cotation)
    // - 'gestion' (via le bouton 'Gestion Garantie d'origine' record page de l'opp)
    viewMode = 'direct';
    get isDirectView() { return this.viewMode === 'direct'; }
    get isPopupView()  { return this.viewMode === 'popup'; }

    // Modale GO (simple)
    showGOPopup = false;
    openGOPopup = () => { this.showGOPopup = true; };
    closeGOPopup = () => { this.showGOPopup = false; };

    coproId = null;
    setOfCoproId = new Set([]);
    fournisseurOptions = [];
    selectedFournisseurs = [];
    uniqueFournisseur = [];
    quoteNumberList = [];
    oppHasSituationActuelle;
    oppIsMasse;
    oppIsForSyndic = false;
    oppName;
    sectionTTC = true;
    sectionSituationActuelle = true;
    coproData = [];
    coproDataLoaded = false;
    oprList = [];
    coproColumns = coproColumns;
    goOptions = [];
    selectedGO = [];
    margePEPS;
    minMargePEPS;
    maxMargePEPS;
    hasTurpeQuote = false;

    // Empeche la modification des inputs si les données de la copropriété ne sont pas chargées
    get disabledInputs() {
        if (!this.oppIsForSyndic) {
            return false;
        } else {
            return !this.coproDataLoaded;
        }
    }

    // Propriété calculée pour le label avec concaténation
    get label() {
        if(this.oppName == undefined){return "Offres à afficher dans le comparatif";}
        return `Offres à afficher dans le comparatif : ${this.oppName}`;
    }

    get noGOAvailable() {
        return (this.goOptions || []).length === 0;
    }
    get isGORequired() {
        // GO bloquant si au moins une GO existe (direct & popup)
        return (this.goOptions || []).length > 0;
    }

    // ===== Détection du contexte via CurrentPageReference =====
    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (!pageRef) return;

        // 1) recordId
        if (!this.recordId) {
            this.recordId =
                pageRef?.attributes?.recordId || // Quand le LWC est ouvert en Quick Action
                pageRef?.state?.c__recordId ||   // Quand le LWC est ouvert via une page personnalisée : Ici 'Paramètres du comparatif'
                this.recordId;
        }

        // 2) Déterminer le mode
        const override = pageRef?.state?.c__viewMode;
        if (override === 'popup' || override === 'direct') {
            this.viewMode = override;
        } else if (pageRef?.type === 'standard__recordAction') {
            this.viewMode = 'popup';
        } else if (pageRef?.state?.c__recordId) {
            this.viewMode = 'direct';
        } else {
            this.viewMode = 'popup';
        }

        console.log('PageRef type:', pageRef?.type, 'viewMode:', this.viewMode);
    }
    get showGOSection() { return true; }

    get hasGOToDisplay() {
        return this.isDirectView || (this.goOptions && this.goOptions.length > 0);
    }

    // ===== Données offres non-GO =====
    @wire(getInfosComparatif, { opportunityId: '$recordId' })
    quoteInfos({ error, data }) {
        if (!data) return;

        this.fournisseurOptions = [];
        this.selectedFournisseurs = [];

        this.oppIsMasse = data[0].Opportunity.RecordType.Name.includes('Masse');
        this.sectionTTC = data[0].Opportunity.Section_TTC__c;
        this.oppHasSituationActuelle = data[0].Opportunity.SectionSituationActuelle__c;
        this.oppName = data[0].Opportunity.Name;
        data.forEach(quote => {
            const minDate = quote.Minimum_date_de_debut__c ? this.formatDate(quote.Minimum_date_de_debut__c) : '';
            const maxDate = quote.Maximum_date_de_fin__c   ? this.formatDate(quote.Maximum_date_de_fin__c)   : '';
            const dateValidite = quote.Date_Validite_Offre__c ? this.formatDateValidity(quote.Date_Validite_Offre__c) : '';

            const label = `${quote.Fournisseur__c} - ${minDate} - ${maxDate}${dateValidite}`;
            const value = `${quote.Fournisseur__c} ${quote.QuoteNumber}`;
            this.fournisseurOptions.push({ label, value });
        });

        // Par défaut : tout coché
        this.selectedFournisseurs = this.fournisseurOptions.map(o => o.value);
        this.loadOprAndBuildTable();
    }

    // ===== Données GO (pour les cases à cocher) =====
    @wire(getGOQuotes, { opportunityId: '$recordId' })
    goInfos({ error, data }) {
        if (!data) return;

        this.goOptions = [];
        this.selectedGO = [];

        data.forEach(quote => {
            const start = quote.DebutCouvertureGarantieOrigine__c ? this.formatDate(quote.DebutCouvertureGarantieOrigine__c) : '';
            const end   = quote.FinCouvertureGarantieOrigine__c   ? this.formatDate(quote.FinCouvertureGarantieOrigine__c)   : '';
            const org   = quote.OrigineGarantieOrigine__c || '—';
            const tech  = quote.TechnologieGarantieOrigine__c || '—';
            const label = `${org} / ${tech}${start && end ? ` - ${start} → ${end}` : ''}`;
            // valeur = QuoteNumber (clé de filtrage côté APEX)
            this.goOptions.push({ label, value: quote.QuoteNumber });
        });

        // Par défaut : toutes les GO cochées
        this.selectedGO = this.goOptions.map(o => o.value);
    }

    async connectedCallback() {
        try {
            const cfg = await getPEPSConfig();
            this.margePEPS = cfg.defaultMargin;
            this.minMargePEPS = cfg.minMargin;
            this.maxMargePEPS = cfg.maxMargin;

            // Vérifier si une quote TURPE existe avec au minimum un total d'économie > 0
            const turpeQuotes = await getInfosTurpe({ opportunityId: this.recordId });
            console.log(turpeQuotes);

            if (turpeQuotes && turpeQuotes.length > 0) {
                console.log('Je check la valeur de turpeQuotes');
                this.hasTurpeQuote = turpeQuotes[0].SumEconomieIdentifiee__c > 0;
            } else {
                this.hasTurpeQuote = false;
            }

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur lors du chargement des paramètres PEPS/TURPE',
                    message: error?.body?.message || error?.message,
                    variant: 'error'
                })
            );
        }
    }

    renderedCallback() {
        // Empêcher d’injecter plusieurs fois
        if (this._styleAppended) return;

        const style = document.createElement('style');
        style.innerText = `
            .dt-outer-container {
                height: auto !important;
                margin: 10px !important;
            }
        `;

        // On l’injecte dans le shadowRoot du composant
        this.template.querySelector('div').appendChild(style);

        this._styleAppended = true;
    }

    async loadOprAndBuildTable() {
        try {
            const oprList = await getInfosOpportunity({ opportunityId: this.recordId });
            this.oppIsForSyndic = oprList[0].Opportunity__r.Account.RecordType.DeveloperName === 'Syndic';

            if (!this.oppIsForSyndic) {return;}

            this.oprList = oprList; // mémorisé pour les refresh
            await this.updateCoproData(); // premier affichage
        } catch (err) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur pendant le call de getInfosOpportunity',
                    message: err.body ? err.body.message : err.message,
                    variant: 'error'
                })
            );
        }
    }

    handleFournisseurChange(event) {
        this.selectedFournisseurs = event.detail.value;
        this.updateCoproData();
    }

    handleSectionTTChange(event) {
        this.sectionTTC = event.target.checked;
        this.updateCoproData();
    }

    handleSectionSituationActuelleChange(event) {
        this.sectionSituationActuelle = event.target.checked;
        this.updateCoproData();
    }

    // (optionnel) Nettoie le message si l’utilisateur coche/décoche
    handleGOChange(event) {
        this.selectedGO = event.detail.value;
        const goGroup = this.template.querySelector('lightning-checkbox-group[name="go"]');
        if (goGroup) goGroup.reportValidity();
    }

    // ===== Actions génération =====
    async handleGenerateComparatif() {
        if (!this.validateSelections()) return;

        try {
            if (this.hasTurpeQuote) {
                await applyPEPSMargin({ 
                    opportunityId: this.recordId, 
                    userMargin: parseFloat(this.margePEPS)
                });
            }

            this.processUniqueFournisseur();
            const result = await generatePDFUrl({
                opportunityId: this.recordId,
                selectedFournisseurs: this.uniqueFournisseur.join(';'),
                selectedQuoteNumber: this.quoteNumberList.join(';'),
                sectionTTC: this.sectionTTC,
                sectionSituationActuelle: this.sectionSituationActuelle,
                selectedGOQuoteNumbers: (this.selectedGO || []).join(';'),
                includeAllGO: false
            });

            window.open(result);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur lors de la génération du comparatif',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        }
    }

    async handleGenerateLettreMission() {
        try {
            await applyPEPSMargin({ 
                opportunityId: this.recordId, 
                userMargin: parseFloat(this.margePEPS)
        });
        //Génération de la lettre de mission
        const result = await generateLettreMissionUrl({
            opportunityId: this.recordId
        });
        window.open(result);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur lors de la génération de la lettre de mission',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        }

        //Envoyer le recordID à la classe APEX qui gère la VFP
        

    }


    async handleGenerateResumeComparatif() {
        if (!this.validateSelections()) return;

        try {
            // Appliquer la marge PEPS uniquement si une quote TURPE existe
            if (this.hasTurpeQuote) {
                await applyPEPSMargin({
                    opportunityId: this.recordId,
                    userMargin: parseFloat(this.margePEPS)
                });
            }

            this.processUniqueFournisseur();

            const result = await generateResumePDFUrl({
                opportunityId: this.recordId,
                selectedFournisseurs: this.uniqueFournisseur.join(';'),
                selectedQuoteNumber: this.quoteNumberList.join(';'),
                sectionTTC: this.sectionTTC,
                sectionSituationActuelle: this.sectionSituationActuelle,
                selectedGOQuoteNumbers: (this.selectedGO || []).join(';'),
                includeAllGO: false // on filtre selon les cases cochées
            });

            // Ouvrir le PDF Résumé
            this.quoteNumberList = [];
            this.uniqueFournisseur = [];
            window.open(result);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur lors de la génération du comparatif résumé',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        }
    }


    // Helpers
    validateSelections() {
        let ok = true;

        // Fournisseurs obligatoire
        const fournisseurGroup = this.template.querySelector('lightning-checkbox-group[name="fournisseurs"]');
        if (!this.selectedFournisseurs || this.selectedFournisseurs.length === 0) {
            if (fournisseurGroup) fournisseurGroup.reportValidity();
            ok = false;
        }

        // GO obligatoire si des GO existent
        const goGroup = this.template.querySelector('lightning-checkbox-group[name="go"]');
        if (this.goOptions.length > 0) {
            if (!this.selectedGO || this.selectedGO.length === 0) {
                if (goGroup) goGroup.reportValidity();
                ok = false;
            }
        }

        return ok;
    }


    async updateCoproData() {
        this.coproDataLoaded = false;
        this.processUniqueFournisseur();

        const uniqueOprList = [...new Map(this.oprList.map(opr => [opr.PDE__r.EntiteJuridique__c, opr])).values()];
        // Pour chaque OPR on lance l’appel Apex et on récupère l'URL avant de construire la ligne
        const rowsPromises = uniqueOprList.map(async (opr) => {
            const url = await generatePDFUrl({
                opportunityId: this.recordId,
                coproId: opr.PDE__r.EntiteJuridique__c,
                selectedFournisseurs: this.uniqueFournisseur.join(';'),
                selectedQuoteNumber: this.quoteNumberList.join(';'),
                sectionTTC: this.sectionTTC,
                sectionSituationActuelle: this.sectionSituationActuelle,
                selectedGOQuoteNumbers: (this.selectedGO || []).join(';'),
                includeAllGO: false
            });
            return {
                id: opr.PDE__r.EntiteJuridique__c,
                name: opr.PDE__r.EntiteJuridique__r.Name,
                comparatifLink: url
            };
        });
        this.coproData = await Promise.all(rowsPromises); // on attend TOUTES les promesses
        this.coproDataLoaded = true; 
    }

    processUniqueFournisseur() {
        // 1. On repart de zéro
        this.uniqueFournisseur = [];
        this.quoteNumberList   = [];
    
        // 2. On parse UNIQUEMENT les fournisseurs encore cochés
        (this.selectedFournisseurs || []).forEach(value => {
            const parts = value.split(' ');
            const quoteNumber = parts.pop();     // dernier token = QuoteNumber
            const fournisseur = parts.join(' '); // tout le reste = nom du fournisseur
    
            this.uniqueFournisseur.push(fournisseur);
            this.quoteNumberList.push(quoteNumber);
        });
    
        // 3. On retire d’éventuels doublons (au cas où plusieurs quotes pour le même fournisseur)
        this.uniqueFournisseur = [...new Set(this.uniqueFournisseur)];
    }

    formatDateValidity(dateStr) {
        const date = new Date(dateStr);
        const day = date.getDate().toString().padStart(2, '0');
        const month = (date.getMonth() + 1).toString().padStart(2, '0'); // Months are zero-based
        const year = date.getFullYear();
        const hours = date.getHours().toString().padStart(2, '0');
        const minutes = date.getMinutes().toString().padStart(2, '0');
    
        return ` - Validité offre : ${day}/${month}/${year} à ${hours}h${minutes}`;
    }

    formatDate(dateStr) {
        const date = new Date(dateStr);
        const day = date.getDate().toString().padStart(2, '0');
        const month = (date.getMonth() + 1).toString().padStart(2, '0'); // Months are zero-based
        const year = date.getFullYear();
    
        return `${day}/${month}/${year}`;
    }

    handleMargeChange(event) {
        this.margePEPS = event.target.value;
    }
}