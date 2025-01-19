@{
    RootModule = 'Flake8Automation.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'b91d27c3-6b59-4d6f-9c0e-a4f298b3b8df'
    Author = 'Marcelo Ferreira Augusto'
    Description = 'Módulo para automação de verificações Flake8'
    PowerShellVersion = '5.1'
    RequiredModules = @()
    RequiredAssemblies = @('System.Windows.Forms')
    FunctionsToExport = @(
        # Menu
        'Show-MenuOptions',
        'Show-Main',
        
        # Project
        'Find-Flake8Config',
        'Select-ProjectDirectory',
        
        # Environment
        'Initialize-FlakeEnvironment',
        'New-VirtualEnv',
        'Get-VenvPython',
        'Initialize-VirtualEnv',
        'Install-RequiredPackages',
        
        # Analysis
        'Start-Flake8Analysis',
        'Get-Flake8Errors',
        'Test-Flake8Installation',
        'Repair-Flake8Errors',
        'Install-FixTools',
        
        # Formatting
        'Format-CodeWithBlack',
        'Test-BlackInstallation',
        'Confirm-BlackFormat',
        'Format-WithAutopep8',
        'Format-WithAutoflake',
        'Format-WithAddTrailingComma',
        'Test-Autopep8Installation',
        'Test-AutoflakeInstallation',
        'Test-AddTrailingCommaInstallation'
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
