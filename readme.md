# Frontend Server Tools

Prepares a clean Windows Server Core for use as a Frontend Server.

## Installs

- IIS
- IIS / FTP Server
- ASP.NET MVC
- git
- winacme (at `C:\winacme`)

## Tools

- Rename-Server
- New-FtpUser
- New-WebSite
- New-WebSiteBinding

## Conventions

- Your websites go `C:\www\`
- Module is installed with git clone in `~\Documents\WindowsPowerShell\Modules\`

## Prepare

```powershell
Install-PackageProvider Nuget -Force
Install-Module -Name PowerShellGet -Force
Install-Script -Name Install-Git -Force
& 'C:\Program Files\WindowsPowerShell\Scripts\Install-Git.ps1'
& 'C:\Program Files\Git\bin\git.exe' clone https://github.com/Lamerchun/Powershell "$([Environment]::GetFolderPath("User"))\Documents\WindowsPowerShell\Modules\Frontend-Server-Tools"
```

## Installation

### Environment

```powershell
Rename-Server -ComputerName ComputerName -WorkGroup WorkgroupName
```

### Features

```powershell
Initialize-Server
Install-Features
Restart-Computer -Force
```

### IIS

Will configure IIS with defaults. Creates a ftp user with full rights to your website's root.

```powershell
Install-FrontendServer
New-FtpUser -Name Username -Password Password -PhysicalPath C:\www
```

### Websites

Use these commands to setup websites as you need. Bindings will add http with port 80 bindings. To setup https use installed winacme.

```powershell
- New-WebSite -AppPoolName AppPoolName -SiteName WebsiteName -Host Hostname
- New-WebSiteBinding -SiteName WebsiteName -HostName Hostname
```
