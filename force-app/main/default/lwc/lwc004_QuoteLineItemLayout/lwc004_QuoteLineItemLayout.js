import { LightningElement, api, wire} from 'lwc';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import PDE_FIELD from '@salesforce/schema/QuoteLineItem.PDE__r.RecordType.DeveloperName';
import PDE_FTA from '@salesforce/schema/QuoteLineItem.TECH_MU_CU__c';
import PDE_4_5Postes from '@salesforce/schema/QuoteLineItem.PDE__r.TECH_C5_4Postes__c';
import UnitPrice from  '@salesforce/schema/QuoteLineItem.UnitPrice';
import Taxes from '@salesforce/schema/QuoteLineItem.Taxes__c';
import QUOTE_Cee from '@salesforce/schema/QuoteLineItem.T_QuoteCEE__c';

const fields = [PDE_FIELD,PDE_FTA,PDE_4_5Postes,Taxes,QUOTE_Cee, UnitPrice];
export default class Lwc004_QuoteLineItemLayout extends LightningElement {
    @api recordId;
    @api objectApiName;
    @api isLoaded;
    loadPage = false
    quotelineitem;
    
    get showCard_C1C4(){
        return getFieldValue(this.quotelineitem,PDE_FIELD)==='Elec_C1C2' || getFieldValue(this.quotelineitem,PDE_FIELD)==='Elec_C3_C4';
    }
    
    get showCard_C5MU (){
        return getFieldValue(this.quotelineitem,PDE_FIELD)==='PDE_ElecC5' && getFieldValue(this.quotelineitem,PDE_FTA)==='MU' && getFieldValue(this.quotelineitem,PDE_4_5Postes)=== false ;
    }

    get showCard_C5CU (){
        return getFieldValue(this.quotelineitem,PDE_FIELD)==='PDE_ElecC5' && getFieldValue(this.quotelineitem,PDE_FTA)==='CU' && getFieldValue(this.quotelineitem,PDE_4_5Postes)== false;
    }

    get showCard_C54Postes (){
        return getFieldValue(this.quotelineitem,PDE_FIELD)==='PDE_ElecC5' && getFieldValue(this.quotelineitem,PDE_4_5Postes)=== true;
    }
    
    get showCard_Gaz(){
        return getFieldValue(this.quotelineitem,PDE_FIELD)==='PDE_Gaz';
    }

    get isCEESoumis(){
        return getFieldValue(this.quotelineitem,QUOTE_Cee)!=='Non Soumis';
    }

    @wire(getRecord,{recordId: '$recordId',fields})
    wiredRecord({data, error}){
        if(data){
            this.loadPage = true
            this.quotelineitem = data
        } else if (error){
            console.log(error);
        }
    }
    
    handleSuccess(event){
        const updatedRecord = event.detail.id;
        this.isLoaded=false;
     }

    handleClick(event){
        this.isLoaded = true;
        window.location.reload(true);
    }

}