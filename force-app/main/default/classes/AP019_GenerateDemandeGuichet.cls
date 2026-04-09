public without sharing class AP019_GenerateDemandeGuichet {
    
    @invocableMethod(label='Générer demande guichet')
    public static List<FlowOutput> createDemandeGuichet(List<FlowInputs> params){
        String noteEllipro = null;
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();
        List<String> emailCCAddresses = new List<String>();
        FlowInputs param = params[0];
        List<Id> cvACDIds = new List<Id>();
        Demande_Cotation__c demandeCotiation = [SELECT  Signataire__r.Name, 
                                                        Account__r.Siret__c, 
                                                        Account__r.Name,
                                                        Account__c, 
                                                        Signataire__r.Title, 
                                                        Signataire__r.Phone, 
                                                        Signataire__r.Email 
                                                FROM Demande_Cotation__c
                                                WHERE Id = :param.DemandeCotation.Id];

        if (Test.isRunningTest()) {
            noteEllipro = '10';
        } else {
            List<ELLISPHERE__Elli_Assessement__c> Ellipro = [  SELECT ELLISPHERE__Elli_Tch_Score__c 
                                FROM ELLISPHERE__Elli_Assessement__c 
                                WHERE ELLISPHERE__Elli_Score_account__c = :demandeCotiation.Account__c
                                ORDER BY credit_score_date__c DESC];

            if (Ellipro.size() > 0) {
                noteEllipro = Ellipro[0].ELLISPHERE__Elli_Tch_Score__c;
            }
        }

        for (ContentVersion cvACD : [SELECT VersionData, FileExtension FROM ContentVersion WHERE ContentDocumentId IN :param.ContentDocumentIds AND IsLatest = true]) {
            cvACDIds.add(cvACD.Id);
        }

        // Construct the XML content for Excel
        String xmlContent = '<?xml version="1.0"?>' +
                            '<?mso-application progid="Excel.Sheet"?>' +
                            '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"' +
                            ' xmlns:o="urn:schemas-microsoft-com:office:office"' +
                            ' xmlns:x="urn:schemas-microsoft-com:office:excel"' +
                            ' xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">' +
                            '<Worksheet ss:Name="Sheet1">' +
                            '<Table>';

        // Add first header row
        xmlContent += '<Row>' +
                      '<Cell><Data ss:Type="String">RAISON SOCIALE</Data></Cell>' +
                      '<Cell><Data ss:Type="String">SIRET</Data></Cell>' +
                      '<Cell><Data ss:Type="String">NON & PRENOM</Data></Cell>' +
                      '<Cell><Data ss:Type="String">FONCTION</Data></Cell>' +
                      '<Cell><Data ss:Type="String">TELEPHONE</Data></Cell>' +
                      '<Cell><Data ss:Type="String">EMAIL</Data></Cell>' +
                      '</Row>';

        // Add data row with null coalescing operator
        xmlContent += '<Row>' +
                      '<Cell><Data ss:Type="String">' + (demandeCotiation.Account__r.Name ?? '') + '</Data></Cell>' +
                      '<Cell><Data ss:Type="String">' + (demandeCotiation.Account__r.Siret__c ?? '') + '</Data></Cell>' +
                      '<Cell><Data ss:Type="String">' + (demandeCotiation.Signataire__r.Name ?? '') + '</Data></Cell>' +
                      '<Cell><Data ss:Type="String">' + (demandeCotiation.Signataire__r.Title ?? '') + '</Data></Cell>' +
                      '<Cell><Data ss:Type="String">' + (demandeCotiation.Signataire__r.Phone ?? '') + '</Data></Cell>' +
                      '<Cell><Data ss:Type="String">' + (demandeCotiation.Signataire__r.Email ?? '') + '</Data></Cell>' +
                      '</Row>';

        // Add an empty row for a line break before the second header
        xmlContent += '<Row></Row>';

        // Add second header row
        xmlContent += '<Row>' +
                      '<Cell><Data ss:Type="String">SIRET PAYEUR</Data></Cell>' +
                      '<Cell><Data ss:Type="String">RAE</Data></Cell>' +
                      '<Cell><Data ss:Type="String">PCE</Data></Cell>' +
                      '<Cell><Data ss:Type="String">NOM DU SITE OU DE LA COPRO</Data></Cell>' +
                      '<Cell><Data ss:Type="String">NUMERO VOIE</Data></Cell>' +
                      '<Cell><Data ss:Type="String">VOIE</Data></Cell>' +
                      '<Cell><Data ss:Type="String">CODE POSTAL</Data></Cell>' +
                      '<Cell><Data ss:Type="String">COMMUNE</Data></Cell>' +
                      '<Cell><Data ss:Type="String">FOURNISSEUR ACTUEL</Data></Cell>' +
                      '<Cell><Data ss:Type="String">SEGMENT</Data></Cell>' +
                      '<Cell><Data ss:Type="String">CAR</Data></Cell>' +
                      '<Cell><Data ss:Type="String">PUISSANCE SOUSCRITE</Data></Cell>' +
                      '<Cell><Data ss:Type="String">DATE REPRISE CONTRAT</Data></Cell>' +
                      '</Row>';

        // Add more rows for other data if necessary with null coalescing operator
        for (PDE__c pde : param.SelectedPDEs) {
            xmlContent += '<Row>' +
                          '<Cell><Data ss:Type="String">' + (pde.Siret_payeur__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.ReferencePointEnergie_Refonte__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.PCE_Refonte__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.Name ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.NumeroVoie__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.voie__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.Code_Postal__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.Ville__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.fournisseur__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + (pde.Segment__c ?? '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + pde.TECH_CAR__c + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + ((pde.Puissance_souscrite__c != null) ? String.valueOf(pde.Puissance_souscrite__c) : '') + '</Data></Cell>' +
                          '<Cell><Data ss:Type="String">' + ((pde.DateEcheance__c != null) ? pde.DateEcheance__c.addDays(1).format() : '') + '</Data></Cell>' +
                          '</Row>';
        }

        // Close the XML content
        xmlContent += '</Table></Worksheet></Workbook>';

        Blob xmlBlob = Blob.valueOf(xmlContent);
        String fileName = 'Perimetre_' + demandeCotiation.Account__r.Name + '.xls';

        // Create email attachment
        Messaging.EmailFileAttachment xlsAttachment = new Messaging.EmailFileAttachment();
        xlsAttachment.setFileName(fileName);
        xlsAttachment.setBody(xmlBlob);
        xlsAttachment.setContentType('application/vnd.ms-excel');

        // Create subject and email body text
        String subject = param.TypeDemande.capitalize() + ' - ' + param.TypeEnergie + ' - ' + demandeCotiation.Account__r.Name + ' - ' + param.DateRetourSouhaitee.format();

        String emailBody = 'Bonjour,\n\n';
        emailBody += 'Vous trouverez ci-joint une ' + param.TypeDemande + ' pour la société ' + demandeCotiation.Account__r.Name;

        if (noteEllipro != null) { 
            emailBody += ', dont la note Ellipro est de ' + noteEllipro + '/10.\n'; 
        } else {
            emailBody += '.\n';
        }

        emailBody += 'Est-il possible de vous positionner pour le ' + param.DateRetourSouhaitee.format() + ' s\'il vous plait ?\n';

        if (param.DateDureeFourniture != null) {
            emailBody += 'Nous souhaitons une date de fin de fourniture au ' + param.DateDureeFourniture.format() + ', une offre de type ' + param.TypeOffre + ' et une marge à partager de ' + param.MargeSouhaitee + '.\n\n';
        } else {
            emailBody += 'Nous souhaitons une ' + param.DureeFourniture + ', une offre de type ' + param.TypeOffre + ' et une marge à partager de ' + param.MargeSouhaitee + '.\n\n';
        }

        if (param.Commentaire != '') {
            emailBody += 'Informations complémentaires : \n'; 
            emailBody += param.Commentaire + '\n\n';
        }

        emailBody += 'Pourriez-vous nous confirmer votre retour pour cette date, ou nous proposer une nouvelle date s\'il vous plait ? \n';
        emailBody += 'En vous remerciant,\n\n';

        // check and add email cc addresses
        if (!String.isBlank(param.EmailCC1)) emailCCAddresses.add(param.EmailCC1);
        if (!String.isBlank(param.EmailCC2)) emailCCAddresses.add(param.EmailCC2);
        if (!String.isBlank(param.EmailCC3)) emailCCAddresses.add(param.EmailCC3);
        if (!String.isBlank(param.EmailCC4)) emailCCAddresses.add(param.EmailCC4);
        if (!String.isBlank(param.EmailCC5)) emailCCAddresses.add(param.EmailCC5);

        // Create email and send it
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{param.EmailFournisseur});
        if (!emailCCAddresses.isEmpty()) { email.setCcAddresses(emailCCAddresses); }
        email.setSubject(subject);
        email.setPlainTextBody(emailBody);
        email.setCharset('utf-8');
        email.setUseSignature(true);
        email.setEntityAttachments(cvACDIds);
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{xlsAttachment});

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);

        if (results[0].success) {
            output.Success = true;
        } else {
            for (Messaging.SendEmailError error : results[0].errors) {
                System.debug('Error status code: ' + error.statusCode);
                System.debug('Error message: ' + error.message);
            }
            output.Success = false;
        }

        outputs.add(output);
        return outputs;
    }

    public class FlowInputs {
        @invocableVariable public Demande_Cotation__c DemandeCotation;
        @invocableVariable public List<Id> ContentDocumentIds;
        @invocableVariable public Date DateRetourSouhaitee;
        @invocableVariable public Date DateDureeFourniture;
        @invocableVariable public String DureeFourniture;
        @invocableVariable public String TypeDemande;
        @invocableVariable public String TypeOffre;
        @invocableVariable public String TypeEnergie;
        @invocableVariable public String MargeSouhaitee;
        @invocableVariable public String EmailFournisseur;
        @invocableVariable public String EmailCC1;
        @invocableVariable public String EmailCC2;
        @invocableVariable public String EmailCC3;
        @invocableVariable public String EmailCC4;
        @invocableVariable public String EmailCC5;
        @invocableVariable public String Commentaire;
        @invocableVariable public List<PDE__c> SelectedPDEs;
    }
    
    public class FlowOutput {
        @InvocableVariable public Boolean Success;
    }
}

// Create perimetre.csv
        // String formatRaisonSociale = demandeCotiation.Account__r.Name +'\t';
        // String formatSiret = demandeCotiation.Account__r.Siret__c +'\t';
        // String formatName = demandeCotiation.Signataire__r.Name +'\t';
        // String formatTitle = demandeCotiation.Signataire__r.Title +'\t';
        // String formatPhoneNumber = demandeCotiation.Signataire__r.Phone +'\t';
        
        // String csvString = 'RAISON SOCIALE;SIRET;NON & PRENOM;FONCTION;TELEPHONE;EMAIL\n';
        // csvString += formatRaisonSociale + ';' + formatSiret + ';' + formatName + ';' + formatTitle + ';' + formatPhoneNumber + ';' + demandeCotiation.Signataire__r.Email + '\n\n';
        // csvString += 'SIRET PAYEUR;RAE;PCE;NOM DU SITE OU DE LA COPRO;NUMERO VOIE;VOIE;CODE POSTAL;COMMUNE;FOURNISSEUR ACTUEL;SEGMENT;FTA;PUISSANCE SOUSCRITE;DATE ECHEANCE CONTRAT\n';

        // for (PDE__c pde : param.SelectedPDEs) {
        //     String RAE = pde.ReferencePointEnergie_Refonte__c == null ? '' : pde.ReferencePointEnergie_Refonte__c;
        //     String PCE = pde.PCE_Refonte__c == null ? '' : pde.PCE_Refonte__c;
        //     String FournisseurActuel = pde.fournisseur__c == null ? '' : pde.fournisseur__c;
        //     String NumeroVoie = pde.NumeroVoie__c == null ? '' : pde.NumeroVoie__c;
        //     String Segment = pde.Segment__c == null ? '' : pde.Segment__c;
        //     String FTA = pde.FTA__c == null ? '' : pde.FTA__c;
        //     String Puissance = pde.Puissance_souscrite__c == null ? '' : String.valueOf(pde.Puissance_souscrite__c);
        //     String dateEcheance = pde.DateEcheance__c == null ? '' : pde.DateEcheance__c.format();

        //     String formatSiretPayeur = pde.Siret_payeur__c +'\t';
        //     String formatRAE = RAE +'\t';
        //     String formatPCE = PCE +'\t';
        //     String formatPdeName = pde.Name +'\t';
        //     String formatNumeroVoie = NumeroVoie +'\t';
        //     String formatVoie = pde.voie__c +'\t';
        //     String formatCP = pde.Code_Postal__c +'\t';
        //     String formatVille = pde.Ville__c +'\t';
        //     String formatFournisseurActuel = FournisseurActuel +'\t';
        //     String formatSegment = Segment +'\t';
        //     String formatFTA = FTA +'\t';
        //     String formatPuissance = Puissance +'\t';

        //     csvString += formatSiretPayeur + ';' + formatRAE + ';' + formatPCE + ';' + formatPdeName + ';' + formatNumeroVoie + ';' + formatVoie + ';' + formatCP + ';' + formatVille + ';' + formatFournisseurActuel + ';' + formatSegment + ';' + formatFTA + ';' + formatPuissance + ';' + dateEcheance +'\n';
        // }

        // Blob csvBlob = Blob.valueOf(csvString);
        // String csvContent = '\ufeff' + csvBlob.toString(); // Forcer l'encodage UTF-8

        // Messaging.EmailFileAttachment csvFile = new Messaging.EmailFileAttachment();
        // csvFile.setFileName('Perimetre ' + demandeCotiation.Account__r.Name + '.csv');
        // csvFile.setBody(blob.valueOf(csvContent));
        // csvFile.setContentType('text/csv');