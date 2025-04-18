declare module "@salesforce/apex/EventLogController.getEventLogs" {
  export default function getEventLogs(param: {recordLimit: any, status: any, days: any}): Promise<any>;
}
declare module "@salesforce/apex/EventLogController.getEventDetails" {
  export default function getEventDetails(param: {recordId: any}): Promise<any>;
}
