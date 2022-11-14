param location string
param serviceFarmResourceUri string
param autoscaleName string
param logAnalyticsResourceId string


resource FunctionplanElastic_Autoscale 'Microsoft.Insights/autoscaleSettings@2022-10-01' = {
  location: location
  tags: {
  }
  properties: {
    name: autoscaleName
    enabled: true
    targetResourceUri: serviceFarmResourceUri
    profiles: [
      {
        name: 'Auto created default scale condition'
        capacity: {
          minimum: '1'
          maximum: '4'
          default: '1'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT15M'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: serviceFarmResourceUri
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 70
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              dimensions: []
              dividePerInstance: false
            }
          }
          {
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: serviceFarmResourceUri
              operator: 'LessThan'
              statistic: 'Average'
              threshold: 30
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT10M'
              dimensions: []
              dividePerInstance: false
            }
          }
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT15M'
            }
            metricTrigger: {
              metricName: 'HttpQueueLength'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: serviceFarmResourceUri
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 70
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT10M'
              dimensions: []
              dividePerInstance: true
            }
          }
          {
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger: {
              metricName: 'HttpQueueLength'
              metricNamespace: 'microsoft.web/serverfarms'
              metricResourceUri: serviceFarmResourceUri
              operator: 'LessThan'
              statistic: 'Average'
              threshold: 20
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT10M'
              dimensions: []
              dividePerInstance: false
            }
          }
        ]
      }
    ]
    notifications: []
    targetResourceLocation: location
  }
  name: autoscaleName
}

resource LogAnalyticsConnection 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'scaling'
  scope: FunctionplanElastic_Autoscale
  properties: {
    workspaceId: logAnalyticsResourceId
    logs: [
      { 
        enabled: true
        categoryGroup: 'allLogs'
        retentionPolicy: {
          days: 30
          enabled:true 
        }
      }
    ]
  }
}

