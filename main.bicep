
@description('suffix to use for names in different environments')
param envName string = 'nef'

@description('Location for all resources.')
param location string = resourceGroup().location

var projectName = 'ilyatest'

var appServicePlanName = '${projectName}-asp-${envName}'
var webAppName = '${projectName}apiwebapp${envName}'
var webhookName = '${webAppName}webhook${envName}'

var appServiceSkuName = 'B1'
var appServiceSkuTier = 'Basic'
var imageName = '${projectName}:latest'

@description('Tags')
param tags object = {
  environment: envName
  dveleopedBy: 'ilya'
  project: 'playground'
}

// #section API
resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
  name: appServicePlanName
  location: location
  kind: 'linux'
  properties: {
    reserved: true
    perSiteScaling: false
  }
  sku: {
    name: appServiceSkuName
    tier: appServiceSkuTier
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'vnet-${projectName}-${envName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.6.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'apps'
        properties: {
          addressPrefix: '10.6.0.0/24'
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: 'privatelink'
        properties: {
          addressPrefix: '10.6.1.0/24'
        }
      }
      {
        name: 'functions'
        properties: {
          addressPrefix: '10.6.2.0/24'
          delegations: [
            {
              name: 'Microsoft.Web/serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
  resource functionsSubnet 'subnets' existing = {
    name: 'functions'
  }
}


// Create container registry for API
resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: '${projectName}${envName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}


// container reference "value": "DOCKER|ilyatestnef.azurecr.io/ilyaservices:latest"
resource webApp 'Microsoft.Web/sites@2021-01-01' = {
  name: webAppName
  location: location
  properties: {
    siteConfig: {
      appSettings: []
      acrUseManagedIdentityCreds: true
      linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/${imageName}'
      alwaysOn: true
    }
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: vnet.properties.subnets[0].id
    httpsOnly: true
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
}

// https://www.xprtz.net/azure-app-service-container-bicep
resource publishingcreds 'Microsoft.Web/sites/config@2022-03-01' existing = {
  name: '${webAppName}/publishingcredentials'
}
var creds = publishingcreds.list().properties.scmUri

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

resource acrReaderRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

resource acrReaderAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, webApp.id, acrReaderRoleDefinition.id, envName, envName)
  scope: acr
  properties: {
    roleDefinitionId: acrReaderRoleDefinition.id
    principalId: webApp.identity.principalId
  }
}
