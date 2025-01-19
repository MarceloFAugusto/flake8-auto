# Funções de análise e formatação
function Start-Flake8Analysis {
    [CmdletBinding()]
    param(
        [string]$Path,
        [hashtable]$Config,
        [string[]]$LogParams
    )
    
    if (-not (Assert-ProjectEnvironment)) { return }
    
    $pythonPath = Get-VenvPython
    $configParams = @()
    
    if ($Config) {
        $configParams += "--max-line-length=$($Config.MaxLineLength)"
        $configParams += "--max-complexity=$($Config.MaxComplexity)"
    }

    # Usa os parâmetros de log fornecidos ou obtém novos se não existirem
    $logParameters = $LogParams
    if (-not $logParameters) {
        $logParameters = Get-LogConfiguration
    }
    
    & $pythonPath -m flake8 $Path @configParams @logParameters
}

function Get-Flake8Errors {
    param (
        [string]$logFile
    )
    
    if (-not (Test-Path $logFile)) {
        Write-Host "Arquivo de log não encontrado!" -ForegroundColor Red
        return $null
    }

    $errors = @{}
    # Inicializa o dicionário com os códigos de erro conhecidos
    $script:ERROR_CODES.Keys | ForEach-Object {
        $errors[$_] = @()
    }
    $errors['other'] = @()

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