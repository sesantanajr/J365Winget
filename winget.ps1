# Jornada 365 | Sua jornada começa aqui
# https://jornada365.cloud

<#
.SYNOPSIS
    Script para instalar/desinstalar o 7-Zip usando winget via Microsoft Intune.
.DESCRIPTION
    Este script verifica se o winget está instalado, instala-o se necessário,
    e então instala ou desinstala o 7-Zip silenciosamente.
.PARAMETER Action
    Ação a ser executada: 'Install' ou 'Uninstall'
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("Install", "Uninstall")]
    [string]$Action
)

# Definir o ID do pacote para 7-Zip
$PackageId = "Piriform.CCleaner"

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

function Install-Winget {
    try {
        # Verificar se o App Installer está instalado
        $appInstaller = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller"
        if (-not $appInstaller) {
            Write-Host "Instalando App Installer (winget)..."
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
        }
        
        # Verificar se o winget está disponível
        winget --version
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Winget está instalado e funcionando corretamente."
        } else {
            throw "Falha ao verificar a versão do winget."
        }
    } catch {
        Write-Error "Falha ao instalar ou verificar o winget: $($_.Exception.Message)"
        exit 1
    }
}

function Install-Package {
    param ([string]$PackageId)
    try {
        Write-Host "Instalando $PackageId..."
        winget install $PackageId --silent --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$PackageId instalado com sucesso."
        } else {
            throw "Falha ao instalar $PackageId."
        }
    } catch {
        Write-Error "Erro durante a instalação de ${PackageId}: $($_.Exception.Message)"
        exit 1
    }
}

function Uninstall-Package {
    param ([string]$PackageId)
    try {
        Write-Host "Desinstalando $PackageId..."
        winget uninstall $PackageId --silent
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$PackageId desinstalado com sucesso."
        } else {
            throw "Falha ao desinstalar $PackageId."
        }
    } catch {
        Write-Error "Erro durante a desinstalação de ${PackageId}: $($_.Exception.Message)"
        exit 1
    }
}

# Verificar se está rodando como administrador
if (-not (Test-Admin)) {
    Write-Error "Este script precisa ser executado como Administrador."
    exit 1
}

# Instalar winget se necessário
Install-Winget

# Executar a ação especificada
switch ($Action) {
    "Install" { Install-Package -PackageId $PackageId }
    "Uninstall" { Uninstall-Package -PackageId $PackageId }
}

# Para mais informações e guias detalhados, acesse: https://jornada365.cloud
