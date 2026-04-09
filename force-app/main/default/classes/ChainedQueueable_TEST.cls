@isTest
private class ChainedQueueable_TEST {

    // Flag statique pour savoir si execute() a été exécuté
    private static Boolean EXECUTED = false;

    private class TestQueueable extends ChainedQueueable implements Queueable {

        public TestQueueable() {
            super(null); 
        }

        public override void execute(QueueableContext context) {
            ChainedQueueable_TEST.EXECUTED = true; 
            super.execute(context);
        }
    }

    @isTest
    static void testExecuteWithoutChain() {

        EXECUTED = false;

        Test.startTest();
        System.enqueueJob(new TestQueueable());
        Test.stopTest();

        Assert.areEqual(
            true,
            EXECUTED,
            'execute() doit être déclenché'
        );
    }
}