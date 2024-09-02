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

@description('Specifies the name of the Virtual Network (VNet)')
param vnetName string

@description('Specifies the name of the subnet within the VNet .')
param subnetName string

@description('Specifies an array of ports that are allowed through the Network Security Group (NSG).')
param allowedPorts array

@description('Specifies an array of ports that are denied access through the Network Security Group (NSG).')
param deniedPorts array

@description('Specifies the resource ID of the Network Security Group (NSG) associated with the network interface.')
#disable-next-line no-unused-params
param nsgId string

@description('Specifies the name of the key pair used for authentication, typically for SSH access on Linux VMs.')
param keypairName string

@description('Specifies the type of authentication to be used, such as password or SSH key.')
param authenticationType string

@description('Specifies the type of security to be implemented, such as standard or advanced options.')
param securityType string

@description('Specifies the SKU for the public IP address associated with the network interface.')
param publicIpSku string


// Deploys a Network Security Group (NSG)
module securityModule 'network-security-group.bicep' = {
  name: '${serverName}-securityDeploy'
  params: {
    allowedPorts: allowedPorts
    deniedPorts: deniedPorts
    nsgName: nsgName
    serverName: serverName
  }
}

// Deploys a Network Interface (NIC)
module networkInterfaceModule 'network-interface.bicep' = {
  name: 'NetworkInterface-Deploy'
  params: {
    location: location
    allowedPorts: allowedPorts
    deniedPorts: deniedPorts
    nicname: nicname
    nsgId:  securityModule.outputs.nsgId   // Reference the NSG ID from the securityModule output.
    nsgName: nsgName
    serverName:serverName 
    subnetCidrRange: subnetCidrRange
    subnetName: subnetName
    vnetCidrRange: vnetCidrRange
    vnetName: vnetName
    publicIpSku: publicIpSku
  }
}
  
// Creates a virtual machine (VM)
resource vmModule 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: serverName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: serverSize
    }
    osProfile: {
      computerName: serverName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: (authenticationType == 'password' ? null : {
        disablePasswordAuthentication: false 
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: keypairName
            }
          ]
        }
      })
    }
    /*
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageModule.outputs.storageUri
      }
    }
    */
    
    storageProfile: {
      imageReference: {
        publisher: serverOS
        offer: serveroffer
        sku: serversku
        version: serverversion
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          
          storageAccountType: osDiskType 
        }
      }
      dataDisks: [
        {
          diskSizeGB: osDiskSize
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceModule.outputs.nicId
        }
      ]
    }
    securityProfile: (securityType == 'TrustedLaunch' ? {
      securityType: securityType
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    } : null)
  }
}

// Outputs the ID of the created VM.
output vmId string = vmModule.id

// Outputs a message indicating that the VM has been successfully created.
output message string = 'VM created successfully. Retrieve IP addresses using Azure CLI commands.'

// Outputs the name of the created VM.
output vmNameOutput string = serverName 

// Outputs the ID of the created NSG.
output nsgId string = securityModule.outputs.nsgId
