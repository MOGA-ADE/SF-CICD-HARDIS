public class QueueableJobChain {
    private List<ChainedQueueable> chain;

    public QueueableJobChain() {
        this.chain = new List<ChainedQueueable>();
    }

    public void chainFirst(ChainedQueueable job) {
        this.chain.add(0, job);
    }

    public void chainLast(ChainedQueueable job) {
        this.chain.add(job);
    }

    public Boolean hasNext() {
        Boolean result = !this.chain.isEmpty();
        return result;
    }

    public void runNext() {
        if (this.hasNext()) {
            ChainedQueueable nextJob = this.chain.remove(0);
            nextJob.setChain(this);
            System.enqueueJob(nextJob);
        }
    }
}