
@description('suffix to use for names in different environments')
param envName string = 'nef'

@description('Location for all resources.')
param location string = resourceGroup().location

var projectName = 'ilyatest'

var appServicePlanName = '${projectName}-asp-${envName}'
var webAppName = '${projectName}apiwebapp${envName}'
var webhookName = '${webAppName}webhook${envName}'
var registryName = '${projectName}acr${envName}'
var appStorageAccountName = '${projectName}appstorage${envName}'

var appServiceSkuName = 'B1'
var appServiceSkuTier = 'Basic'
var imageName = '${projectName}:latest'
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
  project: 'playground'
}



// #section API
// resource appServicePlan 'Microsoft.Web/serverfarms@2020-12-01' = {
//   name: appServicePlanName
//   location: location
//   kind: 'linux'
//   properties: {
//     reserved: true
//     perSiteScaling: false
//   }
//   sku: {
//     name: appServiceSkuName
//     tier: appServiceSkuTier
//   }
// }

// resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
//   name: 'vnet-${projectName}-${envName}'
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: [
//         '10.6.0.0/16'
//       ]
//     }
//     subnets: [
//       {
//         name: 'apps'
//         properties: {
//           addressPrefix: '10.6.0.0/24'
//           delegations: [
//             {
//               name: 'Microsoft.Web/serverFarms'
//               properties: {
//                 serviceName: 'Microsoft.Web/serverFarms'
//               }
//             }
//           ]
//         }
//       }
//       {
//         name: 'privatelink'
//         properties: {
//           addressPrefix: '10.6.1.0/24'
//         }
//       }
//       {
//         name: 'functions'
//         properties: {
//           addressPrefix: '10.6.2.0/24'
//           delegations: [
//             {
//               name: 'Microsoft.Web/serverFarms'
//               properties: {
//                 serviceName: 'Microsoft.Web/serverFarms'
//               }
//             }
//           ]
//         }
//       }
//     ]
//   }
//   resource functionsSubnet 'subnets' existing = {
//     name: 'functions'
//   }
// }


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

// container reference "value": "DOCKER|blaqddev.azurecr.io/blaqdservices:latest"
// resource webApp 'Microsoft.Web/sites@2021-01-01' = {
//   name: webAppName
//   location: location
//   properties: {
//     siteConfig: {
//       appSettings: []
//       acrUseManagedIdentityCreds: true
//       linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/${imageName}'
//     }
//     serverFarmId: appServicePlan.id
//     virtualNetworkSubnetId: vnet.properties.subnets[0].id
//     httpsOnly: true
//   }
//   identity: {
//     type: 'SystemAssigned'
//   }
//   tags: tags
// }

// // IDK why it's working - https://github.com/Azure/bicep/discussions/3352
// resource publishingcreds 'Microsoft.Web/sites/config@2021-01-01' existing = {
//   name: '${webAppName}/publishingcredentials'
// }
// var creds = list(publishingcreds.id, publishingcreds.apiVersion).properties.scmUri

// // webhook
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
//     serviceUri: '${creds}/api/registry/webhook'
//   }
// }


