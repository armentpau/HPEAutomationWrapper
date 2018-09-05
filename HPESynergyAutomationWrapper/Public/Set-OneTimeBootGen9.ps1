function Set-OneTimeBootGen9
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$BootTarget,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$iLOsession
	)
	
	$Systems = Get-HPRESTDataRaw -Href "/rest/v1/Systems" -Session $iLOsession
	
	foreach ($sys in $Systems.links.member.href) # /rest/v1/systems/1 or /rest/v1/systems/2
	{
		
		#Get System Data
		$sysData = Get-HPRESTDataRaw -Href $sys -Session $iLOsession
		
		$bootData = $sysData.boot
		if (-not ($bootData.BootSourceOverrideSupported -Contains $BootTarget))
		{			
			# if user provided not supported then print error
			write-warning -message "$BootTarget not supported"
		}
		
		else
		{
			
			# create object to PATCH
			$tempBoot = @{ 'BootSourceOverrideTarget' = $BootTarget }
			$OneTimeBoot = @{ 'Boot' = $tempBoot }
			
			# PATCH the data using Set-HPRESTData cmdlet
			$ret = Set-HPRESTData -Href $sys -Setting $OneTimeBoot -Session $iLOsession
			
			#process message returned by Set-HPRESTData cmdlet
			if ($ret.Messages.Count -gt 0)
			{
				foreach ($msgID in $ret.Messages)
				{
					$status = Get-HPRESTError -MessageID $msgID.MessageID -MessageArg $msgID.MessageArgs -Session $iLOSession
					$status
				}	
			}
		}
	}
}