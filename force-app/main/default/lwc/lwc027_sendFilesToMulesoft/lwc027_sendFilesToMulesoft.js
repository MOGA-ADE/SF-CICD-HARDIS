import { LightningElement, api } from 'lwc';
import { RefreshEvent } from 'lightning/refresh';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import sendFiles from '@salesforce/apex/AP026_SendInvoicesToMulesoft.sendFiles';

export default class Lwc027_sendFilesToMulesoft extends LightningElement {
    @api recordId;
    acceptedFormats = ['.pdf'];
    isLoading = false;

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log('event.detail.files: ' + JSON.stringify(event.detail.files));
        console.log('uploadedFiles: ' + JSON.stringify(uploadedFiles));
        const filesIds = uploadedFiles.map(file => file.documentId);
        filesIds.forEach(fileId => {
            this.sendFiles(fileId);
        });
        this.dispatchEvent(new RefreshEvent());
    }

    async sendFiles(filesIds) {
        this.isLoading = true;
        try {
            const response = await sendFiles({ fileId: filesIds, recordId: this.recordId, filesFromAccount : true });
            const { title, message, variant } = response;
            this.sendToast(title, message, variant);
        } catch (error) {
            const title = 'Error';
            const message = error.body ? error.body.message : 'An unexpected error occurred.';
            const variant = 'error';
            this.sendToast(title, message, variant);
        } finally {
            this.isLoading = false;
        }
    }

    sendToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({title: title,message: message,variant: variant}));
    }
}