@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of your NGINX deployment resource')
param nginxDeploymentName string = 'myDeployment'

@description('SKU of NGINX deployment')
param sku string = 'publicpreview_Monthly_gmz7xq9ge3py'

@description('Name of public IP')
param publicIPName string = 'myPublicIP'

@description('Name of public subnet')
param subnetName string

@description('Name of customer virtual network')
param virtualNetworkName string

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: publicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  tags: {
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    ipTags: []
  }
}

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
        publicIPAddresses: [
          {
            id: publicIP.id
          }
        ]
        privateIPAddresses: []
      }
      networkInterfaceConfiguration: {
        subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
      }
    }
  }
}
