function ServerPowerRest
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
	$systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session $iloSession
	foreach ($sys in $systems.links.member.href) # rest/v1/systems/1, rest/v1/system/2
	{
		# creating setting object to invoke reset action. 
		# Details of invoking reset (or other possible actions) is present in 'AvailableActions' of system data  
		$dataToPost = @{ }
		$dataToPost.Add('Action', $Action)
		$dataToPost.Add($PropertyName, $PropertyValue)
		
		# Sending reset request to system using 'POST' in Invoke-HPRESTAction
		try
		{
			$ret = Invoke-HPRESTAction -Href $sys -Data $dataToPost -Session $iloSession -erroraction stop
			"Successfully sent a shutdown command to the computer"
		}
		catch
		{
			"There was an error sending a shutdown command to the computer.  The error is $($psitem.tostring())"
		}
	}
}