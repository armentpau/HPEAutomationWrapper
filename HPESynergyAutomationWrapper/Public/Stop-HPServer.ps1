function Stop-HPServer
{
	[CmdletBinding(DefaultParameterSetName = 'CSV')]
	param
	(
		[switch]$Force,
		[Parameter(ParameterSetName = 'CSV')]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ test-path $_ })]
		[Alias('CSV', 'File', 'FilePath')]
		[string]$Path,
		[Parameter(ParameterSetName = 'Computer')]
		[ValidateNotNullOrEmpty()]
		[Alias('comp', 'server')]
		$Computer
	)
	BEGIN
	{
		try
		{
			#outputting to null to ignore any output - we don't need the output here - this is just to test if a connection is present.
			$null = Get-HPOVLoginMessage -erroraction stop
		}
		catch
		{
			Throw "Connection to an HPOVMgmt Server is not established.  Please establish a connection first."
		}
		if ($force)
		{
			$resetValue = "ForceOff"
		}
		else
		{
			$resetValue = "PushPowerButton"
		}
	}
	PROCESS
	{
		switch ($PsCmdlet.ParameterSetName)
		{
			'CSV' {
				if ((Test-PDCSV -Path $Path -Headers @("ServerName")).csvvalid)
				{
					foreach ($item in Import-Csv $path)
					{
						$ilosession = New-SSOIloSession -Computer (get-hpovserver -servername $($item.servername)) -ErrorAction Stop
						switch ($ilosession.method)
						{
							"Redfish"{
								ServerPowerRedfish -ilosession $ilosession.session -action "Reset" -PropertyName "ResetType" -PropertyValue $resetValue
							}
							"Rest"{
								ServerPowerRest -ilosession $ilosession.session -action "Reset" -propertyName "ResetType" -propertyValue $resetValue
							}
							default
							{
								throw "There was an error creating or finding the server $($Computer) with a valid REST method."
							}
						}
					}
				}
				else
				{
					throw "The CSV file is not valid.  The header ServerName was expected but not found."
				}
				break
			}
			'Computer' {
				$ilosession = New-SSOIloSession -Computer (get-hpovserver -servername $computer) -ErrorAction Stop
				switch ($ilosession.method)
				{
					"Redfish"{
						ServerPowerRedfish -ilosession $ilosession.session -action "Reset" -PropertyName "ResetType" -PropertyValue $resetValue
					}
					"Rest"{
						ServerPowerRest -ilosession $ilosession.session -action "Reset" -propertyName "ResetType" -propertyValue $resetValue
					}
					default
					{
						throw "There was an error creating or finding the server $($Computer) with a valid REST method."
					}
				}
				break
			}
		}
	}
	END
	{
		
	}
}