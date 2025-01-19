function Write-LogMessage {
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

# Variável global para armazenar parâmetros de log
$script:logParameters = $null

function Get-LogConfiguration {
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
            Write-Host "Usando arquivo de log: $logFile" -ForegroundColor Green
            $script:logParameters = @("--output-file=$logFile", "--tee", "--format=$format")
        }
        '2' { 
            if (Test-Path "flake8.log") {
                Remove-Item "flake8.log" -Force
            }
            $script:logParameters = @("--output-file=flake8.log", "--tee", "--format=$format")
        }
        '3' { 
            $logFile = Read-Host "Digite o nome do arquivo de log"
            $script:logParameters = @("--output-file=$logFile", "--tee", "--format=$format")
        }
        '4' { 
            $script:logParameters = @("--format=$format")
        }
        default { 
            Write-Host "Opção inválida! Usando novo arquivo de log..." -ForegroundColor Yellow
            $logFile = Get-NextLogFile
            Write-Host "Usando arquivo de log: $logFile" -ForegroundColor Green
            $script:logParameters = @("--output-file=$logFile", "--tee", "--format=$format")
        }
    }
}