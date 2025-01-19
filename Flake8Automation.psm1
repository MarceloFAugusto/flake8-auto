# Importa todos os arquivos .ps1 da pasta Private primeiro
Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" | ForEach-Object {
    . $_.FullName
}

# Depois importa todos os arquivos .ps1 da pasta Public
Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" | ForEach-Object {
    . $_.FullName
}

# Exporta apenas as funções listadas no manifesto
Export-ModuleMember -Function $((Get-Module Flake8Automation).ExportedFunctions.Keys)