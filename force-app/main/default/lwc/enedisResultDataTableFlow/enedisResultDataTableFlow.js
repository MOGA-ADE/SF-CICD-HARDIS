import { LightningElement, api } from 'lwc';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';

export default class EnedisResultDataTableFlow extends LightningElement {
    @api columns;
    @api input;
    titles = [{label: "Nom du site",fieldName: "siteName"},{label: "Données mesures",fieldName: "message"}, {label: "Données techniques",fieldName: "messageConsulterPoint"}, {label: "Mise à jour dans Salesforce",fieldName: "messageUpdate"}];
    rows = [];
    //titles = JSON.parse(columns);
    connectedCallback() {
        this.rows = this.input.map(site => ({
            siteName: site.siteName,
            message: site.messageConsulterMesure,
            messageConsulterPoint : site.messageConsulterPoint,
            messageUpdate : site.messageUpdate
        }));
        
        
    }
    


}