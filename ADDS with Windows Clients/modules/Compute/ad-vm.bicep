@description('The IP Addresses assigned to the domain controllers (a, b). Remember the first IP in a subnet is .4 e.g. 10.0.0.0/16 reserves 10.0.0.0-3. Specify one IP per server - must match numberofVMInstances or deployment will fail.s')
param adIP string = '10.0.1.4'

@description('Admin password')
@secure()
param adminPassword string

@description('Admin username')
param adminUsername string

@description('Location of scripts')
param DeployADTemplateUri string = 'https://raw.githubusercontent.com/pthoor/deploy-azure/main/ADDS%20with%20Windows%20Clients/scripts/adDSCConfiguration.ps1'

@description('When deploying the stack N times, define the instance - this will be appended to some resource names to avoid collisions.')
param deploymentNumber string = '1'
param adSubnetName string = 'adSubnet${deploymentNumber}'
param adVMName string = 'AZAD'
param adDomainName string = 'contoso.com'

@metadata({ Description: 'The region to deploy the resources into' })
param location string

@description('This is the prefix name of the Network interfaces')
param NetworkInterfaceName string = 'NIC'
param virtualNetworkName string = 'vnet'

@description('This is the allowed list of VM sizes')
param vmSize string = 'Standard_B2ms'

var imageOffer = 'WindowsServer'
var imagePublisher = 'MicrosoftWindowsServer'
var imageSKU = '2022-R2-Datacenter'
var vnetID = resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
var adPubIPName = 'adPubIP${deploymentNumber}'
var adNicName = 'ad-${NetworkInterfaceName}${deploymentNumber}'

resource adPIPName 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: adPubIPName
  location: location
  tags: {
    displayName: 'adPubIP'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: toLower('${adVMName}${deploymentNumber}')
    }
  }
}

resource ad_NicName 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: adNicName
  location: location
  tags: {
    displayName: 'adNIC'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig${deploymentNumber}'
        properties: {
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: resourceId('${vnetID}/subnets/', '${adSubnetName}')
          }
          privateIPAddress: adIP
          publicIPAddress: {
            id: adPIPName.id
          }
        }
      }
    ]
  }
}

resource adVMName_resource 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: adVMName
  location: location
  tags: {
    displayName: 'adVM'
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: adVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSKU
        version: 'latest'
      }
      osDisk: {
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ad_NicName.id
        }
      ]
    }
  }
}

resource adVMName_DeployAD 'Microsoft.Compute/virtualMachines/extensions@2022-08-01' = {
  name: '${adVMName}/DeployAD'
  location: location
  tags: {
    displayName: 'DeployAD'
  }
  properties: {
    type: 'CustomScriptExtension'
    forceUpdateTag: '1.0.1'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        DeployADTemplateUri
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${DeployADTemplateUri} ${adDomainName} ${adminPassword}'
    }
  }
  dependsOn: [
    adVMName_resource
  ]
}

//output ADVMFQDN string = adVMName_resource.properties.DnsSettings.Fqdn
