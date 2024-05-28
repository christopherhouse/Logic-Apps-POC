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

// Custom bicep function to accept a parameter named resourceName that returns output in the format of '${resourceName}-${deployment().name}'
func generateDeploymentName(resourceName string) string => '${resourceName}-${deployment().name}'

// Log Analytics Workspace
module law './modules/logAnalytics/logAnalyticsWorkspace.bicep' = {
  name: generateDeploymentName(lawName)
  params: {
    location: location
    logAnalyticsWorkspaceName: lawName
    retentionInDays: logAnalyticsRetentionDays
  }
}
