@description('Admin password')
@secure()
param adminPassword string

@description('Admin username')
param adminUsername string

@description('When deploying the stack N times, define the instance - this will be appended to some resource names to avoid collisions.')
param deploymentNumber string = '1'
param virtualNetworkName string = 'vnet'
param cliSubnetName string = 'cliSubnet${deploymentNumber}'
param adDomainName string = 'contoso.com'
param clientsToDeploy int

@description('Select a VM SKU')
param vmSize string = 'Standard_B2ms'
param assetLocation string

param location string = resourceGroup().location

var shortDomainName = split(adDomainName, '.')[0]
var pubIpAddressName = toLower('cliPubIp${resourceGroup().name}${deploymentNumber}')
var nicName = 'nic-${deploymentNumber}-'
var domainJoinOptions = 3
var ConfigRDPUsers = 'ConfigRDPUsers.ps1'
var ConfigRDPUsersUri = '${assetLocation}scripts/ConfigRDPUsers.ps1'

resource pubIpAddressName_1 'Microsoft.Network/publicIPAddresses@2022-07-01' = [for i in range(0, clientsToDeploy): {
  name: '${pubIpAddressName}${i}'
  location: location
  tags: {
    displayName: 'ClientPubIP'
    isClient: 'true'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('win${i}-${uniqueString(resourceGroup().id)}')
    }
  }
}]

resource nicName_1 'Microsoft.Network/networkInterfaces@2022-07-01' = [for i in range(0, clientsToDeploy): {
  name: '${nicName}${i}'
  location: location
  tags: {
    displayName: 'ClientNIC'
    isClient: 'true'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', '${pubIpAddressName}${i})')
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, cliSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    pubIpAddressName_1
  ]
}]

resource cli_Win_ClientsToDeploy_1_deploymentNumber 'Microsoft.Compute/virtualMachines@2022-08-01' = [for i in range(0, clientsToDeploy): {
  name: 'cli-Win${i}'
  location: location
  tags: {
    displayName: 'ClientVM'
    isClient: 'true'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'win${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-11'
        sku: 'win11-22h2-ent'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicName}${i}')
        }
      ]
    }
  }
  dependsOn: [
    nicName_1
  ]
}]

resource cli_Win_ClientsToDeploy_1_deploymentNumber_joindomain 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = [for i in range(0, clientsToDeploy): {
  name: 'cli-Win${i}/joindomain'
  location: location
  tags: {
    displayName: 'ClientVMJoin'
    isClient: 'true'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: adDomainName
      OUPath: ''
      User: '${shortDomainName}\\${adminUsername}'
      Restart: 'true'
      Options: domainJoinOptions
    }
    protectedSettings: {
      Password: adminPassword
    }
  }
  dependsOn: [
    cli_Win_ClientsToDeploy_1_deploymentNumber
  ]
}]

resource cli_Win_ClientsToDeploy_1_deploymentNumber_ConfigRDPUsers 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = [for i in range(0, clientsToDeploy): {
  name: 'cli-Win${i}/ConfigRDPUsers'
  location: location
  tags: {
    displayName: 'ConfigRDPUsers'
    isClient: 'true'
  }
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    forceUpdateTag: '1.0.1'
    settings: {
      fileUris: [
        ConfigRDPUsersUri
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${ConfigRDPUsers}'
    }
  }
  dependsOn: [
    cli_Win_ClientsToDeploy_1_deploymentNumber
  ]
}]
