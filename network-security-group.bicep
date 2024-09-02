@description('Specifies an array of ports that are allowed through the Network Security Group (NSG).')
param allowedPorts array

@description('Specifies an array of ports that are denied access through the Network Security Group (NSG).')
param deniedPorts array

@description('Name of the Sever')
param serverName string 

@description(' Specifies the name of network security group')
param nsgName string 

// Creates a Network Security Group (NSG)
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: '${serverName}-${nsgName}'
  location: resourceGroup().location
  properties: {
    securityRules: [
      // Define the security rules for allowed and denied ports
      for port in union(allowedPorts, deniedPorts): {
        name: contains(allowedPorts, port) ? 'AllowPort${port}' : 'DenyPort${port}'
        properties: {
          priority: contains(allowedPorts, port) ? 100 + indexOf(allowedPorts, port) : 200 + indexOf(deniedPorts, port)
          direction: 'Inbound'
          access: contains(allowedPorts, port) ? 'Allow' : 'Deny'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '${port}'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Outputs the unique ID of the created NSG.
output nsgId string = nsg.id
