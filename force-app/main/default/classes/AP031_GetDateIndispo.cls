public without sharing class AP031_GetDateIndispo {

    @invocableMethod(label='Récupération des dates indisponible pour les vente indirecte')
    public static List<FlowOutput> GetDatesIndisponibles(List<FlowInputs> params) {
        FlowInputs param = params[0];
        FlowOutput output = new FlowOutput();
        List<FlowOutput> outputs = new List<FlowOutput>();

        DateTime startOfDay = DateTime.newInstanceGMT(Date.today(), Time.newInstance(0, 0, 0, 0));
        DateTime endOfDay = startOfDay.addDays(14);

        //System.debug('intervalle : ' + startOfDay + ' - ' + endOfDay);

        List<String> formattedDates = new List<String>();
        Integer nbDossiersLeJour;
        Integer limiteNbDossier;



        if (param.UserCompany != 'ADE') {
            for (AggregateResult ddc : [
                SELECT count(id) NombreDeDDCPourleJour, DAY_ONLY(TECH_Date_RDV_Reactu__c) DateRDV
                FROM Demande_Cotation__c
                WHERE
                TECH_Date_RDV_Reactu__c  >= :startOfDay AND TECH_Date_RDV_Reactu__c  <= :endOfDay
                AND Societe_du_commercial__c != 'ADE'
                Group By DAY_ONLY(TECH_Date_RDV_Reactu__c)
            ]) {
                Date dateRDV = (Date) ddc.get('DateRDV');    
                nbDossiersLeJour = Integer.valueOf(ddc.get('NombreDeDDCPourleJour'));
                limiteNbDossier = AP028_CheckNbDemandeCotationFromFlow.getLimiteNbDossier(dateRDV);
                //System.debug('date ddc found : ' + dateRDV + ' nbDossiersLeJour : ' + nbDossiersLeJour + ' limit : ' + limiteNbDossier); 

                if (nbDossiersLeJour >= limiteNbDossier) {
                    String formattedDate = String.valueOf(dateRDV.day()) + '/' +
                                    String.valueOf(dateRDV.month()) + '/' +
                                    String.valueOf(dateRDV.year());
                    formattedDates.add('• ' + formattedDate);
                    //System.debug('date to display in flow : ' + formattedDate); 
                }
            }

            if(!formattedDates.isEmpty())   {
                //System.debug('all date to display in flow : ' + formattedDates); 
                output.DMLSuccess = true;
                output.datesindisponibles = String.join(formattedDates, '\n');
                outputs.add(output);
                //System.debug('### dates : ' + output.datesindisponibles);
                //System.debug('### dates size :');
                
            }
            else {
                output.DMLSuccess = false;
                output.ErrorMessage = '';
                outputs.add(output);
            }
        }

        return outputs;
        }

    public class FlowInputs {
        @invocableVariable public String UserCompany;

    }
    
    public class FlowOutput {
        @InvocableVariable public Boolean DMLSuccess;
        @InvocableVariable public String ErrorMessage;
        @InvocableVariable public String datesindisponibles;

    }


}