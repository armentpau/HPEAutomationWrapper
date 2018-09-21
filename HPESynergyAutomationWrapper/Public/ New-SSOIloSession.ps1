function New-SSOIloSession
{
	[CmdletBinding(DefaultParameterSetName = 'HPOVServer')]
	param
	(
		[Parameter(ParameterSetName = 'HPOVServer',
				   Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[Alias('Server', 'computername', 'name', 'Computer')]
		$HPOVServer,
		[Parameter(ParameterSetName = 'ServerName',
				   Mandatory = $true)]
		$HPServer,
		[switch]$DisableHPERedfishCertificateAuthentication
	)
	
	switch ($PSCmdlet.ParameterSetName)
	{
		"HPOVSERVER"{
			#nothing needs to happen here - this is an hpovserver profile
		}
		"ServerName"{
			try
			{
				$HPOVServer = Get-HPOVServer -ServerName $($hpserver) -ErrorAction Stop
			}
			catch
			{
				throw "Unable to get a server named $($HPServer) from OneView.  The error is $($psitem.tostring())"
			}
		}
	}
	if ($DisableHPERedfishCertificateAuthentication)
	{
		#we are disabling redfish certifcate authentication right now due to issues
		#with the certifacte authenticity
		Disable-HPERedfishCertificateAuthentication
	}
	$remoteConsole = "$($HPOVServer.uri)/remoteConsoleUrl"
	$resp = send-hpovrequest $remoteConsole
	$url, $session = $resp.remoteconsoleUrl.split("&")
	$http, $iloip = $url.split("=")
	$sName, $sessionKey = $session.split("=")
	#testing for redfish first since this is going to be more common version
	$rootUri = "https://$iloip/redfish/v1"
	$returnObject = [pscustomobject]@{
		"Method"  = $null;
		"Session" = $null
	}
	try
	{
		$systems = Get-HPERedfishDataRaw -odataid '/redfish/v1/systems/' -Session (new-object PSObject -Property @{ "RootUri" = $rootURI; "X-Auth-Token" = $sessionkey } -ErrorAction Stop) -ErrorAction Stop
		$returnObject.method = "Redfish"
		$returnObject.session = new-object PSObject -Property @{ "RootUri" = $rootURI; "X-Auth-Token" = $sessionkey } -ErrorAction Stop
	}
	catch
	{
		#redfish method errored out - so lets try rest
		$rootUri = "https://$iloip/rest/v1"
		try
		{
			$systems = Get-HPRESTDataRaw -Href 'rest/v1/systems' -Session (new-object PSObject -Property @{ "RootUri" = $rootURI; "X-Auth-Token" = $sessionkey } -ErrorAction Stop) -erroraction stop
			$returnObject.method = "Rest"
			$returnObject.session = new-object PSObject -Property @{ "RootUri" = $rootURI; "X-Auth-Token" = $sessionkey } -ErrorAction Stop
		}
		catch
		{
			$returnObject.method = "There was an error creating a SSO Ilo Session for $($HPOVServer.name)  The error is $($psitem.tostring())"
			$returnObject.session = "ERROR"
		}
	}
	$returnObject
}