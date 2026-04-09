@isTest
private class ContentVersionTriggerHandler_TEST {

    @isTest
    static void testBlockZipOnAccount() {
        // Création d'un compte
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Création d'un fichier .zip destiné au compte
        ContentVersion zipFile = new ContentVersion(
            Title = 'Fichier ZIP',
            PathOnClient = 'test_fichier.zip',
            VersionData = Blob.valueOf('dummy data'),
            FirstPublishLocationId = acc.Id
        );

        Test.startTest();
        try {
            insert zipFile;
            System.assert(false, 'Une exception aurait dû être levée pour un .zip sur un compte.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Le téléchargement de fichiers .zip est interdit sur les Comptes.'));
        }
        Test.stopTest();
    }

    @isTest
    static void testAllowZipOnContact() {
        // Création d'un contact
        Contact contact = new Contact(LastName = 'Contact Test');
        insert contact;

        // Création d'un fichier .zip destiné au contact
        ContentVersion zipFile = new ContentVersion(
            Title = 'Fichier ZIP',
            PathOnClient = 'test_contact.zip',
            VersionData = Blob.valueOf('dummy data'),
            FirstPublishLocationId = contact.Id
        );

        Test.startTest();
        insert zipFile; // Ne doit pas lever d'erreur
        Test.stopTest();

        // Vérifie que l'enregistrement a bien été inséré
        List<ContentVersion> inserted = [SELECT Id FROM ContentVersion WHERE Title = 'Fichier ZIP'];
        System.assertEquals(1, inserted.size(), 'Le fichier aurait dû être inséré sans erreur');
    }

}