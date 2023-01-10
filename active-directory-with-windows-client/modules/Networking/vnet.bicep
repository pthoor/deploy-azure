@description('Virtual network name')
param virtualNetworkName string

@description('The address range of the new VNET in CIDR format')
param virtualNetworkAddressRange string = '10.0.0.0/16'
param subnets array

param location string = resourceGroup().location

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: virtualNetworkName
  location: location
  tags: {
    displayName: 'virtualNetwork'
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressRange
      ]
    }
    subnets: subnets
  }
}

// Creates an Azure Bastion Subnet and host in the specified virtual network
@description('The address prefix to use for the Bastion subnet')
param addressPrefix string = '192.168.250.0/27'

@description('The name of the Bastion public IP address')
param publicIpName string = 'pip-bastion'

@description('The name of the Bastion host')
param bastionHostName string = 'bastion-jumpbox'

// The Bastion Subnet is required to be named 'AzureBastionSubnet'
var subnetName = 'AzureBastionSubnet'

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-01-01' = {
  name: '${virtualNetworkName}/${subnetName}'
  properties: {
    addressPrefix: addressPrefix
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
}

resource publicIpAddressForBastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: publicIpAddressForBastion.id
          }
        }
      }
    ]
  }
}

output bastionId string = bastionHost.id

output VNet object = virtualNetworkName_resource.properties
