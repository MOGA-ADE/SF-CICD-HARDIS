public class GRDFCreateDroits {
    
    @InvocableMethod(label='GRDF - Créer Droits Accès' 
                     description='Crée les droits d\'accès GRDF pour une liste de PCE'
                     category='GRDF')
    public static List<Result> createDroitsAcces(List<Request> requests) {
        
        Request req = requests[0];
        List<Result> results = new List<Result>();
        Result result = new Result();
        
        try {           
            // Lancer le job Queueable
            GRDFCreateDroitsQueueable job = new GRDFCreateDroitsQueueable(req.pces, req.userEmail);
            Id jobId = System.enqueueJob(job);
            
            result.success = true;
            result.message = 'Traitement lancé pour ' + req.pces.size() + ' PCE(s). Vous recevrez un email de confirmation.';
            result.jobId = jobId;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Erreur : ' + e.getMessage();
            //TODO: Log error here
        }
        
        results.add(result);
        return results;
    }
    
    // ========================================
    // INNER CLASSES - INPUT/OUTPUT
    // ========================================
    
    public class Request {
        @InvocableVariable(label='Liste des PCEs' required=true)
        public List<PDE__c> pces;
        
        @InvocableVariable(label='Email utilisateur' required=true)
        public String userEmail;
    }
    
    public class Result {
        @InvocableVariable(label='Succès')
        public Boolean success;
        
        @InvocableVariable(label='Message')
        public String message;
        
        @InvocableVariable(label='Job ID')
        public String jobId;
    }
}