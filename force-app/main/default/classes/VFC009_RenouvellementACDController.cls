public with sharing class VFC009_RenouvellementACDController {
    public List<PDE__c> listPDE { get; private set; }
    public Contact signataire { get; private set; }
    public Account account { get; private set; }
    public String nomSignataire {
        get {
            return signataire != null ? signataire.FirstName + ' ' + signataire.LastName : '';
        }
    }

    public VFC009_RenouvellementACDController() {
        String signataireId = ApexPages.currentPage().getParameters().get('signataireId');
        String accountId = ApexPages.currentPage().getParameters().get('accountId');

        account = [
            SELECT Name, SIRET__c
            FROM Account
            WHERE Id = :accountId
            LIMIT 1];

        signataire = [
            SELECT FirstName, LastName, Salutation,Title
            FROM Contact
            WHERE Id = :signataireId
            LIMIT 1];

        listPDE = [
            SELECT TECH_num_compteur__c,Adresse_de_consommation__c
            FROM PDE__c
            WHERE TECH_SelectedPDE__c = true
            AND entiteJuridique__c = :accountId];
    }
}