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

resource ActiveDirectoryDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: '${automationaccountname}/ActiveDirectoryDsc'
  dependsOn: [
    AutomationAccount
  ]
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/packages/ActiveDirectoryDsc/6.2.0'
      version: '6.2.0'
    }
  }
}

resource ComputerManagementDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: '${automationaccountname}/ComputerManagementDsc'
  dependsOn: [
    AutomationAccount
    ActiveDirectoryDsc
  ]
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/packages/ComputerManagementDsc/8.5.0'
      version: '8.5.0'
    }
  }
}

resource PSDesiredStateConfiguration 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: '${automationaccountname}/PSDesiredStateConfiguration'
  dependsOn: [
    AutomationAccount
    ActiveDirectoryDsc
    ComputerManagementDsc
  ]
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/packages/PSDesiredStateConfiguration/2.0.5'
      version: '2.0.5'
    }
  }
}

resource NetworkingDsc 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  name: '${automationaccountname}/NetworkingDsc'
  dependsOn: [
    AutomationAccount
    ActiveDirectoryDsc
    ComputerManagementDsc
    PSDesiredStateConfiguration
  ]
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/packages/NetworkingDsc/9.0.0'
      version: '9.0.0'
    }
  }
}
