function Wait-OSInstall
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$CSVData,
		[Parameter(Mandatory = $true)]
		$BootObjectArray,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$ServerList
	)
	
	do
	{
		$allip = $null
		#sleeping for 5 minutes for the settings to take
		start-sleep -seconds 300
		foreach ($item in $csvdata)
		{
			if (test-connection $item.servername -quiet -count 1)
			{
				$currentobj = $BootObjectArray | where-object{ $_.servername -eq $($item.servername) }
				if ([string]::IsNullOrEmpty($currentobj.endtime))
				{
					$currentobj.endtime = $(Get-Date -Format g)
				}
				if ($null -eq $allip)
				{
					$allip = $true
				}
			}
			else
			{
				$allip = $false
				$lastResponder = $BootObjectArray | Sort-Object -Property endtime| Select-Object -first 1
				if (-not ([string]::IsNullOrEmpty($lastResponder.endtime)))
				{
					$checkTime = Get-Date (Get-Date($lastResponder.endtime)).addhours(1) -Format g
					if ($checkTime -lt (Get-Date -Format g))
					{
						$lastResponder.endtime = $checkTime
						$selectedServer = $ServerList | where-object{ $_.serialnumber -eq $($item.serialnumber) }
						$ilosession = New-SSOIloSession -HPOVServer $selectedServer
						switch ($ilosession.method)
						{
							"Redfish"{
								Reset-ServerPowerRedfish -ilosession $($ilosession.session) -Action Reset -PropertyName ResetType -PropertyValue ForceRestart
							}
							"Rest"{
								Reset-ServerPowerRest -ilosession $($ilosession.session) -Action Reset -PropertyName ResetType -PropertyValue ForceRestart
							}
						}
					}
				}
			}
		}
	}
	while ($allIp -eq $false -or $Null -eq $allip)
}
