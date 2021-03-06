$_FtpSiteName = "Ftp"
$_FtpUserGroupName = "Ftp"

Function Show-SpecialChars {
    echo "Special chars you need: $([char]123) $([char]125)"
}

Function Install-HetznerDrivers {
    Param(
        [Parameter(Mandatory=$true)]
        $Source
    )
	Get-ChildItem "$Source\**\2k16\amd64\*.inf" -Recurse | ForEach-Object { PNPUtil.exe /add-driver $_.FullName /install }
}

Function Install-WinAcme {
    curl https://github.com/PKISharp/win-acme/releases/download/v2.0.4.227/win-acme.v2.0.4.227.zip -OutFile winacme.zip
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Expand-Archive winacme.zip c:\winacme
}

Function Rename-Server {
    Param(
        [Parameter(Mandatory=$true)]
        $ComputerName,

        [Parameter(Mandatory=$true)]
        $WorkGroup
    )
    Rename-Computer $ComputerName
    Add-Computer -WorkGroupName $WorkGroup
}

Function Config-AllowAdminRdp {
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
    netsh advfirewall firewall add rule name="allow RemoteDesktop" dir=in protocol=TCP localport=3389 action=allow
}

Function Uninstall-WindowsDefender {
    Uninstall-WindowsFeature -Name Windows-Defender
}

Function Config-AutomaticWindowsUpdate {
    Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name ScheduledInstallDay -Value 4
    Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name ScheduledInstallTime -Value 4
    Set-ItemProperty -Path HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU -Name AUOptions -Value 4
}

Function Config-DisablePasswordComplexity {
    secedit /export /cfg c:\secpol.cfg
    (gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
    secedit /configure /db c:\windows\security\local.sdb /cfg c:\secpol.cfg /areas SECURITYPOLICY
    rm -force c:\secpol.cfg -confirm:$false
}

Function Install-IisForAspNet {
    dism /online /norestart /enable-feature /featurename:IIS-WebServerRole
    dism /online /norestart /enable-feature /featurename:IIS-WebServer
    dism /online /norestart /enable-feature /featurename:IIS-CommonHttpFeatures
    dism /online /norestart /enable-feature /featurename:IIS-Security
    dism /online /norestart /enable-feature /featurename:IIS-RequestFiltering
    dism /online /norestart /enable-feature /featurename:IIS-StaticContent
    dism /online /norestart /enable-feature /featurename:IIS-DefaultDocument
    dism /online /norestart /enable-feature /featurename:IIS-HttpErrors
    dism /online /norestart /enable-feature /featurename:IIS-HttpRedirect
    dism /online /norestart /enable-feature /featurename:IIS-ApplicationDevelopment
    dism /online /norestart /enable-feature /featurename:IIS-WebSockets
    dism /online /norestart /enable-feature /featurename:IIS-ApplicationInit
    dism /online /norestart /enable-feature /featurename:IIS-NetFxExtensibility
    dism /online /norestart /enable-feature /featurename:IIS-NetFxExtensibility45
    dism /online /norestart /enable-feature /featurename:IIS-ISAPIExtensions
    dism /online /norestart /enable-feature /featurename:IIS-ISAPIFilter
    dism /online /norestart /enable-feature /featurename:IIS-HttpCompressionStatic
    dism /online /norestart /enable-feature /featurename:IIS-HttpCompressionDynamic    
    dism /online /norestart /enable-feature /featurename:IIS-ASPNET45 /all 
}

Function Config-DisableIisLogging {
    Set-WebConfigurationProperty -PSPath "IIS:\" -filter "system.webServer/httpLogging" -name dontLog -value $true
}

Function Grant-FullControl {
    Param(
        [Parameter(Mandatory=$true)]
        $Path, 

        [Parameter(Mandatory=$true)]
        $GroupName
    )
    $Acl = Get-Acl $Path
    $Ar = New-Object  system.security.accesscontrol.filesystemaccessrule($GroupName,"FullControl","Allow")
    $Acl.SetAccessRule($Ar)
    Set-Acl $Path $Acl
}

Function Remove-WebSite {
    Param(
        [Parameter(Mandatory=$true)]
        $SiteName
    )
    Import-Module WebAdministration

    $manager = Get-IISServerManager
    $manager.Sites.Remove($manager.Sites[$SiteName])
    $manager.CommitChanges()
}

Function Clear-WebSites {
    Import-Module WebAdministration

    $manager = Get-IISServerManager
    $manager.Sites.Clear()
    $manager.CommitChanges()
}

Function Clear-AppPools {
    Import-Module WebAdministration

    $manager = Get-IISServerManager
    $manager.ApplicationPools.Clear()
    $manager.CommitChanges()
}

Function Config-AppPoolDefaults {
    Import-Module WebAdministration

    $manager = Get-IISServerManager
    $manager.ApplicationPoolDefaults.Enable32BitAppOnWin64 = $True
    $manager.ApplicationPoolDefaults.StartMode = "AlwaysRunning"
    $manager.ApplicationPoolDefaults.ProcessModel.IdleTimeoutAction ="Suspend"
    $manager.ApplicationPoolDefaults.ProcessModel.IdleTimeout = New-TimeSpan -Minutes 180
    $manager.CommitChanges()
}

Function New-WebSite {
    Param(
        [Parameter(Mandatory=$true)]
        $AppPoolName, 

        [Parameter(Mandatory=$true)]
        $SiteName, 

        [Parameter(Mandatory=$true)]
        $HostName,

        $FolderName
    )
    Import-Module WebAdministration

    if (!$FolderName) {
        $FolderName = $SiteName
    }

    $path = "C:\www\$FolderName"

    $manager = Get-IISServerManager
    $manager.ApplicationPools.Add($AppPoolName)
    $manager.CommitChanges()

    $manager.Sites.Add($SiteName, "http", "*:80:$HostName", $path)
    $site = $manager.Sites[$SiteName];
    $site.ApplicationDefaults.ApplicationPoolName = $AppPoolName;
    $manager.CommitChanges()

    New-Item -type directory -path $path
}

Function New-WebSiteBinding {
    Param(
        [Parameter(Mandatory=$true)]
        $SiteName, 

        [Parameter(Mandatory=$true)]
        $HostName
    )
    Import-Module WebAdministration

    $manager = Get-IISServerManager
    $site = $manager.Sites[$SiteName]
    $bindingObject = $site.Bindings.CreateElement()
    $bindingObject.Protocol = "http"
    $bindingObject.BindingInformation = "*:80:$HostName"
    $site.Bindings.Add($bindingObject)
    $manager.CommitChanges()
}

Function Config-FtpServerFirewall {
    Set-WebConfigurationProperty -PSPath IIS:\ -Filter system.ftpServer/firewallSupport -Name lowDataChannelPort -Value 32500
    Set-WebConfigurationProperty -PSPath IIS:\ -Filter system.ftpServer/firewallSupport -Name highDataChannelPort -Value 32800
}

Function New-DefaultWebFtpSite {
    Import-Module WebAdministration
    $manager = Get-IISServerManager

    $ftpAppPoolName = "Ftp"
    $manager.ApplicationPools.Add($ftpAppPoolName)
    $manager.CommitChanges()

    New-WebFtpSite -Name "FTP" -Port 21 -PhysicalPath $Path
    New-Item "IIS:\Sites\$_FtpSiteName\LocalUser" -physicalPath C:\Inetpub\Ftproot -type VirtualDirectory
    Clear-WebConfiguration -Filter /System.FtpServer/Security/Authorization -PSPath IIS: -Location $_FtpSiteName
    Add-WebConfiguration -Filter /System.FtpServer/Security/Authorization -Value (@{AccessType="Allow"; Roles=$_FtpUserGroupName; Permissions="Read,Write"}) -PSPath IIS: -Location $_FtpSiteName

    Set-ItemProperty IIS:\Sites\$_FtpSiteName -Name ftpServer.security.authentication.basicAuthentication.enabled -Value $True
    Set-ItemProperty IIS:\Sites\$_FtpSiteName -Name ftpServer.security.ssl.controlChannelPolicy -Value "SslAllow"
    Set-ItemProperty IIS:\Sites\$_FtpSiteName -Name ftpServer.security.ssl.dataChannelPolicy -Value "SslAllow"
    Set-ItemProperty IIS:\Sites\$_FtpSiteName -Name ftpServer.userIsolation.mode -Value 3
    Set-ItemProperty IIS:\Sites\$_FtpSiteName -Name ftpServer.directoryBrowse.showFlags -Value 32
    Set-ItemProperty IIS:\Sites\$_FtpSiteName -Name applicationPool -Value $ftpAppPoolName
    Set-ItemProperty IIS:\Sites\$_FtpSiteName -Name ftpServer.logFile.enabled -Value $False
    Restart-WebItem IIS:\Sites\$_FtpSiteName
}

Function New-FtpUser {
    Param(
        [Parameter(Mandatory=$true)]
        $Name, 

        [Parameter(Mandatory=$true)]
        $Password, 

        [Parameter(Mandatory=$true)]
        $PhysicalPath
    )
    Import-Module WebAdministration

    New-LocalUser -Name $Name -Password (ConvertTo-SecureString $Password -AsPlainText -Force) -PasswordNeverExpires -UserMayNotChangePassword
    New-LocalGroup -Name $_FtpUserGroupName -Description "Lokale FTP Benutzer"
    Add-LocalGroupMember -Group $_FtpUserGroupName -Member $Name
    New-Item "IIS:\Sites\$_FtpSiteName\LocalUser\$Name" -physicalPath $PhysicalPath -type VirtualDirectory
}

Function Create-HostingDirectory {
    New-Item -type directory -path C:\www
    Grant-FullControl -Path C:\www -GroupName "Jeder"
}

Function Initialize-Server {
    Config-AllowAdminRdp
    Config-AutomaticWindowsUpdate
    Config-DisablePasswordComplexity
}

Function Install-Features {
    Uninstall-WindowsDefender
    Install-IisForAspNet
    Install-WindowsFeature Web-FTP-Server -IncludeAllSubFeature
    Install-WinAcme
}

Function Install-FrontendServer {
    Config-DisableIisLogging
    Config-AppPoolDefaults
    Config-FtpServerFirewall

    Clear-WebSites
    Clear-AppPools

    Create-HostingDirectory

    New-DefaultWebFtpSite
}

Function New-SslCertificate {
    Param(
        [Parameter(Mandatory=$true)]
        $Email, 

        [Parameter(Mandatory=$true)]
        $HostName, 

        [Parameter(Mandatory=$true)]
        $PhysicalPath
    )
    C:\winacme\wacs.exe --target manual --host $HostName --webroot $PhysicalPath --emailaddress $Email --accepttos
}

