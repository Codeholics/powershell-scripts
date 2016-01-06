# This needs to be ran by a user with Admin credentials 


#requires -version 4.0
#requires -runasadministrator

# Set script params
param([switch]$install, [switch]$uninstall)

<#
 # Global Vars
 #>

$ErrorActionPreference = "Stop"

$pkgDir = $PWD
$commonDLLs = "C\path\to\Dlls"
$comName = "com-name"
$serviceAcc = "user"
$serviceAccPass = "Password"
$compList = "$commonDLLs\file1.dll", "$commonDLLs\file2.dll", "$commonDLLs\file3.dll"

<#
 # Functions
 #>

Function addComPlusApp($comName, $user, $pass, $comList)
{
    $comAdmin = New-Object -comobject COMAdmin.COMAdminCatalog
    $apps = $comAdmin.GetCollection(“Applications”)
    $apps.Populate();

    $newComPackageName = $comName

    $appExistCheckApp = $apps | Where-Object {$_.Name -eq $newComPackageName}

    if($appExistCheckApp)
    {
        Write-Host(“This COM+ Application already exists : $newComPackageName”)
    }
    Else
    {
        $newApp1 = $apps.Add()
        $newApp1.Value(“Name”) = $newComPackageName
        $newApp1.Value(“ApplicationAccessChecksEnabled”) = 0

        $newApp1.Value(“Identity”) = $user
        $newApp1.Value(“Password”) = $pass

        $saveChangesResult = $apps.SaveChanges()
        Write-Host(“COM+ App Created : $saveChangesResult”)

        #Add Components
        Write-Host("Adding Components...")
        foreach($com in $comList) 
        {

            if(Test-Path $com)
            {
                try
                {
                    $comAdmin.InstallComponent($comName, $com, $null, $null)
                    Write-Host("$com added to $comName")
                }
                catch
                {
                    $_
                }
            }
            else
            {
                Write-Host("Err: File Not Found")
            }
        }
    }
}

Function removeComPlueApp($comName)
{
    $comAdmin = New-Object -ComObject COMAdmin.COMAdminCatalog
    $appColl = $comAdmin.GetCollection("Applications")
    $appColl.Populate()
 
    $index = 0
    foreach($app in $appColl) {
        if ($app.Name -eq $comName) {
            try
            {
                $appColl.Remove($index)
                $stat = $appColl.SaveChanges()
                Write-Host("Com+ App Removed: $stat")
            }
            catch
            {
                $_
            }
        }
        $index++
    } 
}

<#
 # Main
 #>

if ($install)
{
    addComPlusApp $comName $serviceAcc $serviceAccPass $compList
}
elseif ($uninstall)
{
    removeComPlueApp $comName
}