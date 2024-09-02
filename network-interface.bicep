@description('Name of the Sever')
param serverName string 

@description('Location for all resources.')
param location string

@description('Specifies the resource ID of the Network Security Group (NSG) associated with the network interface.')
param nsgId string

@description(' Specifies the name of network security group')
param nsgName string

@description('Specifies the name of the Virtual Network (VNet)')
param vnetName string

@description('Specifies the name of the subnet within the VNet .')
param subnetName string

@description(' Specifies the name of network interface')
param nicname string 

@description('specifes the SKU of the Public IP address.')
param publicIpSku string 

@description(' CIDR range assigned to a Virtual Network')
param vnetCidrRange string  

@description(' CIDR range assigned to a subnet within a VNet.')
param subnetCidrRange string 

@description('Specifies an array of ports that are allowed through the Network Security Group (NSG).')
param allowedPorts array

@description('Specifies an array of ports that are denied access through the Network Security Group (NSG).')
param deniedPorts array


module nsgModule 'network-security-group.bicep' = {
  name: 'nsgDeployment'
  params: {
    serverName: serverName
    allowedPorts: allowedPorts
    deniedPorts:deniedPorts
    nsgName: nsgName
  }
}

module publicIpModule 'public-IP-address.bicep' = {
  name: 'PublicIp-Deploy'
  params: {
    location: location
    publicipname:'${serverName}-PublicIp'
    publicIpSku:publicIpSku
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-01-01' = {
  name: '${serverName}-${vnetName}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetCidrRange]
    }
    subnets: [
      {
        name: '${serverName}-${subnetName}'
        properties: {
          addressPrefix: subnetCidrRange
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name:'${serverName}-${nicname}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${serverName}-ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          
          publicIPAddress: {
            id: publicIpModule.outputs.publicIpId
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

output nicId string = nic.id

