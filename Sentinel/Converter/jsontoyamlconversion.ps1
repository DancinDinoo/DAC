Get-ChildItem -Filter '*.json' | ForEach-Object { # Find all json files
    Write-Host "Processing: $($_.Name)"
    
    $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
    $id = $json.resources[0].properties.alertRuleTemplateName # Get the unique id

    $match = Get-ChildItem -Filter '*.yaml' | Where-Object { # Find any yaml files matching that id
        try {
            $yaml = Get-Content $_.FullName -Raw | ConvertFrom-Yaml
            Write-Host "Checking $($_.Name): Looking for ID $id"
            $yaml.id -eq $id
        } catch {
            $false
        }
    }
    $matchedFile = $match | Select-Object -First 1 # Should only ever be 1 id match per json<->yaml combo
    $newYamlPath = $_.FullName -replace '\.json$', '.yaml' # Generate new yaml file path

    if ($matchedFile) {
        Write-Host "Match found: Renaming $($matchedFile.Name) to $newYamlPath"             # If the name has changed, rename the YAML file
        
        if ($matchedFile.FullName -ne $newYamlPath) { # Remove new file to avoid conflict
            if (Test-Path $newYamlPath) {
                Remove-Item $newYamlPath -Force
            }

            Rename-Item -Path $matchedFile.FullName -NewName (Split-Path $newYamlPath -Leaf)
        }
        Convert-SentinelARArmToYaml -Filename $_.FullName -OutFile $newYamlPath -Force         # Overwrite the renamed file
    } else {
        Write-Host "No match found: Creating new YAML at $newYamlPath"
        Convert-SentinelARArmToYaml -Filename $_.FullName -OutFile $newYamlPath -Force          # Create new file
    }
}
