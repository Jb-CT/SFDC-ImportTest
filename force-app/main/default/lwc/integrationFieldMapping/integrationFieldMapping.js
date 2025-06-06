import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSalesforceFields from '@salesforce/apex/IntegrationSyncController.getSalesforceFields';
import saveFieldMappings from '@salesforce/apex/IntegrationSyncController.saveFieldMappings';
import getExistingMappings from '@salesforce/apex/IntegrationSyncController.getExistingMappings';

export default class IntegrationFieldMapping extends LightningElement {
    @api syncId;
    @api sourceEntity;
    @api targetEntity;

    @track sourceFields = [];
    @track mandatoryFieldMapping = { 
        Identity: '',
        event_name: ''
    };
    @track additionalMappings = [];
    @track isLoading = false;

    dataTypeOptions = [
        { label: 'Text', value: 'Text' },
        { label: 'Number', value: 'Number' },
        { label: 'Date', value: 'Date' },
        { label: 'Boolean', value: 'Boolean' }
    ];

    get showEmptyState() {
        return this.additionalMappings.length === 0;
    }
    
    get isEventEntity() {
        return this.targetEntity === 'event';
    }
    
    connectedCallback() {
        if (this.sourceEntity) {
            this.loadSourceFields();
            this.loadExistingMappings();
        }
        
        if (this.isEventEntity && !this.mandatoryFieldMapping.event_name) {
            this.mandatoryFieldMapping.event_name = 'sf_' + this.sourceEntity?.toLowerCase();
        }
    }

    async loadSourceFields() {
        try {
            this.isLoading = true;
            const fields = await getSalesforceFields({ objectName: this.sourceEntity });
            if (fields) {
                this.sourceFields = fields.map(field => ({
                    label: field.label,
                    value: field.value
                }));
            }
        } catch (error) {
            this.showToast('Error', 'Failed to load source fields: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    async loadExistingMappings() {
        if (!this.syncId) return;

        try {
            this.addPredefinedFieldsIfNeeded();
            const existingMappings = await getExistingMappings({ syncId: this.syncId });
            if (existingMappings) {
                const customerIdMapping = existingMappings.find(m => m.CleverTap__Field__c === 'Identity' && m.CleverTap__Is_Mandatory__c);
                if (customerIdMapping) {
                    this.mandatoryFieldMapping.Identity = customerIdMapping.CleverTap__Salesforce_Field__c;
                }
                
                const eventNameMapping = existingMappings.find(m => m.CleverTap__Field__c === 'evtName' && m.CleverTap__Is_Mandatory__c);
                if (eventNameMapping) {
                    this.mandatoryFieldMapping.event_name = eventNameMapping.CleverTap__Salesforce_Field__c;
                }

                this.additionalMappings = existingMappings
                    .filter(m => !m.CleverTap__Is_Mandatory__c)
                    .map(m => ({
                        id: Date.now() + Math.random(),
                        targetField: m.CleverTap__Field__c,
                        sourceField: m.CleverTap__Salesforce_Field__c,
                        dataType: m.CleverTap__Data_Type__c || 'Text'
                    }));
            }
            
            this.addPredefinedFieldsIfNeeded();
        } catch (error) {
            this.showToast('Error', 'Failed to load existing mappings: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
        }
    }
    
    addPredefinedFieldsIfNeeded() {
        if (this.isEventEntity && this.sourceEntity == 'Lead') {
            const hasStatusField = this.additionalMappings.some(
                mapping => mapping.targetField === 'status'
            );
            
            if (!hasStatusField) {
                this.additionalMappings.push({
                    id: Date.now() + Math.random(),
                    targetField: 'status',
                    sourceField: '',
                    dataType: 'Text'
                });
            }
        }
    }

    handleCustomerIdChange(event) {
        this.mandatoryFieldMapping.Identity = event.detail.value;
    }
    
    handleEventNameChange(event) {
        this.mandatoryFieldMapping.event_name = event.target.value;
    }

    handleTargetFieldChange(event) {
        const index = parseInt(event.target.dataset.index);
        if (this.additionalMappings[index]) {
            this.additionalMappings[index] = {
                ...this.additionalMappings[index],
                targetField: event.target.value
            };
        }
    }

    handleSourceFieldChange(event) {
        const index = parseInt(event.target.dataset.index);
        if (this.additionalMappings[index]) {
            this.additionalMappings[index] = {
                ...this.additionalMappings[index],
                sourceField: event.detail.value
            };
        }
    }

    handleDataTypeChange(event) {
        const index = parseInt(event.target.dataset.index);
        if (this.additionalMappings[index]) {
            this.additionalMappings[index] = {
                ...this.additionalMappings[index],
                dataType: event.detail.value
            };
        }
    }

    handleAddField() {
        this.additionalMappings.push({
            id: Date.now(),
            targetField: '',
            sourceField: '',
            dataType: 'Text'
        });
    }

    handleDeleteMapping(event) {
        const index = parseInt(event.target.dataset.index);
        this.additionalMappings = this.additionalMappings.filter((_, i) => i !== index);
    }

    async handleSave() {
        if (!this.validateMappings()) {
            return;
        }

        try {
            this.isLoading = true;

            const mappings = [
                {
                    CleverTap__Field__c: 'Identity',
                    CleverTap__Salesforce_Field__c: this.mandatoryFieldMapping.Identity,
                    CleverTap__Data_Type__c: 'Text',
                    CleverTap__Is_Mandatory__c: true
                }
            ];
            
            if (this.isEventEntity) {
                mappings.push({
                    CleverTap__Field__c: 'evtName',
                    CleverTap__Salesforce_Field__c: this.mandatoryFieldMapping.event_name,
                    CleverTap__Data_Type__c: 'Text',
                    CleverTap__Is_Mandatory__c: true
                });
            }
            
            const mappingData = {
                syncId: this.syncId,
                mappings: [
                    ...mappings,
                    // Additional mappings
                    ...this.additionalMappings
                        .filter(m => m.targetField && m.sourceField)
                        .map(m => ({
                            CleverTap__Field__c: m.targetField,
                            CleverTap__Salesforce_Field__c: m.sourceField,
                            CleverTap__Data_Type__c: m.dataType || 'Text',
                            CleverTap__Is_Mandatory__c: false
                        }))
                ]
            };

            await saveFieldMappings({ 
                mappingData: JSON.stringify(mappingData) 
            });

            this.showToast('Success', 'Field mappings saved successfully', 'success');
            this.dispatchEvent(new CustomEvent('save'));

        } catch (error) {
            this.showToast('Error', 'Failed to save mappings: ' + (error.body?.message || error.message || 'Unknown error'), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    validateMappings() {
        if (!this.mandatoryFieldMapping.Identity) {
            this.showToast('Error', 'Please map the mandatory customer ID field', 'error');
            return false;
        }
        
        if (this.isEventEntity && !this.mandatoryFieldMapping.event_name) {
            this.showToast('Error', 'Please provide an event name', 'error');
            return false;
        }

        const allValid = [...this.template.querySelectorAll('lightning-input,lightning-combobox')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);

        if (!allValid) {
            return false;
        }

        const targetFields = this.additionalMappings
            .filter(m => m.targetField)
            .map(m => m.targetField.toLowerCase());

        const hasDuplicates = targetFields.length !== new Set(targetFields).size;
        if (hasDuplicates) {
            this.showToast('Error', 'Duplicate target field names are not allowed', 'error');
            return false;
        }

        return true;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}