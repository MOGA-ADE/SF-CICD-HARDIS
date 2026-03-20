import { LightningElement, api } from 'lwc';

export default class Lwcc001_RechercheClientListe extends LightningElement {
    @api listAccount;
    @api isLoading;

    get listEmpty() {
        return this.listAccount === undefined || this.listAccount?.length === 0;
    }

    get accountsNumber() {
        return this.listAccount === undefined ? 0 : this.listAccount.length;
    }
}