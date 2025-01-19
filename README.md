# Flake8 Automation Tool

Ferramenta de automação PowerShell para análise e correção de código Python usando Flake8 e outras ferramentas de formatação.

## Características

- Análise de código com Flake8
- Formatação automática usando:
  - Black
  - Autopep8
  - Autoflake
  - Add-Trailing-Comma
- Interface interativa em menu
- Suporte a arquivos de configuração .flake8
- Geração de logs detalhados
- Correção automática de erros comuns

## Requisitos

- PowerShell 5.1 ou superior
- Python 3.6 ou superior
- pip (gerenciador de pacotes Python)

## Instalação

1. Clone este repositório:
```powershell
git clone https://github.com/seu-usuario/flake8_automation.git
```

## Importação e uso

2. Importe o módulo:
```powershell
Import-Module (Join-Path $PSScriptRoot "Flake8Automation.psd1") -Verbose
```

3. Iniciar a ferramenta:

```powershell
Show-Main [-ProjectPath <caminho>] [-Force]
```

Parâmetros:
- `-ProjectPath`: (Opcional) Caminho do projeto Python a ser analisado
- `-Force`: (Opcional) Força a recriação do ambiente virtual

## Uso direto

### Usando o Script de Inicialização

A maneira mais simples de iniciar a ferramenta é usando o script `Start-Flake8Tool.ps1`:

```powershell
.\Start-Flake8Tool.ps1 [-ProjectPath <caminho>] [-Force]
```

Parâmetros:
- `-ProjectPath`: (Opcional) Caminho do projeto Python a ser analisado
- `-Force`: (Opcional) Força a recriação do ambiente virtual

Exemplo:
```powershell
.\Start-Flake8Tool.ps1 -ProjectPath "C:\MeuProjeto\Python" -Force
```

### Menu Principal

1. **Análise com Flake8**
   - Verificar todo projeto
   - Verificar arquivo específico
   - Verificar com configurações personalizadas
   - Exibir ajuda do Flake8
   - Configurar arquivo de log

2. **Correção Automática**
   - Formatar código com Black
   - Formatar código com Autopep8
   - Remover imports não utilizados (Autoflake)
   - Adicionar vírgulas pendentes (Add-Trailing-Comma)
   - Tentar correção automática dos erros do Flake8

## Configuração

A ferramenta respeita a configuração do arquivo `.flake8` presente no diretório do projeto. Se não existir, serão usadas as configurações padrão.

Exemplo de `.flake8`:
```ini
[flake8]
max-line-length = 100
max-complexity = 10
exclude = .git,__pycache__,build,dist
```

## Logs

Os logs são gerados no diretório `logs` do projeto e seguem o formato:
```
arquivo.py||linha||coluna|| código_erro mensagem_erro
```

## Estrutura do Projeto

```
flake8_automation/
├── Public/
│   ├── Analysis.ps1
│   ├── CodeFixers.ps1
│   ├── Environment.ps1
│   ├── Formatting.ps1
│   ├── Menu.ps1
│   └── Project.ps1
├── Private/
│   ├── Constants.ps1
│   ├── Utilities.ps1
│   └── Validation.ps1
├── Flake8Automation.psd1
├── Flake8Automation.psm1
└── Start-Flake8Tool.ps1
```

## Contribuição

Contribuições são bem-vindas! Por favor, sinta-se à vontade para submeter pull requests.

## Licença

MIT License

## Autor

Marcelo Ferreira Augusto