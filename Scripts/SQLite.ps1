param(
	[parameter()]
	[string]
	$Relative = "..\..\GitClones\PSSQLite\PSSQLite\PSSQLite.psm1",
	
	[parameter()]
	[string]
	$Database = "..\..\SQLite\keys.sqlite",
	
	[parameter()]
	[string]
	$Password
)

try {
	$cookie = Join-Path -Path $PSScriptRoot -ChildPath $Relative -EA stop -Resolve
	Import-Module $cookie -EA stop
	Import-Module "..\..\GitClones\PSSQLite\PSSQLite\Update-SqliteDb.psm1" -EA stop
}
catch {
	Write-Error -Message "Unable to locate or import PSSQLite.psm1 from relative path '$Relative' - can be cloned from 'https://github.com/CAndRyan/PSSQLite.git'"
	return;
}
$Database = Join-Path -Path $PSScriptRoot -ChildPath $Database
Import-Module (Join-Path -Path $PSScriptRoot -ChildPath "..\Modules\SQLite.psm1") -EA stop

#New-KeysDatabase -Database $Database -Password $Password
#Add-ToKeysDatabase 0 "test" "test123" "http://test.com" -Database $Database -Password $Password
#Update-SqliteDbPassword -Database $Database -Password $Password -NewPassword "pass"
#Get-FromKeysDatabase 0 -Database $Database -Password $Password

#Add-Type -path "..\..\GitClones\PSSQLite\PSSQLite\x64\System.Data.SQLite.dll"
#$Database = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Database)
#$ConnectionString = "Data Source={0};Version=3;" -f $Database
#$conn = New-Object System.Data.SQLite.SQLiteConnection -ArgumentList $ConnectionString
#$conn.ParseViaFramework = $true
#$conn.SetPassword("password");
#$conn.Open();
#$cmd = $Conn.CreateCommand()
#$cmd.CommandText = "CREATE TABLE keys (
#			Id INT PRIMARY KEY,
#			Name TEXT NOT NULL,
#			Key TEXT NOT NULL,
#			Reference TEXT)"
#$cmd.CommandTimeout = 600
#$ds = New-Object system.Data.DataSet 
#$da = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
#$conn.Close();
