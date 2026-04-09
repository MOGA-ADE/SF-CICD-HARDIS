import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import generateCSV from '@salesforce/apex/AP035_FacturationGazEuroCSVController.generateCSV';

export default class Lwc032_FacturationGazEuroCSV extends LightningElement {

    @track month;
    @track year;

    monthOptions = [
        { label: "Toute l'année", value: 0 },
        { label: 'Janvier', value: 1 },
        { label: 'Février', value: 2 },
        { label: 'Mars', value: 3 },
        { label: 'Avril', value: 4 },
        { label: 'Mai', value: 5 },
        { label: 'Juin', value: 6 },
        { label: 'Juillet', value: 7 },
        { label: 'Août', value: 8 },
        { label: 'Septembre', value: 9 },
        { label: 'Octobre', value: 10 },
        { label: 'Novembre', value: 11 },
        { label: 'Décembre', value: 12 }
    ];

    yearOptions = [];

    connectedCallback() {
        const currentYear = new Date().getFullYear();
        const start = currentYear - 3;
        const end = currentYear + 5;

        const years = [];
        for (let y = start; y <= end; y++) {
            years.push({ label: String(y), value: y });
        }

        this.yearOptions = years;
    }

    get isDisabled() {
        return this.month === undefined || this.month === null
            || this.year === undefined || this.year === null;
    }

    handleMonthChange(event) {
        this.month = parseInt(event.detail.value, 10);
    }

    handleYearChange(event) {
        this.year = parseInt(event.detail.value, 10);
    }

    async handleDownload() {
        if (this.isDisabled) {
            this.showToast("Information", "Veuillez sélectionner un mois et une année.", "warning");
            return;
        }

        try {
            const result = await generateCSV({
                monthNumber: this.month,
                yearNumber: this.year
            });

            if (!result.hasData) {
                this.showToast(
                    "Aucun résultat",
                    "Aucun appel à facturation n'a été trouvé pour cette période.",
                    "warning"
                );
                return;
            }

            this.showToast(
                "Succès",
                "Le fichier CSV a été généré avec succès.",
                "success"
            );

            const filename =
                this.month === 0
                    ? `Appel_Facturation_Annee_${this.year}.csv`
                    : `Appel_Facturation_${this.month}_${this.year}.csv`;

            const encoded = "data:text/csv;charset=utf-8,%EF%BB%BF " + encodeURI(result.csv);

            const downloadElement = document.createElement("a");
            downloadElement.href = encoded;
            downloadElement.target = "_blank";
            downloadElement.download = filename;

            document.body.appendChild(downloadElement);
            downloadElement.click();
            document.body.removeChild(downloadElement);

        } catch (e) {
            console.error(e);
            this.showToast("Erreur", "Une erreur est survenue lors de la génération du CSV.", "error");
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}