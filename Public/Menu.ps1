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

function Show-Main {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateScript({Test-Path $_})]
        [string]$ProjectPath,
        
        [Parameter()]
        [switch]$Force
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    try {
        # Carregar módulo com força apenas se especificado
        $moduleParams = @{
            Path = Join-Path $PSScriptRoot "Flake8Automation.psd1"
        }
        if ($Force) {
            $moduleParams['Force'] = $true
        }
        Import-Module @moduleParams

        # Inicialização
        if (-not (Initialize-FlakeEnvironment -Force:$Force)) {
            throw "Falha na inicialização do ambiente"
        }

        # Definir e validar caminho do projeto
        $ProjectPath = $ProjectPath ?? (Select-ProjectDirectory)
        if (-not $ProjectPath) {
            throw "Caminho do projeto não definido"
        }
        
        Set-Location $ProjectPath

        # Menu principal
        do {
            Show-MenuOptions
            $option = Read-Host "Selecione uma opção"
            
            try {
                switch ($option) {
                    '1' { 
                        $filePath = Read-Host "Caminho do arquivo"
                        Start-Flake8Analysis -Path $filePath
                    }
                    '2' { 
                        Start-Flake8Analysis -Path "."
                    }
                    '3' { 
                        $config = @{
                            MaxLineLength = Read-Host "Comprimento máximo da linha"
                            MaxComplexity = Read-Host "Complexidade máxima"
                        }
                        Start-Flake8Analysis -Path "." -Config $config
                    }
                    '4' {
                        if (Test-Flake8Installation) {
                            $pythonPath = Get-VenvPython
                            & $pythonPath -m flake8 --help
                        }
                        pause
                    }
                    '5' {
                        Get-LogConfiguration
                        Write-Host "`nConfiguração de log atualizada!" -ForegroundColor Green
                        pause
                    }
                    '6' {
                        Format-CodeWithBlack
                        pause
                    }
                    '7' {
                        Write-Host "Digite o caminho do arquivo de log do Flake8:" -ForegroundColor Yellow
                        $logFile = Read-Host
                        if (Assert-ProjectPath -and (Test-Path $logFile)) {
                            Repair-Flake8Errors $logFile
                        } else {
                            Write-Host "Arquivo de log não encontrado!" -ForegroundColor Red
                        }
                        pause
                    }
                    'Q' { return }
                    default {
                        Write-Host "Opção inválida!" -ForegroundColor Red
                        pause
                    }
                }
            }
            catch {
                Write-LogMessage "Erro: $_" -Level Error
                pause
            }
        } while ($option -ne 'Q')
    }
    catch {
        Write-Error -Exception $_.Exception
        return $false
    }
}