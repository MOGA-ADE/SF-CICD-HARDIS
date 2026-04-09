import { LightningElement, api, track } from 'lwc';

export default class Lwc031_DDCImportCompteurs extends LightningElement {

    @api selectedPDE = '';
    @api csvModeActive = false;

    @track errorMessage = '';
    @track successMessage = '';

    handleDragOver(event) {
        event.preventDefault();
    }

    handleDrop(event) {
        event.preventDefault();

        this.errorMessage = '';
        this.successMessage = '';

        const file = event.dataTransfer?.files?.[0];
        if (!file) return;

        if (!file.name.toLowerCase().endsWith('.csv')) {
            this.errorMessage = "Erreur : merci d'utiliser un fichier CSV valide.";
            return;
        }

        const reader = new FileReader();

        reader.onload = () => {

            const content = reader.result || '';

            const lines = content
                .split(/\r\n|\n|\r/)
                .map(v => v.trim())
                .filter(v => v.length > 0);

            if (lines.length < 2) {
                this.errorMessage = "Erreur : le fichier CSV est vide.";
                return;
            }

            if (!lines[0].toLowerCase().includes("numero")) {
                this.errorMessage = "Erreur : l'en-tête doit contenir une colonne 'Numero de compteur'.";
                return;
            }

            const pde = lines.slice(1);

            if (pde.length === 0) {
                this.errorMessage = "Erreur : aucun numéro de compteur trouvé.";
                return;
            }

            this.selectedPDE = pde.join(';');
            this.csvModeActive = true;
            this.successMessage = "Fichier CSV importé avec succès.";
        };

        reader.readAsText(file, 'UTF-8');
    }

    downloadTemplate() {
        let doc = "Numero de compteur\n";

        let element = "data:text/csv;charset=utf-8," + encodeURIComponent(doc);
        let downloadElement = document.createElement("a");
        downloadElement.href = element;
        downloadElement.target = "_self";

        downloadElement.download = "Template_Compteurs.csv";
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }
}