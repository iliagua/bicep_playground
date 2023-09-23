

param location string = resourceGroup().location

resource stg 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'ilya${uniqueString(resourceGroup().id)}stg'
  location: location 
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'BlobStorage' 
  properties: {
    accessTier: 'Hot'
  }
}

output blobUri string = stg.properties.primaryEndpoints.blob
