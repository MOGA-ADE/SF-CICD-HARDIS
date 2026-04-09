/**
 * Scheduler pour lancer le batch GRDFCheckValidationBatch toutes les 30 minutes
 */
public class GRDFCheckValidationScheduler implements Schedulable {
    
    public void execute(SchedulableContext sc) {
        GRDFCheckValidationBatch batch = new GRDFCheckValidationBatch();
        Database.executeBatch(batch, 10);
    }
}