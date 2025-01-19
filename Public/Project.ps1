$script:projectPath = $null

function Show-MenuOptions {
    Write-Host "=== Flake8 Menu de Verificação ===" -ForegroundColor Cyan
    Write-Host "1. Verificar arquivo específico"
    Write-Host "2. Verificar todo projeto"
    Write-Host "3. Verificar com configurações personalizadas"
    Write-Host "4. Exibir ajuda do Flake8"
    Write-Host "5. Configurar arquivo de log"
    Write-Host "6. Formatar código com Black"
    Write-Host "7. Tentar correção automática de erros do Flake8"
    Write-Host "Q. Sair"
    Write-Host
}

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
    [CmdletBinding()]
    param()
    
    $initialPath = (Get-Location).Path
    $configPath = Find-Flake8Config $initialPath

    if ($configPath) {
        Write-Host "`nEncontrado arquivo .flake8 em: $configPath" -ForegroundColor Green
        Write-Host "1. Usar este diretório"
        Write-Host "2. Selecionar outro diretório"
        Write-Host "3. Cancelar"
        $choice = Read-Host "Escolha uma opção"

        switch ($choice) {
            "1" { 
                $script:projectPath = $configPath
                return $configPath 
            }
            "2" { break }
            default { 
                $script:projectPath = $null
                return $null 
            }
        }
    } else {
        Write-Host "`nNão foi encontrado arquivo .flake8 no diretório atual ou superiores." -ForegroundColor Yellow
        Write-Host "1. Selecionar diretório manualmente"
        Write-Host "2. Cancelar"
        $choice = Read-Host "Escolha uma opção"
        
        if ($choice -ne "1") {
            $script:projectPath = $null
            return $null
        }
    }

    Write-Host "`nPor favor, selecione o diretório do projeto que contém o arquivo .flake8:"
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = "Selecione o diretório do projeto"
    $folderBrowser.SelectedPath = $initialPath

    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedPath = $folderBrowser.SelectedPath
        if (Test-Path (Join-Path $selectedPath ".flake8")) {
            $script:projectPath = $selectedPath
            return $selectedPath
        } else {
            Write-Host "Arquivo .flake8 não encontrado no diretório selecionado!" -ForegroundColor Red
            $script:projectPath = $null
            return $null
        }
    }
    $script:projectPath = $null
    return $null
}

function Select-AnalysisPath {
    Write-Host "`nEscolha o tipo de análise:" -ForegroundColor Cyan
    Write-Host "1. Verificar arquivo específico"
    Write-Host "2. Verificar diretório de projeto"
    Write-Host "3. Cancelar"
    
    $choice = Read-Host "Opção"
    
    switch ($choice) {
        '1' {
            Write-Host "`nDigite o caminho do arquivo:" -ForegroundColor Yellow
            $filePath = Read-Host
            if (Test-Path $filePath) {
                return $filePath
            } else {
                Write-Host "Arquivo não encontrado!" -ForegroundColor Red
                return $null
            }
        }
        '2' {
            return Select-ProjectDirectory
        }
        default {
            return $null
        }
    }
}

function Assert-ProjectPath {
    if ([string]::IsNullOrEmpty($script:projectPath)) {
        Write-Host "Caminho do projeto não definido!" -ForegroundColor Red
        return $false
    }
    return $true
}