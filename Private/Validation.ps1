# Funções auxiliares privadas
function script:Assert-PythonInstalled {
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

function script:Assert-ProjectPath {
    if (-not $script:projectPath) {
        Write-Host "`nCaminho do projeto não definido. Selecionando diretório..." -ForegroundColor Yellow
        $script:projectPath = Select-ProjectDirectory
        if ($null -eq $script:projectPath) {
            Write-Host "Não foi possível encontrar ou selecionar um diretório de projeto válido." -ForegroundColor Red
            return $false
        }
        # Garantir que temos um caminho completo
        $script:projectPath = [System.IO.Path]::GetFullPath($script:projectPath)
        Write-Host "Usando diretório do projeto: $script:projectPath" -ForegroundColor Green
    }
    return $true
}

function script:Assert-ProjectEnvironment {
    [CmdletBinding()]
    param()
    
    if (-not (Assert-ProjectPath)) { return $false }
    if (-not (Initialize-VirtualEnv)) { return $false }
    if (-not (Test-Flake8Installation)) { return $false }
    
    return $true
}

function script:Test-PackageInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageName
    )
    
    try {
        $pythonPath = Get-VenvPython
        if ($null -eq $pythonPath) {
            Write-Error "Ambiente Python virtual não encontrado"
            return $false
        }

        # Usa pip list que é mais rápido que pip show
        $installedPackages = & $pythonPath -m pip list 2>$null
        
        # Verifica se o pacote está na lista de pacotes instalados
        $packageFound = $installedPackages | Where-Object { $_ -match "^$PackageName\s+" }
        
        return [bool]$packageFound
    }
    catch {
        Write-Error "Erro ao verificar pacote $PackageName`: $_"
        return $false
    }
}

function script:Get-FullPath {
    param (
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if ([System.IO.Path]::IsPathRooted($Path)) {
        return $Path
    }
    
    if ($script:projectPath) {
        return Join-Path $script:projectPath $Path
    }
    
    return [System.IO.Path]::GetFullPath($Path)
}