
function echo_error {
    Write-Host $args[0] -ForegroundColor Red
}
function echo_ok {
    Write-Host $args[0] -ForegroundColor Green
}
function echo_ok_yellow {
    Write-Host $args[0] -ForegroundColor Yellow -BackgroundColor Black
}

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
        [Parameter(Mandatory = $true)][pscustomobject]$repoList 
    )
    echo_ok "Creating temporary directory for cloning repositories: $($rootCloneTempDirectory)..."
    # Cancellazione della directory di destinazione se esiste, altrimenti creazione della directory di destinazione
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
        [Parameter(Mandatory = $true)][pscustomobject]$repoList,
        [Parameter(Mandatory = $true)][string]$repoNameFilter 
    )
    echo_ok("Filtering repos...")
    $filteredRepos = @() # array vuoto per memorizzare i match trovati
    foreach ($repo in $repoList) {
        if ($repo.name.StartsWith('.')) {
            echo_ok($repo.name, "Skipping repository $($repo.name) because it starts with a dot.")
            continue
        }        
        else {
            if ($repo.name -like $repoNameFilter) {
                echo_ok("Repository $($repo.name) matches the filter criteria.")
                $filteredRepos += $repo
            }
        }
    }
    return $filteredRepos
}

function Grep-Git-Repositories {
    param(
        [Parameter(Mandatory = $true)] [pscustomobject]$repoList ,
        [Parameter(Mandatory = $true)] [string]$searchString,
        [Parameter(Mandatory = $true)] [string]$filePathFilter,
        [Parameter(Mandatory = $true)] [string]$branchNameFilter

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
            echo_ok_yellow("Searching for string '$searchString' in repository $($repo.name)...")            
            Set-Location "$($rootCloneTempDirectory)\$($repo.name)"
            $curDir = Get-Location
            $branches = git branch -r | Select-String -Pattern "->" -NotMatch | Select-String -pattern "^  origin/" | ForEach-Object { $_ -replace '^  origin/', '' }
            $branchIdx = 0
            foreach ($branch in $branches) {
                if ($branch -like $branchNameFilter -or $branchNameFilter -eq "*") {
                    echo_ok("")            
                    echo_ok("Searching for string '$searchString' in repository $($repo.name) and branch $branch...")            
                    echo_ok("[$($branchIdx)/$($branches.Count)] checkout of branch $branch...")
                    $res = git checkout $branch 
                    echo_ok("[$($branchIdx)/$($branches.Count)] pull of branch $branch...")
                    $res = git pull           
                    $seachFiles = [System.IO.Path]::Combine($curDir, $filePathFilter)
                    Get-ChildItem -Path $seachFiles -Recurse | Select-String -Pattern $searchString -CaseSensitive | ForEach-Object {
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
    }
    Set-Location "$($rootCloneTempDirectory)"
    return $matchesFound
}

$TextFileExtensions = @(".bat", ".bpmn", ".cfg", ".cmd", ".conf", ".config", ".cs", ".css", ".csv", ".doc", ".fls", ".gitattributes", ".gitignore", ".gitkeep", ".gitmodules", ".h", ".html", ".java", ".js", ".json", ".log", ".lst", ".pom", ".pubxml", ".py", ".pyc", ".pyi", ".qxt", ".scss", ".toml", ".tpl", ".ts", ".tt", ".txt", ".typed", ".wsdl", ".wsuo", ".xml", ".xsd", ".xsl", ".yaml", ".yml")
function Is-Text-File {
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$file
    )
    if ($file.Extension -in $TextFileExtensions) {
        return $true
    }
    return $false    
}
if ($?) {
    echo_ok "git.exe is available in the system PATH."
}
else {
    echo_error "git.exe is not available in the system PATH. Please install Git and ensure it is added to the PATH environment variable."
    exit 1
}

function Save-Git-Repositories-By-Branch {
    param(
        [Parameter(Mandatory = $true)] [pscustomobject]$repoList ,
        [Parameter(Mandatory = $true)] [string]$branchNameFilter
    )
    
    foreach ($repo in $repoList) {
        if ($repo.name.StartsWith('.')) {
            echo_ok($repo.name, "Skipping repository $($repo.name) because it starts with a dot.")
            continue
        }        
        else {
            echo_ok("")            
            echo_ok_yellow("Searching for string '$searchString' in repository $($repo.name)...")            
            Set-Location "$($rootCloneTempDirectory)\$($repo.name)"
            $curDir = Get-Location
            $branches = git branch -r | Select-String -Pattern "->" -NotMatch | Select-String -pattern "^  origin/" | ForEach-Object { $_ -replace '^  origin/', '' }
            $branchIdx = 0
            foreach ($branch in $branches) {
                if ($branch -like $branchNameFilter -or $branchNameFilter -eq "*") {
                    echo_ok("")            
                    echo_ok("[$($branchIdx)/$($branches.Count)] checkout of branch $branch...")
                    $res = git checkout $branch 
                    echo_ok("[$($branchIdx)/$($branches.Count)] pull of branch $branch...")
                    $res = git pull           
                    # Read all file contents for the branch and save them in a file named $repo.name_$branch.txt
                    $outputFilePath = [System.IO.Path]::Combine($rootCloneTempDirectory, "content_repo_@_$($repo.name)_branch_@_$($branch)")
                    $outputFilePath = $outputFilePath -replace '\.', '_' -replace '/', '_'                                        
                    $outputFilePath = $outputFilePath + ".txt"

                    Write-Host "Output file path is $outputFilePath"
                    $filePath = $outputFilePath                    
                    if (Test-Path -Path $filePath) {
                        Write-Host "File $filePath already exists. Deleting it..."
                        Remove-Item -Path $outputFilePath -Force
                    }
                    echo_ok("Saving content of repository $($repo.name) and branch $branch in file $outputFilePath...")
                    foreach ($file in Get-ChildItem -Path $curDir -Recurse -File) {                                                
                        if (Is-Text-File -file $file) {
                            try {                                
                                $fileContent = Get-Content -Path $file.FullName 
                                Add-Content -Path $outputFilePath -Value "File: $($file.FullName)"
                                Add-Content -Path $outputFilePath -Value "Content:"
                                Add-Content -Path $outputFilePath -Value $fileContent
                                Add-Content -Path $outputFilePath -Value "====================================="
                            }
                            catch {
                                echo_error "Error reading file $($file.FullName): $_"                                   
                            }
                        }
                    }
                    $branchIdx += 1
                }
            }
        }
    }
    Set-Location "$($rootCloneTempDirectory)"
}
Export-ModuleMember -Function echo_error, echo_ok, echo_ok_yellow, Read-Git-Repositories, Clone-Git-Repositories, Filter-Git-Repositories, Grep-Git-Repositories, Save-Git-Repositories-By-Branch