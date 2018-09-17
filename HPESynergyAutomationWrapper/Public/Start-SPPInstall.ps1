function Start-SPPInstall
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('script', 'name')]
		[string]$ScriptName,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,
		[Parameter(Mandatory = $true)]
		$csvData,
		[ValidateRange(1, 100)]
		[ValidateNotNullOrEmpty()]
		[int]$MaxThreads = $env:NUMBER_OF_PROCESSORS + 1,
		[ValidateSet('MTA', 'STA', IgnoreCase = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ApartmentState = 'MTA',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$SPPScript
	)
	BEGIN
	{
		$winRMScript = [scriptblock]{
			[CMDletBinding()]
			Param (
				[Parameter(Mandatory=$true)]
				$ip,
				[Parameter(Mandatory = $true)]
				[pscredential]$credential,
				[Parameter(Mandatory = $true)]
				[String]$SPPScript
			)
			Invoke-Command -Credential $Credential -ScriptBlock {
				New-Item -type directory -Path "c:\temp" -force
				$args[0] | Out-File "c:\temp\SPPScript.ps1" -encoding ascii -Force
				& "c:\temp\SPPScript.ps1"
			} -ComputerName $ip -ArgumentList $SPPScript
		}
		
		$nonWinRmScript = [scriptblock]{
			[CMDletBinding()]
			Param (
				[Parameter(Mandatory = $true)]
				$ip,
				[Parameter(Mandatory = $true)]
				[pscredential]$credential,
				[Parameter(Mandatory = $true)]
				[String]$SPPScript
			)
			$SPPScript = "new-item -type directory -path 'c:\temp' -force`r`n" + $SPPScript
			
		}
	}
	PROCESS
	{
		$hash = [hashtable]::Synchronized(@{ })
		$hash.host = $Host
		$sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
		$pool = [RunspaceFactory]::CreateRunspacePool(1, $maxthreads, $sessionstate, $Host)
		$pool.ApartmentState = $ApartmentState
		$pool.Open()
		$runspaces = @()
		foreach ($item in $csvdata)
		{
			$ip = (Test-Connection $($item.servername) -Count 1 | Select-Object ipv4eaddress).ipv4address.ipaddresstostring
			$useWinRm = Test-PDWinRM -ComputerName $($ip) -Credential $Credential
			
		}
	}
	END
	{
	}
	
}