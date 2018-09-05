function New-SSOIloSession
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Server', 'computername', 'name')]
		$Computer
	)
	Disable-HPERedfishCertificateAuthentication
	$remoteConsole = "$($Computer.uri)/remoteConsoleUrl"
	$resp = send-hpovrequest $remoteConsole
	$url, $session = $resp.remoteconsoleUrl.split("&")
	$http, $iloip = $url.split("=")
	$sName, $sessionKey = $session.split("=")
	$rootUri = "https://$iloip/redfish/v1"
	$returnObject = [pscustomobject]@{
		"Method"    = $null;
		"Obj" = $null
	}
	try
	{
		$systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session (new-object PSObject -Property @{ "RootUri" = $rootURI; "X-Auth-Token" = $sessionkey } -ErrorAction Stop) -ErrorAction Stop
		$returnObject.method = "Redfish"
		$returnObject.obj = new-object PSObject -Property @{ "RootUri" = $rootURI; "X-Auth-Token" = $sessionkey } -ErrorAction Stop
	}
	catch
	{
		$rootUri = "https://$iloip/rest/v1"
		try
		{
			$systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session (new-object PSObject -Property @{ "RootUri" = $rootURI; "X-Auth-Token" = $sessionkey } -ErrorAction Stop) -erroraction stop
			$returnObject.method = "Rest"
			$returnObject.obj = new-object PSObject -Property @{ "RootUri" = $rootURI; "X-Auth-Token" = $sessionkey } -ErrorAction Stop
		}
		catch
		{
			throw "There was an error creating a SSO Ilo Session for $($Computer.name)  The error is $($psitem.tostring())"
		}
	}
}