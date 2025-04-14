/**
 * @class EntityExportJob
 * @description A generic Queueable class that processes Salesforce records and sends them to CleverTap.
 */
@SuppressWarnings('PMD.QueueableWithoutFinalizer')
public class EntityExportJob implements Queueable, Database.AllowsCallouts {
    private List<SObject> records;
    private String objectType;
    private DIModule diModule;

    /**
     * @description Constructor for processing a single SObject record with dependency injection.
     * @param record A single Salesforce record.
     * @param module The dependency injection module.
     */
    public EntityExportJob(SObject record, DIModule module) {
        this.records = new List<SObject>{record};
        this.objectType = record.getSObjectType().getDescribe().getName();
        this.diModule = module;
    }
    
    /**
     * @description Constructor for processing multiple SObject records with dependency injection.
     * @param records A list of Salesforce records of the same type.
     * @param module The dependency injection module.
     */
    public EntityExportJob(List<SObject> records, DIModule module) {
        if (records == null || records.isEmpty()) {
            this.records = new List<SObject>();
            this.objectType = '';
        } else {
            this.records = records;
            this.objectType = records[0].getSObjectType().getDescribe().getName();
        }
        this.diModule = module;
    }

    /**
     * @description Constructor for processing a single SObject record (backwards compatibility).
     * @param record A single Salesforce record.
     */
    public EntityExportJob(SObject record) {
        this(record, new DIModuleMain());
    }

    /**
     * @description Constructor for processing multiple SObject records (backwards compatibility).
     * @param records A list of Salesforce records of the same type.
     */
    public EntityExportJob(List<SObject> records) {
        this(records, new DIModuleMain());
    }

    /**
     * @description Executes the job to send each record to CleverTap.
     * @param context The Queueable context.
     */
    public void execute(QueueableContext context) {
        if (records.isEmpty()) {
            return;
        }
        
        // Get the service implementation from the DI module
        DataProcessor service = diModule.provideCleverTapService();
        
        // Process one record at a time to avoid mixing callouts and DML
        SObject record = records[0];
        List<SObject> remainingRecords = new List<SObject>(records);
        remainingRecords.remove(0);
        
        // Process the first record based on its type
        switch on objectType {
            when 'Lead' {
                service.sendLeadToCleverTap((Lead)record);
            }
            when 'Contact' {
                service.sendContactToCleverTap((Contact)record);
            }
            when 'Account' {
                service.sendAccountToCleverTap((Account)record);
            }
            when 'Opportunity' {
                service.sendOpportunityToCleverTap((Opportunity)record);
            }
        }
        
        // Enqueue the next batch if there are more records
        if (!remainingRecords.isEmpty()) {
            System.enqueueJob(new EntityExportJob(remainingRecords, diModule));
        }
    }
}