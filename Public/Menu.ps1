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
        
        Set-Location $script:projectPath

        # Menu principal
        do {
            Show-MenuOptions
            $option = Read-Host "Selecione uma opção"
            
            try {
                switch ($option) {
                    '1' { 
                        $filePath = Read-Host "Caminho do arquivo"
                        Start-Flake8Analysis -Path $filePath
                        Read-Host "Pressione ENTER para continuar"
                    }
                    '2' { 
                        $projectDir = Select-ProjectDirectory
                        if ($projectDir) {
                            Start-Flake8Analysis -Path $projectDir
                        }
                        Read-Host "Pressione ENTER para continuar"
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
                        Read-Host "Pressione ENTER para continuar"
                    }
                    '4' {
                        if (Test-Flake8Installation) {
                            $pythonPath = Get-VenvPython
                            & $pythonPath -m flake8 --help
                        }
                        Read-Host "Pressione ENTER para continuar"
                    }
                    '5' {
                        Get-LogConfiguration
                        Write-Host "`nConfiguração de log atualizada!" -ForegroundColor Green
                        Read-Host "Pressione ENTER para continuar"
                    }
                    '6' {
                        Format-CodeWithBlack
                        Read-Host "Pressione ENTER para continuar"
                    }
                    '7' {
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
                        Read-Host "Pressione ENTER para continuar"
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