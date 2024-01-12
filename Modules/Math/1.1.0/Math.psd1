@{
    # PrivateData is where all third-party metadata goes
    PrivateData        = @{
        # PrivateData.PSData is the PowerShell Gallery data
        PSData = @{
            # Prerelease string should be here, so we can set it
            Prerelease   = ''

            # Release Notes have to be here, so we can update them
            ReleaseNotes = '
            First release to the PowerShell gallery ...
            '

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags         = 'Math', 'Calc'

            # A URL to the license for this module.
            LicenseUri   = 'https://github.com/loresoft/Calculator/blob/master/LICENSE'

        } # End of PSData
    } # End of PrivateData

    # Script module or binary module file associated with this manifest.
    RootModule         = 'Math.psm1'

    # Version number of this module.
    ModuleVersion      = '1.1.0'

    # ID used to uniquely identify this module
    GUID               = '399d730f-ab69-4264-a48e-0c5f156b6a1f'

    # Author of this module
    Author             = 'Joel Bennett'

    # Company or vendor of this module
    CompanyName        = 'http://HuddledMasses.org'

    # Copyright statement for this module
    Copyright          = '(c) 2014-2019 Joel Bennett. All rights reserved.'

    # Description of the functionality provided by this module
    Description        = 'Provides a calculator command (Invoke-MathEvaluator)'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion  = '4.0'

    # Minimum version of the common language runtime (CLR) required by this module
    CLRVersion         = '4.0'

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = 'LoreSoft.MathExpressions.dll'

    # Functions to export from this module
    FunctionsToExport  = 'Invoke-MathEvaluator','Set-MathVariable'

    # Aliases to export from this module
    AliasesToExport    = 'math','calc','c','ime','smv'

}

