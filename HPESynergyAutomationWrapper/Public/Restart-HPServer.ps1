function Restart-HPServer
{
	[CmdletBinding(DefaultParameterSetName = 'CSV')]
	param
	(
		[Parameter(ParameterSetName = 'CSV')]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ test-path $_ })]
		[Alias('CSV', 'File', 'FilePath')]
		[string]$Path,
		[Parameter(ParameterSetName = 'Computer')]
		[ValidateNotNullOrEmpty()]
		[Alias('comp', 'server')]
		$Computer,
		[switch]$ColdBoot,
		[switch]$Async
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
		$resetValue = "PushPowerButton"
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
						start-hpovserver -inputobject (get-hpovserver -servername $($item.servername)) -async:$($Async.IsPresent) -coldboot:$($ColdBoot.IsPresent)
					}
				}
				else
				{
					throw "The CSV file is not valid.  The header ServerName was expected but not found."
				}
				break
			}
			'Computer' {
				start-hpovserver -inputobject (get-hpovserver -servername $($computer)) -async:$($Async.IsPresent) -coldboot:$($ColdBoot.IsPresent)
				break
			}
		}
	}
	END
	{
		
	}
}