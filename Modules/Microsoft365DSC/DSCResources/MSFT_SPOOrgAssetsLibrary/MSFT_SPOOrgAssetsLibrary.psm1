function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LibraryUrl,

        [Parameter()]
        [System.String]
        $ThumbnailUrl,

        [Parameter()]
        [ValidateSet('Public', 'Private')]
        [System.String]
        $CdnType = 'Public',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Getting configuration of SPO Org Assets Library"
    $ConnectionMode = New-M365DSCConnection -Platform 'PnP' `
        -InboundParameters $PSBoundParameters

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace("MSFT_", "")
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $ResourceName)
    $data.Add("Method", $MyInvocation.MyCommand)
    $data.Add("Principal", $GlobalAdminAccount.UserName)
    $data.Add("TenantId", $TenantId)
    $data.Add("ConnectionMode", $ConnectionMode)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $nullReturn = $PSBoundParameters
    $nullReturn.Ensure = "Absent"

    try
    {
        try
        {
            $orgAssets = Get-PnPOrgAssetsLibrary -ErrorAction SilentlyContinue
        }
        catch
        {
            try
            {
                Write-Verbose -Message $_
                $tenantIdValue = ""
                if (-not [System.String]::IsNullOrEmpty($TenantId))
                {
                    $tenantIdValue = $TenantId
                }
                elseif ($null -ne $GlobalAdminAccount)
                {
                    $tenantIdValue = $GlobalAdminAccount.UserName.Split('@')[1]
                }
                Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                    -EventID 1 -Source $($MyInvocation.MyCommand.Source) `
                    -TenantId $tenantIdValue
            }
            catch
            {
                Write-Verbose -Message $_
            }
        }

        $cdn = $null
        if ($CdnType -eq 'Public')
        {
            if (Get-PnPTenantCdnEnabled -CdnType $CdnType)
            {
                $cdn = "Public"
            }
        }

        if ($CdnType -eq 'Private')
        {
            if (Get-PnPTenantCdnEnabled -CdnType $CdnType)
            {
                $cdn = "Private"
            }
        }

        if ($null -eq $orgAssets)
        {
            return $nullReturn
        }
        else
        {
            if ($ConnectionMode -eq 'Credential')
            {
                $tenantName = Get-M365TenantName -GlobalAdminAccount $GlobalAdminAccount
            }
            else
            {
                $tenantName = $TenantId.Split(".")[0]
            }

            foreach ($orgAsset in $orgAssets.OrgAssetsLibraries)
            {
                $orgLibraryUrl = "https://$tenantName.sharepoint.com/$($orgAsset.libraryurl.DecodedUrl)"

                if ($orgLibraryUrl -eq $LibraryUrl)
                {
                    Write-Verbose -Message "Found existing SharePoint Org Site Assets for $LibraryUrl"
                    if ($null -ne $orgAsset.ThumbnailUrl.DecodedUrl)
                    {
                        $orgthumbnailUrl = "https://$tenantName.sharepoint.com/$($orgAsset.LibraryUrl.decodedurl.Substring(0,$orgAsset.LibraryUrl.decodedurl.LastIndexOf("/")))/$($orgAsset.ThumbnailUrl.decodedurl)"
                    }

                    $result = @{
                        LibraryUrl            = $orgLibraryUrl
                        ThumbnailUrl          = $orgthumbnailUrl
                        CdnType               = $cdn
                        Ensure                = "Present"
                        GlobalAdminAccount    = $GlobalAdminAccount
                        ApplicationId         = $ApplicationId
                        TenantId              = $TenantId
                        CertificatePassword   = $CertificatePassword
                        CertificatePath       = $CertificatePath
                        CertificateThumbprint = $CertificateThumbprint
                    }
                    Write-Verbose -Message "Get-TargetResource Result: `n $(Convert-M365DscHashtableToString -Hashtable $result)"
                    return $result
                }
            }
            $currentValues = $PSBoundParameters
            $currentValues.Ensure = "Absent"
            return $currentValues
        }
    }
    catch
    {
        try
        {
            Write-Verbose -Message $_
            $tenantIdValue = ""
            if (-not [System.String]::IsNullOrEmpty($TenantId))
            {
                $tenantIdValue = $TenantId
            }
            elseif ($null -ne $GlobalAdminAccount)
            {
                $tenantIdValue = $GlobalAdminAccount.UserName.Split('@')[1]
            }
            Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                -EventID 1 -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $tenantIdValue
        }
        catch
        {
            Write-Verbose -Message $_
        }
        return $nullReturn
    }
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $LibraryUrl,

        [Parameter()]
        [System.String]
        $ThumbnailUrl,

        [Parameter()]
        [ValidateSet('Public', 'Private')]
        [System.String]
        $CdnType = 'Public',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )

    Write-Verbose -Message "Setting configuration of SharePoint Org Site Assets"
    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace("MSFT_", "")
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $ResourceName)
    $data.Add("Method", $MyInvocation.MyCommand)
    $data.Add("Principal", $GlobalAdminAccount.UserName)
    $data.Add("TenantId", $TenantId)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    $currentOrgSiteAsset = Get-TargetResource @PSBoundParameters
    $currentParameters = $PSBoundParameters
    $currentParameters.Remove("Ensure") | Out-Null
    $currentParameters.Remove("GlobalAdminAccount") | Out-Null
    $currentParameters.Remove("ApplicationId") | Out-Null
    $currentParameters.Remove("TenantId") | Out-Null
    $currentParameters.Remove("CertificatePath") | Out-Null
    $currentParameters.Remove("CertificatePassword") | Out-Null
    $CurrentParameters.Remove("CertificateThumbprint") | Out-Null

    $cdn = $null
    if ($CdnType -eq 'Public')
    {
        if (Get-PnPTenantCdnEnabled -CdnType $CdnType)
        {
            $cdn = "Public"
        }
    }

    if ($CdnType -eq 'Private')
    {
        if (Get-PnPTenantCdnEnabled -CdnType $CdnType)
        {
            $cdn = "Private"
        }
    }


    if ($null -eq $cdn)
    {
        throw "Tenant $CdnType CDN must be configured before setting site organization Library"
    }


    if ($Ensure -eq 'Present' -and $currentOrgSiteAsset.Ensure -eq 'Present')
    {
        ## No set so remove / add
        Remove-PnPOrgAssetsLibrary -LibraryUrl $currentOrgSiteAsset.LibraryUrl
        ### add slight delay fails if you immediately try to add
        Start-Sleep -Seconds 30
        Add-PnPOrgAssetsLibrary @currentParameters
    }
    elseif ($Ensure -eq 'Present' -and $currentOrgSiteAsset.Ensure -eq 'Absent')
    {
        $ErrorActionPreference = 'Continue'

        $siteUrl = "https://$($domain)-admin.sharepoint.com"

        write-Verbose ("Connect to site: $siteUrl")

        Connect-PnPOnline -Thumbprint $CertificateThumbprint -Tenant $TenantId -ClientId $ApplicationId -Url $siteUrl

        write-Verbose ("Retrieve sites")

        $sites = Get-PnPTenantSite | select Url -ExpandProperty Url

        $currentOrgAssetLibraryPath = $null
        $OrgAssetLibraryPath = $null

        $testSitePath = "sites/$sitePath"

        $ErrorActionPreference = 'SilentlyContinue'

        $libraryPath = "sites/$sitePath/$title"

        $libraryUrl = "https://$domain.sharepoint.com/sites/$sitePath/$title"

        foreach ($site in $sites) {

            write-Verbose ("Connect to site: $site and retrieve OrgAssetLibrary")

            Connect-PnPOnline -Thumbprint $CertificateThumbprint -Tenant $TenantId -ClientId $ApplicationId -Url $site

            $OrgAssetLibrariesPath=(Get-PnPOrgAssetsLibrary).OrgAssetsLibraries.LibraryUrl.DecodedUrl
            foreach( $OrgAssetLibraryPath in $OrgAssetLibrariesPath  ){
                    if ( $OrgAssetLibraryPath -eq $libraryPath)
                        {
                            $currentOrgAssetLibraryPath = $OrgAssetLibraryPath
                            write-host ("")
                        }
            }
        }
        $ErrorActionPreference = 'Continue'
        If ($currentOrgAssetLibraryPath -eq $null -or $currentOrgAssetLibraryPath -eq "" -or $currentOrgAssetLibraryPath -ne $libraryPath   ) {

            Write-Host ("No active OrgAssetLibrary found for $libraryUrl")
            Write-Host ("Found OrgAssetLibraries : $OrgAssetLibrariesPath")
            write-host("$testSitePath")

            if ( ($OrgAssetLibrariesPath -match $testSitePath ) -ne $null -or $OrgAssetLibrariesPath -eq $null -or $OrgAssetLibrariesPath -eq "" ) {

                Write-Verbose ("Adding Everyone except external user group to $sitePath Visitor")
                spoAddEveryoneExceptExternalToSiteVisitors -domain $domain -sitePaths @($sitePath) -ApplicationId $ApplicationId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint

                Write-Verbose ("Creating document library $title at $sitePath")
                spoCreateDocumentLibrary -domain $domain -title $title -sitePath $sitePath -ApplicationId $ApplicationId -TenantId $TenantId -CertificateThumbprint $CertificateThumbprint

                Write-Host ("You can now deploy the orgAssetLibrary LZ with libraryUrl: $libraryUrl")
            
            }
            else{
                write-host("")
                Write-host ("Document library not in the same site as Org Asset Library")
                Write-Host("You can specify up to 30 organization asset libraries for a single organization. All of these libraries (regardless of type) must be on the same site.")
           }
    
        }
        else {
            Write-Host ("OrgAssetLibrary already exists at https://$domain.sharepoint.com/$currentOrgAssetLibraryPath")
        }
        Add-PnPOrgAssetsLibrary @currentParameters
    }
    elseif ($Ensure -eq 'Absent' -and $currentOrgSiteAsset.Ensure -eq 'Present')
    {
        Remove-PnPOrgAssetsLibrary -LibraryUrl $currentOrgSiteAsset.LibraryUrl
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (

        [Parameter(Mandatory = $true)]
        [System.String]
        $LibraryUrl,

        [Parameter()]
        [System.String]
        $ThumbnailUrl,

        [Parameter()]
        [ValidateSet('Public', 'Private')]
        [System.String]
        $CdnType = 'Public',

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure = 'Present',

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )
    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace("MSFT_", "")
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $ResourceName)
    $data.Add("Method", $MyInvocation.MyCommand)
    $data.Add("Principal", $GlobalAdminAccount.UserName)
    $data.Add("TenantId", $TenantId)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    Write-Verbose -Message "Testing configuration of SharePoint Org Site Assets"

    $CurrentValues = Get-TargetResource @PSBoundParameters
    Write-Verbose -Message "Starting the test to compare"
    Write-Verbose -Message "Target Values: `n $(Convert-M365DscHashtableToString -Hashtable $PSBoundParameters)"

    $ValuesToCheck = $PSBoundParameters
    $ValuesToCheck.Remove('GlobalAdminAccount') | Out-Null
    $ValuesToCheck.Remove("ApplicationId") | Out-Null
    $ValuesToCheck.Remove("TenantId") | Out-Null
    $ValuesToCheck.Remove("CertificatePath") | Out-Null
    $ValuesToCheck.Remove("CertificatePassword") | Out-Null
    $ValuesToCheck.Remove("CertificateThumbprint") | Out-Null

    $TestResult = Test-M365DSCParameterState -CurrentValues $CurrentValues `
        -Source $($MyInvocation.MyCommand.Source) `
        -DesiredValues $PSBoundParameters `
        -ValuesToCheck $ValuesToCheck.Keys

    Write-Verbose -Message "Test-TargetResource returned $TestResult"

    return $TestResult
}

function Export-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.Management.Automation.PSCredential]
        $GlobalAdminAccount,

        [Parameter()]
        [System.String]
        $ApplicationId,

        [Parameter()]
        [System.String]
        $TenantId,

        [Parameter()]
        [System.String]
        $CertificatePath,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        $CertificatePassword,

        [Parameter()]
        [System.String]
        $CertificateThumbprint
    )
    $ConnectionMode = New-M365DSCConnection -Platform 'PnP' `
        -InboundParameters $PSBoundParameters

    #region Telemetry
    $ResourceName = $MyInvocation.MyCommand.ModuleName.Replace("MSFT_", "")
    $data = [System.Collections.Generic.Dictionary[[String], [String]]]::new()
    $data.Add("Resource", $ResourceName)
    $data.Add("Method", $MyInvocation.MyCommand)
    $data.Add("Principal", $GlobalAdminAccount.UserName)
    $data.Add("TenantId", $TenantId)
    $data.Add("ConnectionMode", $ConnectionMode)
    Add-M365DSCTelemetryEvent -Data $data
    #endregion

    try
    {
        [array]$orgAssets = Get-PnPOrgAssetsLibrary -ErrorAction Stop
        $i = 1
        $dscContent = ''

        Write-Host "`r`n" -NoNewline
        if ($null -ne $orgAssets)
        {
            foreach ($orgAssetLib in $orgAssets.OrgAssetsLibraries)
            {
                Write-Host "    [$i/$($orgAssets.Length)] $LibraryUrl" -NoNewline
                $Params = @{
                    GlobalAdminAccount    = $GlobalAdminAccount
                    LibraryUrl            = "https://$tenantName.sharepoint.com/$($orgAssetLib.libraryurl.DecodedUrl)"

                    ApplicationId         = $ApplicationId
                    TenantId              = $TenantId
                    CertificatePassword   = $CertificatePassword
                    CertificatePath       = $CertificatePath
                    CertificateThumbprint = $CertificateThumbprint
                }
                $Results = Get-TargetResource @Params
                $Results = Update-M365DSCExportAuthenticationResults -ConnectionMode $ConnectionMode `
                    -Results $Results
                $currentDSCBlock = Get-M365DSCExportContentForResource -ResourceName $ResourceName `
                    -ConnectionMode $ConnectionMode `
                    -ModulePath $PSScriptRoot `
                    -Results $Results `
                    -GlobalAdminAccount $GlobalAdminAccount
                $dscContent += $currentDSCBlock
                Save-M365DSCPartialExport -Content $currentDSCBlock `
                    -FileName $Global:PartialExportFileName
                Write-Host $Global:M365DSCEmojiGreenCheckMark
                $i++
            }
        }
        return $dscContent
    }
    catch
    {
        try
        {
            Write-Verbose -Message $_
            $tenantIdValue = ""
            if (-not [System.String]::IsNullOrEmpty($TenantId))
            {
                $tenantIdValue = $TenantId
            }
            elseif ($null -ne $GlobalAdminAccount)
            {
                $tenantIdValue = $GlobalAdminAccount.UserName.Split('@')[1]
            }
            Add-M365DSCEvent -Message $_ -EntryType 'Error' `
                -EventID 1 -Source $($MyInvocation.MyCommand.Source) `
                -TenantId $tenantIdValue
        }
        catch
        {
            Write-Verbose -Message $_
        }
        return ""
    }
}

Export-ModuleMember -Function *-TargetResource
