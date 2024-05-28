@export()
func formatDeploymentName(resourceName string) string => '${resourceName}-${deployment().name}'

@export()
func formatResourceName(workloadName string, environmentSuffix string, resourceSuffix string) string => '${workloadName}-${environmentSuffix}-${resourceSuffix}'
