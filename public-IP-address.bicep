@description('Location for all resources.')
param location string

@description('specifes the name of the Public IP address resource.')
param publicipname string

@description('specifes the SKU of the Public IP address.')
param publicIpSku string 

// Creates a Public IP address resource 
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: publicipname
  location: location
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: 'Static' // Use 'Dynamic' if you need a dynamically allocated IP
  }
}


// Outputs the ID of the created Public IP address resource.
output publicIpId string = publicIp.id

// Outputs the actual IP address allocated to the Public IP address resource.
output publicIpAddress string = publicIp.properties.ipAddress
