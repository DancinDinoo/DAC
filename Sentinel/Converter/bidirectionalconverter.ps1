param (
    [string[]]$FilePath
)

function Get-IdFromJsonFile($path) {
    try {
        $json = Get-Content $path -Raw | ConvertFrom-Json
        return $json.resources[0].properties.alertRuleTemplateName
    } catch {
        throw "Failed to read ID from JSON file: $path"
    }
}

function Get-IdFromYamlFile($path) {
    try {
        $yaml = Get-Content $path -Raw | ConvertFrom-Yaml
        return $yaml.id
    } catch {
        throw "Failed to read ID from YAML file: $path"
    }
}

foreach ($path in $FilePath) {
    $extension = [System.IO.Path]::GetExtension($path).ToLower()

    if ($extension -eq '.json') {
        Write-Host "Processing JSON file: $path"
        $id = Get-IdFromJsonFile $path

        # Find matching YAML by ID
        $match = Get-ChildItem -Recurse -Filter '*.yaml' | Where-Object {
            try {
                $yaml = Get-Content $_.FullName -Raw | ConvertFrom-Yaml
                $yaml.id -eq $id
            } catch { $false }
        }

        $matchedFile = $match | Select-Object -First 1
        $newYamlPath = $path -replace '\.json$', '.yaml'

        if ($matchedFile) {
            if ($matchedFile.FullName -ne $newYamlPath) {
                if (Test-Path $newYamlPath) {
                    Remove-Item $newYamlPath -Force
                }
                Rename-Item -Path $matchedFile.FullName -NewName (Split-Path $newYamlPath -Leaf)
            }
            Convert-SentinelARArmToYaml -Filename $path -OutFile $newYamlPath -Force
        } else {
            Convert-SentinelARArmToYaml -Filename $path -OutFile $newYamlPath -Force
        }
    }

    elseif ($extension -eq '.yaml') {
        Write-Host "Processing YAML file: $path"
        $id = Get-IdFromYamlFile $path

        # Find matching JSON by ID
        $match = Get-ChildItem -Recurse -Filter '*.json' | Where-Object {
            try {
                $json = Get-Content $_.FullName -Raw | ConvertFrom-Json
                $json.resources[0].properties.alertRuleTemplateName -eq $id
            } catch { $false }
        }

        $matchedFile = $match | Select-Object -First 1
        $newJsonPath = $path -replace '\.yaml$', '.json'

        if ($matchedFile) {
            if ($matchedFile.FullName -ne $newJsonPath) {
                if (Test-Path $newJsonPath) {
                    Remove-Item $newJsonPath -Force
                }
                Rename-Item -Path $matchedFile.FullName -NewName (Split-Path $newJsonPath -Leaf)
            }
            Convert-SentinelARYamlToArm -Filename $path -OutFile $newYamlPath -Force
        } else {
            Convert-SentinelARArmToYaml -Filename $path -OutFile $newYamlPath -Force
        }
    }
    else {
        Write-Warning "Unsupported file type: $path"
    }
}
