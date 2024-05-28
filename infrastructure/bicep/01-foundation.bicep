import * as vn from './modules/virtualNetwork/virtualNetwork.bicep'
import * as func from './modules/userDefined/userDefinedFunctions.bicep'

param workloadName string
param environmentSuffix string
param location string
param addressPrefixes array
param subnetConfigurations vn.subnetConfigurationsType
param logAnalyticsRetentionDays int
param tags object = {}

// Vnet
var vnetName = '${workloadName}-${environmentSuffix}-vnet'

// Log Analytics
var lawName = '${workloadName}-${environmentSuffix}-law'

// NSGs
var apimNsgName = '${workloadName}-${environmentSuffix}-apim-nsg'
var appGwNsgName = '${workloadName}-${environmentSuffix}-appgw-nsg'
var servicesNsgName = '${workloadName}-${environmentSuffix}-services-nsg'

// Key Vault
var keyVaultName = func.formatResourceName(workloadName, environmentSuffix, 'kv')

// App Insights
var appInsightsName = func.formatResourceName(workloadName, environmentSuffix, 'ai')

// Log Analytics Workspace
module law './modules/logAnalytics/logAnalyticsWorkspace.bicep' = {
  name: func.formatDeploymentName(lawName)
  params: {
    location: location
    logAnalyticsWorkspaceName: lawName
    retentionInDays: logAnalyticsRetentionDays
    tags: tags
  }
}

module apimNsg './modules/networkSecurityGroup/apimNetworkSecurityGroup.bicep' = {
  name: func.formatDeploymentName(apimNsgName)
  params: {
    location: location
    apimSubnetRange: subnetConfigurations.apimSubnet.addressPrefix
    appGatewaySubnetRange: subnetConfigurations.appGwSubnet.addressPrefix
    logAnalyticsWorkspaceResourceId: law.outputs.id
    nsgName: apimNsgName
    tags: tags
  }
}

module appGwNsg './modules/networkSecurityGroup/applicationGatewayNetworkSecurityGroup.bicep' = {
  name: func.formatDeploymentName(appGwNsgName)
  params: {
    location: location
    appGatewaySubnetAddressSpace: subnetConfigurations.appGwSubnet.addressPrefix
    logAnalyticsWorkspaceResourceId: law.outputs.id
    networkSecurityGroupName: appGwNsgName
    tags: tags
  }
}

module servicesNsg './modules/networkSecurityGroup/servicesNetworkSecurityGroup.bicep' = {
  name: func.formatDeploymentName(servicesNsgName)
  params: {
    location: location
    apimSubnetRange: subnetConfigurations.apimSubnet.addressPrefix
    appGatewaySubnetRange: subnetConfigurations.appGwSubnet.addressPrefix
    servicesSubnetRange: subnetConfigurations.keyVaultSubnet.addressPrefix
    logAnalyticsWorkspaceId: law.outputs.id
    networkSecurityGroupName: servicesNsgName
    tags: tags
  }
}

module vnet './modules/virtualNetwork/virtualNetwork.bicep' = {
  name: func.formatDeploymentName(vnetName)
  params: {
    location: location
    addressPrefixes: addressPrefixes
    apimNsgResourceId: apimNsg.outputs.id
    appGwNsgResourceId: appGwNsg.outputs.id
    servicesNsgResourceId: servicesNsg.outputs.id
    subnetConfiguration: subnetConfigurations
    virtualNetworkName: vnetName
    tags: tags
  }
}

module kv './modules/keyVault/privateKeyVault.bicep' = {
  name: func.formatDeploymentName(keyVaultName)
  params: {
    location: location
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceResourceId: law.outputs.id
    servicesSubnetResourceId: vnet.outputs.kvSubnetId
    vnetName: vnetName
  }
}

module ai './modules/applicationInsights/applicationInsights.bicep' = {
  name: func.formatDeploymentName(appInsightsName)
  params: {
    location: location
    appInsightsName: appInsightsName
    keyVaultName: keyVaultName
    logAnalyticsWorkspaceId: law.outputs.id
  }
}
