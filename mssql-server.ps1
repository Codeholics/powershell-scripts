# This needs to be ran by a user with Admin credentials on the target database

#requires -version 4.0

# Imports
Import-Module SQLPS -DisableNameChecking

<#
 # Global Vars
 #>

$pkg = $PWD

$instanceName = "yourdb.server.com"

$loginName = "dbuser"
$password = "dbuser"
$databaseNames = "yourDBName1", "yourDBName2"
$bakPath = "G:\Path\To\Backup.bak"
$role = "db_owner"

$setSQLFile = "$pkg\SQL\tsqlFile.sql"

# Create Server Object
$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName

<#
 # Functions
 #>

Function addSQLUser($user, $password)
{
    if($server.Logins.Contains($user))
    {
        Write-Host("Login: $user Exists")
        return
    }
    else
    {
        $newUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.login -ArgumentList $server, $loginName
        $newUser.LoginType = [Microsoft.SqlServer.Management.Smo.LoginType]::SqlLogin
        $newUser.PasswordExpirationEnabled = $false
        $newUser.PasswordPolicyEnforced = $false ## not recommended ##
        $newUser.Create($password)
        Write-Host("Login: $user Created")
    }
}

Function mapSQLUser($user, $role, [string[]]$databaseNames)
{
    foreach($databaseToMap in $databaseNames)
    {
        $database = $server.Databases[$databaseToMap]
        if($database.Users[$user])
        {
            Write-Host("Database user $user exists on $database.")
        }
        else
        {
            $dbUser = New-Object -TypeName Microsoft.SqlServer.Management.Smo.User -ArgumentList $database, $user
            $dbUser.Login = $user
            $dbUser.Create()
            Write-Host("$user Mapped to $database")
            # Assign role: might be good in a new function
            $dbrole = $database.Roles[$role]
            $dbrole.AddMember($user)
            $dbrole.Alter()
            Write-Host("$user added as $role")
        }
    }
}

Function createDB($server, $db)
{
    try
    {
        Write-Host("Creating Database: $db")
        $db = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Database($server, $db)
        $db.Create()
    }
    catch
    {
        $_
    }
}

Function restoreDB($server, $db, $path)
{
    try
    {
        Write-Host("Restoring Database: $db")
        Restore-SqlDatabase -ServerInstance $server -Database $db -BackupFile $path -ReplaceDatabase
    }
    catch
    {
        $_
    }
}

Function tsql($queryFile, $server)
{
    Invoke-Sqlcmd -InputFile $queryFile -Server $server
}

<#
 # Main
 #>

Write-Host("Installing...")
createDB $server $databaseNames
restoreDB $instanceName $databaseNames $bakPath
tsql $setSQLFile $server
addSQLUser $loginName $password
mapSQLUser $loginName $role $databaseNames