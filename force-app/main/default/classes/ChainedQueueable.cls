public abstract class ChainedQueueable implements Queueable {
    protected QueueableJobChain chain;

    public ChainedQueueable(QueueableJobChain chain) {
        this.chain = chain;
    }

    public void setChain(QueueableJobChain chain) {
        this.chain = chain;
    }

    protected Boolean isChained() {
        Boolean result = this.chain != null;
        return result;
    }

    protected void executeNext() {
        if (this.isChained()) this.chain.runNext();
    }

    public virtual void execute(QueueableContext context) {
        this.executeNext();
    }
}