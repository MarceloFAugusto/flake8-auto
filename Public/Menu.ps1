function Show-MenuOptions {
    Write-Host "=== Menu Principal ===" -ForegroundColor Cyan
    Write-Host "1. Análise com Flake8"
    Write-Host "2. Correção Automática"
    Write-Host "Q. Sair"
    Write-Host
}

function Show-AnalysisOptions {
    Write-Host "`n=== Opções de Análise ===" -ForegroundColor Cyan
    Write-Host "1. Verificar todo projeto"
    Write-Host "2. Verificar arquivo específico"
    Write-Host "3. Verificar com configurações personalizadas"
    Write-Host "4. Exibir ajuda do Flake8"
    Write-Host "5. Configurar arquivo de log"
    Write-Host "0. Voltar"
    Write-Host
}

function Show-CorrectionOptions {
    Write-Host "`n=== Opções de Correção ===" -ForegroundColor Cyan
    Write-Host "1. Formatar código com Black"
    Write-Host "2. Tentar correção automática dos erros do Flake8"
    Write-Host "0. Voltar"
    Write-Host
}

function Show-Main {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [ValidateScript({
            $_ -eq $null -or $_ -eq '' -or (Test-Path $_)
        }, ErrorMessage = "Caminho '{0}' não existe ou é inválido")]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$ProjectPath,
        
        [Parameter()]
        [switch]$Force
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'

    try {
        # Inicialização
        if (-not (Initialize-FlakeEnvironment -Force:$Force)) {
            throw "Falha na inicialização do ambiente"
        }

        # Definir e validar caminho do projeto
        if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
            $script:projectPath = Select-ProjectDirectory
        } else {
            $script:projectPath = $ProjectPath
        }
        
        if (-not $script:projectPath) {
            throw "Caminho do projeto não definido"
        }

        # Menu principal
        do {
            Show-MenuOptions
            $option = Read-Host "Selecione uma opção"
            
            try {
                switch ($option) {
                    '1' { 
                        # Submenu de Análise
                        do {
                            Show-AnalysisOptions
                            $analysisOption = Read-Host "Selecione uma opção"
                            
                            switch ($analysisOption) {
                                '1' { 
                                    $projectDir = Select-ProjectDirectory
                                    if ($projectDir) {
                                        Start-Flake8Analysis -Path $projectDir
                                    }
                                }
                                '2' { 
                                    $filePath = Read-Host "Caminho do arquivo"
                                    Start-Flake8Analysis -Path $filePath
                                }
                                '3' { 
                                    $targetPath = Select-AnalysisPath
                                    if ($targetPath) {
                                        $config = @{
                                            MaxLineLength = Read-Host "Comprimento máximo da linha"
                                            MaxComplexity = Read-Host "Complexidade máxima"
                                        }
                                        Start-Flake8Analysis -Path $targetPath -Config $config
                                    }
                                }
                                '4' {
                                    if (Test-Flake8Installation) {
                                        $pythonPath = Get-VenvPython
                                        & $pythonPath -m flake8 --help
                                    }
                                }
                                '5' {
                                    Get-LogConfiguration
                                    Write-Host "`nConfiguração de log atualizada!" -ForegroundColor Green
                                }
                            }
                            if ($analysisOption -ne '0') {
                                Read-Host "Pressione ENTER para continuar"
                            }
                        } while ($analysisOption -ne '0')
                    }
                    '2' { 
                        # Submenu de Correção
                        do {
                            Show-CorrectionOptions
                            $correctionOption = Read-Host "Selecione uma opção"
                            
                            switch ($correctionOption) {
                                '1' { Format-CodeWithBlack }
                                '2' {
                                    if (-not $script:projectPath) {
                                        $script:projectPath = Select-ProjectDirectory
                                    }
                                    if ($script:projectPath) {
                                        $logFile = Get-CurrentLogFile
                                        if ($logFile) {
                                            Write-Host "Usando arquivo de log: $logFile" -ForegroundColor Green
                                            Repair-Flake8Errors $logFile
                                        } else {
                                            Write-Host "Nenhum arquivo de log encontrado!" -ForegroundColor Red
                                        }
                                    } else {
                                        Write-Host "Diretório do projeto não configurado!" -ForegroundColor Red
                                    }
                                }
                            }
                            if ($correctionOption -ne '0') {
                                Read-Host "Pressione ENTER para continuar"
                            }
                        } while ($correctionOption -ne '0')
                    }
                    'Q' { return }
                    default {
                        Write-Host "Opção inválida!" -ForegroundColor Red
                        Read-Host "Pressione ENTER para continuar"
                    }
                }
            }
            catch {
                Write-LogMessage "Erro: $_" -Level Error
                Read-Host "Pressione ENTER para continuar"
            }
        } while ($option -ne 'Q')
    }
    catch {
        Write-Error -Exception $_.Exception
        return $false
    }
}