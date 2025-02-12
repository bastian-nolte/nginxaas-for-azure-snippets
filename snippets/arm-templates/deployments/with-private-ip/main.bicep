@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of your NGINX deployment resource')
param nginxDeploymentName string = 'myDeployment'

@description('SKU of NGINX deployment')
param sku string = 'publicpreview_Monthly_gmz7xq9ge3py'

@description('Private IP address located on subnet delegated to NGINX deployment')
param privateIPAddress string

@description('Name of private subnet')
param subnetName string

@description('Name of customer virtual network')
param virtualNetworkName string

resource deployment 'NGINX.NGINXPLUS/nginxDeployments@2021-05-01-preview' = {
  name: nginxDeploymentName
  location: location
  sku: {
    name: sku
  }
  properties: {
    enableDiagnosticsSupport: false
    networkProfile: {
      frontEndIPConfiguration: {
        privateIPAddresses: [
          {
            subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
            privateIPAllocationMethod: 'Static'
            privateIPAddress: privateIPAddress
          }
        ]
        publicIPAddresses: []
      }
      networkInterfaceConfiguration: {
        subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
      }
    }
  }
}
