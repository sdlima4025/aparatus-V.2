# Script Simplificado de Configuração do Banco de Dados
# Versão que não requer psql instalado - usa apenas Prisma

param(
    [string]$PostgresUser = "postgres",
    [string]$PostgresPassword = "postgres",
    [string]$DatabaseName = "casa_do_barbeiro",
    [string]$Host = "localhost",
    [int]$Port = 5432
)

$ErrorActionPreference = "Continue"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path $scriptPath ".env"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuração Simplificada do BD" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Write-Step {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor Yellow
}

# 1. Verificar PostgreSQL
Write-Host "[1/4] Verificando PostgreSQL..." -ForegroundColor Cyan

$postgresProcess = Get-Process -Name postgres -ErrorAction SilentlyContinue
$services = Get-Service | Where-Object { $_.Name -like "*postgresql*" }

if ($postgresProcess -or $services) {
    Write-Step "PostgreSQL detectado"
    
    # Tentar iniciar serviço se não estiver rodando
    foreach ($service in $services) {
        if ($service.Status -ne "Running") {
            Write-Info "Iniciando serviço $($service.Name)..."
            try {
                Start-Service -Name $service.Name
                Start-Sleep -Seconds 2
                Write-Step "Serviço iniciado"
            } catch {
                Write-Host "  Aviso: Não foi possível iniciar automaticamente" -ForegroundColor Yellow
            }
        }
    }
} else {
    Write-Host "⚠ PostgreSQL não encontrado!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Opções:" -ForegroundColor Yellow
    Write-Host "  1. Instale PostgreSQL: https://www.postgresql.org/download/windows/" -ForegroundColor White
    Write-Host "  2. Use Docker: docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres" -ForegroundColor White
    Write-Host ""
    Write-Host "Pressione Enter para continuar mesmo assim (o Prisma tentará conectar)..." -ForegroundColor Cyan
    Read-Host
}

# 2. Criar/Atualizar .env
Write-Host ""
Write-Host "[2/4] Configurando arquivo .env..." -ForegroundColor Cyan

$databaseUrl = "postgresql://${PostgresUser}:${PostgresPassword}@${Host}:${Port}/${DatabaseName}?schema=public"

if (Test-Path $envPath) {
    $content = Get-Content $envPath -Raw
    
    if ($content -match "DATABASE_URL") {
        $content = $content -replace 'DATABASE_URL="[^"]*"', "DATABASE_URL=`"$databaseUrl`""
        $content = $content -replace "DATABASE_URL=[^\r\n]*", "DATABASE_URL=`"$databaseUrl`""
        Set-Content -Path $envPath -Value $content -NoNewline
        Write-Step "DATABASE_URL atualizado"
    } else {
        Add-Content -Path $envPath -Value "`nDATABASE_URL=`"$databaseUrl`""
        Write-Step "DATABASE_URL adicionado"
    }
} else {
    Set-Content -Path $envPath -Value "DATABASE_URL=`"$databaseUrl`""
    Write-Step "Arquivo .env criado"
}

# 3. Instalar dependências se necessário
Write-Host ""
Write-Host "[3/4] Verificando dependências..." -ForegroundColor Cyan

Set-Location $scriptPath

if (-not (Test-Path "node_modules")) {
    Write-Info "Instalando dependências..."
    if (Test-Path "pnpm-lock.yaml") {
        pnpm install
    } elseif (Test-Path "yarn.lock") {
        yarn install
    } else {
        npm install
    }
    Write-Step "Dependências instaladas"
} else {
    Write-Step "Dependências já instaladas"
}

# 4. Configurar Prisma
Write-Host ""
Write-Host "[4/4] Configurando Prisma..." -ForegroundColor Cyan

Write-Info "Gerando Prisma Client..."
try {
    npx prisma generate 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Step "Prisma Client gerado"
    }
} catch {
    Write-Host "  Aviso ao gerar Prisma Client" -ForegroundColor Yellow
}

Write-Info "Aplicando schema do banco de dados..."
Write-Host "  (Isso pode criar o banco automaticamente se não existir)" -ForegroundColor Gray

try {
    npx prisma db push --accept-data-loss 2>&1 | ForEach-Object {
        if ($_ -match "error|Error|ERROR") {
            Write-Host $_ -ForegroundColor Red
        } elseif ($_ -match "success|Success|SUCCESS|applied|Applied") {
            Write-Host $_ -ForegroundColor Green
        } else {
            Write-Host $_
        }
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Step "Schema aplicado com sucesso!"
    } else {
        Write-Host ""
        Write-Host "⚠ Houve problemas ao aplicar o schema" -ForegroundColor Yellow
        Write-Host "  Verifique se:" -ForegroundColor Yellow
        Write-Host "    - PostgreSQL está rodando" -ForegroundColor White
        Write-Host "    - Credenciais no .env estão corretas" -ForegroundColor White
        Write-Host "    - O usuário tem permissão para criar bancos" -ForegroundColor White
    }
} catch {
    Write-Host "  Erro: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuração Concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Arquivo .env criado em: $envPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "  pnpm run dev          - Iniciar servidor" -ForegroundColor White
Write-Host "  pnpm run db:studio    - Abrir Prisma Studio" -ForegroundColor White
Write-Host ""

