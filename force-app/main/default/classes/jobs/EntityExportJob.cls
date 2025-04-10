/**
 * @class EntityExportJob
 * @description A generic Queueable class that processes Salesforce records and sends them to CleverTap.
 */
@SuppressWarnings('PMD.QueueableWithoutFinalizer')
public class EntityExportJob implements Queueable, Database.AllowsCallouts {
    private List<SObject> records;
    private String objectType;

    /**
     * @description Constructor for processing a single SObject record.
     * @param record A single Salesforce record.
     */
    public EntityExportJob(SObject record) {
        this.records = new List<SObject>{record};
        this.objectType = record.getSObjectType().getDescribe().getName();
    }

    /**
     * @description Constructor for processing multiple SObject records.
     * @param records A list of Salesforce records of the same type.
     */
    public EntityExportJob(List<SObject> records) {
        if (records == null || records.isEmpty()) {
            this.records = new List<SObject>();
            this.objectType = '';
        } else {
            this.records = records;
            this.objectType = records[0].getSObjectType().getDescribe().getName();
        }
    }

    /**
     * @description Executes the job to send each record to CleverTap.
     * @param context The Queueable context.
     */
public void execute(QueueableContext context) {
    if (records.isEmpty()) {
        return;
    }
    
    // Process one record at a time to avoid mixing callouts and DML
    SObject record = records[0];
    List<SObject> remainingRecords = new List<SObject>(records);
    remainingRecords.remove(0);
    
    // Process the first record based on its type
    switch on objectType {
        when 'Lead' {
            DataProcessor.sendLeadToCleverTap((Lead)record);
        }
        when 'Contact' {
            DataProcessor.sendContactToCleverTap((Contact)record);
        }
        when 'Account' {
            DataProcessor.sendAccountToCleverTap((Account)record);
        }
        when 'Opportunity' {
            DataProcessor.sendOpportunityToCleverTap((Opportunity)record);
        }
    }
    
    // Enqueue the next batch if there are more records
    if (!remainingRecords.isEmpty()) {
        System.enqueueJob(new EntityExportJob(remainingRecords));
    }
}
}