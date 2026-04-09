global class WrapFournisseursEligibleGrille {

    @AuraEnabled @InvocableVariable public String name;

    public WrapFournisseursEligibleGrille(String name) {this.name = name;}

}