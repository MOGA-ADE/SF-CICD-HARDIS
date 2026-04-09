import { LightningElement, api, wire } from 'lwc';
import getLeadRelatedContacts from '@salesforce/apex/AP012_LeadEllisphereController.getLeadRelatedContacts';
import updateLeadLastScore from '@salesforce/apex/AP012_LeadEllisphereController.updateLeadLastScore';

import SIRET_FIELD from '@salesforce/schema/Lead.ELLISPHERE__Elli_Siret__c';
import LAST_SCORE_DATE_FIELD from '@salesforce/schema/Lead.LastScoreDate__c';

import { getRecord } from 'lightning/uiRecordApi';

export default class Lwc022_GetLeadRelatedInfoParent extends LightningElement {
    @api recordId;
    listContact;
    listScore;
    isLoading = true;
    error = false;

    @wire(getRecord, {
        recordId: '$recordId',
        fields: [SIRET_FIELD, LAST_SCORE_DATE_FIELD]
    })
    wiredLead({ error, data }) {
        if (!data) return;

        const siret = data.fields.ELLISPHERE__Elli_Siret__c.value;
        const currentDate = data.fields.LastScoreDate__c.value;

        getLeadRelatedContacts({ siret })
            .then(response => {
                if (response?.[0]?.error) {
                    this.error = true;
                    return;
                }

                const tmpListContact = [];
                const tmpListScore = [];

                response?.[0]?.managers?.forEach(contact => {
                    const c = { ...contact, Id: Math.random().toString() };
                    tmpListContact.push(c);
                });

                response?.[0]?.scores?.forEach(score => {
                    const s = { ...score, Id: Math.random().toString() };
                    s.score = isNaN(s.score) ? s.score : `${s.score}/10`;
                    tmpListScore.push(s);
                });

                this.listContact = tmpListContact;
                this.listScore = tmpListScore;

                const latest = this.computeLatestScore(response?.[0]?.scores);
                if (!latest) return;

                const latestDate = latest.date;
                const latestScore  = latest.score;

                const isDifferent = !currentDate || currentDate !== latestDate;

                if (isDifferent) {
                    updateLeadLastScore({
                        leadId: this.recordId,
                        latestDate: latestDate,
                        latestScore: latestScore
                    });
                }
            })
            .catch(e => {
                console.error('ERROR ', e);
                this.error = true;
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * Retourne { date: 'YYYY-MM-DD', score: Number } pour le score le plus récent ET numérique
     */
    computeLatestScore(scores) {
        let latestDate = null; 
        let latestScore = null;

        for (const row of scores) {
            const rawDate  = row?.dateScore;
            const rawScore = row?.score;

            // garder uniquement les scores numériques (ex: '6', '2', pas 'NA')
            if (!rawScore || !/^[0-9]+(\.[0-9]+)?$/.test(String(rawScore))) continue;

            let newScoreDate = null;
            newScoreDate = rawDate.substring(0, 10);
            console.log('newScoreDate' + newScoreDate);
            console.log('latestScore' + latestScore);
            if (!newScoreDate) continue;

            if (!latestDate || newScoreDate > latestDate) {
                latestDate = newScoreDate;
                latestScore = Number(rawScore);
            }
        }

        return latestDate ? { date: latestDate, score: latestScore } : null;
    }
}