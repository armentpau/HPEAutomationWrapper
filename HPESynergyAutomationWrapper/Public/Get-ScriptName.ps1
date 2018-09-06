function Get-ScriptName
{
	Param (
		[switch]$AppendUsername
	)
	
	if ((Get-Host).Version.Major -eq 2)
	{
		try
		{
			$scriptName = (Split-Path $MyInvocation.ScriptName -Leaf).tolower().Replace('.ps1', '')
		}
		catch
		{
			Write-Warning "Unable to determine script name.  Defaulting to Unknown."
			$scriptName = "Unknown"
		}
	}
	else
	{
		try
		{
			$scriptName = (Split-Path $MyInvocation.PSCommandPath -Leaf).tolower().Replace('.ps1', '')
		}
		catch
		{
			$scriptName = "Unknown"
		}
	}
	if ($scriptName -eq "Unknown" -and ((Get-Process -Id $PID).name -ne "Powershell"))
	{
		$scriptName = (Get-Process -Id $PID).name
	}
	if ($ScriptName -eq "Unknown")
	{
		Write-Warning "Unable to determine script name.  Defaulting to Unknown."
	}
	if ($AppendUsername)
	{
		$scriptName = "$($env:USERNAME)_$($scriptName)"
	}
	$scriptName
}