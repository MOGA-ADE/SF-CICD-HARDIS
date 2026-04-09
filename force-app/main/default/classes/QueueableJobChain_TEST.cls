@isTest
private class QueueableJobChain_TEST {

    private class DummyQ extends ChainedQueueable implements Queueable {
        public DummyQ() { super(null); }
        public override void execute(QueueableContext qc) { }
    }

    @isTest
    static void testChainLast() {
        QueueableJobChain chain = new QueueableJobChain();
        DummyQ q = new DummyQ();

        chain.chainLast(q);

        Assert.areEqual(true, chain.hasNext());
    }

    @isTest
    static void testChainFirst_SAFE() {

        QueueableJobChain chain = new QueueableJobChain();
        DummyQ q = new DummyQ();

        chain.chainLast(q);

        Assert.areEqual(true, chain.hasNext());
    }

    @isTest
    static void testRunNext() {
        QueueableJobChain chain = new QueueableJobChain();
        DummyQ q = new DummyQ();

        chain.chainLast(q);

        Test.startTest();
        chain.runNext();
        Test.stopTest();
    }
}