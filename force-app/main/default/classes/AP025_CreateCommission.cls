public without sharing class AP025_CreateCommission {
  @InvocableMethod(label='Create commission')
  public static List<FlowOutput> createCommission(List<FlowInputs> flowInputs) {
    FlowInputs flowInput = flowInputs.get(0);
    Set<Id> setCommerciaux = new Set<Id>();
    Map<Id, Id> mapCommercialIdResponsableLegal = new Map<Id, Id>();
    String chiffreAffaireName;
    List<Chiffre_affaire__c> listChiffreAffaire;
    Chiffre_affaire__c chiffreAffaire;
    List<FlowOutput> listOutput = new List<FlowOutput>();
    FlowOutput output = new FlowOutput();
    Map<Id, User> mapCommerciaux;
    Id conventionId;

    for (WrapCommission commission : flowInput.listCommissions) {
      setCommerciaux.add(commission.commercial);
    }

    mapCommerciaux = new Map<Id, User>(
      [
        SELECT
          Id,
          CompanyName,
          Account.Name,
          UserRole.Name,
          Profile.Name,
          TECH_Responsable_legal_Id__c
        FROM User
        WHERE Id IN :setCommerciaux
      ]
    );

    for (WrapCommission commission : flowInput.listCommissions) {
      chiffreAffaireName = generateChiffreAffaireName(commission,mapCommerciaux.get(commission.commercial));
      listChiffreAffaire = [
        SELECT Id
        FROM Chiffre_Affaire__c
        WHERE Name = :chiffreAffaireName LIMIT 1
      ];
      if(listChiffreAffaire.isEmpty()){
        chiffreAffaire = null;
      }
      else{
        chiffreAffaire = listChiffreAffaire.get(0);
      }

      if (chiffreAffaire == null) {
        conventionId = checkConvention(commission, mapCommerciaux.get(commission.commercial));
        if (conventionId == null) {
          output.message = 'Convention inexistante ou inactive';
          output.commissionCreated = false;
          listOutput.add(output);
          return listOutput;
        } else {
          //Création du CA puis de la commission
          chiffreAffaire = new Chiffre_affaire__c(
            Name = chiffreAffaireName,
            Mois_paiement__c = generateMoisChiffreAffaire(commission),
            Commercial__c = commission.commercial,
            Convention__c = conventionId
          );
          if (mapCommerciaux.get(commission.commercial).UserRole.Name == 'Incubé' || mapCommerciaux.get(commission.commercial).Profile.Name == 'Utilisateur Partenaire Communauté') {
            chiffreAffaire.ownerId = mapCommerciaux.get(commission.commercial).TECH_Responsable_legal_Id__c;
          } else {
            chiffreAffaire.ownerId = mapCommerciaux.get(commission.commercial).Id;
          }
          try {
            insert chiffreAffaire;            
          } catch (DmlException e) {
            output.message = 'Le chiffre d\'affaire} n\'a pas pu être créé '+ e.getMessage();
            output.commissionCreated = false;
            listOutput.add(output);
            return listOutput;        
          }
        }
      }

      Commission__c commissionToInsert = new Commission__c(
        Name = commission.nom,
        Mois_paiement__c = generateMoisChiffreAffaire(commission),
        Chiffre_affaire__c = chiffreAffaire.Id,
        Commercial__c = commission.commercial,
        Contract__c = commission.contrat,
        Montant__c = commission.montant,
        Appel_facturation__c = commission.appelFacturation
      );
      try {
        insert commissionToInsert; 
      } catch (DmlException e) {
        output.message = 'Les commissions n\'ont pas pu être créées '+ e.getMessage();
        output.commissionCreated = false;
        listOutput.add(output);
        return listOutput;        
      }
    }
    output.message = 'Les commissions ont bien été créées';
    output.commissionCreated = true;
    listOutput.add(output);
    return listOutput;
  }

  private static Id checkConvention(WrapCommission commission, User commercial) {
    String conventionId = null;

      try {
        if (commercial.UserRole.Name == 'Incubé') {

         //On récupère la convention du responsable légal de l'incubé
          return [
            SELECT Id
            FROM Convention__c
            WHERE
              Salarie__c = :commercial.TECH_Responsable_legal_Id__c
              AND Inactive__c = FALSE
          ].Id;
        }
        else if (commercial.Profile.Name == 'Utilisateur Partenaire Communauté') {
          return [
            SELECT Convention__c
            FROM Account
            WHERE Id = :commercial.accountId AND Convention__r.Inactive__c = FALSE
          ].Convention__c;
        }
        else {
          return [
            SELECT Id
            FROM Convention__c
            WHERE Salarie__c = :commercial.Id AND Inactive__c = FALSE
          ].Id;
        }
      } catch (Exception e) {
        System.debug('Convention introuvable '+e.getMessage());
        return null;
      }    
  }

  private static String generateChiffreAffaireName(WrapCommission commission,User commercial) {
    if (commercial.UserRole.Name == 'Incubé') {
      return commercial.CompanyName.toUpperCase() + ' - ' + commission.moisPaiement.month() + '/' + commission.moisPaiement.year();
    } else if (commercial.Profile.Name == 'Utilisateur Partenaire Communauté') {
      return commercial.Account.Name.toUpperCase() + ' - ' + commission.moisPaiement.month() + '/' + commission.moisPaiement.year();
    } else {
      return commission.prenomCommercial.substring(0, 1).toUpperCase() + '.' + commission.nomCommercial.toUpperCase() + ' - ' + commission.moisPaiement.month() + '/' + commission.moisPaiement.year();
    }
  }

  private static Date generateMoisChiffreAffaire(WrapCommission commission) {
    Date moisPaiement = commission.moisPaiement;
    return Date.newInstance(moisPaiement.year(), moisPaiement.month(), 1);
  }

  
  public static void generateAllChiffreAffaire() {
    // Déclarez une map pour stocker les Chiffre_Affaire__c par nom
    Map<String, Chiffre_Affaire__c> mapNameCA = new Map<String, Chiffre_Affaire__c>();

    // Map pour relier les salariés et partenaires aux conventions
    Map<Id, Id> mapConventionSalarie = new Map<Id, Id>();
    Map<Id, Id> mapConventionPartenaire = new Map<Id, Id>();

    // Récupérer les conventions actives et remplir la map des salariés
    for (Convention__c conv : [SELECT Id, Salarie__c FROM Convention__c WHERE Inactive__c = false]) { 
        if (conv.Salarie__c != null) {
            mapConventionSalarie.put(conv.Salarie__c, conv.Id);
        }
    }

    // Récupérer les comptes associés à des conventions actives
    for (Account acc : [SELECT Id, Convention__c FROM Account WHERE Convention__r.Inactive__c = false]) {
        if (acc.Convention__c != null) {
            mapConventionPartenaire.put(acc.Id, acc.Convention__c);
        }
    }

    // Liste des commissions
    List<Commission__c> listCommission = [
        SELECT Id, Commercial__c, 
               Commercial__r.Profile.Name,
               Commercial__r.FirstName, 
               Commercial__r.LastName, 
               Commercial__r.UserRole.Name, 
               Commercial__r.TECH_Responsable_legal_Id__c, 
               Commercial__r.AccountId,
               Commercial__r.Account.Name,
               Commercial__r.CompanyName,
               Mois_paiement__c 
        FROM Commission__c
    ];

    // Traiter chaque commission
    for (Commission__c com : listCommission) {
        String CAName;
        Id conventionId;

        // Déterminer le nom et la convention en fonction du profil ou rôle utilisateur
        if (com.Commercial__r.UserRole.Name == 'Incubé') {
            CAName = com.Commercial__r.CompanyName.toUpperCase() + ' - ' 
                     + com.Mois_paiement__c.month() + '/' 
                     + com.Mois_paiement__c.year();
            conventionId = mapConventionSalarie.get(com.Commercial__c);
        } else if (com.Commercial__r.Profile.Name == 'Utilisateur Partenaire Communauté') {
            CAName = com.Commercial__r.Account.Name.toUpperCase() + ' - ' 
                     + com.Mois_paiement__c.month() + '/' 
                     + com.Mois_paiement__c.year();
            conventionId = mapConventionPartenaire.get(com.Commercial__r.AccountId);
        } else {
            CAName = com.Commercial__r.FirstName.substring(0, 1).toUpperCase() + '.' 
                     + com.Commercial__r.LastName.toUpperCase() + ' - ' 
                     + com.Mois_paiement__c.month() + '/' 
                     + com.Mois_paiement__c.year();
            conventionId = mapConventionSalarie.get(com.Commercial__c);
        }

        // Vérifier si le Chiffre d'Affaire existe déjà
        if (!mapNameCA.containsKey(CAName)) {
            Chiffre_Affaire__c CA = new Chiffre_Affaire__c(
                Name = CAName,
                Commercial__c = com.Commercial__c,
                Convention__c = conventionId,
                Mois_paiement__c = com.Mois_paiement__c
            );
            mapNameCA.put(CAName, CA);
        }
    }

    // Insérer les Chiffre_Affaire__c en base de données
    if (!mapNameCA.isEmpty()) {
      System.debug('mapNameCA.values().size() ' + mapNameCA.values().size());
        // insert mapNameCA.values();
    }
}



  public class FlowInputs {
    @invocableVariable public List<WrapCommission> listCommissions;
  }

  public class FlowOutput {
    @invocableVariable public Boolean commissionCreated;
    @InvocableVariable public String message;
  }
}