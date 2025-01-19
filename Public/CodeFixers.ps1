function Format-WithAutopep8 {
    if (-not (Assert-ProjectPath)) { return }
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-Autopep8Installation)) { return }
    
    $pythonPath = Get-VenvPython
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "1. Formatar arquivo específico"
    Write-Host "2. Formatar todo o projeto"
    Write-Host "3. Exibir ajuda do Autopep8"
    $choice = Read-Host "Opção"

    switch ($choice) {
        '1' {
            Write-Host "Digite o caminho do arquivo:" -ForegroundColor Yellow
            $file = Read-Host
            if (Test-Path $file) {
                Write-Host "Aplicando Autopep8 com opções agressivas..." -ForegroundColor Cyan
                & $pythonPath -m autopep8 --in-place --aggressive --aggressive $file
                Write-Host "Formatação concluída!" -ForegroundColor Green
            } else {
                Write-Host "Arquivo não encontrado!" -ForegroundColor Red
            }
        }
        '2' {
            $projectDir = Select-ProjectDirectory
            if ($projectDir) {
                Write-Host "Formatando projeto em: $projectDir" -ForegroundColor Yellow
                $files = Get-ProjectFiles -projectDir $projectDir -filter "*.py"
                $files | ForEach-Object {
                    Write-Host "Processando $($_.FullName)..." -ForegroundColor Cyan
                    & $pythonPath -m autopep8 --in-place --aggressive --aggressive $_.FullName
                }
                Write-Host "Formatação concluída!" -ForegroundColor Green
            }
        }
        '3' {
            & $pythonPath -m autopep8 --help
        }
        default {
            Write-Host "Opção inválida!" -ForegroundColor Red
        }
    }
}

function Format-WithAutoflake {
    if (-not (Assert-ProjectPath)) { return }
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-AutoflakeInstallation)) { return }
    
    $pythonPath = Get-VenvPython
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "1. Processar arquivo específico"
    Write-Host "2. Processar todo o projeto"
    Write-Host "3. Exibir ajuda do Autoflake"
    $choice = Read-Host "Opção"

    switch ($choice) {
        '1' {
            Write-Host "Digite o caminho do arquivo:" -ForegroundColor Yellow
            $file = Read-Host
            if (Test-Path $file) {
                Write-Host "Aplicando Autoflake..." -ForegroundColor Cyan
                & $pythonPath -m autoflake --in-place --remove-all-unused-imports --remove-unused-variables $file
                Write-Host "Processamento concluído!" -ForegroundColor Green
            } else {
                Write-Host "Arquivo não encontrado!" -ForegroundColor Red
            }
        }
        '2' {
            $projectDir = Select-ProjectDirectory
            if ($projectDir) {
                Write-Host "Processando projeto em: $projectDir" -ForegroundColor Yellow
                $files = Get-ProjectFiles -projectDir $projectDir -filter "*.py"
                $files | ForEach-Object {
                    Write-Host "Processando $($_.FullName)..." -ForegroundColor Cyan
                    & $pythonPath -m autoflake --in-place --remove-all-unused-imports --remove-unused-variables $_.FullName
                }
                Write-Host "Processamento concluído!" -ForegroundColor Green
            }
        }
        '3' {
            & $pythonPath -m autoflake --help
        }
        default {
            Write-Host "Opção inválida!" -ForegroundColor Red
        }
    }
}

function Format-WithAddTrailingComma {
    if (-not (Assert-ProjectPath)) { return }
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-AddTrailingCommaInstallation)) { return }
    
    $pythonPath = Get-VenvPython
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "1. Processar arquivo específico"
    Write-Host "2. Processar todo o projeto"
    Write-Host "3. Exibir ajuda do Add-Trailing-Comma"
    $choice = Read-Host "Opção"

    switch ($choice) {
        '1' {
            Write-Host "Digite o caminho do arquivo:" -ForegroundColor Yellow
            $file = Read-Host
            if (Test-Path $file) {
                Write-Host "Aplicando Add-Trailing-Comma..." -ForegroundColor Cyan
                & $pythonPath -m add_trailing_comma $file
                Write-Host "Processamento concluído!" -ForegroundColor Green
            } else {
                Write-Host "Arquivo não encontrado!" -ForegroundColor Red
            }
        }
        '2' {
            $projectDir = Select-ProjectDirectory
            if ($projectDir) {
                Write-Host "Processando projeto em: $projectDir" -ForegroundColor Yellow
                $files = Get-ProjectFiles -projectDir $projectDir -filter "*.py"
                $files | ForEach-Object {
                    Write-Host "Processando $($_.FullName)..." -ForegroundColor Cyan
                    & $pythonPath -m add_trailing_comma $_.FullName
                }
                Write-Host "Processamento concluído!" -ForegroundColor Green
            }
        }
        '3' {
            & $pythonPath -m add_trailing_comma --help
        }
        default {
            Write-Host "Opção inválida!" -ForegroundColor Red
        }
    }
}

function Test-Autopep8Installation {
    return Test-ToolInstallation "autopep8"
}

function Test-AutoflakeInstallation {
    return Test-ToolInstallation "autoflake"
}

function Test-AddTrailingCommaInstallation {
    return Test-ToolInstallation "add-trailing-comma"
}

function Test-ToolInstallation {
    param (
        [string]$toolName
    )
    
    $pythonPath = Get-VenvPython
    if ($null -eq $pythonPath) {
        Write-Host "Ambiente virtual não encontrado!" -ForegroundColor Red
        return $false
    }

    try {
        & $pythonPath -m pip show $toolName 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        
        Write-Host "$toolName não encontrado. Tentando instalar..." -ForegroundColor Yellow
        & $pythonPath -m pip install $toolName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$toolName instalado com sucesso!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Erro ao instalar $toolName!" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Erro ao verificar/instalar $toolName`: $_" -ForegroundColor Red
        return $false
    }
}
