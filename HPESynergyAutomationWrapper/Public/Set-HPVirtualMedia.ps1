function Set-HPVirtualMedia
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$iLOsession,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$ISOUri
	)
	
	switch ($ilosession.method)
	{
		"Redfish"{
			try
			{
				set-virtualmediaRedFish -Ilosession $($ilosession.session) -erroraction stop
				Write-Output "Successfully unmounted the virtual media for ilosession $($iLOsession.session.rooturi.trim())"
			}
			catch
			{
				Write-Verbose -Message "There was an error unmounting the virtual media for ilosession $($ilosession.session.rooturi.trim()).  The error is $($psitem.tostring())."
				Write-Warning -Message "There was an error removing virtual media for $($iLOsession.session.rooturi.trim())"
			}
			try
			{
				set-virtualmediaRedfish -isourl $ISOUri -ilosession $($ilosession.session) -erroraction stop
				Write-Output "Successfully mounted $($ISOUri) as virtual media to ilosession $($iLOsession.session.rooturi.trim())"
			}
			catch
			{
				Write-Verbose "There was an error mounting the iso url $isouri to ilosession $($ilosession.session.rooturi.trim()).  The error is $($psitem.tostring())"
				throw "There was an error mounting the ISO to $($ilosession.session.rooturi.trim()).  The error is $($psitem.tostring())."
			}
		}
		"Rest"{
			
			try
			{
				set-virtualmediarest -Ilosession $($ilosession.session) -erroraction stop
				Write-Output "Successfully unmounted the virtual media for ilosession $($iLOsession.session.rooturi.trim())"
			}
			catch
			{
				Write-Verbose -Message "There was an error unmounting the virtual media for ilosession $($ilosession.session.rooturi.trim()).  The error is $($psitem.tostring())."
				Write-Warning -Message "There was an error removing virtual media for $($iLOsession.session.rooturi.trim())"
			}
			
			try
			{
				Set-VirtualMediaRest -isourl $ISOUri -ilosession $($ilosession.session) -erroraction stop
			}
			catch
			{
				Write-Verbose "There was an error mounting the iso url $isouri to ilosession $($ilosession.session.rooturi.trim()).  The error is $($psitem.tostring())"
				throw "There was an error mounting the ISO to $($ilosession.session.rooturi.trim()).  The error is $($psitem.tostring())."
			}
		}
	}
}