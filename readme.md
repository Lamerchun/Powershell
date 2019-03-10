# Frontend Server Tools

Prepares a clean Windows Server Core for use as a Frontend Server.

## Installs

- IIS
- IIS / FTP Server
- ASP.NET MVC
- git

## Tools

- Rename-Server
- New-FtpUser
- New-WebSite
- New-WebSiteBinding

## Help

- Show-FE-Help

## Conventions

- Your websites go C:\www\
- Module is installed with git clone in ~\Documents\WindowsPowerShell\Modules\

## Installation

Paste these commands in powershell

### Prepare

```powershell
Install-PackageProvider Nuget -Force
Install-Module -Name PowerShellGet -Force
Install-Script -Name Install-Git -Force
& 'C:\Program Files\WindowsPowerShell\Scripts\Install-Git.ps1'
& 'C:\Program Files\Git\bin\git.exe' clone https://github.com/Lamerchun/Powershell "$([Environment]::GetFolderPath("User"))\Documents\WindowsPowerShell\Modules\Frontend-Server-Tools"
Show-FST-Help
```

### Hints

- Use `Show-FST-Help` to show steps to setup server
