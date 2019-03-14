$_MongoServiceName = "MongoDB"
$_MongoVersion = "mongodb-win32-x86_64-2008plus-ssl-4.0.6";

$_MongoPath = "C:\\MongoDB"
$_MongoBinPath = "$_MongoPath\\bin"
$_MongoDataPath = "C:\\Data"
 
Set-Alias mongod "$_MongoBinPath\mongod.exe"
Set-Alias mongo "$_MongoBinPath\mongo.exe"

Function Create-Folders {
  @("$_MongoPath", "$_MongoDataPath\db", "$_MongoDataPath\log") | foreach {
    if (!(Test-Path -Path $_)) {
      New-Item -ItemType directory -Path $_ | Out-Null
    }
  }
}

Function Download-Mongo {
  $url = "https://fastdl.mongodb.org/win32/$_MongoVersion.zip" 
  $zipFile = "mongo.zip" 
  
  $ProgressPreference = "SilentlyContinue"
  curl $url -ContentType "application/octet-stream" -OutFile $zipFile
  $ProgressPreference = "Continue"
  
  Expand-Archive $zipFile $_MongoPath
  $mongoExtractedFolder = "$_MongoPath\$_MongoVersion";
  Move-Item "$mongoExtractedFolder\**" $_MongoPath -Force
  Remove-Item $mongoExtractedFolder -Force
  Remove-Item $zipFile -Force
}

Function Write-Config {
  Param(
    [Parameter(Mandatory=$true)]
    $Authorization,

    [int]
    [Parameter(Mandatory=$true)]
    $Port
  )

  $content = @"
  # mongod.conf
   
  # for documentation of all options, see:
  # http://docs.mongodb.org/manual/reference/configuration-options/
   
  systemLog:
    destination: file
    path: $_MongoDataPath\log\mongod.log
    logAppend: true
  storage:
    dbPath: $_MongoDataPath\db
    directoryPerDB: true
    wiredTiger:
      engineConfig:
       cacheSizeGB: 2
    journal:
      enabled: true
  net:
    port: $Port
    bindIpAll: true
  processManagement:
    windowsService:
      serviceName: "$_MongoServiceName"
      displayName: "$_MongoServiceName"
      description: "mongod service"
  security:
    authorization: "$Authorization"
  setParameter:
    enableLocalhostAuthBypass: false
"@

  [IO.File]::WriteAllLines("$_MongoPath\mongod.cfg" , $content)
}

Function Create-AdminAccount {
  Param(
    [Parameter(Mandatory=$true)]
    $AdminUserName,

    [Parameter(Mandatory=$true)]
    $AdminUserPassword
  )

  mongo 'admin' --quiet --eval @"
  db=db.getSiblingDB('admin');
  db.createUser(
    {
      user: '$AdminUserName',
      pwd: '$AdminUserPassword',
      roles: [ 'userAdminAnyDatabase', 'readWriteAnyDatabase', 'dbAdminAnyDatabase', 'clusterAdmin' ]
    }
  );
"@
}

Function Install-MongoService {
  mongod --config "$_MongoPath\mongod.cfg" --install
  Set-Service -Name $_MongoServiceName -StartupType automatic
  Start-Service $_MongoServiceName
}

Function New-MongoFirewallRule {
  Param(
    [Parameter(Mandatory=$true)]
    $Port
  )
  
  New-NetFirewallRule `
    -DisplayName $_MongoServiceName `
    -Description "Allow Remote Connections" `
    -Direction Inbound `
    -Protocol TCP -LocalPort $Port `
    -Action Allow
}

Function Read-MongoLog {
  Get-Content -Path "$_MongoDataPath\log\mongod.log" -tail 20
}

Function Install-Mongo {
  Param(
    [Parameter(Mandatory=$true)]
    $AdminUserName,

    [Parameter(Mandatory=$true)]
    $AdminUserPassword,

    [Int]
    [Parameter(Mandatory=$true)]
    $Port
  )

  Create-Folders

  Write-Host "Downloading mongo..."
  Download-Mongo
   
  Write-Host "Install mongo..."
  Write-Config -Authorization "disabled" -Port $Port
  Install-MongoService

  Write-Host "Create admin..."
  Create-AdminAccount -AdminUserName $AdminUserName -AdminUserPassword $AdminUserPassword | Out-Null

  Write-Host "Enable authentication..."
  Write-Config -Authorization "enabled" -Port $Port
  
  Restart-Service "$_MongoServiceName"    
  Write-Host "Installation completed."
}

Export-ModuleMember -Function Install-Mongo
Export-ModuleMember -Function New-MongoFirewallRule
Export-ModuleMember -Function Read-MongoLog


