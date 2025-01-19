Write-Verbose "Iniciando carregamento do módulo Flake8Automation"

# Carrega arquivos na ordem correta (primeiro Private, depois Public)
foreach ($folder in @('Private', 'Public')) {
    $folderPath = Join-Path $PSScriptRoot $folder
    if (Test-Path $folderPath) {
        Get-ChildItem -Path $folderPath -Filter '*.ps1' | 
            ForEach-Object { . $_.FullName }
    }
}