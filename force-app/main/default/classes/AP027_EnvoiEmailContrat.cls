public with sharing class AP027_EnvoiEmailContrat {

    // @AuraEnabled
    // public static List<Contact> getSignataire(Id accountId) {
      
    //     if (accountId == null) {
    //         System.debug('Account ID is null');
    //         return new List<Contact>();
    //     }
  
    //     List<Contact> signataires = [
    //         SELECT Id, Name, Email, Salutation, FirstName, LastName
    //         FROM Contact
    //         WHERE Id IN (
    //             SELECT ContactId
    //             FROM AccountContactRelation
    //             WHERE AccountId = :accountId AND Roles INCLUDES ('Signataire')
    //         )
    //     ];
  
    //     System.debug('Nombre de signataires trouvés : ' + signataires.size());
  
    //     return signataires; 
    // }

    public static Map<String, List<Contract>> getContractsGroupedBySignataire(List<Contract> contracts) {
    
        // Construire la map (Email du signataire -> Liste de contrats)
        Map<String, List<Contract>> signataireToContracts = new Map<String, List<Contract>>();

        for (Contract ctr : contracts) {
            String emailSignataire = ctr.Mail_signataire__c;

            if (emailSignataire != null) {
                // Ajouter l'email du signataire à la map s'il n'est pas encore présent
                if (!signataireToContracts.containsKey(emailSignataire)) {
                    signataireToContracts.put(emailSignataire, new List<Contract>());
                }
                // Ajouter le contrat à la liste correspondante
                signataireToContracts.get(emailSignataire).add(ctr);
            }
        }
    
        return signataireToContracts;
    }
    
    public static String formatDate(Date ladate) {
        String day = (ladate.day() < 10 ? '0' : '') + ladate.day();
        String month = (ladate.month() < 10 ? '0' : '') + ladate.month();
        return day + '/' + month + '/' + ladate.year();
    }
    
/*
    public static String generateICSFileAndUpload(List<Contract> contrats) {
        //  Génération du fichier ICS
        String icsData = 'BEGIN:VCALENDAR\n' +
                         'VERSION:2.0\n' +
                         'PRODID:-//Salesforce//FR\n';
    
        for (Contract contrat : contrats) {
            if (contrat.Date_echeance__c == null) continue;
                //  Calcul de la date du rappel (3 mois avant l'échéance à 10h00)
                Date rappelDate = contrat.Date_echeance__c.addMonths(-3);
                Datetime rappelDateTime = Datetime.newInstance(rappelDate, Time.newInstance(10, 0, 0, 0));
                //  Ajouter un nouvel événement
                icsData += 'BEGIN:VEVENT\n';
                icsData += 'UID:' + contrat.Id + '@salesforce.com\n';
                icsData += 'DTSTAMP:' + Datetime.now().formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'') + '\n';
                icsData += 'DTSTART:' + rappelDateTime.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'') + '\n';
                icsData += 'DTEND:' + rappelDateTime.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'') + '\n';
                icsData += 'SUMMARY:Échéance de votre contrat ' + contrat.ContractNumber + '\n';
                icsData += 'DESCRIPTION:Votre contrat ' + contrat.ContractNumber + ' arrive à échéance. Contactez-nous pour renouveler dans les meilleures conditions.\n';
                icsData += 'LOCATION:Votre agence Alliance des Énergies\n';
                icsData += 'END:VEVENT\n';
        }
        icsData += 'END:VCALENDAR';
    
    
        try {
            // Création du fichier ICS dans Salesforce (ContentVersion)
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = 'Rappels_Contrats.ics';
            contentVersion.PathOnClient = 'Rappels_Contrats.ics';
            contentVersion.VersionData = Blob.valueOf(icsData);
            contentVersion.IsMajorVersion = true;
            insert contentVersion;
    
            // Récupération de l'ID du fichier stocké (correction du type)
            ContentVersion insertedCV = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1];
            String fileId = insertedCV.ContentDocumentId;
    
            // Génération de l'URL publique du fichier ICS (correction de l'URL)
            String icsFileUrl = System.Url.getOrgDomainUrl().toExternalForm() + '/sfc/servlet.shepherd/document/download/' + fileId;
            List<Contract> tmp = new List<Contract>();
            for (Contract contrat : contrats) {
                contrat.Envoi_Validation_Email__c = true;
                contrat.Date_Envoi_Validation_Email__c = Date.today();
                tmp.add(contrat);
            }
            // Mise à jour du contrat avec l'URL du fichier
            update tmp;
    
            return icsFileUrl;
        } catch (Exception e) {
            System.debug(' Erreur lors de l’upload ICS: ' + e.getMessage());
            return null;
        }
    }
*/

    // EnvoiMail
    @InvocableMethod(label='Envoi Mail')
    public static List<FlowOutput> EnvoiMail(List<FlowInputs> flowInputs)   {
        
        FlowInputs flowInput = flowInputs.get(0);
        Set<String> setContratIds = new Set<String>();

        List<FlowOutput> listOutput = new List<FlowOutput>();
        FlowOutput output = new FlowOutput();

        setContratIds.addAll(flowInput.listContratIds);

        String emailBody;
        User commercial;
        Contract tmp;

        

        List<Contract> contracts = [SELECT Id,
                                        AccountId,
                                        Commercial__c,
                                        ContractNumber,
                                        Mail_signataire__c,
                                        Nom_signataire__c,
                                        Prenom_signataire__c,
                                        FournisseurPicklist__c,
                                        Type_energie__c,
                                        startDate,
                                        Date_echeance__c,
                                        Envoi_Validation_Email__c,
                                        Date_Envoi_Validation_Email__c
                                    FROM Contract
                                    WHERE Id IN :setContratIds
                                    AND Source__r.Name != 'LE CEDRE'];

        //String emailSignataire = contracts.get(0).Mail_signataire__c;

        for(Contract co : contracts) {
            if(co.Envoi_Validation_Email__c)    {
                FlowOutput outp = new FlowOutput();
                outp.message = 'Email de validation déjà envoyé pour le contrat : ' + co.ContractNumber;
                listOutput.add(outp);
                return listOutput;
            }
        }

        
        if(!contracts.isEmpty())    {

            // List<Contact> contacts = getSignataire(contracts.get(0).AccountId);

            Map<String, List<Contract>> mapsignataire = getContractsGroupedBySignataire(contracts);

            for (String emailSignataire : mapsignataire.keySet()) {
                List<Contract> contratsignataire = mapsignataire.get(emailSignataire);
            


                emailBody = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" '
                + '"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">'
                + '<html dir="ltr" xmlns="http://www.w3.org/1999/xhtml" xmlns:o="urn:schemas-microsoft-com:office:office" lang="fr">'
                + '<head>'
                + '<meta charset="UTF-8">'
                + '<meta content="width=device-width, initial-scale=1" name="viewport">'
                + '<meta name="x-apple-disable-message-reformatting">'
                + '<meta http-equiv="X-UA-Compatible" content="IE=edge">'
                + '<meta content="telephone=no" name="format-detection">'
                +   '<title>Merci pour votre confiance – Alliance des Énergies</title><!--[if (mso 16)]>'
                +       '<style type="text/css">'
                +           'a {text-decoration: none;}'
                +       '</style>'
                +       '<![endif]--><!--[if gte mso 9]><style>sup { font-size: 100% !important; }</style><![endif]--><!--[if gte mso 9]>'
                +       '<noscript>'
                +           '<xml>'
                +               '<o:OfficeDocumentSettings>'
                +               '<o:AllowPNG></o:AllowPNG>'
                +               '<o:PixelsPerInch>96</o:PixelsPerInch>'
                +               '</o:OfficeDocumentSettings>'
                +           '</xml>'
                +        '</noscript>'
                +        '<![endif]--><!--[if mso]><xml>'
                +       '<w:WordDocument xmlns:w="urn:schemas-microsoft-com:office:word">'
                +           '<w:DontUseAdvancedTypographyReadingMail/>'
                +       '</w:WordDocument>'
                +       '</xml><![endif]-->'
                +       '<style type="text/css">.rollover:hover .rollover-first {'
                +           'max-height:0px!important;'
                +           'display:none!important;'
                +       '}'
                +       '.rollover:hover .rollover-second {'
                +           'max-height:none!important;'
                +           'display:block!important;'
                +       '}'
                +       '.rollover span {'
                +           'font-size:0px;'
                +       '}'
                +       'u + .body img ~ div div {'
                +           'display:none;'
                +       '}'
                +       '#outlook a {'
                +           'padding:0;'
                +       '}'
                +       'span.MsoHyperlink,'
                +       'span.MsoHyperlinkFollowed {'
                +           'color:inherit;'
                +           'mso-style-priority:99;'
                +       '}'
                +       'a.bi {'
                +           'mso-style-priority:100!important;'
                +           'text-decoration:none!important;'
                +       '}'
                +       'a[x-apple-data-detectors],'
                +       '#MessageViewBody a {'
                +           'color:inherit!important;'
                +           'text-decoration:none!important;'
                +           'font-size:inherit!important;'
                +           'font-family:inherit!important;'
                +           'font-weight:inherit!important;'
                +           'line-height:inherit!important;'
                +       '}'
                +       '.y {'
                +           'display:none;'
                +           'float:left;'
                +           'overflow:hidden;'
                +           'width:0;'
                +           'max-height:0;'
                +           'line-height:0;'
                +           'mso-hide:all;'
                +       '}'
                ;

                emailBody += '@media only screen and (max-width:600px) {.bz { padding:10px!important } .by { padding-top:0px!important } .bx { padding-bottom:20px!important }  *[class="gmail-fix"] { display:none!important } p, a { line-height:150%!important } h1, h1 a { line-height:120%!important } h2, h2 a { line-height:120%!important } h3, h3 a { line-height:120%!important } h4, h4 a { line-height:120%!important } h5, h5 a { line-height:120%!important } h6, h6 a { line-height:120%!important } .bv p { } .bu p { margin-bottom:16px!important } .bt p { }  h1 { font-size:30px!important; text-align:left; margin-bottom:18px!important } h2 { font-size:24px!important; text-align:left; margin-bottom:15px!important } h3 { font-size:20px!important; text-align:left; margin-bottom:12px!important } h4 { font-size:24px!important; text-align:left; margin-bottom:15px!important } h5 { font-size:20px!important; text-align:left; margin-bottom:12px!important } h6 { font-size:16px!important; text-align:left; margin-bottom:10px!important }        .bv p, .bv a { font-size:14px!important } .bu p, .bu a { font-size:16px!important } .bt p, .bt a { font-size:14px!important }  .bp, .bp h1, .bp h2, .bp h3, .bp h4, .bp h5, .bp h6 { text-align:center!important }     .bo .rollover:hover .rollover-second, .bp .rollover:hover .rollover-second, .bq .rollover:hover .rollover-second { display:inline!important }  .bn { display:inline-table }    .bh, .bh .bi, .bj, .bj td, .w { display:inline-block!important } .be table, .bf, .bg { width:100%!important } .bb table, .bc table, .bd table, .bb, .bd, .bc { width:100%!important; max-width:600px!important } .adapt-img { width:100%!important; height:auto!important } .z, .ba { display:none!important }      table.v, .esd-block-html table { width:auto!important } .h-auto { height:auto!important } .img-5877 { width:160px!important; height:auto!important } .img-4270 { width:80px!important; height:auto!important }  .r .s.t, .r .s.t * { font-size:20px!important; line-height:150%!important } .q .b, .q .b * { font-size:14px!important; line-height:150%!important } .p .b, .p .b * { font-size:14px!important; line-height:150%!important } .o .b, .o .b * { font-size:14px!important; line-height:150%!important } .n .b, .n .b * { font-size:14px!important; line-height:150%!important } .m .b, .m .b * { font-size:14px!important; line-height:150%!important } .l .b, .l .b * { font-size:14px!important; line-height:150%!important } .k .b, .k .b * { font-size:14px!important; line-height:150%!important } .j .b, .j .b * { font-size:14px!important; line-height:150%!important } .i .b, .i .b * { font-size:14px!important; line-height:150%!important } .h .b, .h .b * { font-size:14px!important; line-height:150%!important } .g .b, .g .b * { font-size:14px!important; line-height:150%!important } .f .b, .f .b * { font-size:14px!important; line-height:150%!important } .e .b, .e .b * { font-size:14px!important; line-height:150%!important } .d .b, .d .b * { font-size:14px!important; line-height:150%!important } .c .b, .c .b * { font-size:14px!important; line-height:150%!important } .a .b, .a .b * { font-size:14px!important; line-height:150%!important } }'
                +       '@media screen and (max-width:384px) {.mail-message-content { width:414px!important } }</style>'
                +       '<body class="body" style="width:100%;height:100%;-webkit-text-size-adjust:100%;-ms-text-size-adjust:100%;padding:0;Margin:0"><span style="color:#ffffff;visibility:hidden;height:0;mso-hide:all;display:none !important;opacity:0;line-height:0;width:0;font-size:0px">Alliance des Énergies vous remercie de votre confiance pour la négociation de vos contrats d’énergie.</span>'
                +           '<div dir="ltr" class="es-wrapper-color" lang="fr" style="background-color:#D2E8E9"><!--[if gte mso 9]>'
                +               '<v:background xmlns:v="urn:schemas-microsoft-com:vml" fill="t">'
                +               '<v:fill type="tile" src="https://ecovfaj.stripocdn.email/content/guids/CABINET_01daba8992a1ccc1f969612fe3fee01e8f867b16e7ad71a4424fa872ab0c74fe/images/vermicelles_bleuciel.png" color="#d2e8e9" origin="0.5, 0" position="0.5, 0"></v:fill>'                              
                +               '</v:background>'
                +           '<![endif]-->'
                +               '<table width="100%" cellspacing="0" cellpadding="0" background="https://ecovfaj.stripocdn.email/content/guids/CABINET_01daba8992a1ccc1f969612fe3fee01e8f867b16e7ad71a4424fa872ab0c74fe/images/vermicelles_bleuciel.png" class="es-wrapper" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;padding:0;Margin:0;width:100%;height:100%;background-image:url(https://ecovfaj.stripocdn.email/content/guids/CABINET_01daba8992a1ccc1f969612fe3fee01e8f867b16e7ad71a4424fa872ab0c74fe/images/vermicelles_bleuciel.png);background-repeat:repeat;background-position:center top;background-size:contain;background-color:#D2E8E9">'
                +                   '<tr>'
                +                       '<td valign="top" class="bz" style="padding:0;Margin:0">'
                +                           '<table cellspacing="0" cellpadding="0" align="center" background class="bc" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important;background-color:transparent;background-repeat:repeat;background-position:center top">'
                +                               '<tr>'
                +                                   '<td align="center" style="padding:0;Margin:0">'
                +                                       '<table cellspacing="0" cellpadding="0" bgcolor="transparent" align="center" class="bv" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:transparent;width:680px" role="none">'
                +                                           '<tr>'
                +                                               '<td align="left" class="by" style="padding:0;Margin:0;padding-top:20px;padding-right:20px;padding-left:20px">'
                +                                                   '<table width="100%" cellspacing="0" cellpadding="0" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                                       '<tr>'
                +                                                           '<td valign="top" align="center" style="padding:0;Margin:0;width:640px">'
                +                                                               '<table width="100%" cellspacing="0" cellpadding="0" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                                                   '<tr>'
                +                                                                       '<td align="center" style="padding:0;Margin:0;padding-bottom:10px"><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:18.2px;letter-spacing:0;color:#27457A;font-size:14px;"><br></p></td>'
                +                                                                   '</tr>'
                +                                                                '</table>'
                +                                                           '</td>'
                +                                                       '</tr>'
                +                                                   '</table>'
                +                                               '</td>'
                +                                           '</tr>'
                +                                       '</table>'
                +                                   '</td>'
                +                               '</tr>'
                +                           '</table>'
                +                           '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important">'
                +                               '<tr>'
                +                                   '<td align="center" style="padding:0;Margin:0">'
                +                                       '<table cellspacing="0" cellpadding="0" bgcolor="transparent" align="center" class="bu" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:transparent;width:680px" role="none">'
                +                                           '<tr>'
                +                                               '<td align="left" style="padding:0;Margin:0">'
                +                                                   '<table cellspacing="0" cellpadding="0" width="100%" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                                       '<tr>'
                +                                                           '<td valign="top" align="center" style="padding:0;Margin:0;width:680px">'
                +                                                               '<table width="100%" cellspacing="0" cellpadding="0" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                                                   '<tr>'
                +                                                                       '<td align="center" style="padding:0;Margin:0;font-size:0"><a target="_blank" href="https://alliancedesenergies.fr" style="mso-line-height-rule:exactly;text-decoration:underline;color:#E56633;font-size:17px"><img src="https://alliancedesenergies.cdn.salesforce-experience.com/cms/delivery/media/MC37546R3ZP5C3ZBOGB5VOARHAX4?oid=00D2o000000srHzEAI&channelId=0ap2o0000008fRuAAI" alt="Merci pour votre confiance - Alliance des Énergies" width="680" title="Merci pour votre confiance - Alliance des Énergies" class="adapt-img" style="display:block;font-size:17px;border:0;outline:none;text-decoration:none;border-radius:4px 4px 0 0" height="227"></a></td>'
                +                                                                   '</tr>'
                +                                                               '</table></td>'
                +                                                       '</tr>'
                +                                                   '</table></td>'
                +                                           '</tr>'
                +                                       '</table></td>'
                +                               '</tr>'
                +                           '</table>'
                +                           '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important">'
                +                               '<tr>'
                +                                   '<td align="center" style="padding:0;Margin:0">'
                +                                       '<table cellspacing="0" cellpadding="0" bgcolor="#ffffff" align="center" class="bu" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:#FFFFFF;width:680px">'
                +                                           '<tr>'
                +                                               '<td align="left" style="padding:0;Margin:0;padding-top:20px;padding-right:20px;padding-left:20px">'
                +                                                   '<table cellspacing="0" cellpadding="0" width="100%" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                                       '<tr>'
                +                                                           '<td valign="top" align="center" style="padding:0;Margin:0;width:640px">'
                +                                                               '<table width="100%" cellspacing="0" cellpadding="0" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                                                   '<tr>'
                                                                                       + '<td align="left" style="padding:0;Margin:0"><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px">Bonjour [CONTACT_NAME],</p><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px">Je tiens à vous remercier d\'avoir fait appel à Alliance des Énergies pour la négociation de vos contrats d\'énergie. Nous sommes ravis de vous accompagner dans cette démarche.<br><br>En tant que client, vous bénéficiez également d\'un service assuré par notre marque PEP\'S, pour améliorer durablement votre performance énergétique : optimisation de vos consommations, réduction durable de vos dépenses et identification des aides financières mobilisables pour vos projets de transition énergétique. Pour être accompagné par nos experts, vous pouvez consulter directement <a href="https://alliancedesenergies.fr/?utm_source=mail&utm_medium=email&utm_campaign=ouverture-compte-ade#peps" target="_blank" style="color:#E56633; text-decoration:underline;">notre page dédiée</a> sur notre site.</p><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px">Voici les informations concernant votre nouveau contrat d\'énergie :</p></td>'
                +                                                                   '</tr>'
                +                                                               '</table></td>'
                +                                                       '</tr>'
                +                                                   '</table></td>'
                +                                           '</tr>'
                +                                       '</table></td>'
                +                               '</tr>'
                +                           '</table>'
                +                       '</td>'
                +                   '</tr>'
                +               '</table>'        
                ;

                emailBody += '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important">'
                +                   '<tr>'
                +                       '<td align="center" bgcolor="transparent" style="padding:0;Margin:0">'
                +                           '<table bgcolor="#ffffff" align="center" cellpadding="0" cellspacing="0" class="bu" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:#FFFFFF;width:680px;border-bottom:1px solid #a2d9e0" role="none">'        
                +                               '<tr>'
                ;

                emailBody = emailBody.replace('[CONTACT_NAME]',(contratsignataire.get(0).Prenom_signataire__c != null ? contratsignataire.get(0).Prenom_signataire__c : '') + ' ' +(contratsignataire.get(0).Nom_signataire__c != null ? contratsignataire.get(0).Nom_signataire__c : ''));

                for (Contract c : contratsignataire) {  // contracts
                    //
                    tmp = c;

                    String startDateFormatted = formatDate(c.StartDate);
                    String endDateFormatted = formatDate(c.Date_echeance__c);

                    String type_energie = c.Type_energie__c == 'Elec' ? 'Electricité' : c.Type_energie__c;
                    
                    String rowColor = (Math.Mod(contratsignataire.indexOf(c), 2) == 0) ? null : '#f4fafb';
                    
                    emailBody += '<td ' + (rowColor != null ? 'bgcolor="' + rowColor + '"' : '') + ' align="left" style="padding:0;Margin:0;padding-top:20px;padding-right:20px;padding-left:20px"><!--[if mso]><table style="width:640px" cellpadding="0" cellspacing="0"><tr><td style="width:165px" valign="top"><![endif]-->'
                    +                                       '<table cellspacing="0" align="left" cellpadding="0" class="bf" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;float:left">'
                    +                                           '<tr>'
                    +                                               '<td align="left" class="bx" style="padding:0;Margin:0;width:145px">'
                    +                                                    '<table cellspacing="0" width="100%" role="presentation" cellpadding="0" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                    +                                                       '<tr>'
                    +                                                           '<td align="left" class="q" style="padding:0;Margin:0"><p class="b" style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:18.2px;letter-spacing:0;color:#27457a;font-size:14px;margin-bottom:16px">Contrat N° <strong>' + c.ContractNumber + '</strong><br></p></td>'
                    +                                                       '</tr>'
                    +                                                   '</table>'
                    +                                               '</td>'
                    +                                               '<td class="ba" style="padding:0;Margin:0;width:20px"></td>'
                    +                                           '</tr>'
                    +                                       '</table><!--[if mso]></td><td style="width:145px" valign="top"><![endif]-->'
                    +                                       '<table cellpadding="0" cellspacing="0" align="left" class="bf" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;float:left">'
                    +                                           '<tr>'
                    +                                               '<td align="left" class="bx" style="padding:0;Margin:0;width:145px">'
                    +                                                    '<table cellspacing="0" width="100%" role="presentation" cellpadding="0" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                    +                                                       '<tr>'
                    +                                                           '<td align="left" class="q" style="padding:0;Margin:0"><p class="b" style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:18.2px;letter-spacing:0;color:#27457a;font-size:14px;margin-bottom:16px">' + c.FournisseurPicklist__c + '</strong><br></p></td>'
                    +                                                       '</tr>' 
                    +                                                   '</table>' 
                    +                                               '</td>'
                    +                                               '<td class="ba" style="padding:0;Margin:0;width:20px"></td>'
                    +                                           '</tr>'
                    +                                       '</table><!--[if mso]></td><td style="width:145px" valign="top"><![endif]-->'
                    +                                       '<table cellpadding="0" cellspacing="0" align="left" class="bf" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;float:left">'
                    +                                           '<tr>'
                    +                                               '<td align="left" class="bx" style="padding:0;Margin:0;width:145px">'
                    +                                                   '<table cellpadding="0" cellspacing="0" width="100%" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                    +                                                       '<tr>'
                    +                                                           '<td align="left" class="i" style="padding:0;Margin:0"><p class="b" style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:18.2px;letter-spacing:0;color:#27457a;font-size:14px;margin-bottom:16px"><strong>' + type_energie  + '</strong></p></td>'
                    +                                                       '</tr>'
                    +                                                   '</table>'
                    +                                                '</td>'
                    +                                           '</tr>'
                    +                                       '</table><!--[if mso]></td><td style="width:20px"></td><td style="width:145px" valign="top"><![endif]-->'
                    +                                       '<table align="right" cellpadding="0" cellspacing="0" class="bg" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;float:right">'
                    +                                           '<tr>'
                    +                                               '<td align="left" style="padding:0;Margin:0;width:145px">'
                    +                                                   '<table cellpadding="0" cellspacing="0" width="100%" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                    +                                                       '<tr>'
                    +                                                           '<td align="left" class="e" style="padding:0;Margin:0"><p class="b" style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:18.2px;letter-spacing:0;color:#27457a;font-size:14px;margin-bottom:16px">Du : <strong>' + startDateFormatted +'</strong><br>Au : <strong>' + endDateFormatted + '</strong></p></td>'
                    +                                                       '</tr>'
                    +                                                   '</table>'
                    +                                               '</td>'
                    +                                           '</tr>'
                    +                                       '</table><!--[if mso]></td></tr></table><![endif]--></td>'
                    + '</tr>'
                    ;
            
                }
                
                emailBody +=                                   
                +                                  '</table>'
                +                                  '</td>'
                +                                  '</tr>'
                + '</table>';

                

                emailBody += '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important">'
                +   '<tr>'
                +       '<td align="center" bgcolor="transparent" style="padding:0;Margin:0">'
                +           '<table align="center" cellpadding="0" cellspacing="0" bgcolor="#ffffff" class="bu" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:#FFFFFF;width:680px">'
                +               '<tr>'
                +                   '<td align="left" style="padding:0;Margin:0;padding-top:20px;padding-right:20px;padding-left:20px">'
                +                       '<table cellspacing="0" width="100%" cellpadding="0" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                           '<tr>'
                +                               '<td align="left" style="padding:0;Margin:0;width:640px">'
                +                                   '<table cellpadding="0" cellspacing="0" width="100%" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                       '<tr>'
                +                                           '<td align="left" style="padding:0;Margin:0"><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px">Nous vous avons proposé l’offre la plus adaptée à vos besoins, issue d\'une analyse approfondie de votre profil énergétique et des tendances du marché.&nbsp;</p><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px">Si un fournisseur d’énergie vous sollicite directement, sachez que nous assurons une veille permanente du marché et mettons systématiquement en concurrence l’ensemble des acteurs, afin de vous garantir en toute transparence les meilleures conditions possibles. Grâce à notre expertise et à notre pouvoir de négociation, vous bénéficiez des offres les plus avantageuses.</p><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px">Je reste à votre disposition pour répondre à toutes vos questions et vous accompagner dans vos prochaines démarches.</p></td>'
                +                                       '</tr>'
                +                                   '</table></td>'
                +                             '</tr>'
                +                        '</table></td>'
                +                '</tr>'
                +               '<tr>'
                +                   '<td align="left" style="padding:0;Margin:0;padding-top:20px;padding-right:20px;padding-left:20px">'
                +                       '<table align="left" cellpadding="0" cellspacing="0" class="bf" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;float:left">'
                +                           '<tr>'
                +                               '<td align="left" style="padding:0;Margin:0;width:640px">'
                +                                   '<table cellspacing="0" width="100%" role="presentation" cellpadding="0" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                       '<tr>'
                +                                           '<td align="center" style="padding:0;Margin:0;font-size:0"><a target="_blank" href="https://g.page/r/CbA2ehesViGyEB0/review" style="mso-line-height-rule:exactly;text-decoration:underline;color:#E56633;font-size:17px"><img height="100" src="https://alliancedesenergies.cdn.salesforce-experience.com/cms/delivery/media/MCG5HKDV55PBAWPHCTYKMSBIUUEU?oid=00D2o000000srHzEAI&channelId=0ap2o0000008fRuAAI" alt="" class="adapt-img" width="344" style="display:block;font-size:17px;border:0;outline:none;text-decoration:none"></a></td>'
                +                                       '</tr>'
                +                                   '</table></td>'
                +                            '</tr>'
                +                       '</table></td>'
                +               '</tr>'
                +               '<tr>'
                +                   '<td align="left" style="padding:0;Margin:0;padding-top:20px;padding-right:20px;padding-left:20px">'
                +                       '<table cellspacing="0" width="100%" cellpadding="0" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                           '<tr>'
                +                               '<td align="left" style="padding:0;Margin:0;width:640px">'
                +                                   '<table cellpadding="0" cellspacing="0" width="100%" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                       '<tr>'
                +                                           '<td align="left" style="padding:0;Margin:0"><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px">Nous espérons que notre accompagnement vous a été utile et efficace.</p><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px">N’hésitez pas à recommander <strong>Alliance des Énergies</strong> à vos partenaires et collaborateurs, ou à nous contacter pour toute question supplémentaire.</p><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, \'helvetica neue\', helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000B18;font-size:17px;margin-bottom:16px"><strong>Encore merci pour votre confiance, et à très bientôt !</strong></p></td>'
                +                                       '</tr>'
                +                                   '</table></td>'
                +                            '</tr>'
                +                       '</table></td>'
                +               '</tr>'
                +                   '</table></td>'
                +               '</tr>'
                +           '</table>'
                ;
                
        
                emailBody += '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important">'
                +       '<tr>'
                +           '<td align="center" bgcolor="transparent" style="padding:0;Margin:0">'
                +               '<table cellpadding="0" cellspacing="0" bgcolor="#ffffff" align="center" class="bu" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:#FFFFFF;width:680px;border-bottom:1px solid #a2d9e0" role="none">'
                +                   '<tr>'
                +                       '<td align="left" style="padding:0;Margin:0;padding-top:20px;padding-right:20px;padding-left:20px">'
                +                           '<table width="100%" cellpadding="0" cellspacing="0" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                               '<tr>'
                +                                   '<td align="left" style="padding:0;Margin:0;width:640px">'
                +                                       '<!--<table width="100%" role="presentation" cellpadding="0" cellspacing="0" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                           '<tr>'
                +                                               '<td align="left" style="padding:0;Margin:0;padding-right:20px;padding-bottom:20px;font-size:0">'
                +                                                   '<table width="220px" height="100%" cellpadding="0" cellspacing="0" border="0" class="bn" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                                       '<tr>'
                +                                                           '<td style="padding:0;Margin:0;margin:0px;border-bottom:2px solid #a2d9e0;background:none;height:0px;width:100%"></td>'
                +                                                       '</tr>'
                +                                                   '</table>--></td>'
                +                                           '</tr>'
                +                                           '<tr>'
                +                                               '<td align="left" style="padding:0;Margin:0;padding-bottom:10px;font-size:0"><img alt="" width="210" src="https://alliancedesenergies.cdn.salesforce-experience.com/cms/delivery/media/MCLLZRHKLUCNEY3IG4AICDLUDCUM?oid=00D2o000000srHzEAI&amp;channelId=0ap2o0000008fRuAAI" class="img-5877 adapt-img" height="40" style="display:block;font-size:17px;border:0;outline:none;text-decoration:none"></td>'
                +                                           '</tr>'
                +                                           '<tr>'
                +                                               '<td align="left" style="padding:0;Margin:0"><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, &quot;helvetica neue&quot;, helvetica, sans-serif;line-height:22.1px;letter-spacing:0;color:#000b18;font-size:17px;margin-bottom:16px;">Service Client<br>Votre consultant : <strong style="color:#27457a">[COMMERCIAL_NAME]</strong> <br>[COMMERCIAL_EMAIL]<br>Portable : [COMMERCIAL_PHONE]<br> Standard : 04 72 82 99 28</p></td>'
                +                                           '</tr>'
                +                                       '</table></td>'
                +                               '</tr>'
                +                       '</table></td>'
                +               '</tr>'
                +           '</table></td>'
                +       '</tr>'
                +   '</table>'
                ;
                
                emailBody += '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important">'
                +       '<tr>'
                +          '<td align="center" bgcolor="transparent" style="padding:0;Margin:0">'
                +               '<table cellpadding="0" cellspacing="0" bgcolor="#ffffff" align="center" class="bu" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:#FFFFFF;width:680px;border-bottom:1px solid #a2d9e0" role="none">'
                +                   '<tr>'
                +                       '<td align="left" style="padding:20px;Margin:0">'
                +                           '<table width="100%" cellpadding="0" cellspacing="0" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                               '<tr>'
                +                                   '<td align="left" style="padding:0;Margin:0;width:640px">'
                +                                       '<table width="100%" role="presentation" cellpadding="0" cellspacing="0" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                           '<tr>'
                +                                               '<td align="center" style="padding:0;Margin:0;font-size:0"><a target="_blank" href="https://alliancedesenergies.fr/?utm_source=mail&utm_medium=email&utm_campaign=ouverture-compte-ade#peps" style="mso-line-height-rule:exactly;text-decoration:underline;color:#E56633;font-size:17px"><img width="640" src="https://alliancedesenergies.cdn.salesforce-experience.com/cms/delivery/media/MC224I7MSKOJB4DEQQB6X4UQ6XAM?oid=00D2o000000srHzEAI&channelId=0ap2o0000008fRuAAI" alt="Réduisez vos coûts et votre impact environnemental avec PEP\'S" title="Réduisez vos coûts et votre impact environnemental avec PEP\'S" class="adapt-img" style="display:block;font-size:17px;border:0;outline:none;text-decoration:none;border-radius:4px" height="224"></a></td>'
                +                                           '</tr>'
                +                                           '<tr>'
                +                                               '<td align="center" style="padding:0; margin:0; padding-top:20px;"><h3 class="bp" style="margin:0; font-family:arial, &quot;helvetica neue&quot;, helvetica, sans-serif; mso-line-height-rule:exactly; letter-spacing:0; font-size:22px; font-style:normal; font-weight:bold; line-height:26.4px; color:#27457A; margin-bottom:12px;">Partenariat</h3></td>'
                +                                           '</tr>'
                +                                           '<tr>'
                +                                               '<td align="center" style="padding:0;Margin:0;font-size:0"><a target="_blank" href="https://alliancedesenergies.my.site.com/adhesion/s/symposium?c=[URL_SYMPOSIUM]" style="mso-line-height-rule:exactly;text-decoration:underline;color:#E56633;font-size:17px"><img src="https://alliancedesenergies.cdn.salesforce-experience.com/cms/delivery/media/MCYNVP4SJNYZHFZASRZOSGJRP5WY?oid=00D2o000000srHzEAI&channelId=0ap2o0000008fRuAAI" alt="Optimisez vos frais généraux avec notre platefoeme d\'achats négociés et économisez jusqu\'à 25%!" width="640" title="Optimisez vos frais généraux avec notre platefoeme d\'achats négociés et économisez jusqu\'à 25%!" class="adapt-img" style="display:block;font-size:17px;border:0;outline:none;text-decoration:none;border-radius:4px" height="213"></a></td>'
                +                                           '</tr>'
                +                                       '</table></td>'
                +                               '</tr>'
                +                           '</table></td>'
                +                   '</tr>'
                +               '</table></td>'
                +       '</tr>'
                +   '</table>'
                ;
                
                emailBody += '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important">'
                +       '<tr>'
                +           '<td align="center" bgcolor="transparent" style="padding:0;Margin:0">'
                +               '<table cellpadding="0" cellspacing="0" bgcolor="transparent" align="center" class="bu" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:transparent;width:680px" role="none">'
                +                   '<tr>'
                +                       '<td align="left" bgcolor="#ffffff" style="padding:20px;Margin:0;border-radius:0 0 4px 4px;background-color:#ffffff">'
                +                           '<table cellspacing="0" width="100%" cellpadding="0" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                               '<tr>'
                +                                   '<td align="left" style="padding:0;Margin:0;width:640px">'
                +                                       '<table role="presentation" cellpadding="0" cellspacing="0" width="100%" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                           '<tr>'
                +                                               '<td align="left" class="r" style="padding:0;Margin:0"><h4 align="center" class="bp t s" style="Margin:0;font-family:arial, &quot;helvetica neue&quot;, helvetica, sans-serif;mso-line-height-rule:exactly;letter-spacing:0;font-size:20px;font-style:normal;font-weight:bold;line-height:24px !important;color:#27457A;margin-bottom:15px;">Retrouvez-nous aussi sur</h4></td>'
                +                                           '</tr>'
                +                                           '<tr>'
                +                                               '<td align="center" style="padding:0;Margin:0;padding-bottom:10px;font-size:0">'
                +                                                  '<table cellpadding="0" cellspacing="0" class="v bj" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                                       '<tr>'
                +                                                           '<td align="center" valign="top" style="padding:0;Margin:0;padding-right:20px"><a target="_blank" href="https://www.linkedin.com/company/alliance-des-energies/" style="mso-line-height-rule:exactly;text-decoration:underline;color:#E56633;font-size:17px"><img title="Linkedin" src="https://ecovfaj.stripocdn.email/content/assets/img/social-icons/circle-colored/linkedin-circle-colored.png" alt="In" width="34" height="34" style="display:block;font-size:17px;border:0;outline:none;text-decoration:none"></a></td>'
                +                                                               '<td align="center" valign="top" style="padding:0;Margin:0"><a target="_blank" href="https://www.youtube.com/@alliancedesenergies" style="mso-line-height-rule:exactly;text-decoration:underline;color:#E56633;font-size:17px"><img height="34" title="Youtube" src="https://ecovfaj.stripocdn.email/content/assets/img/social-icons/circle-colored/youtube-circle-colored.png" alt="Yt" width="34" style="display:block;font-size:17px;border:0;outline:none;text-decoration:none"></a></td>'
                +                                                       '</tr>'
                +                                                   '</table></td>'
                +                                           '</tr>'
                +                                       '</table></td>'
                +                               '</tr>'
                +                           '</table></td>'
                +                   '</tr>'
                +               '</table></td>'
                +       '</tr>'
                +   '</table>'
                ;
        
                
                emailBody += '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                +   '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                +   '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                +   '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                +   '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                +   '<table align="center" cellspacing="0" cellpadding="0" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                +   '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                +   '<table cellspacing="0" cellpadding="0" align="center" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                +   '<table cellpadding="0" align="center" cellspacing="0" class="bb" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important"></table>'
                ;

                
        
                emailBody += '<table cellpadding="0" align="center" cellspacing="0" background class="bd" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;width:100%;table-layout:fixed !important;background-color:transparent;background-repeat:repeat;background-position:center top">'
                +       '<tr>'
                +           '<td bgcolor="transparent" align="center" style="padding:0;Margin:0">'
                +               '<table cellspacing="0" bgcolor="transparent" align="center" cellpadding="0" class="bt" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px;background-color:transparent;width:680px" role="none">'
                +                   '<tr>'
                +                       '<td align="left" style="Margin:0;padding-top:20px;padding-right:20px;padding-left:20px;padding-bottom:40px">'
                +                           '<table cellspacing="0" width="100%" cellpadding="0" role="none" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                               '<tr>'
                +                                   '<td align="left" style="padding:0;Margin:0;width:640px">'
                +                                       '<table cellpadding="0" cellspacing="0" width="100%" role="presentation" style="mso-table-lspace:0pt;mso-table-rspace:0pt;border-collapse:collapse;border-spacing:0px">'
                +                                           '<tr>'
                +                                               '<td align="center" style="padding:0;Margin:0"><p style="Margin:0;mso-line-height-rule:exactly;font-family:arial, &quot;helvetica neue&quot;, helvetica, sans-serif;line-height:18.2px;letter-spacing:0;color:#27457A;font-size:14px">© Alliance des Énergies &amp; PEP&rsquo;S par Alliance des Énergies.<br>77 Bd de Stalingrad, 69100 Villeurbanne.</p></td>'
                +                                           '</tr>'
                +                                       '</table></td>'
                +                               '</tr>'
                +                           '</table></td>'
                +                   '</tr>'
                +               '</table></td>'
                +       '</tr>'
                +   '</table>'
                + '</tr>'
                + '</table>'
                +  '</div>'            
                + '</body>'
                + '</head>'
                + '</html>'; 
                    

                    commercial = [  SELECT Id, Name, Email, Phone
                                        FROM User
                                        WHERE Id =: tmp.Commercial__c
                                        LIMIT 1];

                    emailBody = emailBody.replace('[COMMERCIAL_NAME]', commercial.Name != null ? commercial.Name : '');
                    emailBody = emailBody.replace('[COMMERCIAL_EMAIL]', commercial.Email != null ? commercial.Email : '');
                    emailBody = emailBody.replace('[COMMERCIAL_PHONE]', commercial.Phone != null ? commercial.Phone : '');

                    emailBody = emailBody.replace('[URL_SYMPOSIUM]', tmp.Id);

                    OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'service-client@alliancedesenergies.fr'];                  
                    // Création de l'email
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    if ( owea.size() > 0 ) {
                        email.setOrgWideEmailAddressId(owea.get(0).Id);
                    }
                
                    email.setToAddresses(new String[] {emailSignataire});
                    email.setCcAddresses(new String[] {commercial.Email});
                    email.setBccAddresses(new String[] {'service-client@alliancedesenergies.fr'});
                    email.setSubject('Merci pour votre confiance – Alliance des Énergies');
                    email.setHtmlBody(emailBody); 
        
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                    System.debug('Email envoyé à ' + contratsignataire.get(0).Mail_signataire__c + ' en copie le commercial ' + commercial.Email);
            }       
                List<Contract> tmp2 = new List<Contract>();
                for (Contract contrat : contracts) {
                    contrat.Envoi_Validation_Email__c = true;
                    contrat.Date_Envoi_Validation_Email__c = Date.today();
                    tmp2.add(contrat);
                }
                update tmp2;
                

                

                output.message = 'Email de validation envoyé avec succès';
                listOutput.add(output);

                return listOutput;


        }
        else {
            System.debug('Aucun contract trouvé');
        }

        return null;
    }

    public class FlowInputs {
        @invocableVariable public List<String> listContratIds;
    }
    
    public class FlowOutput {
        @InvocableVariable public String message;
    }

}