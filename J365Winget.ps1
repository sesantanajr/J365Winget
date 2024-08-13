# =============================
# Script: winget_install.ps1
# Descrição: Gerencia repositórios Winget, aceita todos os acordos automaticamente, lista pacotes instalados e atualiza todos os pacotes disponíveis no sistema.
# Versão: 2.4
# Data: 2024-08-13
# Autor: Seu Nome
# =============================

# Configuração de Log - gera um nome de arquivo baseado na data e hora
$logDir = "C:\Jornada365\Logs"
$logFileName = "winget_install_{0:yyyy-MM-dd_HH-mm}.txt" -f (Get-Date)
$logFile = Join-Path $logDir $logFileName

# =============================
# Função: Ensure-LogDirectory
# Descrição: Garante a existência do diretório de log.
# =============================
function Ensure-LogDirectory {
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory | Out-Null
    }
}

# =============================
# Função: Log-Message
# Descrição: Loga mensagens com timestamp e nível de severidade.
# Parâmetros:
#   - message: A mensagem a ser logada.
#   - severity: O nível de severidade (INFO, ERROR, etc.).
# =============================
function Log-Message {
    param (
        [string]$message,
        [string]$severity = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$severity] $message"
    Write-Host $logEntry
    Add-Content -Path $logFile -Value $logEntry
}

# =============================
# Função: Test-NetworkConnection
# Descrição: Verifica a conectividade de rede.
# Retorno: $true se a rede estiver disponível, $false caso contrário.
# =============================
function Test-NetworkConnection {
    try {
        $response = Test-Connection -ComputerName "www.microsoft.com" -Count 1 -Quiet
        return $response
    } catch {
        Log-Message "Erro ao testar a conectividade de rede: $_" "ERROR"
        return $false
    }
}

# =============================
# Função: Ensure-Repository
# Descrição: Garante que um repositório Winget esteja configurado corretamente.
# Parâmetros:
#   - name: Nome do repositório.
#   - url: URL do repositório.
#   - retries: Número de tentativas em caso de falha.
# =============================
function Ensure-Repository {
    param (
        [string]$name,
        [string]$url,
        [int]$retries = 3
    )

    $repoConfigured = winget source list | Select-String $name

    if ($repoConfigured) {
        Log-Message "Repositório '$name' já está configurado. Verificando se está funcionando..."
        if (Test-Repository -url $url) {
            Log-Message "Repositório '$name' está funcionando corretamente. Não há necessidade de substituição."
            return
        } else {
            Log-Message "Repositório '$name' não está funcionando. Tentando substituir..."
            winget source remove --name $name
        }
    }

    for ($i = 0; $i -lt $retries; $i++) {
        try {
            winget source add --name $name --arg $url --accept-source-agreements
            Log-Message "Repositório '$name' adicionado com sucesso."
            return
        } catch {
            Log-Message "Falha ao adicionar repositório '$name'. Tentando novamente... ($i/$retries)" "ERROR"
            Start-Sleep -Seconds ([Math]::Pow(2, $i))  # Retentativa exponencial
        }
    }

    Log-Message "Falha ao adicionar repositório '$name' após $retries tentativas. Verifique a URL ou a conectividade." "ERROR"
}

# =============================
# Função: Ensure-ReliableRepositories
# Descrição: Verifica e adiciona repositórios confiáveis ao Winget.
# =============================
function Ensure-ReliableRepositories {
    Log-Message "Verificando e adicionando repositórios confiáveis..."

    # Lista de repositórios confiáveis
    $repositories = @(
        @{name="winget"; url="https://cdn.winget.microsoft.com/cache"}, # Repositório oficial do Winget
        @{name="msstore"; url="https://storeedgefd.dsx.mp.microsoft.com/v9.0"} # Repositório da Microsoft Store
    )

    foreach ($repo in $repositories) {
        Ensure-Repository -name $repo.name -url $repo.url
    }
}

# =============================
# Função: Check-Winget
# Descrição: Verifica se o Winget está instalado.
# Retorno: $true se o Winget estiver instalado, $false caso contrário.
# =============================
function Check-Winget {
    try {
        Get-Command winget -ErrorAction Stop | Out-Null
        Log-Message "Winget está instalado e disponível."
        return $true
    } catch {
        Log-Message "Winget não está instalado. Por favor, instale o Winget e tente novamente." "ERROR"
        return $false
    }
}

# =============================
# Função: Ensure-Prerequisites
# Descrição: Verifica e instala os pré-requisitos necessários para o script funcionar.
# =============================
function Ensure-Prerequisites {
    Log-Message "Verificando e instalando pré-requisitos..."
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop
        Log-Message "Provedor NuGet instalado com sucesso."
    }
    if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client)) {
        Install-Module -Name Microsoft.WinGet.Client -Repository PSGallery -Force -ErrorAction Stop
        Log-Message "Módulo Microsoft.WinGet.Client instalado com sucesso."
    }
}

# =============================
# Função: Reset-WingetSources
# Descrição: Reseta todas as fontes do Winget.
# =============================
function Reset-WingetSources {
    Log-Message "Resetando fontes do Winget..."
    winget source reset --force
    Log-Message "Fontes do Winget resetadas com sucesso."
}

# =============================
# Função: Test-Repository
# Descrição: Verifica a conectividade com um repositório específico.
# Parâmetros:
#   - url: URL do repositório a ser testado.
# Retorno: $true se a conectividade estiver OK, $false caso contrário.
# =============================
function Test-Repository {
    param (
        [string]$url
    )
    try {
        $uri = New-Object System.Uri($url)
        $domain = $uri.Host
        $dnsResult = Resolve-DnsName -Name $domain -ErrorAction Stop
        Log-Message "Conectividade com o repositório '$url' confirmada."
        return $true
    } catch {
        Log-Message "Falha ao resolver o DNS para '$url'. Erro: $_" "ERROR"
        return $false
    }
}

# =============================
# Função: Update-Repositories
# Descrição: Atualiza todos os repositórios do Winget.
# =============================
function Update-Repositories {
    Log-Message "Atualizando todos os repositórios do Winget..."
    winget source update --verbose
    Log-Message "Repositórios atualizados com sucesso."
}

# =============================
# Função: Ensure-NoProcessesLocking
# Descrição: Garante que não há processos em execução que possam bloquear a atualização.
# Parâmetros:
#   - processName: Nome do processo a ser verificado.
# =============================
function Ensure-NoProcessesLocking {
    param (
        [string]$processName
    )
    $processes = Get-Process | Where-Object { $_.Name -eq $processName }
    if ($processes) {
        Log-Message "Processo '$processName' em execução. Tentando fechá-lo."
        Stop-Process -Name $processName -Force
        Log-Message "Processo '$processName' fechado com sucesso."
    }
}

# =============================
# Função: List-InstalledPackages
# Descrição: Lista todos os pacotes instalados no sistema, filtrando ruídos e aceitando os acordos.
# =============================
function List-InstalledPackages {
    Log-Message "Listando um número limitado de pacotes instalados (até 10 pacotes)..."

    try {
        # Executa o comando winget list com aceitação de acordos e interatividade desativada
        $wingetOutput = winget list --accept-source-agreements --disable-interactivity | Out-String
        
        # Filtra linhas relevantes (pacotes instalados) e ignora linhas vazias ou ruído
        $installedPackages = $wingetOutput -split "`r`n" | Where-Object { $_ -match '\S' -and $_ -notmatch "Failed when searching source; results will not be included" } | Select-Object -First 10
        
        if ($installedPackages.Count -eq 0) {
            Log-Message "Nenhum pacote instalado encontrado pelo Winget." "INFO"
        } else {
            foreach ($package in $installedPackages) {
                if ($package -notmatch "msstore" -and $package -notmatch "The `msstore` source requires") {
                    Log-Message "Pacote listado: $package"
                }
            }
        }
    } catch {
        Log-Message "Erro ao listar pacotes instalados: $_" "ERROR"
    }
}

# =============================
# Função: Update-AllPackages
# Descrição: Atualiza todos os pacotes disponíveis e aceita todos os acordos necessários.
# =============================
function Update-AllPackages {
    Log-Message "Atualizando todos os pacotes e aceitando acordos..."
    try {
        # Certifique-se de que processos comuns que podem interferir estão fechados
        Ensure-NoProcessesLocking -processName "AnyDesk"
        Ensure-NoProcessesLocking -processName "OBS Studio"

        # Atualizar todos os pacotes disponíveis
        $packages = winget upgrade --include-unknown --accept-source-agreements --accept-package-agreements --disable-interactivity --verbose | Where-Object { $_.Id -ne $null }

        if ($packages.Count -eq 0) {
            Log-Message "Nenhum pacote a ser atualizado."
        } else {
            foreach ($package in $packages) {
                Log-Message "Atualizando pacote '$($package.Id)' para a versão '$($package.Available)'..."
                winget upgrade --id $package.Id --accept-source-agreements --accept-package-agreements --disable-interactivity --verbose
            }
        }

        Log-Message "Todos os pacotes foram atualizados com sucesso."
    } catch {
        Log-Message "Falha ao atualizar pacotes. Erro: $_" "ERROR"
        throw
    }
}

# =============================
# Função: Clear-WingetCache
# Descrição: Limpa o cache do Winget, se existente.
# =============================
function Clear-WingetCache {
    Log-Message "Verificando o cache do Winget..."
    $cachePath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalCache\Local\Microsoft\WinGet"
    if (Test-Path $cachePath) {
        Log-Message "Cache do Winget encontrado. Limpando..."
        Remove-Item $cachePath -Recurse -Force
        Log-Message "Cache do Winget limpo com sucesso."
    } else {
        Log-Message "Cache do Winget não encontrado, nada para limpar."
    }
}

# =============================
# Função: Main
# Descrição: Função principal que executa o script.
# =============================
function Main {
    Ensure-LogDirectory

    if (-not (Check-Winget)) {
        return
    }

    # Verificar conectividade de rede antes de continuar
    if (-not (Test-NetworkConnection)) {
        Log-Message "Conectividade de rede falhou. Verifique sua conexão e tente novamente." "ERROR"
        return
    }

    Ensure-Prerequisites
    Clear-WingetCache
    Reset-WingetSources
    Ensure-ReliableRepositories
    Update-Repositories
    List-InstalledPackages
    Update-AllPackages
}

# Executa a função principal
Main
