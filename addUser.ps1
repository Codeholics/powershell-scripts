# Setup a local user
 
#requires -version 4.0
#requires -runasadministrator
 
# Set script params
param([switch]$install, [switch]$uninstall)
 
<#
 # Global Vars
 #>
 
$localAcc = "User1"
$localAccPass = "P@ssW0rd"
$localAccGroup = "Administrators"
$localAccDescript = "PowerShell Created User"
 
<#
 # Functions
 #>
 
Function addUser($userName, $pass, $descript)
{
    Write-Host("Adding Local User: $userName")
    try
    {
        $compName = $env:COMPUTERNAME
        $cn = [ADSI]"WinNT://$compName"
        $user = $cn.Create('User',$userName)
        $user.SetPassword($pass)
        $user.setinfo()
        $user.description = $descript
        $user.SetInfo()
    }
    catch
    {
        $_
    }
}
 
Function addToGroup($userName, $userGroup)
{
    Write-Host("Adding $userName to $userGroup...")
    try
    {
        $group = [ADSI]"WinNT://$env:COMPUTERNAME/$userGroup,group"
        $group.Add("WinNT://$env:COMPUTERNAME/$userName,user")
    }
    catch
    {
        $_
    }
}
 
Function rmUser($userName)
{
    Write-Host("Removing Local User...")
    try
    {
        $compName = $env:COMPUTERNAME
        $cn = [ADSI]"WinNT://$compName"
        $user = $cn.Delete("User", $userName)
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
    addUser $localAcc $localAccPass $localAccDescript
    addToGroup $localAcc $localAccGroup
}
elseif ($uninstall)
{
    rmUser $localAcc
}