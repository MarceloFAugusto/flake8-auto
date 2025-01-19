#Requires -Version 5.1

# Configurações do módulo
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Variáveis privadas do módulo
$script:defaultConfig = @{
    MaxLineLength = 120
    MaxComplexity = 10
    LogFormat = "'%(path)s:%(row)d:%(col)d: %(code)s %(text)s'"
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

function Test-Flake8Installation {
    $pythonPath = Get-VenvPython
    if ($null -eq $pythonPath) {
        Write-Host "Ambiente virtual não encontrado!" -ForegroundColor Red
        return $false
    }

    try {
        # Verifica se flake8 está instalado
        & $pythonPath -m pip show flake8 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        
        # Se não estiver instalado, tenta instalar
        Write-Host "Flake8 não encontrado. Tentando instalar..." -ForegroundColor Yellow
        & $pythonPath -m pip install flake8
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Flake8 instalado com sucesso!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Erro ao instalar Flake8!" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Erro ao verificar/instalar Flake8: $_" -ForegroundColor Red
        return $false
    }
}

function Test-BlackInstallation {
    $pythonPath = Get-VenvPython
    if ($null -eq $pythonPath) {
        Write-Host "Ambiente virtual não encontrado!" -ForegroundColor Red
        return $false
    }

    try {
        # Verifica se black está instalado
        & $pythonPath -m pip show black 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        
        # Se não estiver instalado, tenta instalar
        Write-Host "Black não encontrado. Tentando instalar..." -ForegroundColor Yellow
        & $pythonPath -m pip install black
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Black instalado com sucesso!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Erro ao instalar Black!" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Erro ao verificar/instalar Black: $_" -ForegroundColor Red
        return $false
    }
}

function Show-MenuOptions {
    Clear-Host
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

function Get-NextLogFile {
    param (
        [string]$baseLogName = "flake8.log"
    )
    
    if (-not (Test-Path $baseLogName)) {
        return $baseLogName
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($baseLogName)
    $extension = [System.IO.Path]::GetExtension($baseLogName)
    $counter = 1

    while (Test-Path "${baseName}${extension}.$counter") {
        $counter++
    }

    return "${baseName}${extension}.$counter"
}

function Get-LogConfiguration {
    Write-Host "Escolha a opção de log:" -ForegroundColor Yellow
    Write-Host "1. Criar novo arquivo de log (incrementar número)"
    Write-Host "2. Sobrescrever arquivo existente"
    Write-Host "3. Especificar nome do arquivo"
    Write-Host "4. Sem arquivo de log"
    $choice = Read-Host "Opção"

    $format = "'%(path)s:%(row)d:%(col)d: %(code)s %(text)s'"
    
    switch ($choice) {
        '1' { 
            $logFile = Get-NextLogFile
            Write-Host "Usando arquivo de log: $logFile" -ForegroundColor Green
            return @("--output-file=$logFile", "--tee", "--format=$format")
        }
        '2' { 
            if (Test-Path "flake8.log") {
                Remove-Item "flake8.log" -Force
            }
            return @("--output-file=flake8.log", "--tee", "--format=$format")
        }
        '3' { 
            $logFile = Read-Host "Digite o nome do arquivo de log"
            return @("--output-file=$logFile", "--tee", "--format=$format")
        }
        '4' { return @("--format=$format") }
        default { 
            Write-Host "Opção inválida! Usando novo arquivo de log..." -ForegroundColor Yellow
            $logFile = Get-NextLogFile
            Write-Host "Usando arquivo de log: $logFile" -ForegroundColor Green
            return @("--output-file=$logFile", "--tee", "--format=$format")
        }
    }
}

function Test-SingleFile {
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-Flake8Installation)) { return }
    $pythonPath = Get-VenvPython
    Write-Host "Digite o caminho do arquivo:" -ForegroundColor Yellow
    $file = Read-Host
    if (Test-Path $file) {
        $logParams = Get-LogConfiguration
        & $pythonPath -m flake8 $file @logParams
        Confirm-BlackFormat
    } else {
        Write-Host "Arquivo não encontrado!" -ForegroundColor Red
    }
}

function Test-CustomSettings {
    if (-not (Assert-ProjectPath)) { return }
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-Flake8Installation)) { return }
    $pythonPath = Get-VenvPython
    Write-Host "Digite o comprimento máximo da linha (Enter para padrão 120):" -ForegroundColor Yellow
    $maxLength = Read-Host
    if (!$maxLength) { $maxLength = 120 }

    Write-Host "Digite a complexidade máxima (Enter para padrão 10):" -ForegroundColor Yellow
    $maxComplexity = Read-Host
    if (!$maxComplexity) { $maxComplexity = 10 }

    $logParams = Get-LogConfiguration
    Push-Location $script:projectPath
    & $pythonPath -m flake8 . --max-line-length=$maxLength --max-complexity=$maxComplexity @logParams
    Pop-Location
    Confirm-BlackFormat
}

function Format-CodeWithBlack {
    if (-not (Assert-ProjectPath)) { return }
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-BlackInstallation)) { return }
    
    $pythonPath = Get-VenvPython
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "1. Formatar arquivo específico"
    Write-Host "2. Formatar todo o projeto"
    $choice = Read-Host "Opção"

    switch ($choice) {
        '1' {
            Write-Host "Digite o caminho do arquivo:" -ForegroundColor Yellow
            $file = Read-Host
            if (Test-Path $file) {
                & $pythonPath -m black $file
            } else {
                Write-Host "Arquivo não encontrado!" -ForegroundColor Red
            }
        }
        '2' {
            Write-Host "Formatando todo o projeto..." -ForegroundColor Yellow
            & $pythonPath -m black .
        }
        default {
            Write-Host "Opção inválida!" -ForegroundColor Red
        }
    }
}

function Confirm-BlackFormat {
    Write-Host "`nDeseja formatar o código com Black? (S/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq 'S' -or $response -eq 's') {
        Format-CodeWithBlack
    }
}

function Install-FixTools {
    $pythonPath = Get-VenvPython
    $tools = @("black", "autopep8", "autoflake", "add-trailing-comma")
    
    foreach ($tool in $tools) {
        Write-Host "Verificando $tool..." -ForegroundColor Yellow
        & $pythonPath -m pip show $tool 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Instalando $tool..." -ForegroundColor Yellow
            & $pythonPath -m pip install $tool
        }
    }
}

function Get-Flake8Errors {
    param (
        [string]$logFile
    )
    
    if (-not (Test-Path $logFile)) {
        Write-Host "Arquivo de log não encontrado!" -ForegroundColor Red
        return $null
    }

    $errors = @{
        'W291' = @() # trailing whitespace
        'F541' = @() # f-string issues
        'E722' = @() # bare except
        'E402' = @() # import not at top
        'C901' = @() # complexity
        'other' = @()
    }

    Get-Content $logFile | ForEach-Object {
        $line = $_
        if ($line -match ':(.*?):.*?: ([A-Z][0-9]{3})') {
            $code = $matches[2]
            if ($errors.ContainsKey($code)) {
                $errors[$code] += $line
            } else {
                $errors['other'] += $line
            }
        }
    }

    return $errors
}

function Repair-Flake8Errors {
    param (
        [string]$logFile
    )

    if (-not (Assert-ProjectPath)) { return }
    Install-FixTools
    $pythonPath = Get-VenvPython
    $errors = Get-Flake8Errors $logFile

    if ($null -eq $errors) { return }

    Write-Host "`nAnalisando erros do Flake8..." -ForegroundColor Cyan
    
    # Conjunto de arquivos únicos com problemas
    $affectedFiles = @()
    $errors.Values | ForEach-Object {
        $_ | ForEach-Object {
            if ($_ -match '^[.\\]*(.*?):') {
                try {
                    # Remove quaisquer aspas do caminho e normaliza
                    $filePath = $matches[1].Trim("'").Trim('"')
                    
                    # Se o caminho começar com .\ ou /, considera como relativo ao diretório do projeto
                    if ($filePath -match '^[.\\\/]') {
                        $fullPath = Join-Path $script:projectPath $filePath
                    } else {
                        $fullPath = $filePath
                    }

                    # Normaliza o caminho e verifica se existe
                    $fullPath = [System.IO.Path]::GetFullPath($fullPath)
                    if (Test-Path $fullPath) {
                        $affectedFiles += $fullPath
                        Write-Host "Arquivo encontrado: $fullPath" -ForegroundColor Green
                    } else {
                        Write-Host "Arquivo não encontrado: $fullPath" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "Erro ao processar caminho: $($matches[1])" -ForegroundColor Red
                    Write-Host $_.Exception.Message -ForegroundColor Red
                }
            }
        }
    }
    $affectedFiles = $affectedFiles | Select-Object -Unique

    if ($affectedFiles.Count -eq 0) {
        Write-Host "`nNenhum arquivo válido encontrado para processar." -ForegroundColor Yellow
        return
    }

    Write-Host "`nAplicando correções automáticas..." -ForegroundColor Yellow
    foreach ($file in $affectedFiles) {
        Write-Host "`nProcessando $file..." -ForegroundColor Cyan
        
        try {
            # Black para formatação geral
            & $pythonPath -m black $file --quiet

            # Autopep8 para conformidade PEP8
            & $pythonPath -m autopep8 --in-place --aggressive $file

            # Autoflake para imports não utilizados
            & $pythonPath -m autoflake --in-place --remove-unused-variables --remove-all-unused-imports $file

            # Add-trailing-comma para vírgulas pendentes
            & $pythonPath -m add_trailing_comma $file
        } catch {
            Write-Host "Erro ao processar arquivo $file" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
    }

    Write-Host "`nCorreções automáticas concluídas!" -ForegroundColor Green
    Write-Host "Nota: Alguns problemas podem requerer correção manual:" -ForegroundColor Yellow
    
    if ($errors['C901'].Count -gt 0) {
        Write-Host "`nFunções muito complexas (requer refatoração manual):" -ForegroundColor Red
        $errors['C901'] | ForEach-Object { Write-Host $_ }
    }
    
    if ($errors['E722'].Count -gt 0) {
        Write-Host "`nExceções genéricas (especifique as exceções):" -ForegroundColor Red
        $errors['E722'] | ForEach-Object { Write-Host $_ }
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

# Funções auxiliares privadas
function private:Assert-PythonInstalled {
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        throw "Python não está instalado ou não está no PATH."
    }
}

function private:Write-LogMessage {
    param (
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $color = @{
        Info = 'White'
        Warning = 'Yellow'
        Error = 'Red'
    }[$Level]
    
    Write-Host $Message -ForegroundColor $color
}

# Funções de gerenciamento do ambiente virtual
function Initialize-FlakeEnvironment {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    Assert-PythonInstalled
    if (-not (New-VirtualEnv)) { return $false }
    if (-not (Initialize-VirtualEnv)) { return $false }
    if (-not (Install-RequiredPackages -Force:$Force)) { return $false }
    
    return $true
}

function Install-RequiredPackages {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    $packages = @('flake8', 'black', 'autopep8', 'autoflake', 'add-trailing-comma')
    $pythonPath = Get-VenvPython
    
    foreach ($package in $packages) {
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

# Funções de análise e formatação
function Start-Flake8Analysis {
    [CmdletBinding()]
    param(
        [string]$Path,
        [hashtable]$Config
    )
    
    if (-not (Assert-ProjectEnvironment)) { return }
    
    $pythonPath = Get-VenvPython
    $logParams = Get-LogConfiguration
    $configParams = @()
    
    if ($Config) {
        $configParams += "--max-line-length=$($Config.MaxLineLength)"
        $configParams += "--max-complexity=$($Config.MaxComplexity)"
    }
    
    & $pythonPath -m flake8 $Path @configParams @logParams
}

Export-ModuleMember -Function @(
    'New-VirtualEnv',
    'Find-Flake8Config',
    'Select-ProjectDirectory',
    'Get-VenvPython',
    'Initialize-VirtualEnv',
    'Test-Flake8Installation',
    'Test-BlackInstallation',
    'Show-MenuOptions',
    'Get-NextLogFile',
    'Get-LogConfiguration',
    'Test-SingleFile',
    'Test-CustomSettings',
    'Format-CodeWithBlack',
    'Confirm-BlackFormat',
    'Install-FixTools',
    'Get-Flake8Errors',
    'Repair-Flake8Errors',
    'Assert-ProjectPath',
    'Initialize-FlakeEnvironment',
    'Install-RequiredPackages',
    'Start-Flake8Analysis'
)