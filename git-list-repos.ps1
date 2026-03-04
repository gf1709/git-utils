Import-Module -Verbose -Name (Resolve-Path  ".\utils.psm1")
function Read-Git-Repositories {
    echo_ok "Starting to list repositories for organization $($orgName)..."
    $headers = @{
        "Authorization" = [String]::Format("Bearer {0}", $gitAccessToken)
        "Content-Type"  = "application/json"
    }
    # $orgName = "corebanking"
    # $reposAPIUri = "https://github.servizi.allitude.it/api/v3/orgs/$($orgName)/repos"
    $pageNbr = 1
    $idx = 1
    $repos = @() # array vuoto per memorizzare i repository
    while ($true) {
        $reposAPIUri = "https://github.servizi.allitude.it/api/v3/orgs/$($orgName)/repos?sort=full_name&per_page=100&page=$($pageNbr)"
        $githubRepositories = Invoke-RestMethod -Method get -Uri $reposAPIUri -Headers $headers 
        $pageNbr += 1
        foreach ($respository in $githubRepositories) {
            $idx += 1
            $repos += $respository
            # echo_ok($idx.ToString() + "-" +$respository.name)
        }
        if ($githubRepositories.Count -eq 0) {
            break
        }        
    } 
    return $repos
    # # # $reposAPIUri = "https://github.servizi.allitude.it/api/v3/orgs/corebanking/repos?page=2"
    # # # $githubRepositories = Invoke-RestMethod -Method get -Uri $reposAPIUri -Headers $headers 
    # # # # $githubRepositories | Out-File -FilePath "reposAPIUri.html" -Append -Encoding utf8
    # # # # Write-Host "Output is $($githubRepositories)"
    # # # $githubRepositories | Out-File -FilePath "reposAPIUri.html" -Append -Encoding utf8
    # # # Write-Host "Output is $($githubRepositories)"
}

function Clone-Git-Repositories {
    param(
        [pscustomobject]$repoList 
    )
    echo_ok "Creating temporary directory for cloning repositories: $($rootCloneTempDirectory)..."
    # TODO GREG da ripristinare - I
    # if (!(Test-Path -Path $rootCloneTempDirectory)) {
    #     New-Item -ItemType Directory -Path $rootCloneTempDirectory
    # }
    # else {
    #     echo_error "Directory $($rootCloneTempDirectory) already exists. Deleting it..."
    #     return     
    # }
    # TODO GREG da ripristinare - F
    # $repoList = Read-Git-Repositories
    echo_ok "Total repositories passed as params: $($repoList.Count)"
    $idx = 0
    foreach ($repo in $repoList) {
        if ($repo.name.StartsWith('.')) {
            echo_ok($repo.name, "Skipping repository $($repo.name) because it starts with a dot.")
            continue
        }        
        else {
            $idx += 1
            echo_ok("[$idx/$($repoList.Count)] Cloning repository $($repo.name) from $($repo.clone_url) to $($rootCloneTempDirectory)\$($repo.name)")
            git clone $repo.clone_url "$($rootCloneTempDirectory)\$($repo.name)"
        }
    }   
}
function Filter-Git-Repositories {
    param(
        [pscustomobject]$repoList 
    )
    echo_ok("Filtering repos...")
    $filteredRepos = @() # array vuoto per memorizzare i match trovati
    foreach ($repo in $repoList) {
        if ($repo.name.StartsWith('.')) {
            echo_ok($repo.name, "Skipping repository $($repo.name) because it starts with a dot.")
            continue
        }        
        else {
            if ($repo.name -like "wealth-management*") {
                echo_ok("Repository $($repo.name) matches the filter criteria.")
                $filteredRepos += $repo
            }
        }
    }
    return $filteredRepos
}

function Grep-Git-Repositories {
    param(
        [pscustomobject]$repoList ,
        [string]$searchString
    )
    $matchesFound = New-Object System.Collections.Generic.List[System.String] # array vuoto per memorizzare i match trovati
    $matchesFound.Clear()
    foreach ($repo in $repoList) {
        if ($repo.name.StartsWith('.')) {
            echo_ok($repo.name, "Skipping repository $($repo.name) because it starts with a dot.")
            continue
        }        
        else {
            echo_ok("")            
            echo_ok("Searching for string '$searchString' in repository $($repo.name)...")            
            Set-Location "$($rootCloneTempDirectory)\$($repo.name)"
            $curDir = Get-Location
            $branches = git branch -r | Select-String -Pattern "->" -NotMatch | Select-String -pattern "^  origin/" | ForEach-Object { $_ -replace '^  origin/', '' }
            $branchIdx = 0
            foreach ($branch in $branches) {
                echo_ok("")            
                echo_ok("Searching for string '$searchString' in repository $($repo.name) and branch $branch...")            
                echo_ok("[$($branchIdx)/$($branches.Count)] checkout of branch $branch...")
                $res = git checkout $branch 
                echo_ok("[$($branchIdx)/$($branches.Count)] pull of branch $branch...")
                $res = git pull           
                Get-ChildItem -Path $curDir -Recurse | Select-String -Pattern $searchString -CaseSensitive | ForEach-Object {
                    $matchInfo = $_
                    # $filePath = $matchInfo.Path
                    $filePath = [System.IO.Path]::GetFileName($matchInfo.Path)
                    $lineNumber = $matchInfo.LineNumber
                    $lineText = $matchInfo.Line
                    $matchesFound.Add("$($repo.name):$($branch) $($filePath):$($lineNumber):$($lineText)")
                }
                echo_ok("Searching for string '$searchString' in repository $($repo.name) and branch $branch done.")            
                $branchIdx += 1
            }
        }
    }
    Set-Location "$($rootCloneTempDirectory)"
    return $matchesFound
}



# Main program
$curDir = Get-Location
$repoList = Read-Git-Repositories
echo_ok "Total repositories found: $($repoList.Count)"
$repoList = Filter-Git-Repositories -repoList $repoList
echo_ok "Total repositories filtered: $($repoList.Count)"

Clone-Git-Repositories -repoList $repoList
$matchesFound = Grep-Git-Repositories -repoList $repoList -searchString "TKK18R"
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

# checkout di tutti i branch remoti
# git branch -r | Select-String -Pattern "->" -NotMatch | Select-String -pattern "^  origin/" | foreach { $_ -replace '^  origin/', '' } | Foreach { git checkout $_ }

# serch in all branches for a string
# git rev-list --all | git grep --ignore-case -I "string"