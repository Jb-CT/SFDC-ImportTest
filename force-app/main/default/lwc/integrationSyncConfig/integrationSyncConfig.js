import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createSyncConfiguration from '@salesforce/apex/IntegrationSyncController.createSyncConfiguration';
import getSyncConfigurations from '@salesforce/apex/IntegrationSyncController.getSyncConfigurations';
import getSyncConfigurationById from '@salesforce/apex/IntegrationSyncController.getSyncConfigurationById';
import updateSyncConfiguration from '@salesforce/apex/IntegrationSyncController.updateSyncConfiguration';
import deleteSyncConfiguration from '@salesforce/apex/IntegrationSyncController.deleteSyncConfiguration';

export default class IntegrationSyncConfig extends LightningElement {
    @api recordId;
    @api mode = 'new';
    @api objectName = 'CleverTap__Mapping__c';
    @api fieldName = 'CleverTap__Data_Type__c';
    @api connectionId;
    @api connectionName;
    
    @track picklistOptions = [];
    @track isLoading = false;
    @track syncData = {
        name: '',
        syncType: '',
        sourceEntity: '',
        targetEntity: '',
        status: 'Active', 
        connectionId: ''
    };
    
    @track showBasicConfig = true;
    @track showFieldMapping = false;
    @track syncId;
    @track existingSyncConfigs = [];

    @wire(getSyncConfigurations, { connectionId: '$connectionId' })
    wiredSyncConfigs({ error, data }) {
        if (data) {
            this.existingSyncConfigs = data;
        } else if (error) {
            console.error('Error fetching sync configurations', error);
        }
    }

    connectedCallback() {
        if (this.connectionId) {
            this.syncData.connectionId = this.connectionId;
        }
        
        if (this.mode === 'edit' && this.recordId) {
            this.syncId = this.recordId;
            this.loadSyncConfiguration();
        }
    }

    async loadSyncConfiguration() {
        if (!this.recordId) {
            return;
        }
        
        try {
            this.isLoading = true;
            
            const result = await getSyncConfigurationById({ syncId: this.recordId });
            
            if (result) {
                this.syncData = {
                    name: result.name || '',
                    syncType: result.syncType || '',
                    sourceEntity: result.sourceEntity || '',
                    targetEntity: result.targetEntity || '',
                    status: result.status || 'Inactive',
                    connectionId: this.syncData.connectionId
                };
                
                this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(element => {
                    if (element.name && this.syncData[element.name] !== undefined) {
                        setTimeout(() => {
                            element.value = this.syncData[element.name];
                        }, 0);
                    }
                });
                
                this.syncId = this.recordId;
            } else {
                this.showToast('Warning', 'No data found for this configuration', 'warning');
            }
        } catch (error) {
            this.showToast('Error', 'Error loading sync configuration: ' + (error.message || error.body?.message || 'Unknown error'), 'error');
        } finally {
            this.isLoading = false;
        }
    }

    get syncTypeOptions() {
        return [
            { label: 'Salesforce to CleverTap', value: 'salesforce_to_clevertap' }
        ];
    }

    get sourceEntityOptions() {
        return [
            { label: 'Contact', value: 'Contact' },
            { label: 'Lead', value: 'Lead' },
            { label: 'Account', value: 'Account' },
            { label: 'Opportunity', value: 'Opportunity' },
            { label: 'Case', value: 'Case' },
            { label: 'Campaign', value: 'Campaign' },
            { label: 'Event', value: 'Event' },
            { label: 'Task', value: 'Task' },
            { label: 'Campaign Member', value: 'CampaignMember' },
            { label: 'Service Appointment', value: 'ServiceAppointment' },
            { label: 'Quote', value: 'Quote' },
            { label: 'Contract', value: 'Contract' },
            { label: 'Order', value: 'Order' },
            { label: 'Product', value: 'Product2' },
            { label: 'Price Book', value: 'Pricebook2' },
            { label: 'Asset', value: 'Asset' },
            { label: 'Opportunity Product', value: 'OpportunityLineItem' }
        ];
    }

    get targetEntityOptions() {
        return [
            { label: 'Profile', value: 'profile' },
            { label: 'Event', value: 'event' }
        ];
    }

    handleNameChange(event) {
        this.syncData.name = event.target.value;
    }

    handleSyncTypeChange(event) {
        this.syncData.syncType = event.target.value;
    }

    handleSourceEntityChange(event) {
        this.syncData.sourceEntity = event.target.value;
    }

    handleTargetEntityChange(event) {
        this.syncData.targetEntity = event.target.value;
    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    async handleBack() {
        if (this.mode === 'new' && this.syncId) {
            try {
                this.isLoading = true;
                
                await deleteSyncConfiguration({ syncId: this.syncId });
                
                this.syncId = null;
                this.recordId = null;
                
            } catch (error) {
                console.error('Error deleting sync configuration:', error);
            } finally {
                this.isLoading = false;
            }
        }
        
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    validateDuplicateSourceEntity() {
        if (this.mode === 'edit') {
            return true;
        }
        const duplicate = this.existingSyncConfigs.find(config => 
            config.sourceEntity === this.syncData.sourceEntity &&
            config.status === 'Active'
        );

        if (duplicate) {
            this.showToast(
                'Error', 
                `A sync configuration for "${this.syncData.sourceEntity}" already exists. Please edit the existing configuration instead.`, 
                'error'
            );
            return false;
        }

        return true;
    }

    async handleNext() {
        if (this.validateForm() && this.validateDuplicateSourceEntity()) {
            try {
                this.isLoading = true;
                
                if (this.mode === 'new') {
                    this.syncData.status = 'Active';
                }
                
                if (this.mode === 'edit') {
                    await updateSyncConfiguration({
                        syncId: this.recordId,
                        syncData: JSON.stringify(this.syncData)
                    });
                    this.syncId = this.recordId;
                    this.showToast('Success', 'Sync configuration updated successfully', 'success');
                } else {
                    const result = await createSyncConfiguration({
                        syncData: JSON.stringify(this.syncData)
                    });
                    this.syncId = result;
                    this.recordId = result;
                    this.showToast('Success', 'Sync configuration created successfully', 'success');
                }
                
                await new Promise(resolve => setTimeout(resolve, 100));
                
                this.showBasicConfig = false;
                this.showFieldMapping = true;

                const fieldMappingComponent = this.template.querySelector('c-integration-field-mapping');
                if (fieldMappingComponent) {
                    fieldMappingComponent.syncId = this.syncId;
                }
            } catch (error) {
                const action = this.mode === 'edit' ? 'update' : 'create';
                this.showToast('Error', `Failed to ${action} sync configuration: ${error.message || error.body?.message || 'Unknown error'}`, 'error');
            } finally {
                this.isLoading = false;
            }
        }
    }

    validateForm() {
        const inputFields = this.template.querySelectorAll('lightning-input,lightning-combobox');
        let isValid = true;

        inputFields.forEach(field => {
            if (!field.checkValidity()) {
                field.reportValidity();
                isValid = false;
            }
        });

        if (isValid) {
            if (!this.syncData.name || !this.syncData.syncType || 
                !this.syncData.sourceEntity || !this.syncData.targetEntity) {
                this.showToast('Error', 'Please fill in all required fields', 'error');
                return false;
            }
        }

        return isValid;
    }
    
    handleMappingSave() {
        this.showToast('Success', 'Field mappings saved successfully', 'success');
        this.dispatchEvent(new CustomEvent('save'));
    }

    async handleMappingCancel() {
        if (this.mode === 'new' && this.syncId) {
            try {
                this.isLoading = true;
                
                await deleteSyncConfiguration({ syncId: this.syncId });
                
                this.syncId = null;
                this.recordId = null;
                
            } catch (error) {
                console.error('Error deleting sync configuration:', error);
            } finally {
                this.isLoading = false;
            }
        }

        this.showBasicConfig = true;
        this.showFieldMapping = false;
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

    get capitalizedMode() {
    if (!this.mode) return '';
    return this.mode.charAt(0).toUpperCase() + this.mode.slice(1);
}
}