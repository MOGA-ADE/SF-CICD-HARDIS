public class AP034_TURPEOptimisationQueueable extends ChainedQueueable implements Database.AllowsCallouts {
    private String actionType;
    private String recordId;
    private String sourceId;
    private String analyseId;
    private String buildingId;

    public AP034_TURPEOptimisationQueueable(
        QueueableJobChain chain,
        String actionType,
        String recordId,
        String sourceId,
        String analyseId,
        String buildingId
    ) {
        super(chain);
        this.actionType = actionType;
        this.recordId = recordId;
        this.sourceId = sourceId;
        this.analyseId = analyseId;
        this.buildingId = buildingId;
    }

    public override void execute(QueueableContext context) {
        Boolean atMaxDepth = AsyncInfo.hasMaxStackDepth();
        try {
            AP034_TURPEOptimisationService.executeCallout(actionType, recordId, sourceId, analyseId, buildingId);
        } catch (Exception e) {
            System.debug('Callout error: ' + e.getMessage());
        }

        if (!atMaxDepth) {
            super.executeNext();
        }
    }
}