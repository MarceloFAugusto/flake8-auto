[CmdletBinding()]
param(
    [string]$ProjectPath,
    [switch]$Force
)

# Configuração inicial
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Importar módulo
$modulePath = Join-Path $PSScriptRoot "Flake8Automation.psm1"
Import-Module $modulePath -Force

# Inicializar ambiente
try {
    if (-not (Initialize-FlakeEnvironment -Force:$Force)) {
        throw "Falha ao inicializar ambiente"
    }
    
    # Definir caminho do projeto
    if (-not $ProjectPath) {
        $ProjectPath = Select-ProjectDirectory
    }
    
    if (-not $ProjectPath) {
        throw "Caminho do projeto não definido"
    }
    
    $script:projectPath = $ProjectPath
    Set-Location $ProjectPath
    
    # Menu principal
    do {
        Show-MenuOptions
        $option = Read-Host "Selecione uma opção"
        
        try {
            switch ($option) {
                '1' { Start-Flake8Analysis -Path (Read-Host "Caminho do arquivo") }
                '2' { Start-Flake8Analysis -Path "." }
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
                    $logParams = Get-LogConfiguration
                    Write-Host "Configuração de log atualizada!" -ForegroundColor Green
                    pause
                }
                '6' {
                    Format-CodeWithBlack
                    pause
                }
                '7' {
                    Write-Host "Digite o caminho do arquivo de log do Flake8:" -ForegroundColor Yellow
                    $logFile = Read-Host
                    if (Assert-ProjectPath) {
                        Repair-Flake8Errors $logFile
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
            Write-Host "Erro: $_" -ForegroundColor Red
            pause
        }
        
    } while ($option -ne 'Q')
}
catch {
    Write-Host "Erro fatal: $_" -ForegroundColor Red
    exit 1
}
