function Set-StaticIPConfiguration
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ScriptName,
		[ValidateNotNullOrEmpty()]
		[ValidateRange(1, 100)]
		[int]$MaxThreads = $env:NUMBER_OF_PROCESSORS + 1,
		[ValidateNotNullOrEmpty()]
		[ValidateSet('MTA', 'STA', IgnoreCase = $true)]
		[string]$ApartmentState = 'MTA',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$csvData,
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ test-path $_ })]
		[Alias('dns', 'dnscsv')]
		[string]$DNSData,
		[Parameter(Mandatory = $true)]
		[scriptblock]$WinRMScript,
		[Parameter(Mandatory = $true)]
		[scriptblock]$NonWinRMScript,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$2008IPScript,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$2012IPScript
	)
	#region test the script blocks to make sure they have all the necessary paramter blocks
	if (Test-PDScriptBlock -ScriptBlock $WinRMScript -Parameters @("ip", "credential", "changeIpString", "dnsData64", "scriptName"))
	{
		
	}
	else
	{
		throw "The parameters in the script block for the WinRMScript are not valid.  There are missing parameters.  Required parameters are ip,credential,changeIPString,dnsData64,ScriptName."
	}
	if (Test-PDScriptBlock -ScriptBlock $NonWinRMScript -Parameters @("ip", "credential", "changeIpString", "dnsData64", "scriptName"))
	{
		
	}
	else
	{
		throw "The parameters in the script block for NonWinRMScript are not valid.  There are missing parameters.  Required parameters are ip,credential,changeIPString,dnsData64,ScriptName."
	}
	#endregion
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
		if ($item.os -eq "2012")
		{
			$ipAddressScriptUpdated = $2012IPScript.replace("<ip>", $($item.static)).replace("<subnet>", $($item.subnet)).replace("<gateway>", $($item.gateway))
		}
		elseif ($item.os -eq "2008")
		{
			$ipAddressScriptUpdated = $2008IPScript.replace("<ip>", $($item.static)).replace("<subnet>", $($item.subnet)).replace("<gateway>", $($item.gateway))
		}
		
		$null = $runspace.AddArgument($ipAddressScriptUpdated)
		
		$dnsSelectedData = $DNSData | where-object($_.serverRegion -eq $($item.serverregion))
		$dnsData64 = ConvertTo-Base64StringFromObject -object $dnsData64
		$null = $runspace.AddArgument($dnsdata64)
		
		$null = $runspace.AddArgument($scriptname)
		$runspace.RunspacePool = $pool
		$runspaces += [pscustomobject]@{
			Pipe   = $runspace;
			Status = $runspace.begininvoke()
		} | Out-Null
	}
	do
	{
		Write-Progress -Activity "Waiting for all runspaces to finish." -Status "Checking the runspaces to see if more have completed."
		$completed = $runspaces | Where-Object{ $_.status.iscompleted -eq $true }
		foreach ($completedRunspace in $completed)
		{
			$results = $completedRunspace.pipe.endinvoke($completedRunspace.status)
			$completedRunspace.pipe.dispose()
			Write-Progress -Activity "Waiting for all runspaces to finish." -Status "Checking the runspaces to see if more have completed." -CurrentOperation "Terminating completed runspaces"
		}
		Write-Progress -Activity "Waiting for all runspaces to finish." -Status "Sleeping to allow for the runspaces to complete."
		Start-Sleep -Seconds 10
	}
	while ($runspaces.status.iscompleted -contains $false)
	$pool.close()
	$pool.Dispose()
}
