# Funções auxiliares privadas
function Assert-PythonInstalled {
    [CmdletBinding()]
    param()
    
    try {
        $pythonVersion = python --version 2>&1
        if (-not $?) {
            throw "Python não está instalado ou não está no PATH."
        }
        Write-Verbose "Python encontrado: $pythonVersion"
        return $true
    }
    catch {
        Write-Error "Erro ao verificar instalação do Python: $_"
        return $false
    }
}

function Assert-ProjectPath {
    if (-not $script:projectPath) {
        Write-Host "`nCaminho do projeto não definido. Selecionando diretório..." -ForegroundColor Yellow
        $script:projectPath = Select-ProjectDirectory
        if ($null -eq $script:projectPath) {
            Write-Host "Não foi possível encontrar ou selecionar um diretório de projeto válido." -ForegroundColor Red
            return $false
        }
        Write-Host "Usando diretório do projeto: $script:projectPath" -ForegroundColor Green
    }
    return $true
}

function Assert-ProjectEnvironment {
    [CmdletBinding()]
    param()
    
    if (-not (Assert-ProjectPath)) { return $false }
    if (-not (Initialize-VirtualEnv)) { return $false }
    if (-not (Test-Flake8Installation)) { return $false }
    
    return $true
}

function Test-PackageInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PackageName
    )
    
    $pythonPath = Get-VenvPython
    $result = & $pythonPath -m pip show $PackageName 2>&1
    return $LASTEXITCODE -eq 0
}

function Test-SingleFile {
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-Flake8Installation)) { return }
    $pythonPath = Get-VenvPython
    Write-Host "Digite o caminho do arquivo:" -ForegroundColor Yellow
    $file = Read-Host
    if (Test-Path $file) {
        Get-LogConfiguration
        & $pythonPath -m flake8 $file @script:logParameters
        Confirm-BlackFormat
    } else {
        Write-Host "Arquivo não encontrado!" -ForegroundColor Red
    }
}