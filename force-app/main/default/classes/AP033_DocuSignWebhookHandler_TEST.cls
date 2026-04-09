@IsTest
private class AP033_DocuSignWebhookHandler_TEST {

    private static Map<String, Id> setupBaseData() {
        List<Account> accounts = TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact c = [SELECT Id FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        PDE__c pde = [
            SELECT Id, entiteJuridique__c
            FROM PDE__c
            WHERE entiteJuridique__c = :acc.Id
            LIMIT 1
        ];
        pde.TECH_SelectedPDE__c = true;
        pde.EnvelopeUUID__c = 'abc123';
        update pde;

        return new Map<String, Id>{
            'accountId' => acc.Id,
            'contactId' => c.Id,
            'pdeId' => pde.Id
        };
    }

    @IsTest
    static void test_webhook_success_with_pdf_included() {
        Map<String, Id> data = setupBaseData();

        Id accountId = data.get('accountId');
        Id contactId = data.get('contactId');
        Id pdeId = data.get('pdeId');

        Blob fakePdf = Blob.valueOf('FAKE SIGNED PDF');
        String base64Pdf = EncodingUtil.base64Encode(fakePdf);

        String body = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'envelopeId' => 'abc123',
                'status' => 'completed',
                'envelopeSummary' => new Map<String, Object>{
                    'status' => 'completed',
                    'customFields' => new Map<String, Object>{
                        'textCustomFields' => new List<Object>{
                            new Map<String, Object>{ 'name' => 'ACD', 'value' => 'true' },
                            new Map<String, Object>{ 'name' => 'SFAccountId', 'value' => accountId },
                            new Map<String, Object>{ 'name' => 'SFContactId', 'value' => contactId }
                        }
                    },
                    'envelopeDocuments' => new List<Object>{
                        new Map<String, Object>{
                            'documentId' => '1',
                            'name' => 'ACD_Signe.pdf',
                            'PDFBytes' => base64Pdf
                        }
                    }
                }
            }
        });

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        AP033_DocuSignWebhookHandler.handleWebhook();
        Test.stopTest();

        PDE__c updatedPDE = [
            SELECT Date_signature_ACD__c, TECH_SelectedPDE__c, SignataireACD__c
            FROM PDE__c
            WHERE Id = :pdeId
        ];
        Assert.isNotNull(updatedPDE.Date_signature_ACD__c, 'Date de signature doit être mise à jour.');
        Assert.isFalse(updatedPDE.TECH_SelectedPDE__c, 'TECH_SelectedPDE__c doit être false.');
        Assert.areEqual(contactId, updatedPDE.SignataireACD__c, 'Le signataire doit être correct.');

        ContentVersion cv = [
            SELECT Id, Title, VersionData
            FROM ContentVersion
            WHERE Title LIKE 'ACD_Signe%'
            LIMIT 1
        ];
        Assert.isNotNull(cv, 'Le PDF signé doit être enregistré en ContentVersion.');
        Assert.isTrue(cv.VersionData.size() > 0, 'Le PDF signé doit contenir des données.');
        Assert.areEqual(200, RestContext.response.statusCode, 'Code HTTP doit être 200.');
    }

    @IsTest
    static void test_webhook_ignored_non_acd() {
        String body = JSON.serialize(new Map<String, Object>{
            'data' => new Map<String, Object>{
                'envelopeSummary' => new Map<String, Object>{
                    'customFields' => new Map<String, Object>{
                        'textCustomFields' => new List<Object>{
                            new Map<String, Object>{ 'name' => 'ACD', 'value' => 'false' }
                        }
                    }
                },
                'envelopeId' => 'zzz999',
                'status' => 'completed'
            }
        });

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(body);
        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        AP033_DocuSignWebhookHandler.handleWebhook();
        Test.stopTest();

        Assert.areEqual(200, RestContext.response.statusCode, 'Webhook ignoré doit renvoyer 200.');
        Assert.isTrue(
            RestContext.response.responseBody.toString().contains('Ignoré'),
            'Le message doit indiquer que l’enveloppe est ignorée.'
        );
    }
}