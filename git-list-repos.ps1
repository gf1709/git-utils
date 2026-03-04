# .\git-list-repos.ps1 -paramRepoNameFilter 'wealth-management*' -paramFilePathFilter '*.java' -paramSearchString 'TKK19R'
param (    
    [Parameter(Mandatory=$true, HelpMessage = "The repository name filter to use (e.g. 'wealth-management*')", Position = 0)]
    [string]$paramRepoNameFilter,    
    [Parameter(Mandatory=$true, HelpMessage = "The file path filter to use (e.g. '*.java')", Position = 1)]
    [string]$paramFilePathFilter,
    [Parameter(Mandatory=$true, HelpMessage = "The search string to use (e.g. 'TKK19R')", Position = 2)]
    [string]$paramSearchString
 )

Import-Module -Verbose -Name (Resolve-Path  ".\config.psm1")
Import-Module -Verbose -Name (Resolve-Path  ".\utils.psm1")

#######################################################
# Main program
#######################################################

$curDir = Get-Location

# Lettura dei repository da github tramite API
$repoList = Read-Git-Repositories
echo_ok "Total repositories found: $($repoList.Count)"

# Filtraggio dei repository in base al nome
$repoList = Filter-Git-Repositories -repoList $repoList -repoNameFilter $paramRepoNameFilter
echo_ok "Total repositories filtered: $($repoList.Count)"

# Clonazione dei repository filtrati
Clone-Git-Repositories -repoList $repoList

# GREP sui repository clonati
$matchesFound = Grep-Git-Repositories -repoList $repoList -searchString $paramSearchString -filePathFilter $paramFilePathFilter
if ($matchesFound.Count -eq 0) {
    echo_ok "No matches found for the search string."
}
else {
    echo_ok " "
    echo_ok "=================================================================="
    echo_ok "Total matches found: $($matchesFound.Count)"
    echo_ok "=================================================================="
    foreach ($match in $matchesFound) {
        echo_ok($match)
    }   
}

Set-Location $curDir
