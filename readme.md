# Frontend Server Tools

Prepares a clean Windows Server Core for use as a Frontend Server.

## Installs

`IIS`, `FTP Server`, `ASP.NET`, `git`, `winacme`

## Conventions

- Your websites go `C:\www\`
- Module is installed with git clone in `~\Documents\WindowsPowerShell\Modules\Frontend-Server-Tools`

## Installation

### 1. Step: Tools

```powershell
Install-PackageProvider Nuget -Force
Install-Module -Name PowerShellGet -Force
Install-Script -Name Install-Git -Force
& 'C:\Program Files\WindowsPowerShell\Scripts\Install-Git.ps1'
& 'C:\Program Files\Git\bin\git.exe' clone https://github.com/Lamerchun/Powershell "$([Environment]::GetFolderPath("User"))\Documents\WindowsPowerShell\Modules\Frontend-Server-Tools"
```

### 2. Step: Environment

```powershell
Rename-Server -ComputerName ComputerName -WorkGroup WorkgroupName
```

### 3. Step: Features

```powershell
Initialize-Server
Install-Features
Restart-Computer -Force
```

### 4. Step: IIS

Will configure IIS with defaults. Creates a ftp user with full rights to your website's root.

```powershell
Install-FrontendServer
New-FtpUser -Name Username -Password Password -PhysicalPath C:\www
```

### 5. Step: Websites

Use these commands to setup websites as you need. Bindings will add http with port 80.

```powershell
- New-WebSite -AppPoolName AppPoolName -SiteName WebsiteName -Host Hostname
- New-WebSite -AppPoolName AppPoolName -SiteName WebsiteName -Host Hostname -FolderName FolderName
- New-WebSiteBinding -SiteName WebsiteName -HostName Hostname
```

### 6. Step: SSL certificates

Will be issued with letsencrypt. Wacs will automatically renew for you.

```powershell
New-SslCertificate -Email abuse@domain.com -HostName site.domain.com --PhysicalPath C:\www\Website
```
