import * as vn from './modules/virtualNetwork/virtualNetwork.bicep'

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

// Custom bicep function to accept a parameter named resourceName that returns output in the format of '${resourceName}-${deployment().name}'
func generateDeploymentName(resourceName string) string => '${resourceName}-${deployment().name}'

// Log Analytics Workspace
module law './modules/logAnalytics/logAnalyticsWorkspace.bicep' = {
  name: generateDeploymentName(lawName)
  params: {
    location: location
    logAnalyticsWorkspaceName: lawName
    retentionInDays: logAnalyticsRetentionDays
    tags: tags
  }
}

module apimNsg './modules/networkSecurityGroup/apimNetworkSecurityGroup.bicep' = {
  name: generateDeploymentName(apimNsgName)
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
  name: generateDeploymentName(appGwNsgName)
  params: {
    location: location
    appGatewaySubnetAddressSpace: subnetConfigurations.appGwSubnet.addressPrefix
    logAnalyticsWorkspaceResourceId: law.outputs.id
    networkSecurityGroupName: appGwNsgName
    tags: tags
  }
}

module servicesNsg './modules/networkSecurityGroup/servicesNetworkSecurityGroup.bicep' = {
  name: generateDeploymentName(servicesNsgName)
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
  name: generateDeploymentName(vnetName)
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
