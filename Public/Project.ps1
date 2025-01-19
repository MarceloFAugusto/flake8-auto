<#
.SYNOPSIS
    Encontra o arquivo de configuração do Flake8 mais próximo.
#>
function Find-Flake8Config {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$startPath
    )
    
    $currentPath = $startPath
    while ($currentPath) {
        $flake8Path = Join-Path $currentPath ".flake8"
        if (Test-Path $flake8Path) {
            return $currentPath
        }
        $currentPath = Split-Path $currentPath -Parent
        if ([string]::IsNullOrEmpty($currentPath)) {
            break
        }
    }
    return $null
}

function Select-ProjectDirectory {
    $initialPath = (Get-Location).Path
    $configPath = Find-Flake8Config $initialPath

    if ($configPath) {
        Write-Host "`nEncontrado arquivo .flake8 em: $configPath" -ForegroundColor Green
        Write-Host "1. Usar este diretório"
        Write-Host "2. Selecionar outro diretório"
        $choice = Read-Host "Escolha uma opção"

        if ($choice -eq "1") {
            return $configPath
        }
    } else {
        Write-Host "`nNão foi encontrado arquivo .flake8 no diretório atual ou superiores." -ForegroundColor Yellow
    }

    Write-Host "`nPor favor, selecione o diretório do projeto que contém o arquivo .flake8:"
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Selecione o diretório do projeto"
    $folderBrowser.SelectedPath = $initialPath

    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = $folderBrowser.SelectedPath
        if (Test-Path (Join-Path $selectedPath ".flake8")) {
            return $selectedPath
        } else {
            Write-Host "Arquivo .flake8 não encontrado no diretório selecionado!" -ForegroundColor Red
            return $null
        }
    }
    return $null
}

function Test-CustomSettings {
    if (-not (Assert-ProjectPath)) { return }
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-Flake8Installation)) { return }
    $pythonPath = Get-VenvPython
    
    Write-Host "Digite o comprimento máximo da linha (Enter para padrão $($script:defaultConfig.MaxLineLength)):" -ForegroundColor Yellow
    $maxLength = Read-Host
    if (!$maxLength) { $maxLength = $script:defaultConfig.MaxLineLength }

    Write-Host "Digite a complexidade máxima (Enter para padrão $($script:defaultConfig.MaxComplexity)):" -ForegroundColor Yellow
    $maxComplexity = Read-Host
    if (!$maxComplexity) { $maxComplexity = $script:defaultConfig.MaxComplexity }

    Get-LogConfiguration
    
    Push-Location $script:projectPath
    & $pythonPath -m flake8 . --max-line-length=$maxLength --max-complexity=$maxComplexity @script:logParameters
    Pop-Location
    Confirm-BlackFormat
}