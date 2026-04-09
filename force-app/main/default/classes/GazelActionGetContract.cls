public with sharing class GazelActionGetContract {

    @InvocableMethod(label='Gazel - Générer Contrat PDF' description='Récupère le PDF depuis Gazel et l\'attache au Devis' callout=true)
    public static List<Output> execute(List<Input> inputs) {
        List<Output> outputs = new List<Output>();
        Output out = new Output();
        Input input = inputs[0];

        try {
            // Appel de l'API
            String responseSendContractByEmail = GazelAPI.getContractPdf(input.quoteId);
            
            out.isSuccess = responseSendContractByEmail.contains('succes');
            out.message = responseSendContractByEmail;
        } catch (Exception e) {
            out.isSuccess = false;
            out.message = 'Erreur technique lors de la récupération du contrat : ' + e.getMessage();
        }
        outputs.add(out);

        return outputs;
    }

    public class Input {
        @InvocableVariable(label='Quote ID' required=true)
        public Id quoteId;
    }

    public class Output {
        @InvocableVariable(label='Succès ?')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Message')
        public String message;
    }
}