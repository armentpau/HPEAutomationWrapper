function Set-VirtualMediaGen10
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		$ISOurl = $null,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$iLOSession,
		[System.Object]$BootOnNextReset = $null
	)
	
	$managers = Get-HPERedfishDataRaw -odataid '/redfish/v1/Managers/' -Session $Ilosession
	foreach ($mgr in $managers.Members.'@odata.id')
	{
		
		$mgrData = Get-HPERedfishDataRaw -odataid $mgr -Session $Ilosession
		# Check if virtual media is supported
		if ($mgrData.PSObject.Properties.name -Contains 'VirtualMedia' -eq $false)
		{
			# If virtual media is not present in links under manager details, print error
			write-warning -message 'Virtual media not available in Manager links'
		}
		else
		{
			
			$vmOdataId = $mgrData.VirtualMedia.'@odata.id'
			$vmData = Get-HPERedfishDataRaw -odataid $vmOdataId -Session $Ilosession
			foreach ($vm in $vmData.Members.'@odata.id')
			{
				
				$data = Get-HPERedfishDataRaw -odataid $vm -Session $Ilosession
				# select the media option which contains DVD
				if ($data.MediaTypes -contains 'DVD')
				{
					
					# Create object to PATCH to update ISO image URI and to set
					if ($null -eq $IsoUrl)
					{
						$mountSetting = @{ 'Image' = $null }
					}
					else
					{
						$mountSetting = @{ 'Image' = [System.Convert]::ToString($IsoUrl) }
					}
					if ($null -ne $BootOnNextReset -and $null -ne $IsoUrl)
					{
						
						# Create object to PATCH 
						# for iLO 5
						$oem = @{ 'Hpe' = @{ 'BootOnNextServerReset' = [System.Convert]::ToBoolean($BootOnNextReset) } }
						
						## for iLO 4
						#$oem = @{'Hp'=@{'BootOnNextServerReset'=[System.Convert]::ToBoolean($BootOnNextReset)}}
						
						$mountSetting.Add('Oem', $oem)
					}
					# PATCH the data to $vm odataid by using Set-HPERedfishData
					#Disconnect-HPERedfish -Session $session
					$ret = Set-HPERedfishData -odataid $vm -Setting $mountSetting -Session $Ilosession
					
				}
			}
		}
	}
}