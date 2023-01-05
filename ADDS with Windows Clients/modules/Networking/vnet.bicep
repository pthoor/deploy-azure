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

output VNet object = virtualNetworkName_resource.properties
