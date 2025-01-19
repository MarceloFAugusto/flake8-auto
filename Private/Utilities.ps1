# Variáveis globais
$script:logParameters = $null
$script:projectLogPath = $null
$script:currentLogFile = $null

function script:Write-LogMessage {
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

function script:Get-NextLogFile {
    param (
        [string]$baseLogName = "flake8.log"
    )
    
    if (-not (Assert-ProjectPath)) {
        return $null
    }

    $script:projectLogPath = Join-Path $script:projectPath "logs"
    
    if (-not (Test-Path $script:projectLogPath)) {
        New-Item -ItemType Directory -Path $script:projectLogPath | Out-Null
    }

    $fullPath = Join-Path $script:projectLogPath $baseLogName
    if (-not (Test-Path $fullPath)) {
        $script:currentLogFile = $fullPath
        return $fullPath
    }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($baseLogName)
    $extension = [System.IO.Path]::GetExtension($baseLogName)
    $counter = 1

    while (Test-Path (Join-Path $script:projectLogPath "${baseName}${extension}.$counter")) {
        $counter++
    }

    $script:currentLogFile = Join-Path $script:projectLogPath "${baseName}${extension}.$counter"
    return $script:currentLogFile
}

function script:Get-CurrentLogFile {
    if (-not (Assert-ProjectPath)) {
        return $null
    }

    if (-not $script:projectLogPath) {
        $script:projectLogPath = Join-Path $script:projectPath "logs"
    }

    # Se já temos um arquivo de log definido e ele existe, retorna ele
    if ($script:currentLogFile -and (Test-Path $script:currentLogFile)) {
        return $script:currentLogFile
    }

    # Se o diretório de logs não existe, retorna null
    if (-not (Test-Path $script:projectLogPath)) {
        return $null
    }

    # Procura pelo arquivo .log mais recente
    $lastLog = Get-ChildItem -Path $script:projectLogPath -Filter "*.log" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($lastLog) {
        $script:currentLogFile = $lastLog.FullName
        return $script:currentLogFile
    }

    return $null
}

function script:Get-LogConfiguration {
    if (-not (Assert-ProjectPath)) {
        return
    }

    if ($script:logParameters) {
        Write-Host "`nConfiguração de log atual:" -ForegroundColor Cyan
        Write-Host $($script:logParameters -join ' ') -ForegroundColor Green
        Write-Host "`nDeseja modificar a configuração atual? (S/N)" -ForegroundColor Yellow
        $response = Read-Host
        if ($response -ne 'S' -and $response -ne 's') {
            return
        }
    }

    Write-Host "`nEscolha a opção de log:" -ForegroundColor Yellow
    Write-Host "1. Criar novo arquivo de log (incrementar número)"
    Write-Host "2. Sobrescrever arquivo existente"
    Write-Host "3. Especificar nome do arquivo"
    Write-Host "4. Sem arquivo de log"
    $choice = Read-Host "Opção"

    $format = $script:defaultConfig.LogFormat
    
    switch ($choice) {
        '1' { 
            $logFile = Get-NextLogFile
            if ($logFile) {
                Write-Host "Usando arquivo de log: $logFile" -ForegroundColor Green
                $script:logParameters = @("--output-file=$logFile", "--tee", "--format=$format")
            }
        }
        '2' { 
            $defaultLog = Join-Path $script:projectLogPath "flake8.log"
            if (Test-Path $defaultLog) {
                Remove-Item $defaultLog -Force
            }
            $script:currentLogFile = $defaultLog
            $script:logParameters = @("--output-file=$defaultLog", "--tee", "--format=$format")
        }
        '3' { 
            $logName = Read-Host "Digite o nome do arquivo de log"
            $logFile = Join-Path $script:projectLogPath $logName
            $script:currentLogFile = $logFile
            $script:logParameters = @("--output-file=$logFile", "--tee", "--format=$format")
        }
        '4' { 
            $script:currentLogFile = $null
            $script:logParameters = @("--format=$format")
        }
        default { 
            Write-Host "Opção inválida! Usando novo arquivo de log..." -ForegroundColor Yellow
            $logFile = Get-NextLogFile
            if ($logFile) {
                Write-Host "Usando arquivo de log: $logFile" -ForegroundColor Green
                $script:logParameters = @("--output-file=$logFile", "--tee", "--format=$format")
            }
        }
    }
}