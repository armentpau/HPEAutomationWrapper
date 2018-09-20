function Test-PDScriptBlock
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string[]]$Parameters
	)
	
	$parameterData = $ScriptBlock.Ast.paramblock.parameters.name.variablepath.userpath
	$isFunctionValid = $true
	foreach ($item in $Parameters)
	{
		if ($scriptblock -contains $item)
		{
			#nothing right now
		}
		else
		{
			$isFunctionValid = $false
		}
	}
	return $isFunctionValid
}