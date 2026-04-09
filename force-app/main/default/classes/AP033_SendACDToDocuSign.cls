/**
 * Classe responsable de l'envoi d'une enveloppe DocuSign contenant l'ACD.
 * Version simplifiée : envoi des customFields dès la création de l'enveloppe (un seul callout).
 */
public without sharing class AP033_SendACDToDocuSign {

    /**
     * Structure utilisée par le Flow pour transmettre les paramètres nécessaires à l'envoi.
     */
    public class EnvelopeInput {
        @InvocableVariable(required = true)
        public String recordId;  // Id du compte
        @InvocableVariable(required = true)
        public String contactId; // Id du signataire
        @InvocableVariable(required = true)
        public String userId;    // Id de l'utilisateur DocuSign
    }

    /**
     * Méthode principale appelée par le Flow pour envoyer une enveloppe à signer.
     */
    @InvocableMethod(label = 'Envoyer ACD à signer via DocuSign (envoi unique)')
    public static void sendACDToSign(List<EnvelopeInput> inputs) {
        if (inputs.isEmpty()) return;
        EnvelopeInput input = inputs[0];

        try {
            // Chargement de la configuration DocuSign depuis la Custom Setting
            DocuSignConfig__c config = getConfig();

            // Récupération du signataire, de l'utilisateur DocuSign et des PDE sélectionnés
            Contact signataire = getSignataire(input.contactId);
            User docusignUser = getActiveDocuSignUser(input.userId);
            List<PDE__c> selectedPDEs = getSelectedPDEs(input.recordId);

            if (selectedPDEs.isEmpty()) {
                throw new FlowException('Aucun PDE sélectionné (TECH_SelectedPDE__c = true) pour ce compte.');
            }

            // Génération du PDF depuis la page Visualforce
            String pdfBase64 = generateACDPdf(input.recordId, signataire.Id);

            // Construction du modèle d'enveloppe DocuSign incluant déjà les customFields
            List<Id> pdeIds = new List<Id>();
            for (PDE__c p : selectedPDEs) pdeIds.add(p.Id);

            EnvelopeDefinition envelope = new EnvelopeDefinition(
                signataire.Email,
                signataire.FirstName + ' ' + signataire.LastName,
                pdfBase64,
                input.recordId,
                pdeIds,
                signataire.Id,
                config.EmailSubject__c,
                config.PdfFilename__c,
                docusignUser
            );

            // Envoi à l'API DocuSign (avec customFields inclus)
            HttpResponse res = sendEnvelopeToDocuSign(
                JSON.serialize(envelope),
                docusignUser.dfsle__Username__c,
                config.NamedCredential__c,
                config.AccountId__c
            );

            if (res.getStatusCode() != 201) {
                throw new FlowException('Erreur API DocuSign : ' + res.getStatusCode() + ' - ' + res.getBody());
            }

            // Récupération de l'ID de l'enveloppe
            Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            String envelopeId = (String) responseBody.get('envelopeId');
            if (String.isBlank(envelopeId)) {
                throw new FlowException('DocuSign n\'a pas renvoyé d\'identifiant d\'enveloppe.');
            }

            // Mise à jour des PDE avec l'UUID de l'enveloppe
            for (PDE__c p : selectedPDEs) {
                p.EnvelopeUUID__c = envelopeId;
            }
            update selectedPDEs;

        } catch (Exception e) {
            throw new FlowException('Erreur DocuSign : ' + e.getMessage());
        }
    }

    // --- Méthodes utilitaires ---

    private static Contact getSignataire(String contactId) {
        Contact c = [SELECT Id, FirstName, LastName, Email FROM Contact WHERE Id = :contactId LIMIT 1];
        if (String.isBlank(c.Email)) throw new FlowException('Le contact sélectionné ne possède pas d\'adresse e-mail.');
        return c;
    }

    private static User getActiveDocuSignUser(String userId) {
        User u = [SELECT Id, FirstName, LastName, Email, dfsle__Username__c 
                  FROM User 
                  WHERE Id = :userId AND IsActive = true AND dfsle__Status__c = 'Active' 
                  LIMIT 1];
        if (String.isBlank(u.dfsle__Username__c)) throw new FlowException('L\'utilisateur ne possède pas d\'identifiant DocuSign.');
        return u;
    }

    private static String generateACDPdf(String accountId, String contactId) {
        if (Test.isRunningTest()) return EncodingUtil.base64Encode(Blob.valueOf('FAKE_PDF_CONTENT'));
        PageReference pdfPage = Page.renouvellementACD;
        pdfPage.getParameters().put('accountId', accountId);
        pdfPage.getParameters().put('signataireId', contactId);
        return EncodingUtil.base64Encode(pdfPage.getContentAsPDF());
    }

    private static List<PDE__c> getSelectedPDEs(String accountId) {
        return [
            SELECT Id
            FROM PDE__c
            WHERE entiteJuridique__c = :accountId
            AND TECH_SelectedPDE__c = true
        ];
    }

    private static HttpResponse sendEnvelopeToDocuSign(String payload, String docuSignUserId, String namedCredential, String accountId) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(namedCredential + '/restapi/v2.1/accounts/' + accountId + '/envelopes');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('X-DocuSign-Act-As-User', docuSignUserId);
        req.setBody(payload);
        return new Http().send(req);
    }

    private static DocuSignConfig__c getConfig() {
        DocuSignConfig__c config = DocuSignConfig__c.getInstance();
        if (config == null) {
            throw new FlowException('La configuration DocuSign n\'est pas définie dans les Custom Settings.');
        }
        return config;
    }

    // --- Structures JSON ---

    public class EnvelopeDefinition {
        public String status = 'sent';
        public String emailSubject;
        public List<Document> documents = new List<Document>();
        public Recipients recipients;
        public CustomFields customFields;
        public String emailBlurb;

        public EnvelopeDefinition(
            String email,
            String name,
            String base64Pdf,
            String accountId,
            List<Id> pdeIds,
            String contactId,
            String emailSubject,
            String fileName,
            User docusignUser
        ) {
            this.emailSubject = emailSubject;
            if (docusignUser == null) {
                this.emailBlurb = 'Alliance des Énergies vous transmet ce document à signer électroniquement.';
            } else {
                this.emailBlurb = docusignUser.FirstName + ' ' + docusignUser.LastName +
                    ' (' + docusignUser.Email + ') vous a transmis ce document à signer électroniquement via Alliance des Énergies.';
            }

            documents.add(new Document(base64Pdf, fileName));
            recipients = new Recipients(
                new Recipient(email, name),
                (String.isNotBlank(docusignUser.Email)
                    ? new CarbonCopy(docusignUser.Email, docusignUser.FirstName + ' ' + docusignUser.LastName, '2')
                    : null)
            );
            customFields = new CustomFields(accountId, pdeIds, contactId, docusignUser.Id);
        }
    }

    public class CustomFields {
        public List<TextCustomField> textCustomFields;
        public CustomFields(String accountId, List<Id> pdeIds, String contactId, String userId) {
            textCustomFields = new List<TextCustomField>{
                new TextCustomField('ACD', 'true'),
                new TextCustomField('SFAccountId', accountId),
                new TextCustomField('SFUserId', userId)
            };
            if (String.isNotBlank(contactId)) {
                textCustomFields.add(new TextCustomField('SFContactId', contactId));
            }
        }
    }

    public class TextCustomField {
        public String name;
        public String value;
        public Boolean show = false;
        public TextCustomField(String name, String value) {
            this.name = name;
            this.value = value;
        }
    }

    public class Document {
        public String documentBase64;
        public String name;
        public String fileExtension = 'pdf';
        public String documentId = '1';
        public Document(String base64, String fileName) {
            this.documentBase64 = base64;
            this.name = fileName;
        }
    }

    public class Recipients {
        public List<Signer> signers;
        public List<CarbonCopy> carbonCopies;

        public Recipients(Recipient recipientSigner, CarbonCopy ccRecipient) {
            signers = new List<Signer>{ new Signer(recipientSigner) };
            if (ccRecipient != null) carbonCopies = new List<CarbonCopy>{ ccRecipient };
        }
    }

    public class CarbonCopy {
        public String email;
        public String name;
        public String recipientId;
        public String routingOrder = '1'; // Même ordre que le signataire => reçoit dès l'envoi
        public CarbonCopy(String email, String name, String recipientId) {
            this.email = email;
            this.name = name;
            this.recipientId = recipientId;
        }
    }

    public class Signer {
        public String email;
        public String name;
        public String recipientId = '1';
        public String routingOrder = '1';
        public Tabs tabs;
        public Signer(Recipient r) {
            this.email = r.email;
            this.name = r.name;
            this.tabs = new Tabs();
        }
    }

    public class Recipient {
        public String email;
        public String name;
        public Recipient(String email, String name) {
            this.email = email;
            this.name = name;
        }
    }

    public class Tabs {
        public List<SignHere> signHereTabs;
        public List<DateSigned> dateSignedTabs;
        public List<Text> textTabs;
        public List<InitialHere> initialHereTabs;

        public Tabs() {
            signHereTabs   = new List<SignHere>{ new SignHere('SIGNATURE :') };
            dateSignedTabs = new List<DateSigned>{ new DateSigned('Le :') };
            textTabs       = new List<Text>{ new Text('Fait à :') };
            initialHereTabs = new List<InitialHere>{
                new InitialHere('[[PARAPHE]]')
            };
        }
    }

    public class SignHere {
        public String documentId = '1';
        public String anchorString;
        public String anchorUnits = 'pixels';
        public Integer anchorXOffset = 110;
        public Integer anchorYOffset = 2;
        public String recipientId = '1';
        public String tabLabel = 'Signature';
        public SignHere(String anchor) { this.anchorString = anchor; }
    }

    public class DateSigned {
        public String documentId = '1';
        public String anchorString;
        public String anchorUnits = 'pixels';
        public Integer anchorXOffset = 34;
        public Integer anchorYOffset = 2;
        public String recipientId = '1';
        public String tabLabel = 'Date de signature';
        public DateSigned(String anchor) { this.anchorString = anchor; }
    }

    public class Text {
        public String documentId = '1';
        public String anchorString;
        public String anchorUnits = 'pixels';
        public Integer anchorXOffset = 34;
        public Integer anchorYOffset = -3;
        public String recipientId = '1';
        public String tabLabel = 'Lieu de signature';
        public Boolean required = true;
        public Text(String anchor) { this.anchorString = anchor; }
    }

    public class InitialHere {
        public String documentId = '1';
        public String anchorString = '[[PARAPHE]]';
        public String anchorUnits  = 'pixels';
        public Integer anchorXOffset = -6;   // petit décalage pour “coller” le coin
        public Integer anchorYOffset = -6;
        public String recipientId = '1';
        public String tabLabel = 'Paraphe';
        public Boolean anchorIgnoreIfNotPresent = true;
        public Boolean anchorMatchWholeWord = false;
        public InitialHere(String anchor){ this.anchorString = anchor; }
        public InitialHere(){}
    }
}