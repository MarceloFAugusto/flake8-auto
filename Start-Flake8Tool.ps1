[CmdletBinding()]
param(
    [Parameter()]
    [string]$ProjectPath,
    
    [Parameter()]
    [switch]$Force
)

# Remove o módulo se já estiver carregado
if (Get-Module Flake8Automation) {
    Remove-Module Flake8Automation -Force
}

# Importa usando o manifesto
Import-Module (Join-Path $PSScriptRoot "Flake8Automation.psd1") -Verbose

# Executa o menu principal
$params = @{}
if ($ProjectPath) { $params['ProjectPath'] = $ProjectPath }
if ($Force) { $params['Force'] = $true }

Show-Main @params