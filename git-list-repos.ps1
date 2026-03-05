# .\git-list-repos.ps1 -RepoNameFilter 'wealth-management*' -FilePathFilter '*.java' -SearchString 'TKK19R' -BranchNameFilter 'dev'

param (    
    [Parameter(Mandatory=$true, HelpMessage = "The search string to use (e.g. 'TKK19R')")]
    [string]$SearchString,
    [Parameter(HelpMessage = "The repository name filter to use (e.g. 'wealth-management*')")]
    [string]$RepoNameFilter="*",    
    [Parameter(HelpMessage = "The branch name filter to use (e.g. 'dev, master, *')")]
    [string]$BranchNameFilter="*",
    [Parameter(HelpMessage = "The file path filter to use (e.g. '*.java')")]
    [string]$FilePathFilter="*.*"
 )

Import-Module -Name (Resolve-Path  ".\config.psm1")
Import-Module -Name (Resolve-Path  ".\utils.psm1")
Write-Host " "
Write-Host "Starting git repository processing..." -ForegroundColor Green
Write-Host "Search string: " -NoNewline -ForegroundColor Green
Write-Host $SearchString -BackgroundColor Yellow -ForegroundColor DarkBlue 
Write-Host "Repository name filter: " -NoNewline -ForegroundColor Green 
Write-Host $RepoNameFilter -BackgroundColor Yellow -ForegroundColor DarkBlue
Write-Host "Branch name filter: " -NoNewline -ForegroundColor Green
Write-Host $BranchNameFilter -BackgroundColor Yellow -ForegroundColor DarkBlue
Write-Host "File path filter: " -NoNewline -ForegroundColor Green
Write-Host $FilePathFilter -BackgroundColor Yellow -ForegroundColor DarkBlue
#######################################################
# Main program
#######################################################

$curDir = Get-Location

# Lettura dei repository da github tramite API
$repoList = Read-Git-Repositories
echo_ok "Total repositories found: $($repoList.Count)"

# Filtraggio dei repository in base al nome
$repoList = Filter-Git-Repositories -repoList $repoList -repoNameFilter $RepoNameFilter
echo_ok "Total repositories filtered: $($repoList.Count)"

# Clonazione dei repository filtrati
Clone-Git-Repositories -repoList $repoList

# GREP sui repository clonati
$matchesFound = Grep-Git-Repositories -repoList $repoList -searchString $SearchString -filePathFilter $FilePathFilter -branchNameFilter $BranchNameFilter
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
