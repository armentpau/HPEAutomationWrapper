﻿function Stop-HPServer
{
	[CmdletBinding(DefaultParameterSetName = 'CSV')]
	param
	(
		[switch]$Force,
		[Parameter(ParameterSetName = 'CSV')]
		[ValidateScript({ test-path $_ })]
		[ValidateNotNullOrEmpty()]
		[Alias('CSV', 'File', 'FilePath')]
		[string]$Path,
		[Parameter(ParameterSetName = 'Computer')]
		[ValidateNotNullOrEmpty()]
		[Alias('comp', 'server')]
		$Computer,
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
						stop-hpovserver -inputobject (get-hpovserver -servername $($item.servername)) -erroraction stop -force:$($force.IsPresent) -async:$($Async.IsPresent) -confirm:$false 
					}
				}
				else
				{
					throw "The CSV file is not valid.  The header ServerName was expected but not found."
				}
				break
			}
			'Computer' {
				stop-hpovserver -inputobject (get-hpovserver -servername $computer) -erroraction stop -force:$($force.IsPresent) -confirm:$false -async:$($Async.IsPresent)
				break
			}
		}
	}
	END
	{
		
	}
}