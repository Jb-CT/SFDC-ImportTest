public class MockBatchClass implements Database.Batchable<SObject> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Lead LIMIT 10');
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Update a lead to trigger SendLeadToCleverTap in batch context
        Lead l = [SELECT Id, LastName FROM Lead LIMIT 1];
        l.LastName = 'BatchUpdated';
        update l;
    }
    
    public void finish(Database.BatchableContext bc) {}
}