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
            if ($idx -gt $maxRepos) {
                break
            }
        }
    }   

}


# Main program
$repoList = Read-Git-Repositories
echo_ok "Total repositories found: $($repoList.Count)"
Clone-Git-Repositories -repoList $repoList

# foreach ($repo in $repoList) {
#     echo_ok($repo.name)
# }   