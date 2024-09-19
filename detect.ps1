# Jornada 365 | Sua jornada começa aqui
# https://jornada365.cloud

<#
.SYNOPSIS
    Script de detecção para verificar a instalação de um pacote específico via winget.
.DESCRIPTION
    Este script verifica se um pacote específico está instalado usando o winget.
    Retorna 0 se o pacote estiver instalado, 1 se não estiver instalado,
    e 2 se ocorrer um erro durante a verificação.
#>

# Defina aqui o ID do pacote winget que você deseja verificar
$PackageId = "Piriform.CCleaner"

try {
    # Verificar se o winget está disponível
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "Winget não está instalado ou não está disponível."
        exit 1
    }

    # Verificar se o pacote está instalado
    $installedPackages = winget list --id $PackageId --accept-source-agreements | Out-String
    if ($installedPackages -match $PackageId) {
        Write-Host "O pacote $PackageId está instalado."
        exit 0  # Pacote encontrado
    } else {
        Write-Host "O pacote $PackageId não está instalado."
        exit 1  # Pacote não encontrado
    }
} catch {
    Write-Error "Erro ao verificar a instalação do pacote ${PackageId}: $($_.Exception.Message)"
    exit 2  # Erro na verificação
}

# Para mais informações e guias detalhados, acesse: https://jornada365.cloud
