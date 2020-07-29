param (
    [Parameter(Mandatory = $true)][string]$CompilerLogFile,
    [switch]$ErrorOnMissingLog
)

function FixBrokenJson {
    param (
        [Parameter(Mandatory = $true)][string]$CompilerLogFile
    )
    $AW0011 = 'Add PromotedOnly="true" to some or all promoted actions to avoid identical actions from appearing in both the promoted and default sections of the command bar.'
    $AW0011_Fix = 'Add PromotedOnly=\"true\" to some or all promoted actions to avoid identical actions from appearing in both the promoted and default sections of the command bar.'

    $FileContent = Get-Content -Raw -Path $CompilerLogFile
    $FixedContent = $FileContent -replace $AW0011, $AW0011_Fix

    $FixedContent | Set-Content -Path $CompilerLogFile -Force
}

if (! (Test-Path -Path $CompilerLogFile)) {
    if ($ErrorOnMissingLog) {
        Write-Host ("##vso[task.logissue type=error]Cannot find compiler log. {0}" -f $CompilerLogFile)
        exit 1;
    }
    else {
        Write-Host ("##vso[task.logissue type=warning]Cannot find compiler log. {0}" -f $CompilerLogFile)
        exit 0;
    }
}

FixBrokenJson($CompilerLogFile)

$jsondata = Get-Content -Path $CompilerLogFile | ConvertFrom-Json

foreach ($issue in $jsondata.issues) {
    $issuePorperties = $issue.properties
    $shortMessage = $issue.shortMessage
    if (! $shortMessage) {
        $shortMessage = $issue.fullMessage
    }
    $ruleId = $issue.ruleId
    $severity = $issuePorperties.severity
    if ($issue.locations.Count -lt 0) {
        $analysisTarget = $issue.locations[0].analysisTarget[0]
        $analysisTargetUri = $analysisTarget.uri
        $analysisTargetRegion = $analysisTarget.region
        $startLine = $analysisTargetRegion.startLine
        $startColumn = $analysisTargetRegion.startColumn
    }
    if ($severity -eq "Error") {
        $logtype = "error"
    }
    Write-Host ("##vso[task.logissue type={0};sourcepath={1};linenumber={2};columnnumber{3};code={4}]{5}" -f $logtype, $analysisTargetUri, $startLine, $startColumn, $ruleId, $shortMessage)
}