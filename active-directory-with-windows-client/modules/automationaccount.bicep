@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location
param automationaccountname string

resource AutomationAccount 'Microsoft.Automation/automationAccounts@2022-08-08' = {
  name: automationaccountname
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: true
    sku: {
      family: 'string'
      name: 'Basic'
    }
  }
}
