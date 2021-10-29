@secure()
param administratorLogin string
@secure()
param administratorLoginPassword string

param location string = resourceGroup().location

param siteName string

param mySqlServerName string = '${siteName}-mysql'

param tags object = {
  CreatedBy: ''
  Owner: ''
}
resource MySqlServer 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  name: mySqlServerName
  location: location
  tags: tags
  sku: {
    name: 'B_Gen5_1'
    tier: 'Basic'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    createMode: 'Default'
    storageProfile: {
      storageMB: 30720
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
      storageAutogrow: 'Enabled'
    }
    version: '8.0'
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: '${siteName}stcontent'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    defaultToOAuthAuthentication: false
    allowCrossTenantReplication: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}



resource mySqlServerName_wordpress 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  parent: MySqlServer
  name: siteName
  properties: {
    charset: 'utf8mb4'
    collation: 'utf8mb4_unicode_ci'
  }
}

resource mySqlServerName_AllowAllWindowsAzureIps 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01' = {
  parent: MySqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource mySqlServerName_Joakim_Westin_IP 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01' = {
  parent: MySqlServer
  name: 'Joakim_Westin_IP'
  properties: {
    startIpAddress: '98.128.228.104'
    endIpAddress: '98.128.228.104'
  }
}


resource stfileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = {
  parent: storageAccount
  name: 'default'

  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}


resource aci 'Microsoft.ContainerInstance/containerGroups@2021-07-01' = {
  name: '${siteName}-aci'
  location: location
  properties:{
    containers:[
      {
        name: '${siteName}-con1'
        properties:{
          image: 'docker.io/library/wordpress:latest'
          environmentVariables:[
            {
              name: 'WORDPRESS_DB_HOST'
              value: '${mySqlServerName}.mysql.database.azure.com'
            }
            {
              name: 'WORDPRESS_DB_NAME'
              value: siteName
            }
            {
              name: 'WORDPRESS_DB_PASSWORD'
              value: administratorLoginPassword
            }
            {
              name: 'WORDPRESS_DB_USER'
              value: '${administratorLogin}@${mySqlServerName}'
            }
            {
              name: 'WORDPRESS_CONFIG_EXTRA'
              value: 'define( \'MYSQL_CLIENT_FLAGS\', MYSQLI_CLIENT_SSL );'
            }
          ]
          resources:{
            requests:{
              cpu: 1
              memoryInGB: 2
            }
          }
          ports: [
            {
              port: 80
            }
            {
              port: 443
            }
          ]
          volumeMounts:[
            {
              name: 'wordpress'
              mountPath: '/var/www/html'
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress:{
      type: 'Public'
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
        {
          protocol: 'TCP'
          port: 443
        }
      ]
      dnsNameLabel: siteName
    }
    volumes:[
      {
        name: 'wordpress'
        azureFile:{
          shareName: 'wordpress'
          storageAccountName: storageAccount.name
          storageAccountKey: listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value
        }
      }
    ]
  }
}



resource stBlobervice_wordpress 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-06-01' = {
  parent: stfileServices
  name: 'wordpress'
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 5120
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    storageAccount
  ]
}
