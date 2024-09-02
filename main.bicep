
@description('Name of the Sever')
param serverName string 

@description('Location for all resources.')
param location string

@description('Size of the server')
param serverSize string

@description('Admin User Name')
param adminUsername string 

@description('Admin Password')
@secure()
param adminPassword string

@description(' The mage publisher')
param serverOS string 

@description('Specifies the offer of the platform image or marketplace image used to create the virtual machine.')
param serveroffer string 

@description(' The image SKU')
param serversku string 

@description('Specifies the version of the platform image')
param serverversion string

@description('Specifies the storage account type for the managed disk.')
param osDiskType string 

@description(' Specifies the size of an empty data disk in gigabytes.')
param osDiskSize int 

@description(' Specifies the name of network security group')
param nsgName string 

@description(' CIDR range assigned to a Virtual Network')
param vnetCidrRange string  

@description(' CIDR range assigned to a subnet within a VNet.')
param subnetCidrRange string

@description(' Specifies the name of network interface')
param nicname string 

@description('Name of the public IP resource')
param publicipname string 

@description('Specifies the name of the Virtual Network (VNet)')
param vnetName string

@description('Specifies the name of the subnet within the VNet .')
param subnetName string

@description('Specifies an array of ports that are allowed through the Network Security Group (NSG).')
param allowedPorts array

@description('Specifies an array of ports that are denied access through the Network Security Group (NSG).')
param deniedPorts array


@description('Specifies the name of the key pair used for authentication, typically for SSH access on Linux VMs.')
param keypairName string

@description('Specifies the type of authentication to be used, such as password or SSH key.')
param authenticationType string

@description('Specifies the type of security to be implemented, such as standard or advanced options.')
param securityType string

@description('Specifies the SKU for the public IP address associated with the network interface.')
param publicIpSku string



module securityModule 'network-security-group.bicep' = {
  name: '${serverName}-securityDeploy'
  params: {
    allowedPorts: allowedPorts
    deniedPorts: deniedPorts
    nsgName: nsgName
    serverName: serverName
  }
}

module publicIpModule 'public-IP-address.bicep' = {
  name: 'PublicIp-Deploy'
  params: {
    location: location
    publicipname: publicipname
    publicIpSku: publicIpSku
}
}

module networkInterfaceModule 'network-interface.bicep' = {
  name: 'Network-Deploy'
  params: {
    location: location
    serverName: serverName
    allowedPorts:allowedPorts
    deniedPorts:deniedPorts
    nicname:nicname
    nsgId:securityModule.outputs.nsgId
    nsgName:nsgName
    publicIpSku:publicIpSku
    subnetCidrRange:subnetCidrRange
    subnetName:subnetName
    vnetCidrRange:vnetCidrRange
    vnetName:vnetName
  }
  dependsOn: [
    publicIpModule
  ]
}

module vmModule 'Virtual-Machine-creation.bicep' = {
  name: '${serverName}-vmDeploy'
  params: {
    location: location
    serverName: serverName
    serverSize: serverSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    serverOS: serverOS
    serveroffer: serveroffer
    serversku: serversku
    serverversion: serverversion
    osDiskType: osDiskType
    osDiskSize: osDiskSize
    nsgName: nsgName
    vnetCidrRange: vnetCidrRange
    subnetCidrRange: subnetCidrRange
    nicname: nicname
    vnetName: vnetName
    subnetName: subnetName
    allowedPorts: allowedPorts
    deniedPorts: deniedPorts
    keypairName: keypairName
    authenticationType: authenticationType
    securityType: securityType
    nsgId: securityModule.outputs.nsgId
    publicIpSku:publicIpSku
  }
  dependsOn: [
    networkInterfaceModule
  ]
}

output vmId string = vmModule.outputs.vmId
output message string = 'VM created successfully. Retrieve IP addresses using Azure CLI commands.'
output vmNameOutput string = serverName 
output nsgId string = securityModule.outputs.nsgId
