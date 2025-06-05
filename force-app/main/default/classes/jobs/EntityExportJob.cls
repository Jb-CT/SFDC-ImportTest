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

        DataProcessor service = diModule.provideCleverTapService();

        SObject record = records[0];
        List<SObject> remainingRecords = new List<SObject>(records);
        remainingRecords.remove(0);

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
            when 'Case' {
                service.sendCaseToCleverTap((Case)record);
            }
            when 'Campaign' {
                service.sendCampaignToCleverTap((Campaign)record);
            }
            when 'Event' {
                service.sendEventToCleverTap((Event)record);
            }
            when 'Task' {
                service.sendTaskToCleverTap((Task)record);
            }
            when 'CampaignMember' {
                service.sendCampaignMemberToCleverTap((CampaignMember)record);
            }
            when 'ServiceAppointment' {
                service.sendServiceAppointmentToCleverTap((ServiceAppointment)record);
            }
            when 'Quote' {
                service.sendQuoteToCleverTap((Quote)record);
            }
            when 'Contract' {
                service.sendContractToCleverTap((Contract)record);
            }
            when 'Order' {
                service.sendOrderToCleverTap((Order)record);
            }
            when 'Product2' {
                service.sendProductToCleverTap((Product2)record);
            }
            when 'Pricebook2' {
                service.sendPricebookToCleverTap((Pricebook2)record);
            }
            when 'Asset' {
                service.sendAssetToCleverTap((Asset)record);
            }
            when 'OpportunityLineItem' {
                service.sendOpportunityLineItemToCleverTap((OpportunityLineItem)record);
            }
        }
        
        // Only enqueue the next batch if chaining is not disabled
        if (!remainingRecords.isEmpty() && !disableChaining) {
            System.enqueueJob(new EntityExportJob(remainingRecords, diModule));
        }
    }
}