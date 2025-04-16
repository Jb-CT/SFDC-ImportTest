/**
 * @class EntityExportJob
 * @description A generic Queueable class that processes Salesforce records and sends them to CleverTap.
 */
@SuppressWarnings('PMD.QueueableWithoutFinalizer')
public class EntityExportJob implements Queueable, Database.AllowsCallouts {
    private final List<SObject> records;
    private final String objectType;
    private final DIModule diModule;

    @TestVisible private static Boolean disableChaining = false;

    public EntityExportJob(SObject record, DIModule module) {
        this.records = new List<SObject>{record};
        this.objectType = record.getSObjectType().getDescribe().getName();
        this.diModule = module;
    }

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

    public EntityExportJob(SObject record) {
        this(record, new DIModuleMain());
    }

    public EntityExportJob(List<SObject> records) {
        this(records, new DIModuleMain());
    }

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
        
        // Only enqueue the next batch if chaining is not disabled
        if (!remainingRecords.isEmpty() && !disableChaining) {
            System.enqueueJob(new EntityExportJob(remainingRecords, diModule));
        }
    }
}