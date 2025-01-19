function Initialize-FlakeEnvironment {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    try {
        if (-not (Assert-PythonInstalled)) {
            throw "Python não está instalado corretamente"
        }

        if ($Force) {
            Remove-Item -Path (Join-Path $PSScriptRoot "venv") -Recurse -Force -ErrorAction SilentlyContinue
        }

        if (-not (New-VirtualEnv)) {
            throw "Falha ao criar ambiente virtual"
        }

        if (-not (Initialize-VirtualEnv)) { return $false }
        if (-not (Install-RequiredPackages -Force:$Force)) { return $false }
        
        return $true
    }
    catch {
        Write-Error -Exception $_.Exception
        return $false
    }
}

<#
.SYNOPSIS
    Cria um novo ambiente virtual Python.
.DESCRIPTION
    Cria um ambiente virtual Python no diretório do módulo.
#>
function New-VirtualEnv {
    [CmdletBinding()]
    param()
    
    $venvPath = Join-Path $PSScriptRoot "venv"
    if (-not (Test-Path $venvPath)) {
        Write-Host "Criando novo ambiente virtual..." -ForegroundColor Yellow
        try {
            python -m venv $venvPath
            Write-Host "Ambiente virtual criado com sucesso!" -ForegroundColor Green
            return $true
        } catch {
            Write-Host "Erro ao criar ambiente virtual: $_" -ForegroundColor Red
            return $false
        }
    }
    return $true
}

# Modificar a função Get-VenvPython para usar o novo caminho do venv
function Get-VenvPython {
    $venvPath = Join-Path $PSScriptRoot "venv"
    if (-not (Test-Path $venvPath)) {
        if (-not (New-VirtualEnv)) {
            return $null
        }
    }
    
    if ($IsWindows) {
        return Join-Path $venvPath "Scripts\python.exe"
    } else {
        return Join-Path $venvPath "bin/python"
    }
}

function Initialize-VirtualEnv {
    $pythonPath = Get-VenvPython
    if ($null -eq $pythonPath) {
        Write-Host "Ambiente virtual não encontrado em ./venv" -ForegroundColor Red
        return $false
    }
    
    try {
        # Verifica se o ambiente virtual já está ativado
        if ($env:VIRTUAL_ENV) {
            Write-Host "Ambiente virtual já está ativado" -ForegroundColor Green
            return $true
        }

        # Define a função prompt se não existir
        if (-not (Test-Path Function:\prompt)) {
            function global:prompt { "(venv) $($executionContext.SessionState.Path.CurrentLocation)>" }
        }

        # Tenta ativar o ambiente virtual
        if ($IsWindows) {
            $activateScript = Join-Path $PSScriptRoot "venv\Scripts\Activate.ps1"
            if (Test-Path $activateScript) {
                . $activateScript
            }
        } else {
            & source "$PSScriptRoot/venv/bin/activate"
        }

        # Define variáveis de ambiente
        $env:VIRTUAL_ENV = Join-Path $PSScriptRoot "venv"
        $env:PATH = "$env:VIRTUAL_ENV\Scripts;$env:PATH"

        return $true
    } catch {
        Write-Host "Erro ao ativar ambiente virtual: $_" -ForegroundColor Yellow
        Write-Host "Continuando com caminho completo do Python..." -ForegroundColor Yellow
        return $true  # Retorna true mesmo assim pois usaremos o caminho completo
    }
}

function Install-RequiredPackages {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    $pythonPath = Get-VenvPython
    
    foreach ($package in $script:REQUIRED_PACKAGES) {
        if ($Force -or -not (Test-PackageInstalled $package)) {
            Write-LogMessage "Instalando $package..." -Level Info
            & $pythonPath -m pip install $package
            if ($LASTEXITCODE -ne 0) {
                Write-LogMessage "Falha ao instalar $package" -Level Error
                return $false
            }
        }
    }
    
    return $true
}