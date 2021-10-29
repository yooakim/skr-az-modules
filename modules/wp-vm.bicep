
param siteName string = resourceGroup().name
param location string = resourceGroup().location


resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: '${siteName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
      {
        name: 'HTTP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 320
          direction: 'Inbound'
        }
      }
      {
        name: 'HTTPS'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 340
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: '${siteName}-ip'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-03-01' = {
  name: '${siteName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '192.168.0.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: siteName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_E2s_v3'
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: siteName
      adminUsername: 'azureuser'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/azureuser/.ssh/authorized_keys'
              keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1qSW41ue5mp1pqh7gYtPjqDt0D7G3h8CmJtbOiRuji+ief1clU5lFvJ3Me2qCgiYKN+VPNPh9ag3qnS5b48NmXZMQ2oBsfEjtzeJJIdGK1ktC4M0ZCJ8gX+2gQhsskaPU4AMt+iCq/QUGlI6+7tJ5X9BzPVevkNvwNcZjMcQinArWYMrfOJNoxPWUful4MFBzOBtPCWl/+IhMpe8FU8qgv2juup2+fbpFzTTjKsSE4D/j/9uOevLFaHMosdDQ/ECdy5au+RGz3C/bEZZERdi+eRyGYg5bYSW5bQ+Zf4r7xAorzmTDQ3k6H1zCxHfiN9rn0QwKr57Rphax0tx8c9YJy+R7JATdyhRQGJhgDH40bsOuAgZQGt+UqmbMrIssrTeiN8VdMQ1SsaW+vPbKewbdtw1aTWOatjQS0zo6EVTsEvHCwH2SJ2OiI+knniJHwQQImSLshbIXFagG8rNT+jD4wTIC4YOUxLXiC6CN9KcEnY2Gtcshxaow9oiPy1cwHtcSo8lBNAIbDUa+/2MnOb58laAQZ8N4tLSKGBanxfI74RMFcz4jfKGhAu1r6Li08LIloYHjoUmdZGH9QNpkfELfMg8bqVqZRmSBmCzCDa9nncioP98av1ul76BCeM0yI9mFgDzl1CS4UNOMHz4hMwvSbBlEdsARh/44CknVXd8xGw== jwes@skr.se'
            }
          ]
        }
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource nsgRule_HTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2021-03-01' = {
  parent: nsg
  name: 'HTTP'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 320
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource nsgRule_HTTPS 'Microsoft.Network/networkSecurityGroups/securityRules@2021-03-01' = {
  parent: nsg
  name: 'HTTPS'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 340
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource nsgRule_SSH 'Microsoft.Network/networkSecurityGroups/securityRules@2021-03-01' = {
  parent: nsg
  name: 'SSH'
  properties: {
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '22'
    sourceAddressPrefix: '*'
    destinationAddressPrefix: '*'
    access: 'Allow'
    priority: 300
    direction: 'Inbound'
    sourcePortRanges: []
    destinationPortRanges: []
    sourceAddressPrefixes: []
    destinationAddressPrefixes: []
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' = {
  parent: virtualNetwork
  name: 'default'
  properties: {
    addressPrefix: '192.168.0.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: '${siteName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
          subnet: {
            id: subnet.id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}
