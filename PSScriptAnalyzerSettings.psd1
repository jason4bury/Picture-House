# PSScriptAnalyzer settings for Picture-House.ps1.
# Run: Invoke-ScriptAnalyzer -Path .\src\Picture-House.ps1 -Settings .\PSScriptAnalyzerSettings.psd1
@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # The functions are private GUI helpers inside one script, not exported cmdlets,
        # so -WhatIf/-Confirm support, singular nouns and approved verbs add nothing here.
        'PSUseShouldProcessForStateChangingFunctions',
        'PSUseSingularNouns',
        'PSUseApprovedVerbs',
        # Background workers share helpers through script scope on purpose.
        'PSAvoidGlobalVars'
    )
}
