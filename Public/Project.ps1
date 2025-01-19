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