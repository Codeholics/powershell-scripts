# 
# Add/Remove a Web Application in IIS with PowerShell
# This needs to be ran by a user with Admin credentials
# 
 
#requires -version 4.0
#requires -runasadministrator
 
# Set script params
param([switch]$install, [switch]$uninstall)
 
<#
 # Imports
 #>
 
Import-Module WebAdministration
 
<#
 # Global Vars
 #>
 
$ErrorActionPreference = "Stop"
 
$pkg = $PWD
 
$site = "SiteName"
$siteName = "site.mysite.com"
$sitePaths = "E:\Inetpub\sitename", "E:\Logs\sitename"
$siteAppPool = "SiteName"
$siteAppNetCDL = "" #.Net Version leave blank for non managed code
$siteApp32Bit = "False"
$siteAppIdentity = "Local System"
$siteDefaultFile = "login.htm"
$siteVirtualDirs = "vDir1"
$siteVirtualDirPaths = "C:\Path\To\vDir\vDir1"
$siteZip = "$pkg\SiteName.zip"
 
<#
 # Functions
 #>
 
Function expandZipFile($file, $dest)
{
    Write-Host("Extracting $file to $dest...")
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    try
    {
        [System.IO.Compression.Zipfile]::ExtractToDirectory($file, $dest)
    }
    catch
    {
        $_
    }
}
 
Function createFolders($folderPaths)
{
    foreach($folder in $folderPaths)
    {
        try
        {
            New-Item -Force -Type container $folder
            Write-Host("Created: $folder")
        }
        catch
        {
            $_
        }
    }
}
 
Function removeFolders($folderPaths)
{
    foreach($folder in $folderPaths)
    {
        try
        {
            Remove-Item -Force $sitePath -Recurse
            Write-Host("Removed: $sitePath")
        }
        catch
        {
            $_
        }
    }
}
 
Function addAppPool($appPool, $appNetCDL, $appPool32Bit, $appPoolIdentity)
{
    Write-Host("Created AppPool: $appPool")
    try
    {
        $ap = New-Item IIS:\AppPools\$appPool
        $ap | Set-ItemProperty -Name "managedRuntimeVersion" -Value $appNetCDL
        $ap | Set-ItemProperty -Name "enable32BitAppOnWin64" -Value $appPool32Bit
        $ap | Set-ItemProperty -Name "processModel.identityType" -Value $appPoolIdentity
    }
    catch
    {
        $_
    }
}
 
Function removeAppPool($appPool)
{
    try
    {
        Remove-WebAppPool $appPool
        Write-Host("Removed AppPool: $appPool")
    }
    catch
    {
        $_
    }
}
 
Function addWebSite($site, $path, $name, $appPool, $logPath, $defaultFile)
{
    try
    {
        $ws = New-Item IIS:\Sites\$site -PhysicalPath $path -bindings @{protocol="http";bindingInformation=":80:$name"}
        $ws | Set-ItemProperty -name applicationPool -value $appPool
        $ws | Set-ItemProperty -name logFile -value @{directory=$logPath}
        Add-WebConfiguration //defaultDocument/files "IIS:\sites\$site" -atIndex 0 -Value @{value=$defaultFile}
        Write-Host("Added Website: $site")
     }
    catch
    {
        $_
    }
}
 
Function removeWebSite($site)
{
    try
    {
        Remove-Item IIS:\Sites\$site -Recurse
        Write-Host("Removed Website: $site")
    }
    catch
    {
        $_
    }
}
 
Function addVirtDir($site, $vDir, $path)
{
    Try
    {
        New-Item IIS:\Sites\$site\$vdir -physicalPath $path -type VirtualDirectory
    }
    catch
    {
        $_
    }
}
 
<#
 # Main
 #>
 
if ($install)
{
   createFolders $sitePaths
   expandZipFile $siteZip $sitePaths[0]
   addAppPool $siteAppPool $siteAppNetCDL $siteApp32Bit $siteAppIdentity $siteAppIdentityPass
   addWebSite $site $sitePath[0] $siteName $siteAppPool $siteLogPath $siteDefaultFile
   addVirtDir $site $siteVirtualDirs $siteVirtualDirPaths
}
elseif ($uninstall)
{
   removeAppPool $siteAppPool
   removeWebSite $site
   removeFolders $sitePaths
}