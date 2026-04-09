import { LightningElement, api, wire } from 'lwc';
import getInfosTurpeByAccount from '@salesforce/apex/AP034_TURPEOptimisationController.getInfosTurpeByAccount';
import generateLettreMissionUrlFromAccount from '@salesforce/apex/VFC010_LettreMission.generateLettreMissionUrlFromAccount';
import getPEPSConfig from '@salesforce/apex/VFC007_ComparatifPDFController.getPEPSConfig';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class Lwc030_TurpeOptimizationView extends LightningElement {
    @api recordId;
    data;
    error;
    isMonoSite = false;
    margePEPS;
    minMargePEPS;
    maxMargePEPS;
    montantEconomie;
    lstDecorated = [];
    blurAmount;

    renderedCallback() {
        this.template.querySelectorAll('.turpe-blur').forEach(element => {
            element.style.setProperty('--content-blur-amount', this.blurAmount);
        });
    }

    @wire(getInfosTurpeByAccount, { accountId: '$recordId' })
    wiredData({ data, error }) {
        if (data) {
            this.data = data;
            this.isMonoSite = data.isMonoSite;
            this.blurAmount = data.blurPuissanceOptimal ? '5px' : '0px';
            const list = Array.isArray(data.lstPDE) ? data.lstPDE : [];
            this.lstDecorated = list.map(pde => ({
                ...pde,
                // on normalise les valeurs à 0 si null ou undefined
                BudgetTotalActuel__c: this.normalizeNumber(pde.BudgetTotalActuel__c),
                BudgetTotalOptimal__c: this.normalizeNumber(pde.BudgetTotalOptimal__c),
                EconomieIdentifie__c: this.normalizeNumber(pde.EconomieIdentifie__c),
                HCEActuel__c: pde.HCEActuel__c,
                HPEActuel__c: pde.HPEActuel__c,
                HCHActuel__c: pde.HCHActuel__c,
                HPHActuel__c: pde.HPHActuel__c,
                POINTEActuel__c: pde.POINTEActuel__c,
                HCEOptimal__c: pde.HCEOptimal__c,
                HPEOptimal__c: pde.HPEOptimal__c,
                HCHOptimal__c: pde.HCHOptimal__c,
                HPHOptimal__c: pde.HPHOptimal__c,
                POINTEOptimal__c: pde.POINTEOptimal__c,
                PartFixeCSActuel__c: this.normalizeNumber(pde.PartFixeCSActuel__c),
                PartVariableCSActuel__c: this.normalizeNumber(pde.PartVariableCSActuel__c),
                DepassementActuel__c: this.normalizeNumber(pde.DepassementActuel__c),
                TaxeCTAActuel__c: this.normalizeNumber(pde.TaxeCTAActuel__c),
                PartFixeCSOptimal__c: this.normalizeNumber(pde.PartFixeCSOptimal__c),
                PartVariableCSOptimal__c: this.normalizeNumber(pde.PartVariableCSOptimal__c),
                DepassementOptimal__c: this.normalizeNumber(pde.DepassementOptimal__c),
                TaxeCTAOptimal__c: this.normalizeNumber(pde.TaxeCTAOptimal__c),
                InterventionPEPS__c: this.normalizeNumber(pde.InterventionPEPS__c),
                _cssBudget: this.getCssClass(pde?.BudgetTotalOptimal__c, pde?.BudgetTotalActuel__c)
            }));

            this.error = undefined;
        } else if (error) {
            console.error('Erreur lors de la récupération des infos TURPE :', error);
            this.error = error;
            this.data = undefined;
            this.lstDecorated = [];
        }
    }

    async handleGenerateLettreMission() {
        try {
            console.log(this.margePEPS)
            //Génération de la lettre de mission
            if (this.margePEPS < this.minMargePEPS || this.margePEPS > this.maxMargePEPS) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Erreur lors de la génération de la lettre de mission',
                    message: 'La marge doit être comprise entre ' + this.minMargePEPS + '% et ' + this.maxMargePEPS + '%.',
                    variant: 'error'
                }));
            }
            else{
                const result = await generateLettreMissionUrlFromAccount({
                accountId: this.recordId,
                pourcentageRemuneration: this.margePEPS,
                montantEconomie: this.totalEconomie
            });
            window.open(result);   
            }
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur lors de la génération de la lettre de mission',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        }        

    }

    async connectedCallback() {
        try {
            const cfg = await getPEPSConfig();
            this.margePEPS = cfg.defaultMargin;
            this.minMargePEPS = cfg.minMargin;
            this.maxMargePEPS = cfg.maxMargin;

        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Erreur lors du chargement des paramètres de la lettre de mission',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        }
    }


    get lstPDE() {
        return this.data?.lstPDE || [];
    }

    get lstPDEDecorated() {
        return this.lstDecorated || [];
    }

    get firstPde() {
        return this.lstPDE.length > 0 ? this.lstDecorated[0] : null;
    }

    get totalBudgetActuel() {
        return this.normalizeNumber(this.data?.totalBudgetActuel);
    }

    get totalBudgetOptimal() {
        return this.normalizeNumber(this.data?.totalBudgetOptimal);
    }

    get totalEconomie() {
        return this.normalizeNumber(this.data?.totalEconomie);
    }

    get noteDateText() {
        return this.data?.noteDateText;
    }

    get noteConsoText() {
        return this.data?.noteConsoText;
    }

    normalizeNumber(value) {
        const number = value != null ? value : 0;
        return Number(number).toFixed(2);
    }

    get cssPartFixeCS() {
        return this.getCssClass(this.firstPde?.PartFixeCSOptimal__c, this.firstPde?.PartFixeCSActuel__c);
    }
    get cssPartVariableCS() {
        return this.getCssClass(this.firstPde?.PartVariableCSOptimal__c, this.firstPde?.PartVariableCSActuel__c);
    }
    get cssDepassement() {
        return this.getCssClass(this.firstPde?.DepassementOptimal__c, this.firstPde?.DepassementActuel__c);
    }
    get cssTaxeCTA() {
        return this.getCssClass(this.firstPde?.TaxeCTAOptimal__c, this.firstPde?.TaxeCTAActuel__c);
    }
    get cssBudgetTotal() {
        return this.getCssClass(this.firstPde?.BudgetTotalOptimal__c, this.firstPde?.BudgetTotalActuel__c);
    }

    get cssInterventionPEPS() {
        const optimal = this.firstPde?.InterventionPEPS__c;
        return optimal > 0 ? 'turpe-negative' : '';
    }

    getCssClass(optimal, actuel) {
        optimal = Number(optimal);
        actuel = Number(actuel);

        if (optimal === 0 && actuel === 0) return '';
        if (optimal > actuel) return 'turpe-negative';
        if (optimal < actuel) return 'turpe-positive';
        return '';
    }

    handleMargeChange(event) {
        this.margePEPS = event.target.value;
        //this.montantInterventionPEPS = this.normalizeNumber(this.data?.totalEconomie * (this.margePEPS / 100));
    }
}