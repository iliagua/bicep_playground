
@description('suffix to use for names in different environments')
param envName string = 'ilyatest'

@description('Location for all resources.')
param location string = resourceGroup().location
var projectName = 'blaqd'
var appServicePlanName = '${projectName}-asp-${envName}'
var webAppName = '${projectName}apiwebapp${envName}'
var webhookName = '${webAppName}webhook${envName}'
var registryName = '${projectName}acr${envName}'
var appStorageAccountName = '${projectName}appstorage${envName}'

param appServiceSkuName string = 'B1'
param appServiceSkuTier string = 'Basic'
param imageName string = 'blaqdservices:latest'
param appStorageAccountSkuName string = 'Standard_RAGRS'


// #section AD -> function -> storage
// https://learn.microsoft.com/en-us/azure/azure-functions/functions-create-first-function-bicep?tabs=CLI
var functionAppName = '${projectName}funcapp${envName}'
var functionAppServicePlanName = '${projectName}-func-asp-${envName}'
var functionStorageAccountName = '${projectName}funcstorage${envName}'
var applicationInsightsName = '${projectName}appinsights${envName}'

param functionStorageAccountSkuName string = 'Standard_LRS'
param functionAppNameSkuName string = 'Y1'
param functionAppNameSkuTier string = 'Dynamic'


@description('Tags')
param tags object = {
  environment: envName
  dveleopedBy: 'ilya'
  repo: 'tbd'
  project: 'blaqd'
}

// #section API
resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
  }
  sku: {
    name: appServiceSkuName
    tier: appServiceSkuTier
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
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
}

// IDK why it's working - https://github.com/Azure/bicep/discussions/3352
resource publishingcreds 'Microsoft.Web/sites/config@2021-01-01' existing = {
  name: '${webAppName}/publishingcredentials'
}
var creds = list(publishingcreds.id, publishingcreds.apiVersion).properties.scmUri

// webhook
resource symbolicname 'Microsoft.ContainerRegistry/registries/webhooks@2023-01-01-preview' = {
  name:webhookName
  location: location
  tags: tags
  parent: acr
  properties: {
    actions: [
      'push'
    ]
    status: 'enabled'
    scope: imageName
    serviceUri: '${creds}/api/registry/webhook'
  }
}

resource appStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: appStorageAccountName
  location: location
  sku: {
    name: appStorageAccountSkuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  kind: 'StorageV2'
}

resource storageBlobDataContributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '17d1049b-9a84-46fb-8f53-869881c3d3ab'
}

resource blobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webApp.id, storageBlobDataContributorRoleDefinition.id)
  scope: appStorageAccount
  properties: {
    roleDefinitionId: storageBlobDataContributorRoleDefinition.id
    principalId: webApp.identity.principalId
  }
}
// #endsection API^

// #section AD -> function -> storage
// ACP first
resource functionAppServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: functionAppServicePlanName
  location: location
  sku: {
    name: functionAppNameSkuName
    tier: functionAppNameSkuTier
  }
}

resource functionStorageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: functionStorageAccountName
  location: location
  sku: {
    name: functionStorageAccountSkuName
  }
  kind: 'StorageV2'
}

resource functionApp 'Microsoft.Web/sites@2021-02-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: functionAppServicePlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'node18'
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${functionStorageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionStorageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
      ]
    }
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

// notification hub
@description('The name of the Notification Hubs namespace.')
var notificationNamespaceName = 'ntfns-${projectName}-${envName}'
var clientName = 'ntf-${projectName}-client-${envName}'
var driverName = 'ntf-${projectName}-driver-${envName}'


resource notificationNamespace 'Microsoft.NotificationHubs/namespaces@2017-04-01' = {
  name: notificationNamespaceName
  location: location
  sku: {
    name: 'Free'
  }
}

resource notificationClientHub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2017-04-01' = {
  name: clientName
  location: location
  parent: notificationNamespace
  properties: {
  }
}

resource notificationDriverHub 'Microsoft.NotificationHubs/namespaces/notificationHubs@2017-04-01' = {
  name: driverName
  location: location
  parent: notificationNamespace
  properties: {
  }
}


