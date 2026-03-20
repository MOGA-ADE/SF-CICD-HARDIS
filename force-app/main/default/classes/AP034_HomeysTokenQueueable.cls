public class AP034_HomeysTokenQueueable
    extends ChainedQueueable
    implements Database.AllowsCallouts {

    public AP034_HomeysTokenQueueable(QueueableJobChain chain) {
        super(chain);
    }

    public override void execute(QueueableContext context) {
        Boolean atMaxDepth = AsyncInfo.hasMaxStackDepth();
        try {
            Homeys_Auth_Config__mdt conf =
                AP034_TURPEOptimisationService.getStaticHomeysConfig();

            AP034_TURPEOptimisationService.generateNewToken(conf);
        } catch (Exception e) {
            System.debug('Callout error: ' + e.getMessage());
        }

        if (!atMaxDepth) {
            super.executeNext();
        }
    }
}