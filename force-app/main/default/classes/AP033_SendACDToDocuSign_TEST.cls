@IsTest
private class AP033_SendACDToDocuSign_TEST {

    private static Map<String, Id> setupBaseData() {
        List<Account> accounts = TestDataFactory.createAccountsWithOppsAndPointDenergie(1, 1, 1, 1, 1);

        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact c = [SELECT Id, Email FROM Contact WHERE AccountId = :acc.Id LIMIT 1];

        // Ajout : on s'assure qu'au moins un PDE est marqué comme sélectionné
        List<PDE__c> pdes = [SELECT Id FROM PDE__c WHERE entiteJuridique__c = :acc.Id LIMIT 1];
        if (!pdes.isEmpty()) {
            PDE__c p = pdes[0];
            p.TECH_SelectedPDE__c = true;
            update p;
        }

        User u = [
            SELECT Id, Email, dfsle__Username__c, dfsle__Status__c
            FROM User
            WHERE Profile.Name = 'Administrateur Système'
            AND IsActive = true
            LIMIT 1
        ];
        u.dfsle__Username__c = 'dccce9b4-e21f-4a33-a06c-3fd889e080f7';
        u.dfsle__Status__c = 'Active';
        update u;

        return new Map<String, Id>{
            'accountId' => acc.Id,
            'contactId' => c.Id,
            'userId'    => u.Id
        };
    }

    @IsTest
    static void test_sendACDToSign_success() {
        Map<String, Id> data = setupBaseData();

        Test.setMock(HttpCalloutMock.class, new DocuSignHttpMock(201, '{"envelopeId":"1234"}'));

        AP033_SendACDToDocuSign.EnvelopeInput input = new AP033_SendACDToDocuSign.EnvelopeInput();
        input.recordId = (String)data.get('accountId');
        input.contactId = (String)data.get('contactId');
        input.userId = (String)data.get('userId');

        Test.startTest();
        AP033_SendACDToDocuSign.sendACDToSign(new List<AP033_SendACDToDocuSign.EnvelopeInput>{ input });
        Test.stopTest();

        Assert.isTrue(true, 'Le flux nominal doit s\'exécuter sans erreur.');
    }

    @IsTest
    static void test_sendACDToSign_emptyList() {
        Test.startTest();
        AP033_SendACDToDocuSign.sendACDToSign(new List<AP033_SendACDToDocuSign.EnvelopeInput>());
        Test.stopTest();

        Assert.isTrue(true, 'Pas d\'erreur si la liste d\'entrée est vide.');
    }

    @IsTest
    static void test_sendACDToSign_contactWithoutEmail() {
        Map<String, Id> data = setupBaseData();

        Contact c = [SELECT Id, Email FROM Contact WHERE Id = :data.get('contactId') LIMIT 1];
        c.Email = null;
        update c;

        AP033_SendACDToDocuSign.EnvelopeInput input = new AP033_SendACDToDocuSign.EnvelopeInput();
        input.recordId = (String)data.get('accountId');
        input.contactId = (String)data.get('contactId');
        input.userId = (String)data.get('userId');

        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            AP033_SendACDToDocuSign.sendACDToSign(new List<AP033_SendACDToDocuSign.EnvelopeInput>{ input });
            Assert.fail('Une FlowException était attendue pour un contact sans e-mail.');
        } catch (FlowException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Une FlowException doit être levée pour contact sans email.');
        Assert.isTrue(
            exceptionMessage.contains('Erreur DocuSign'),
            'Le message doit contenir "Erreur DocuSign". Message actuel : ' + exceptionMessage
        );
    }

    @IsTest
    static void test_sendACDToSign_userWithoutDocuSignId() {
        Map<String, Id> data = setupBaseData();

        User u = [SELECT Id, dfsle__Username__c FROM User WHERE Id = :data.get('userId') LIMIT 1];
        u.dfsle__Username__c = null;
        update u;

        AP033_SendACDToDocuSign.EnvelopeInput input = new AP033_SendACDToDocuSign.EnvelopeInput();
        input.recordId = (String)data.get('accountId');
        input.contactId = (String)data.get('contactId');
        input.userId = (String)data.get('userId');

        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            AP033_SendACDToDocuSign.sendACDToSign(new List<AP033_SendACDToDocuSign.EnvelopeInput>{ input });
            Assert.fail('Une FlowException était attendue pour un utilisateur sans identifiant DocuSign.');
        } catch (FlowException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Une FlowException doit être levée pour user sans dfsle__Username__c.');
        Assert.isTrue(
            exceptionMessage.contains('Erreur DocuSign'),
            'Le message doit contenir "Erreur DocuSign". Message actuel : ' + exceptionMessage
        );
    }

    @IsTest
    static void test_sendACDToSign_httpError() {
        Map<String, Id> data = setupBaseData();

        Test.setMock(HttpCalloutMock.class, new DocuSignHttpMock(400, '{"error":"Bad Request"}'));

        AP033_SendACDToDocuSign.EnvelopeInput input = new AP033_SendACDToDocuSign.EnvelopeInput();
        input.recordId = (String)data.get('accountId');
        input.contactId = (String)data.get('contactId');
        input.userId = (String)data.get('userId');

        Boolean exceptionThrown = false;
        String exceptionMessage = '';

        Test.startTest();
        try {
            AP033_SendACDToDocuSign.sendACDToSign(new List<AP033_SendACDToDocuSign.EnvelopeInput>{ input });
            Assert.fail('Une FlowException était attendue pour une erreur HTTP 400.');
        } catch (FlowException e) {
            exceptionThrown = true;
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Une FlowException doit être levée si le callout échoue.');
        Assert.isTrue(
            exceptionMessage.contains('Erreur DocuSign'),
            'Le message doit contenir "Erreur DocuSign". Message actuel : ' + exceptionMessage
        );
    }

    private class DocuSignHttpMock implements HttpCalloutMock {
        private Integer code;
        private String body;

        DocuSignHttpMock(Integer code, String body) {
            this.code = code;
            this.body = body;
        }

        public HTTPResponse respond(HTTPRequest req) {
            Assert.isTrue(
                req.getEndpoint().contains('/restapi/v2.1/accounts/'),
                'L\'endpoint DocuSign doit être correct.'
            );
            Assert.isNotNull(req.getBody(), 'Le corps JSON de l\'enveloppe doit être présent.');

            HttpResponse res = new HttpResponse();
            res.setStatusCode(code);
            res.setBody(body);
            return res;
        }
    }
}