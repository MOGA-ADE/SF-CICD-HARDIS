import { LightningElement, api } from 'lwc';
import getOppList from '@salesforce/apex/AP004_ShowOppOnDemandeCotationController.getOppList';
import isCommunity from "@salesforce/apex/Utils.isCommunity";


export default class Lwc013_ShowOppOnDemandeCotation extends LightningElement {

    @api recordId;
    isCommunity = false;
    get baseURL() { 
        return isCommunity ? `https://${location.host}/partenaire`: ``;
    }

    columnsListSalesforce = [
        {label: 'Nom', fieldName: 'OpportunityLink', type: 'url', typeAttributes: {label: { fieldName: "OpportunityName" }, target: "_blank"}, sortable: true},
        {label: 'Fournisseurs', fieldName: 'Liste_fournisseurs__c', sortable: true},
        {label: 'Statut', fieldName: 'StageName', sortable: true},
        {label: 'Comparatif', fieldName: 'ComparatifLink', type: 'url', typeAttributes: {label: { fieldName: "DownloadLabel" }, target: "_blank"}},
    ];

    columnsListCommunity = [
        {label: 'Nom', fieldName: 'Name', sortable: true},
        {label: 'Fournisseurs', fieldName: 'Liste_fournisseurs__c', sortable: true},
        {label: 'Statut', fieldName: 'StageName', sortable: true},
        {label: 'Comparatif', fieldName: 'ComparatifLink', type: 'url', typeAttributes: {label: { fieldName: "DownloadLabel" }, target: "_blank"}},
    ];

    dataList;
    cardTitle = 'Opportunités';

    connectedCallback(){
        isCommunity().then(response => {
            this.isCommunity = response;

            getOppList({'demandeCotationId' : this.recordId})
                .then((opps) => {
                    // Ajout du nombre d'opportunités trouvé dans le titre de la carte
                    this.cardTitle += ` (${opps.length})`;
                    // Si au moins 1 opp est trouvée
                    if (opps.length > 0) {
                        let dataList = [];
                        opps.forEach(opp => {
                            let urlPath = this.isCommunity ? 's/parametres-du-comparatif' : 'lightning/n/Parametres_du_comparatif';
                            let data = {};
                            const baseURL = this.isCommunity ? `https://${location.host}/partenaire` : '';
                            if(this.isCommunity){
                                data.Name = opp.Name;
                            } else{
                                data.OpportunityName = opp.Name;
                                data.OpportunityLink = `${baseURL}/${opp.Id}`;
                            }

                            data.Liste_fournisseurs__c = opp.Liste_fournisseurs__c != null ? opp.Liste_fournisseurs__c.replaceAll(';', ', ') : '';
                            data.StageName = opp.StageName;
                            data.ComparatifLink = opp.StageName !== 'En cours de traitement' ? `${baseURL}/${urlPath}?c__recordId=${opp.Id}` : '';
                            data.DownloadLabel = opp.StageName !==  'En cours de traitement' ? 'Télécharger' : '';

                            dataList.push(data);
                        });
                        this.dataList = dataList;
                    }
                });
        })
    }
}