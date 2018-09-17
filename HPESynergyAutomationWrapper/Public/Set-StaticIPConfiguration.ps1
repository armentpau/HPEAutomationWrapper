function Set-StaticIPConfiguration
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ScriptName,
		[ValidateRange(1, 100)]
		[ValidateNotNullOrEmpty()]
		[int]$MaxThreads = $env:NUMBER_OF_PROCESSORS + 1,
		[ValidateSet('MTA', 'STA', IgnoreCase = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ApartmentState = 'MTA',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$csvData,
		[ValidateScript({ test-path $_ })]
		[ValidateNotNullOrEmpty()]
		[Alias('dns', 'dnscsv')]
		[string]$DNSData,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$IPAddressScript,
		[Parameter(Mandatory = $true)]
		[scriptblock]$WinRMScript,
		[Parameter(Mandatory = $true)]
		[scriptblock]$NonWinRMScript
	)
	
	$hash = [hashtable]::Synchronized(@{ })
	$hash.host = $Host
	$sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
	$pool = [RunspaceFactory]::CreateRunspacePool(1, $maxthreads, $sessionstate, $Host)
	$pool.ApartmentState = $ApartmentState
	$pool.Open()
	$runspaces = @()
	foreach ($item in $csvdata)
	{
		$ip = (Test-Connection $($item.servername) -Count 1 | Select-Object ipv4address).ipv4address.ipaddresstostring
		
		$runspace = [powershell]::Create()
		try
		{
			#test to see if windows remoting is enabled - if it is then use the winrmscript, otherwise use the nonwinrmscript
			Invoke-Command -ScriptBlock { get-process } -ComputerName $ip -Credential $Credential -ErrorAction Stop
			$null = $runspace.addscript($winrmscript)
		}
		catch
		{
			$null = $runspace.addscript($NonWinRMScript)
		}
		$null = $runspace.AddArgument($ip)
		$null = $runspace.AddArgument($credential)
		
		$ipAddressScriptUpdated = $IPAddressScript.replace("<ip>", $($item.static)).replace("<subnet>", $($item.subnet)).replace("<gateway>", $($item.gateway))
		$null = $runspace.AddArgument($IPAddressScript)
		
		$dnsSelectedData = $DNSData | where-object($_.serverRegion -eq $($item.serverregion))
		$dnsData64 = ConvertTo-Base64StringFromObject -object $dnsData64
		$null = $runspace.addargument($dnsdata)
		$null = $runspace.AddArgument($dnsdata64)
		
		$null = $runspace.AddArgument($scriptname)
		$runspace.RunspacePool = $pool
		$runspaces += [pscustomobject]@{
			Pipe   = $runspace;
			Status = $runspace.begininvoke()
		} | Out-Null
		
	}
}
