@description('The Azure Region to deploy the resources into')
param location string = resourceGroup().location

//@description('The name of the Key Vault')
//param keyvaultName string

@description('Key Vault SKU.')
param sku string
param skuCode string

resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: 'kv${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    createMode: 'default'
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    enableRbacAuthorization: true
    enablePurgeProtection: true
    sku: {
      family: skuCode
      name: sku
    }
    softDeleteRetentionInDays: 7
    tenantId: subscription().tenantId
  }
}

output kvUri string = keyVault.properties.vaultUri
