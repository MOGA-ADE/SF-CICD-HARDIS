/**
 * Webhook DocuSign appelé automatiquement lors d'un changement de statut d'enveloppe.
 * Ce service met à jour les PDE liés à l'enveloppe DocuSign ACD concernée.
 */
@RestResource(urlMapping = '/DocuSignWebhook/*')
global without sharing class AP033_DocuSignWebhookHandler {

    /**
     * Point d'entrée du Webhook DocuSign.
     * Récupère les données JSON, identifie les champs personnalisés et met à jour les PDE correspondants.
     */
    @HttpPost
    global static void handleWebhook() {
        try {
            RestRequest req = RestContext.request;
            String body = req.requestBody.toString();
            // Désérialisation du JSON reçu
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(body);
            Map<String, Object> data = (Map<String, Object>) payload.get('data');
            if (data == null) {
                sendResponse(400, 'Erreur : payload incomplet.');
                return;
            }

            // Extraction des champs personnalisés DocuSign
            Map<String, Object> customFields = extractCustomFields(data);

            Boolean isACDEnvelope = false;
            String contactId;
            String accountId;
            String userId;
            String envelopeId = (String) data.get('envelopeId');
            String status;

            // Lecture du statut de l’enveloppe
            if (data.containsKey('envelopeSummary')) {
                Map<String, Object> summary = (Map<String, Object>) data.get('envelopeSummary');
                if (summary != null && summary.containsKey('status')) {
                    status = (String) summary.get('status');
                }
            }

            // Lecture des custom fields personnalisés
            if (customFields != null && customFields.containsKey('textCustomFields')) {
                List<Object> textFields = (List<Object>) customFields.get('textCustomFields');
                for (Object fieldObj : textFields) {
                    Map<String, Object> field = (Map<String, Object>) fieldObj;
                    String name = String.valueOf(field.get('name')).toLowerCase();
                    String value = String.valueOf(field.get('value'));

                    if (name == 'ACD' && value.toLowerCase() == 'true') {
                        isACDEnvelope = true;
                    } else if (name == 'SFAccountId') {
                        accountId = value;
                    } else if (name == 'SFContactId') {
                        contactId = value;
                    } else if (name == 'SFUserId') {
                        userId = value;
                    }
                }
            }

            // Si l'enveloppe n'est pas liée au processus ACD, on ignore le webhook
            if (!isACDEnvelope) {
                sendResponse(200, 'Ignoré : l\'enveloppe n\'est pas liée au process de renouvellement ACD.');
                return;
            }

            // Mise à jour des PDE concernés
            updatePDEs(envelopeId, accountId, contactId);

            // Si l’enveloppe est complétée, on tente d’obtenir le PDF signé
            if (status != null && status.toLowerCase() == 'completed' && !String.isBlank(accountId)) {
                // PDF inclus directement dans le webhook
                if (data.containsKey('envelopeSummary')) {
                    Map<String, Object> summary = (Map<String, Object>) data.get('envelopeSummary');
                    if (summary != null && summary.containsKey('envelopeDocuments')) {
                        List<Object> docs = (List<Object>) summary.get('envelopeDocuments');
                        for (Object o : docs) {
                            Map<String, Object> doc = (Map<String, Object>) o;
                            if (doc.containsKey('PDFBytes') && !String.isBlank((String) doc.get('PDFBytes'))) {
                                Blob pdfBlob = EncodingUtil.base64Decode((String) doc.get('PDFBytes'));
                                savePdfOnAccount(pdfBlob, (String) doc.get('name'), accountId);
                                sendPdfToUser(userId, 'ACD_Signe.pdf', pdfBlob);
                                sendResponse(200, 'Webhook traité + PDF inclus sauvegardé.');
                                return;
                            }
                        }
                    }
                }
            }

            sendResponse(200, 'Webhook traité avec succès pour ' + envelopeId);

        } catch (Exception e) {
            System.debug('Erreur Webhook : ' + e.getMessage() + '\n' + e.getStackTraceString());
            sendResponse(500, 'Erreur : ' + e.getMessage());
        }
    }

    /**
     * Extrait la section "customFields" du payload DocuSign,
     * en prenant en compte les variantes de structure JSON possibles.
     */
    private static Map<String, Object> extractCustomFields(Map<String, Object> data) {
        if (data.containsKey('envelopeSummary')) {
            Map<String, Object> summary = (Map<String, Object>) data.get('envelopeSummary');
            if (summary != null && summary.containsKey('customFields')) {
                return (Map<String, Object>) summary.get('customFields');
            }
        }
        return null;
    }


    /**
     * Met à jour les PDE rattachés à l'enveloppe concernée :
     * - Renseigne la date de signature et le signataire
     * - Désactive le flag TECH_SelectedPDE__c
     * - Lance la mise à jour des données Enedis via la Queueable
     */
    private static void updatePDEs(String envelopeId, String accountId, String contactId) {
        List<PDE__c> pdes = [
            SELECT Id, Name, RecordType.DeveloperName
            FROM PDE__c
            WHERE EnvelopeUUID__c = :envelopeId
        ];

        if (pdes.isEmpty()) return;

        List<Id> pdeIds = new List<Id>();
        List<Id> pdeNonGazIds = new List<Id>();

        for (PDE__c p : pdes) {
            p.Date_signature_ACD__c = Date.today();
            p.TECH_SelectedPDE__c = false;
            p.SignataireACD__c = contactId;
            pdeIds.add(p.Id);

            // On garde uniquement les PDE non "PDE_Gaz"
            if (p.RecordType != null && p.RecordType.DeveloperName != 'PDE_Gaz') {
                pdeNonGazIds.add(p.Id);
            }
        }
        update pdes;

        // Lancement de la mise à jour Enedis uniquement pour les PDE non gaz
        if (!pdeNonGazIds.isEmpty()) {
            System.enqueueJob(new SGERefreshSiteQueueable(pdeNonGazIds));
        }
    }

    // --- Sauvegarde du PDF sur l’Account ---
    private static void savePdfOnAccount(Blob pdf, String fileName, Id accountId) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName.replace('.pdf','') + '_' + DateTime.now().format('yyyyMMdd_HHmm');
        cv.PathOnClient = cv.Title + '.pdf';
        cv.VersionData = pdf;
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = docId;
        cdl.LinkedEntityId = accountId;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
    }

    private static void sendResponse(Integer code, String message) {
        RestContext.response.statusCode = code;
        RestContext.response.responseBody = Blob.valueOf(message);
    }

    private static void sendPdfToUser(String userId, String fileName, Blob pdfBlob) {
        try {
            User u = [
                SELECT Id, Email, FirstName, LastName
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ u.Email });
            email.setSubject('Document ACD signé disponible');
            email.setPlainTextBody(
                'Bonjour ' + u.FirstName + ',\n\n' +
                'Le document ACD que vous avez envoyé a été signé avec succès.\n' +
                'Vous trouverez ci-joint le PDF signé.\n\n' +
                'Cordialement,\nAlliance des Énergies'
            );

            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName(fileName);
            attach.setBody(pdfBlob);
            email.setFileAttachments(new List<Messaging.EmailFileAttachment>{ attach });

            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
        } catch (Exception e) {
            System.debug('❌ [Webhook] Erreur d\'envoi du mail à l\'utilisateur initiateur : ' + e.getMessage());
        }
    }
}