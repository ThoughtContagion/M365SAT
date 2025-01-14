# This is an MailboxForwarding Inspector.

# Date: 25-1-2023
# Version: 1.0
# Product Family: Microsoft Exchange
# Purpose: Checks if MailboxForwarding is enabled for mailboxes
# Author: Leonardo van de Weteringh

# Enables error handling if you have the Write-ErrorLog script in the parent directory
$errorHandling = "$((Get-Item $PSScriptRoot).Parent.FullName)\Write-ErrorLog.ps1"

# Sets the Action Preference when an error occurs. Default is Stop
$ErrorActionPreference = "Stop"

# Calls the Error Handling to check if it is existing
. $errorHandling

function Build-MailboxForwarding($findings)
{
	#Actual Inspector Object that will be returned. All object values are required to be filled in.
	$inspectorobject = New-Object PSObject -Property @{
		ID			     = "M365SATFMEX0042"
		FindingName	     = "Exchange Mailboxes with Forwarding Rules Enabled"
		ProductFamily    = "Microsoft Exchange"
		CVS			     = "5.7"
		Description	     = "The Exchange Online mailboxes listed above have Forwarding rules configured enabled. Attackers commonly create hidden forwarding rules in compromised mailboxes. These rules may be exfiltrating data with or without the user's knowledge."
		Remediation	     = "Verify that the forwarding rules do not violate company policy, are expected and allowed."
		PowerShellScript = 'Remove-InboxRule -Mailbox <email address> -Identity "Rule Name"'
		DefaultValue	 = "NULL"
		ExpectedValue    = "No Forwarding Rules"
		ReturnedValue    = $findings
		Impact		     = "Medium"
		RiskRating	     = "Medium"
		References	     = @(@{ 'Name' = 'Office 365 - List all email forwarding rules (PowerShell)'; 'URL' = "https://geekshangout.com/office-365-powershell-list-email-forwarding-rules-mailboxes/" },
			@{ 'Name' = 'Get-Mailbox Commandlet Reference'; 'URL' = "https://docs.microsoft.com/en-us/powershell/module/exchange/get-mailbox?view=exchange-ps" })
	}
	return $inspectorobject
}

Function Get-MailboxForwarding
{
	Try
	{
		
		$mailboxes = Get-Mailbox -ResultSize Unlimited
		
		$rulesEnabled = @()
		
		foreach ($mailbox in $mailboxes)
		{
			$rulesEnabled += Get-InboxRule -Mailbox $mailbox.UserPrincipalName | Where-Object { ($null -ne $_.ForwardTo) -or ($null -ne $_.ForwardAsAttachmentTo) -or ($null -ne $_.RedirectTo) } | Select-Object MailboxOwnerId, RuleIdentity, Name, ForwardTo, RedirectTo
		}
		if ($rulesEnabled.Count -gt 0)
		{
			$rulesEnabled | Out-File -FilePath "$($path)\ExchangeMailboxeswithForwardingRules.txt" -Append
			$endobject = Build-MailboxForwarding($rulesenabled.MailboxOwnerID)
			Return $endobject 
		}
		Return $null
		
	}
	Catch
	{
		Write-Warning "Error message: $_"
		$message = $_.ToString()
		$exception = $_.Exception
		$strace = $_.ScriptStackTrace
		$failingline = $_.InvocationInfo.Line
		$positionmsg = $_.InvocationInfo.PositionMessage
		$pscommandpath = $_.InvocationInfo.PSCommandPath
		$failinglinenumber = $_.InvocationInfo.ScriptLineNumber
		$scriptname = $_.InvocationInfo.ScriptName
		Write-Verbose "Write to log"
		Write-ErrorLog -message $message -exception $exception -scriptname $scriptname -failinglinenumber $failinglinenumber -failingline $failingline -pscommandpath $pscommandpath -positionmsg $pscommandpath -stacktrace $strace
		Write-Verbose "Errors written to log"
	}
	
}

Get-MailboxForwarding


