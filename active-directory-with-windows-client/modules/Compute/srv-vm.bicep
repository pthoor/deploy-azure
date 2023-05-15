@description('Admin password')
@secure()
param adminPassword string

@description('Admin username')
param adminUsername string

param srvVMName string = 'srv-Win'

@description('When deploying the stack N times, define the instance - this will be appended to some resource names to avoid collisions.')
param deploymentNumber string = '1'
param virtualNetworkName string = 'vnet'
param srvSubnetName string = 'srvSubnet${deploymentNumber}'
param adDomainName string = 'contoso.com'
param srvToDeploy int

@description('Select a VM SKU')
param vmSize string = 'Standard_B2ms'
param assetLocation string

param location string = resourceGroup().location

var shortDomainName = split(adDomainName, '.')[0]
var pubIpAddressName = toLower('srvPubIp${deploymentNumber}')
var nicName = 'srvnic-${deploymentNumber}-'
var domainJoinOptions = 3
var ConfigRDPUsers = 'ConfigRDPUsers.ps1'
var ConfigRDPUsersUri = '${assetLocation}scripts/ConfigRDPUsers.ps1'

var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var imageSKU = '2022-datacenter'

resource pubIpAddressName_1 'Microsoft.Network/publicIPAddresses@2022-07-01' = [for i in range(0, srvToDeploy): {
  name: '${pubIpAddressName}${i}'
  location: location
  tags: {
    displayName: 'srvPubIP'
    isClient: 'true'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('srvwin${i}-${uniqueString(resourceGroup().id)}')
    }
  }
}]

resource nicName_1 'Microsoft.Network/networkInterfaces@2022-07-01' = [for i in range(0, srvToDeploy): {
  name: '${nicName}${i}'
  location: location
  tags: {
    displayName: 'srvNIC'
    isClient: 'true'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'srv-ipconfig1${deploymentNumber}${i}'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pubIpAddressName_1[i].id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, srvSubnetName)
          }
        }
      }
    ]
  }
  dependsOn: [
    pubIpAddressName_1
  ]
}]

resource srv_Win_srvToDeploy_1_deploymentNumber 'Microsoft.Compute/virtualMachines@2022-08-01' = [for i in range(0, srvToDeploy): {
  name: '${srvVMName}${i}'
  location: location
  tags: {
    displayName: 'srvVM'
    isClient: 'true'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: '${srvVMName}${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
      }
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
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

resource srv_Win_srvToDeploy_1_deploymentNumber_joindomain 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = [for i in range(0, srvToDeploy): {
  name: '${srvVMName}${i}/joindomain'
  location: location
  tags: {
    displayName: 'srvVMJoin'
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
    srv_Win_srvToDeploy_1_deploymentNumber
  ]
}]

resource srv_Win_srvToDeploy_1_deploymentNumber_ConfigRDPUsers 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = [for i in range(0, srvToDeploy): {
  name: '${srvVMName}${i}/ConfigRDPUsers'
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
    srv_Win_srvToDeploy_1_deploymentNumber
  ]
}]
