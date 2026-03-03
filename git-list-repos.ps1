Import-Module -Verbose -Name (Resolve-Path  ".\utils.psm1")
# Import-Module -Verbose -Name (Resolve-Path  "./modules/utils.psm1")

$headers = @{
    "Authorization" = [String]::Format("Bearer {0}", $script:gitAccessToken)
    "Content-Type"  = "application/json"
}


# $orgName = "corebanking"
# $reposAPIUri = "https://github.servizi.allitude.it/api/v3/orgs/$($orgName)/repos"
$pageNbr = 1
$idx = 1
while ($true) {
    $reposAPIUri = "https://github.servizi.allitude.it/api/v3/orgs/$($orgName)/repos?sort=full_name&per_page=100&page=$($pageNbr)"
    $githubRepositories = Invoke-RestMethod -Method get -Uri $reposAPIUri -Headers $headers 
    $pageNbr += 1
    foreach ($respository in $githubRepositories) {
        $idx += 1
        # echo_ok($idx.ToString() + "-" +$respository.name)
    }
    if ($githubRepositories.Count -eq 0) {
        break
    }
} 

# # # $reposAPIUri = "https://github.servizi.allitude.it/api/v3/orgs/corebanking/repos?page=2"
# # # $githubRepositories = Invoke-RestMethod -Method get -Uri $reposAPIUri -Headers $headers 
# # # # $githubRepositories | Out-File -FilePath "reposAPIUri.html" -Append -Encoding utf8
# # # # Write-Host "Output is $($githubRepositories)"
# # # $githubRepositories | Out-File -FilePath "reposAPIUri.html" -Append -Encoding utf8
# # # Write-Host "Output is $($githubRepositories)"


