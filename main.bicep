
@description('suffix to use for names in different environments')
param envName string = 'ilyatest'

@description('Location for all resources.')
param location string = resourceGroup().location

// all for app service plane
param appServicePlanName string = 'blaqd-api-plan-${envName}'
param appServiceScuName string = 'B1'
param appServiceScuTier string = 'Basic'
param webAppName string = 'blaqdapiwebapp${envName}'
param registryName string = 'blaqdacr${envName}'
// param webhookName string = '${webAppName}webhook${envName}'
param imageName string = 'blaqdservices:latest'

@description('Tags')
param tags object = {
  environment: envName
  dveleopedBy: 'ilya'
  repo: 'tbd'
  project: 'blaqd'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: appServiceScuName
    tier: appServiceScuTier
  }
  
}

// containerRegistry
resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: registryName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
  }
}

// container reference "value": "DOCKER|blaqddev.azurecr.io/blaqdservices:latest"
resource webApp 'Microsoft.Web/sites@2021-01-01' = {
  name: webAppName
  location: location
  properties: {
    siteConfig: {
      appSettings: []
      acrUseManagedIdentityCreds: true
      linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/${imageName}'
    }
    serverFarmId: appServicePlan.id
  }
  tags: tags
}

// why do i need that?


// webhook
// resource symbolicname 'Microsoft.ContainerRegistry/registries/webhooks@2023-01-01-preview' = {
//   name:webhookName
//   location: location
//   tags: tags
//   parent: acr
//   properties: {
//     actions: [
//       'push'
//     ]
//     status: 'enabled'
//     scope: imageName
//     serviceUri: webApp.properties.defaultHostName
//   }
// }

