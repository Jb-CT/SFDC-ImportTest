import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getEventLogs from '@salesforce/apex/EventLogController.getEventLogs';
import getEventDetails from '@salesforce/apex/EventLogController.getEventDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EventLogViewer extends NavigationMixin(LightningElement) {
    @track eventLogs = [];
    @track isLoading = false;
    @track statusFilter = '';
    @track timeFilter = '7';
    @track recordLimit = '50';
    @track wiredLogsResult;
    @track columns = [
        {
            label: 'Event Number',
            fieldName: 'Name',
            type: 'text',
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'CleverTap__Status__c',
            type: 'text',
            sortable: true,
            cellAttributes: {
                class: { fieldName: 'statusClass' }
            }
        },
        {
            label: 'Date',
            fieldName: 'CreatedDate',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'numeric',
                day: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            },
            sortable: true
        },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View Details', name: 'view_details' }
                ]
            }
        }
    ];

    @track showEventDetailsModal = false;
    @track selectedEvent = {};
    @track selectedEventId;
    
    get formattedResponse() {
        if (this.selectedEvent && this.selectedEvent.CleverTap__Response__c) {
            try {
                const responseObj = JSON.parse(this.selectedEvent.CleverTap__Response__c);
                return JSON.stringify(responseObj, null, 2);
            } catch (e) {
                return this.selectedEvent.CleverTap__Response__c;
            }
        }
        return '';
    }
    
    get selectedEventStatusClass() {
        if (this.selectedEvent && this.selectedEvent.CleverTap__Status__c) {
            return this.selectedEvent.CleverTap__Status__c === 'Success' ? 'slds-theme_success' : 'slds-theme_error';
        }
        return '';
    }
    
    get noRecordsFound() {
        return !this.isLoading && (!this.eventLogs || this.eventLogs.length === 0);
    }
    
    get statusOptions() {
        return [
            { label: 'All Statuses', value: '' },
            { label: 'Success', value: 'Success' },
            { label: 'Failed', value: 'Failed' }
        ];
    }
    
    get timeOptions() {
        return [
            { label: 'Last 24 hours', value: '1' },
            { label: 'Last 7 days', value: '7' },
            { label: 'Last 30 days', value: '30' },
            { label: 'Last 90 days', value: '90' },
            { label: 'All time', value: '1000' }
        ];
    }
    
    get limitOptions() {
        return [
            { label: '10 records', value: '10' },
            { label: '50 records', value: '50' },
            { label: '100 records', value: '100' },
            { label: '500 records', value: '500' }
        ];
    }
    
    @wire(getEventLogs, { 
        recordLimit: '$recordLimit', 
        status: '$statusFilter', 
        days: '$timeFilter' 
    })
    wiredLogs(result) {
        this.wiredLogsResult = result;
        const { data, error } = result;
        
        if (data) {
            this.processLogData(data);
        } else if (error) {
            this.handleError(error);
        }
    }

    processLogData(data) {
        this.eventLogs = data.map(log => {
            const statusClass = log.CleverTap__Status__c === 'Success' ? 'slds-text-color_success' : 'slds-text-color_error';
            
            return {
                ...log,
                statusClass
            };
        });
    }
    
    handleStatusFilterChange(event) {
        this.statusFilter = event.detail.value;
    }
    
    handleTimeFilterChange(event) {
        this.timeFilter = event.detail.value;
    }
    
    handleLimitChange(event) {
        this.recordLimit = event.detail.value;
    }
    
    refreshData() {
        this.isLoading = true;
        refreshApex(this.wiredLogsResult)
            .then(() => {
                this.isLoading = false;
                this.showToast('Success', 'Data refreshed successfully', 'success');
            })
            .catch(error => {
                this.isLoading = false;
                this.handleError(error);
            });
    }
    
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'view_details') {
            this.viewEventDetails(row.Id);
        }
    }
    
    async viewEventDetails(eventId) {
        this.isLoading = true;
        this.selectedEventId = eventId;
        
        try {
            const eventDetails = await getEventDetails({ recordId: eventId });
            this.selectedEvent = eventDetails;
            this.showEventDetailsModal = true;
        } catch (error) {
            this.handleError(error);
        } finally {
            this.isLoading = false;
        }
    }
    
    closeEventDetailsModal() {
        this.showEventDetailsModal = false;
        this.selectedEvent = {};
        this.selectedEventId = null;
    }
    
    handleError(error) {
        console.error('Error:', error);
        let message = 'An error occurred while fetching data';
        if (error.body && error.body.message) {
            message = error.body.message;
        } else if (typeof error === 'string') {
            message = error;
        }
        this.showToast('Error', message, 'error');
    }
    
    showToast(title, message, variant) {
        const toast = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(toast);
    }
}