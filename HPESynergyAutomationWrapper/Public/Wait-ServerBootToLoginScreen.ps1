function Wait-ServerBootToLoginScreen
{
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
		$csvData
	)
	
	$checkScriptBLock = {
		[CmdletBinding()]
		param
		(
			[Parameter(Mandatory = $true)]
			$ip,
			[Parameter(Mandatory = $true)]
			[pscredential]$Credential,
			[string]$scriptName,
			$os
		)
		
		do
		{
			Start-Sleep -Seconds 120
			$passFlag = $false
			if ($os -eq "2012")
			{
				try
				{
					$data = Invoke-Command -ComputerName $ip -Credential $Credential -ScriptBlock {
						try
						{
							get-process -ErrorAction Stop
						}
						catch
						{
							return "Error"
						}
					} -ErrorAction Stop
				}
				catch
				{
					$data = "Error"
				}
			}
			elseif ($os -eq "2008")
			{
				$data = $null
				try
				{
					$Data = Invoke-WmiMethod -Class win32_process -Name create -ArgumentList 'powershell.exe -command "get-process"' -ComputerName $IP -Credential $Credential -ErrorAction Stop
				}
				catch
				{
					$data = "Error"
				}
			}
			if ($data -eq "Error")
			{
				$passFlag = $false
			}
			else
			{
				$passFlag = $true
			}
		}
		while ($passFlag -eq $false)
	}
	
	$hash = [hashtable]::Synchronized(@{ })
	$hash.host = $Host
	$sessionstate = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
	$pool = [RunspaceFactory]::CreateRunspacePool(1, [int]$MaxThreads, $sessionstate, $Host)
	$pool.ApartmentState = $ApartmentState
	$pool.Open()
	$runspaces = [System.Collections.arraylist]@()
	foreach ($item in $csvData)
	{
		$ip = (test-connection $($item.servername) -count 1 | Select-Object ipv4address).ipv4address.ipaddresstostring
		if ($ip)
		{
			$runspace = [powershell]::Create()
			$null = $runspace.addscript($checkScriptBLock)
			$null = $runspace.addargument($ip)
			$null = $runspace.AddArgument($credential)
			$null = $runspace.AddArgument($scriptname)
			$null = $runspace.AddArgument("$($item.os)")
			$runspace.RunspacePool = $pool
			$runspaces.Add([pscustomobject]@{
					Pipe   = $runspace;
					status = $runspace.begininvoke()
				}) | Out-Null
		}
	}
	do
	{
		$completed = $runspaces | Where-Object{ $_.status.iscompleted -eq $true }
		foreach ($completedRunspace in $completed)
		{
			$results = $completedRunspace.pipe.endinvoke($completedRunspace.status)
			$completedRunspace.pipe.dispose()
		}
		Start-Sleep -Seconds 120
	}
	while ($runspaces.status.iscompleted -contains $false)
	
	$pool.close()
	$pool.dispose()
	#endregion
}