using module "..\ORCA.psm1"

class ORCA142 : ORCACheck
{
    <#
    
        CONSTRUCTOR with Check Header Data
    
    #>

    ORCA142()
    {
        $this.Control=142
        $this.Area="Anti-Spam Policies"
        $this.Name="Phish Action"
        $this.PassText="Phish action set to Quarantine message"
        $this.FailRecommendation="Change Phish action to Quarantine message"
        $this.Importance="It is recommended to configure the Phish detection action to Quarantine so that these emails are not visible to the end user from within Outlook. As Phishing emails are designed to look legitimate, users may mistakenly think that a phishing email in Junk is false-positive."
        $this.ExpandResults=$True
        $this.ItemName="Anti-Spam Policy"
        $this.DataType="Action"
        $this.ChiValue=[ORCACHI]::High
        $this.Links= @{
            "Security & Compliance Center - Anti-spam settings"="https://aka.ms/orca-antispam-action-antispam"
            "Recommended settings for EOP and Microsoft Defender for Office 365"="https://aka.ms/orca-atpp-docs-6"
        }
    
    }

    <#
    
        RESULTS
    
    #>

    GetResults($Config)
    {
        #$CountOfPolicies = ($Config["HostedContentFilterPolicy"]).Count
        $CountOfPolicies = ($global:HostedContentPolicyStatus| Where-Object {$_.IsEnabled -eq $True}).Count
         
        ForEach($Policy in $Config["HostedContentFilterPolicy"]) 
        {
            $IsPolicyDisabled = !$Config["PolicyStates"][$Policy.Guid.ToString()].Applies
            $PhishSpamAction = $($Policy.PhishSpamAction)

            $IsBuiltIn = $false
            $policyname = $Config["PolicyStates"][$Policy.Guid.ToString()].Name

            $ConfigObject = [ORCACheckConfig]::new()
            $ConfigObject.Object=$policyname
            $ConfigObject.ConfigItem=$policyname
            $ConfigObject.ConfigReadonly=$Policy.IsPreset
            $ConfigObject.ConfigDisabled=$IsPolicyDisabled
            $ConfigObject.ConfigPolicyGuid=$Policy.Guid.ToString()

            # Fail if PhishSpamAction is not set to Quarantine
    
            If($PhishSpamAction -eq "Quarantine") 
            {
                $ConfigObject.ConfigData=$($PhishSpamAction)
                $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Pass")
            }
            else 
            {
                $ConfigObject.ConfigData=$($PhishSpamAction)
                $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Fail")
            }
            
            If($PhishSpamAction -eq "Delete" -or $PhishSpamAction -eq "Redirect")
            {
                $ConfigObject.ConfigData=$($PhishSpamAction)
                
                # For either Delete or Quarantine we should raise an informational
                $ConfigObject.SetResult([ORCAConfigLevel]::Informational,"Fail")
                $ConfigObject.InfoText = "The $($PhishSpamAction) option may impact the users ability to release emails and may impact user experience."
            }   


            # Add config to check
            $this.AddConfig($ConfigObject)
            
        }        

    }

}