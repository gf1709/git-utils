# .\git-save-repo-content -RepoNameFilter 'wealth-management*'-BranchNameFilter 'dev'

param (    
    [Parameter(HelpMessage = "The repository name filter to use (e.g. 'wealth-management*')")]
    [string]$RepoNameFilter="wealth-management*",    
    [Parameter(HelpMessage = "The branch name filter to use (e.g. 'dev, master, *')")]
    [string]$BranchNameFilter="dev"
 )

Import-Module -Name (Resolve-Path  ".\config.psm1")
Import-Module -Name (Resolve-Path  ".\utils.psm1")
Write-Host " "
Write-Host "Starting git repository processing..." -ForegroundColor Green
Write-Host "Repository name filter: " -NoNewline -ForegroundColor Green 
Write-Host $RepoNameFilter -BackgroundColor Yellow -ForegroundColor DarkBlue
Write-Host "Branch name filter: " -NoNewline -ForegroundColor Green
Write-Host $BranchNameFilter -BackgroundColor Yellow -ForegroundColor DarkBlue

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

# Salvo il contenuto dei repository 
Save-Git-Repositories-By-Branch -repoList $repoList -branchNameFilter $BranchNameFilter

Set-Location $curDir
