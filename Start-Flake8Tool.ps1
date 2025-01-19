[CmdletBinding()]
param(
    [Parameter()]
    [string]$ProjectPath,
    
    [Parameter()]
    [switch]$Force
)

# Determina o caminho do módulo relativo a este script
$modulePath = Join-Path $PSScriptRoot "Flake8Automation.psd1"

# Verifica se o módulo existe
if (-not (Test-Path $modulePath)) {
    throw "Módulo Flake8Automation não encontrado em: $modulePath"
}

# Importa o módulo
Import-Module $modulePath -Force:$Force

# Executa o menu principal
$params = @{}
if ($ProjectPath) { $params['ProjectPath'] = $ProjectPath }
if ($Force) { $params['Force'] = $true }

Show-Main @params