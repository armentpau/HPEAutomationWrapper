<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	8/30/2018 4:19 PM
	 Created by:   	949237a
	 Organization: 	
	 Filename:     	HPEOneViewAutomationWrapper.psm1
	-------------------------------------------------------------------------
	 Module Name: HPEOneViewAutomationWrapper
	===========================================================================
#>
$scriptPath = Split-Path $MyInvocation.MyCommand.Path
try
{
	Get-ChildItem "$scriptPath\Public" -filter *.ps1 | Select-Object -ExpandProperty FullName | ForEach-Object{
		. $_
	}
}
catch
{
	Write-Warning "There was an error loading $($function) and the error is $($psitem.tostring())"
	exit
}
