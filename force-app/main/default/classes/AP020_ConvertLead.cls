public with sharing class AP020_ConvertLead {
    @invocableMethod(label='Convert Lead')
    public static List<FlowOutput> convertLead(List<FlowInputs> params) {


        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();
        Id leadId = params[0].leadId;
        
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true AND MasterLabel = 'ACD reçu' LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        output.success = lcr.isSuccess();
        System.debug('VALEUR de out.success  '+output.success );
        
        if(output.success){
            //On recup le fileId du fichier qui se termine par _completed
            ContentDocumentLink cdl = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :leadId AND ContentDocument.Title LIKE '%_completed%' LIMIT 1];
            System.debug('VALEUR DE Content DocumentLink  '+cdl );
            Id fileId = cdl.ContentDocumentId;
            System.debug('VALEUR de fileId  '+fileId );

            //On recup le account ID
            Lead lead = [SELECT ConvertedAccountId FROM Lead WHERE Id = :leadId];
            Id accountId = lead.ConvertedAccountId;
            System.debug('VALEUR de AccoutnId  '+accountId );
            //On appelle Mulesoft
            //AP026_SendInvoicesToMulesoft.sendFilesAsync(String.valueOf(fileId), String.valueOf(accountId));
            System.debug('JE SUIS APRES LA FONCTION  ' );


        }
        outputs.add(output);
        return outputs;
    }


    public class FlowInputs {
        @invocableVariable public Id leadId;
    }
    
    public class FlowOutput {
        @InvocableVariable public Boolean success;
    }
}