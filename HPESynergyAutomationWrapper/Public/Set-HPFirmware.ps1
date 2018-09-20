function Set-HPFirmware
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		$CSVImportData,
		[string]$ActivationType = 'Immediate',
		[string]$InstallType = 'FirmwareAndOSDrivers',
		[switch]$DontManageFirmware
	)
	
	foreach ($item in $CSVImportData)
	{
		$data = get-hpovserverprofile -name $($item.servername)
		$data.firmware.firmwareBaselineuri = "$($item.firmwareuri)"
		if ($DontManageFirmware)
		{
			$data.firmware.managefirmware = $false
		}
		else
		{
			$data.firmware.managefirmware = $true
		}
		$data.firmware.firmwareActivationType = $ActivationType
		$data.firmware.firmwareInstallType = $InstallType
		Send-HPOVRequest -Uri $data.uri -Method PUT -Body $data -Hostname $data.ApplianceConnection
	}
}



