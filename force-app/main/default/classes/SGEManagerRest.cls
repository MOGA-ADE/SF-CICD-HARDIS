@RestResource(urlMapping='/pdeInfo')
global class SGEManagerRest {
      
    /**
     * Ma fonction prend en entrée une liste d'Id et appel pour chaque ID la fonction refreshSiteInformation
     * Pour chaque appel SI l'appel échoue on considère qu'il s'git d'un compteur gaz et on le met à jour
     *  
     * 
     * 
     */
    global class IdWrapper {
        public List<Id> ids;
    }

    @HttpPost
    global static void updatePdeMulesoft() {
        RestRequest req = RestContext.request;
        IdWrapper input = (IdWrapper) JSON.deserialize(req.requestBody.toString(), IdWrapper.class);
        System.debug('IDs reçus : ' + input.ids);
        for (Id pdeId : input.ids) {
            try {
                SGEManager.refreshSiteInformationFuture(pdeId);
            } catch (Exception e) {
                System.debug('Erreur lors du traitement du PDE Id: ' + pdeId + ' | ' + e.getMessage());
            }
        }
        
    }

}