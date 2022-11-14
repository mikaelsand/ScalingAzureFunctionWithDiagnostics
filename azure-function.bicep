@allowed([
  'DEV'
  'ACC'
  'PROD'
])
param env string
param location string

var appInsightName = 'SYS001-systemName-${env}-appi'
var logAnalyticsName = 'SYS001-SystemName-${env}-log'
var funcName = 'SYS001-SystemName-${env}-FN'
var funcServicePlanName = 'ASP-functionplan-${env}'
var storageAccountName = 'myFuncStorage01'

var nodeVersion = 'Node|18'

// SKU and Properties for the serviceplan.
var EnvironmentSettings = {
  PROD: {
    sku: {
      tier: 'PremiumV2'
      name: 'P1v2'
      size: 'P1v2'
      family: 'Pv2'
      capacity: 1
    }
    alwaysOn: true
  }
  ACC: {
    sku: {
      tier: 'PremiumV2'
      name: 'P1v2'
      size: 'P1v2'
      family: 'Pv2'
      capacity: 1
    }
    alwaysOn: true
  }
  DEV: {
    sku: {
      tier: 'Dynamic'
      name: 'Y1'
      capacity: 0
    }
    alwaysOn: false
  }
}


resource azureFunctionApp 'Microsoft.Web/sites@2020-12-01' = {
  name: funcName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: funcServicePlan.id
    siteConfig: {
      linuxFxVersion: nodeVersion
      alwaysOn: EnvironmentSettings[env].alwaysOn
    }
  }
  tags: resourceGroup().tags
}


module appSettings 'appSettings.bicep' = {
  name: '${funcName}-appsettings'
  params: {
    functionName: azureFunctionApp.name
    currentAppSettings: list('${azureFunctionApp.id}/config/appsettings', '2020-12-01').properties
    appSettings: {
      'ApplicationInsightsAgent_EXTENSION_VERSION': '~3'
      'APPLICATIONINSIGHTS_CONNECTION_STRING': appInsight.properties.ConnectionString
      'APPINSIGHTS_INSTRUMENTATIONKEY': appInsight.properties.InstrumentationKey
      'FUNCTIONS_WORKER_RUNTIME': 'node'
      'FUNCTIONS_EXTENSION_VERSION': '~4'
      'WEBSITE_CONTENTSHARE': toLower(funcName)
      'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING':'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorage.id, functionStorage.apiVersion).keys[0].value}'
      'AzureWebJobsDashboard':'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorage.id, functionStorage.apiVersion).keys[0].value}'
      'AzureWebJobsStorage':'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(functionStorage.id, functionStorage.apiVersion).keys[0].value}'
    }
  }
}


resource funcServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: funcServicePlanName
  location: location
  kind: 'functionapp'
  sku: EnvironmentSettings[env].sku
  properties: {
    reserved: true
    
  }
  tags: resourceGroup().tags
}

// Function autoscale if we are in PROD
module autoscale1 'autoscale.bicep' = if (env != 'DEV') {
  name: 'autoscale'
  params: {
    location: location
    serviceFarmResourceUri: funcServicePlan.id
    autoscaleName: '${funcServicePlanName}-Autoscale'
    logAnalyticsResourceId: logAnalytics.id
  }
}

resource functionStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
  }
  tags: resourceGroup().tags
}

resource appInsight 'Microsoft.Insights/components@2020-02-02-preview' existing = {
  name: appInsightName
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' existing = {
  name: logAnalyticsName
}
