function Reset-ServerPowerRedfish
{
	[CmdletBinding(SupportsShouldProcess = $true)]
	param
	(
		$ilosession,
		[System.String]$Action,
		[System.String]$PropertyName,
		[System.String]$PropertyValue
	)
	
	# getting system list
	$systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session $ilosession
	foreach ($sys in $systems.members.'@odata.id') # /redfish/v1/systems/1/, /redfish/v1/system/2/
	{
		$sysData = Get-HPERedfishDataRaw -odataid $sys -Session $ilosession
		
		# creating setting object to invoke reset action. 
		# Details of invoking reset (or other possible actions) is present in 'Actions' of system data  
		$dataToPost = @{ }
		$dataToPost.Add($PropertyName, $PropertyValue)
		
		# Sending reset request to system using 'POST' in Invoke-HPERedfishAction
		$ret = Invoke-HPERedfishAction -odataid $sysData.Actions.'#ComputerSystem.Reset'.target -Data $dataToPost -Session $ilosession
		
	}
	
	#Reset-ServerExample1 -Address $Address -Credential $cred -Action Reset -PropertyName ResetType -PropertyValue ForceRestart
}