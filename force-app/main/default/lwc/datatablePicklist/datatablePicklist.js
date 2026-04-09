import { LightningElement, api } from 'lwc';

export default class DatatablePicklist extends LightningElement {
    @api value;
    @api placeholder;
    @api options;
    @api context;
    @api contextName;
    @api fieldName;
    @api rowKeyValue;

    handleChange(event) {
        this.value = event.detail.value;
        const effectiveContext = this.context || this.rowKeyValue;

        let draftValue = {};
        draftValue[this.contextName] = effectiveContext;
        draftValue[this.fieldName] = this.value;

        this.dispatchEvent(new CustomEvent('cellchange', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: { draftValues: [draftValue] }
        }));
    }
}