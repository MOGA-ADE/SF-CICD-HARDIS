import { LightningElement, track} from 'lwc';
import searchAccount from '@salesforce/apex/DM000_QueryManager.searchAccount';

export default class Lwcc001_RechercheClientParent extends LightningElement {
    @track accountToShow;
    isLoading = false;

    searchAccount(event){
        this.isLoading = true;
        this.accountToShow = [];
        
        searchAccount({accountName: event.detail.raisonSociale, codeNaf: event.detail.codeNaf})
        .then(response =>{
            response.forEach( account => {
                this.accountToShow.push({
                    Id: account.Id,
                    Name: account.Name,
                    CodeNaf: account.Code_NAF__r?.Name,
                    Statut: account.Statut__c,
                    Owner: account.Owner.Name,
                    Email: account.Owner.Email,
                    Phone: account.Owner.Phone
                });
            })
            this.isLoading = false;
        })
        .catch()
    }

}