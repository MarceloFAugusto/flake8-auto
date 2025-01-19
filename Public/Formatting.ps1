function Format-CodeWithBlack {
    if (-not (Assert-ProjectPath)) { return }
    if (-not (Initialize-VirtualEnv)) { return }
    if (-not (Test-BlackInstallation)) { return }
    
    $pythonPath = Get-VenvPython
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "1. Formatar arquivo específico"
    Write-Host "2. Formatar todo o projeto"
    $choice = Read-Host "Opção"

    switch ($choice) {
        '1' {
            Write-Host "Digite o caminho do arquivo:" -ForegroundColor Yellow
            $file = Read-Host
            if (Test-Path $file) {
                & $pythonPath -m black $file
            } else {
                Write-Host "Arquivo não encontrado!" -ForegroundColor Red
            }
        }
        '2' {
            Write-Host "Formatando todo o projeto..." -ForegroundColor Yellow
            & $pythonPath -m black .
        }
        default {
            Write-Host "Opção inválida!" -ForegroundColor Red
        }
    }
}

function Test-BlackInstallation {
    $pythonPath = Get-VenvPython
    if ($null -eq $pythonPath) {
        Write-Host "Ambiente virtual não encontrado!" -ForegroundColor Red
        return $false
    }

    try {
        # Verifica se black está instalado
        & $pythonPath -m pip show black 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            return $true
        }
        
        # Se não estiver instalado, tenta instalar
        Write-Host "Black não encontrado. Tentando instalar..." -ForegroundColor Yellow
        & $pythonPath -m pip install black
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Black instalado com sucesso!" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Erro ao instalar Black!" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "Erro ao verificar/instalar Black: $_" -ForegroundColor Red
        return $false
    }
}

function Confirm-BlackFormat {
    Write-Host "`nDeseja formatar o código com Black? (S/N)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq 'S' -or $response -eq 's') {
        Format-CodeWithBlack
    }
}