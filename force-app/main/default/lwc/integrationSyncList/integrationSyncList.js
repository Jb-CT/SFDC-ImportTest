import { LightningElement, track, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getSyncConfigurations from '@salesforce/apex/IntegrationSyncController.getSyncConfigurations';
import deleteSyncConfiguration from '@salesforce/apex/IntegrationSyncController.deleteSyncConfiguration';
import updateSyncStatus from '@salesforce/apex/IntegrationSyncController.updateSyncStatus';
import runHistoricalSync from '@salesforce/apex/IntegrationSyncController.runHistoricalSync';

export default class IntegrationSyncList extends NavigationMixin(LightningElement) {
    @api connectionId;
    @api connectionName;
    
    @track syncRecords = [];
    @track sortBy = 'name';
    @track sortDirection = 'asc';
    @track showDeleteModal = false;
    @track selectedRecordId;
    @track isLoading = false;
    @track wiredSyncResult;
    
    @track showSyncConfig = false;
    @track syncConfigMode = 'new';
    @track syncConfigRecordId;

    columns = [
        { 
            label: 'Sync Name', 
            fieldName: 'name', 
            type: 'text',
            sortable: true 
        },
        { 
            label: 'Sync Type', 
            fieldName: 'syncType', 
            type: 'text',
            sortable: true 
        },
        { 
            label: 'Target Entity', 
            fieldName: 'targetEntity', 
            type: 'text',
            sortable: true 
        },
        { 
            label: 'Source Entity', 
            fieldName: 'sourceEntity', 
            type: 'text',
            sortable: true 
        },
        { 
            label: 'Status', 
            fieldName: 'status', 
            type: 'text',
            sortable: true,
            cellAttributes: { 
                class: { fieldName: 'statusClass' }
            }
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: { fieldName: 'availableActions' }
            }
        }
    ];

    connectedCallback() {
        console.log('Connection ID loaded:', this.connectionId);
        this.loadData();
    }

    @wire(getSyncConfigurations, { connectionId: '$connectionId' })
    wiredConfigs(result) {
        this.wiredSyncResult = result;
        this.loadData();
    }

    loadData() {
        if (this.wiredSyncResult && this.wiredSyncResult.data) {
            this.syncRecords = this.wiredSyncResult.data.map(record => ({
                ...record,
                statusClass: this.getStatusClass(record.status),
                availableActions: this.getRowActions(record)
            }));
        } else if (this.wiredSyncResult && this.wiredSyncResult.error) {
            this.showToast('Error', 'Error fetching sync configurations', 'error');
            console.error('Error:', this.wiredSyncResult.error);
        }
    }

    get hasSyncRecords() {
        return this.syncRecords && this.syncRecords.length > 0;
    }

    get pageTitle() {
        return this.connectionName ? 
            `Field Mappings for ${this.connectionName}` : 
            'Integration Field Mappings';
    }

    getRowActions(row) {
        const actions = [
            { label: 'Edit', name: 'edit' },
            { label: 'Delete', name: 'delete' }
        ];
    
        if (row.status === 'Active') {
            actions.push({ label: 'Deactivate', name: 'deactivate' });
            actions.push({ label: 'Historical Sync', name: 'historicalSync' });
        } else {
            actions.push({ label: 'Activate', name: 'activate' });
        }
    
        return actions;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }
    handleAddNewSync() {
        this.syncConfigMode = 'new';
        this.syncConfigRecordId = null;
        this.showSyncConfig = true;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
    
        switch (action.name) {
            case 'edit':
                this.navigateToEdit(row);
                break;
            case 'delete':
                this.selectedRecordId = row.id;
                this.showDeleteModal = true;
                break;
            case 'activate':
            case 'deactivate':
                this.handleStatusChange(row, action.name);
                break;
            case 'historicalSync':
                this.handleHistoricalSync(row);
                break;
        }
    }

    async handleHistoricalSync(row) {
        try {
            if (!confirm(`Are you sure you want to run a historical sync for "${row.name}"? This will process all existing records of type: ${row.sourceEntity}.`)) {
                return;
            }
            
            this.isLoading = true;
            this.showToast('Info', `Starting historical sync for ${row.sourceEntity} records...`, 'info');
            
            await runHistoricalSync({ syncId: row.id });
            
            this.showToast('Success', `Historical sync initiated for ${row.sourceEntity} records. This may take some time to complete depending on data volume.`, 'success');
        } catch (error) {
            this.showToast('Error', `Error starting historical sync: ${error.body?.message || error.message || 'Unknown error'}`, 'error');
            console.error('Error starting historical sync:', error);
        } finally {
            this.isLoading = false;
        }
    }

    navigateToEdit(row) {
        this.syncConfigMode = 'edit';
        this.syncConfigRecordId = row.id;
        this.showSyncConfig = true;
    }

    getStatusClass(status) {
        switch (status?.toLowerCase()) {
            case 'active':
                return 'slds-text-color_success';
            case 'inactive':
                return 'slds-text-color_weak';
            case 'error':
                return 'slds-text-color_error';
            default:
                return '';
        }
    }

    async handleConfirmDelete() {
        try {
            this.isLoading = true;
            await deleteSyncConfiguration({ syncId: this.selectedRecordId });
            this.showToast('Success', 'Sync configuration deleted successfully', 'success');
            this.showDeleteModal = false;
            this.selectedRecordId = null;
            await this.refreshData();
        } catch (error) {
            this.showToast('Error', 'Error deleting sync configuration', 'error');
            console.error('Error:', error);
        } finally {
            this.isLoading = false;
        }
    }

    handleCancelDelete() {
        this.showDeleteModal = false;
        this.selectedRecordId = null;
    }

    async handleStatusChange(row, action) {
        try {
            this.isLoading = true;
            const newStatus = action === 'activate' ? 'Active' : 'Inactive';
            
            await updateSyncStatus({
                syncId: row.id,
                status: newStatus
            });
            
            await this.refreshData();
            this.showToast('Success', `Sync configuration ${action}d successfully`, 'success');
        } catch (error) {
            this.showToast('Error', `Error ${action}ing sync configuration`, 'error');
            console.error('Error:', error);
        } finally {
            this.isLoading = false;
        }
    }

    handleSyncConfigReturn() {
        this.showSyncConfig = false;
        this.refreshData();
    }

    async refreshData() {
        try {
            this.isLoading = true;
            await refreshApex(this.wiredSyncResult);
            this.loadData();
        } catch (error) {
            console.error('Error refreshing data:', error);
        } finally {
            this.isLoading = false;
        }
    }

    handleSort(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData();
    }

    sortData() {
        const reverse = this.sortDirection === 'asc' ? 1 : -1;
        const cloneData = [...this.syncRecords];

        cloneData.sort((a, b) => {
            const valueA = a[this.sortBy] || '';
            const valueB = b[this.sortBy] || '';
            return valueA > valueB ? 1 * reverse : -1 * reverse;
        });

        this.syncRecords = cloneData;
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