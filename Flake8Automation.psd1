@{
    RootModule = 'Flake8Automation.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'b91d27c3-6b59-4d6f-9c0e-a4f298b3b8df'
    Author = 'Marcelo Ferreira Augusto'
    Description = 'Módulo para automação de verificações Flake8'
    PowerShellVersion = '5.1'
    RequiredModules = @()
    FunctionsToExport = @(
        # Funções públicas
        'Show-Main',
        'Initialize-FlakeEnvironment',
        'Start-Flake8Analysis',
        'Format-CodeWithBlack',
        'Repair-Flake8Errors',
        'Test-CustomSettings'
    )
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Python', 'Flake8', 'Linting', 'Code Quality')
            ProjectUri = ''
        }
    }
}
