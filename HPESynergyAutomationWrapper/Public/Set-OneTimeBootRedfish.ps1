function Set-OneTimeBootGen10
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
	
	#Get system list
	$systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session $IloSession
	foreach ($sys in $systems.Members.'@odata.id') # /redfish/v1/systems/1/, /redfish/v1/system/2/
	{
		# get boot data for the system
		$sysData = Get-HPERedfishDataRaw -odataid $sys -Session $IloSession
		
		# create object to PATCH
		$tempBoot = @{ 'BootSourceOverrideTarget' = $BootTarget }
		$OneTimeBoot = @{ 'Boot' = $tempBoot }
		
		# PATCH the data using Set-HPERedfishData cmdlet
		$ret = Set-HPERedfishData -odataid $sys -Setting $OneTimeBoot -Session $IloSession
		$tempboot = @{ "UefiTargetBootSourceOverride" = "UsbClass(0xFFFF,0xFFFF,0xFF,0xFF,0xFF)" }
		$OneTimeBoot = @{ 'Boot' = $tempBoot }
		$ret = Set-HPERedfishData -odataid $sys -Setting $OneTimeBoot -Session $IloSession
	}
}


