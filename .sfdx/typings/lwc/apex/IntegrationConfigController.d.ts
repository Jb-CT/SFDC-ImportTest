declare module "@salesforce/apex/IntegrationConfigController.getConfigurations" {
  export default function getConfigurations(): Promise<any>;
}
declare module "@salesforce/apex/IntegrationConfigController.validateCredentials" {
  export default function validateCredentials(param: {region: any, accountId: any, passcode: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationConfigController.saveConfiguration" {
  export default function saveConfiguration(param: {config: any}): Promise<any>;
}
declare module "@salesforce/apex/IntegrationConfigController.deleteConfiguration" {
  export default function deleteConfiguration(param: {configId: any}): Promise<any>;
}
