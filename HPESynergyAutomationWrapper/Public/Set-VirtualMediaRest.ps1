function Set-VirtualMediaRest
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
	
	$managers = Get-HPRESTDataRaw -Href $RESTManagers -Session $ILOsession
	
	foreach ($mgr in $managers.links.Member.href)
	{
		
		$mgrData = Get-HPRESTDataRaw -Href $mgr -Session $ILOsession
		
		# Check if virtual media is supported
		if ($mgrData.links.PSObject.Properties.name -Contains 'VirtualMedia' -eq $false)
		{
			
			# If virtual media is not present in links under manager details, print error
			write-warning -message 'Virtual media not available in Manager links'
			
		}
		
		else
		{
			
			$vmhref = $mgrData.links.VirtualMedia.href
			$vmdata = Get-HPRESTDataRaw -Href $vmhref -Session $ILOsession
			
			foreach ($vm in $vmdata.links.Member.href)
			{
				
				$data = Get-HPRESTDataRaw -Href $vm -Session $ILOsession
				
				# select the media option which contains DVD
				if ($data.MediaTypes -contains 'DVD')
				{
					
					# Create object to PATCH to update ISO image URI and to set
					
					# Eject Media if there is already one
					if ($data.Image)
					{
						
						# Dismount DVD if there is already one
						$mountSetting = @{ 'Image' = $null }
						$ret = Set-HPRESTData -Href $vm -Setting $mountSetting -Session $ILOsession
						
					}
					
					# Attach DVD file to media
					$mountSetting = @{ 'Image' = [System.Convert]::ToString($IsoUrl) }
					
					if ($null -ne $BootOnNextReset -and $null -ne $IsoUrl)
					{
						
						# Create object to PATCH 
						$oem = @{ 'Hp' = @{ 'BootOnNextServerReset' = [System.Convert]::ToBoolean($BootOnNextReset) } }
						$mountSetting.Add('Oem', $oem)
						
					}
					
					# PATCH the data to $vm href by using Set-HPRESTData                    
					$ret = Set-HPRESTData -Href $vm -Setting $mountSetting -Session $ILOsession
				}
				
			}
			
		}
		
	}
}