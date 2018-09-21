function Set-HPOneTimeBoot
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$BootTarget,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$iLOsession
	)
	switch ($ilosession.method)
	{
		"Redfish"{
			try
			{
				Set-OneTimeBootRedfish -BootTarget $bootTarget -ilosession $($ilosession.session) -erroraction stop
				Write-Output "Successfully set $($iLOsession.session.rooturi.tostring()) to boot to $($BootTarget) on next boot."
			}
			catch
			{
				Write-Verbose "There was an error setting ilosession $($ilosession.session.rooturi.tostring()) to boot to $($bootTarget) on the next boot"
				throw "Unable to set boot setting on next boot to $($BootTarget) on $($iLOsession.session.rooturi.tostring())."
			}
		}
		"Rest"{
			try
			{
				Set-OneTimeBootRest -BootTarget "Cd" -ilosession $($ilosession.session) -erroraction stop
				Write-Output "Successfully set $($iLOsession.session.rooturi.tostring()) to boot to $($BootTarget) on next boot."
			}
			catch
			{
				Write-Verbose "There was an error setting ilosession $($ilosession.session.rooturi.tostring()) to boot to $($bootTarget) on the next boot"
				throw "Unable to set boot setting on next boot to $($BootTarget) on $($iLOsession.session.rooturi.tostring())."
			}
		}
	}	
}