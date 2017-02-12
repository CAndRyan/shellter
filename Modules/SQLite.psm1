function New-KeysDatabase {
	param(
		[parameter()]
		[string]
		$Database = "..\..\SQLite\keys.sqlite",
		
		[parameter()]
		[string]
		$Password,
		
		[parameter()]
		[switch]
		$Force
	)
	
	if ($Force -or !(Test-Path $Database)) {
		$newKeysTable = "CREATE TABLE keys (
			Id INT PRIMARY KEY,
			Name TEXT NOT NULL,
			Key TEXT NOT NULL,
			Reference TEXT)"
	
		Invoke-SqliteQuery -Query $newKeysTable -DataSource $Database -Password $Password
	}
	else {
		Write-Error -Message "Database already exists: '$Database'"
	}
}

function Add-ToKeysDatabase {
	param(
		[parameter(mandatory=$true)]
		[int]
		$Id,
		
		[parameter(mandatory=$true)]
		[string]
		$Name,
		
		[parameter(mandatory=$true)]
		[string]
		$Key,
		
		[parameter()]
		[string]
		$Reference,
		
		[parameter()]
		[string]
		$Database = "..\..\SQLite\keys.sqlite",
		
		[parameter()]
		[string]
		$Password
	)
	
	if ($Reference) {
		$setKey = "INSERT INTO keys (Id, Name, Key, Reference)
			VALUES ($Id, '$Name', '$Key', '$Reference')"
	}
	else {
		$setKey = "INSERT INTO keys (Id, Name, Key)
			VALUES ($Id, '$Name', '$Key')"
	}
	
	Invoke-SqliteQuery -Query $setKey -DataSource $Database -Password $Password
}

function Get-FromKeysDatabase {
	param(
		[parameter(mandatory=$true)]
		[int]
		$Id,
		
		[parameter()]
		[string]
		$Database = "..\..\SQLite\keys.sqlite",
		
		[parameter()]
		[string]
		$Password
	)
	
	$query = "SELECT * FROM keys WHERE Id = $Id"
	
	Invoke-SqliteQuery -Query $query -DataSource $Database -Password $Password
}
