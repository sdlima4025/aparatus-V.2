# Script para configurar PostgreSQL com Docker

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuracao PostgreSQL com Docker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se Docker esta instalado
Write-Host "[1/4] Verificando Docker..." -ForegroundColor Cyan

try {
    $dockerVersion = docker --version 2>&1
    Write-Host "✓ Docker encontrado: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker nao encontrado!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor, instale o Docker Desktop:" -ForegroundColor Yellow
    Write-Host "  https://www.docker.com/products/docker-desktop/" -ForegroundColor White
    Write-Host ""
    Write-Host "Apos instalar, reinicie o computador e execute este script novamente." -ForegroundColor Yellow
    exit 1
}

# Verificar se Docker esta rodando
Write-Host ""
Write-Host "[2/4] Verificando se Docker esta rodando..." -ForegroundColor Cyan

try {
    docker ps 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker esta rodando" -ForegroundColor Green
    } else {
        throw "Docker nao esta respondendo"
    }
} catch {
    Write-Host "✗ Docker nao esta rodando!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Por favor:" -ForegroundColor Yellow
    Write-Host "  1. Abra o Docker Desktop" -ForegroundColor White
    Write-Host "  2. Aguarde ate que apareca 'Docker Desktop is running'" -ForegroundColor White
    Write-Host "  3. Execute este script novamente" -ForegroundColor White
    exit 1
}

# Verificar se container ja existe
Write-Host ""
Write-Host "[3/4] Verificando container existente..." -ForegroundColor Cyan

$containerExists = docker ps -a --filter "name=postgres-casa-barbeiro" --format "{{.Names}}" 2>&1

if ($containerExists -eq "postgres-casa-barbeiro") {
    Write-Host "→ Container 'postgres-casa-barbeiro' ja existe" -ForegroundColor Yellow
    
    $containerRunning = docker ps --filter "name=postgres-casa-barbeiro" --format "{{.Names}}" 2>&1
    
    if ($containerRunning -eq "postgres-casa-barbeiro") {
        Write-Host "✓ Container ja esta rodando" -ForegroundColor Green
    } else {
        Write-Host "→ Iniciando container..." -ForegroundColor Yellow
        docker start postgres-casa-barbeiro 2>&1 | Out-Null
        Start-Sleep -Seconds 2
        Write-Host "✓ Container iniciado" -ForegroundColor Green
    }
} else {
    Write-Host "→ Criando novo container PostgreSQL..." -ForegroundColor Yellow
    
    docker run --name postgres-casa-barbeiro `
        -e POSTGRES_PASSWORD=postgres `
        -e POSTGRES_DB=casa_do_barbeiro `
        -p 5432:5432 `
        -d postgres 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Container criado e iniciado com sucesso" -ForegroundColor Green
        Write-Host "  Aguardando PostgreSQL inicializar..." -ForegroundColor Gray
        Start-Sleep -Seconds 5
    } else {
        Write-Host "✗ Erro ao criar container" -ForegroundColor Red
        exit 1
    }
}

# Verificar se esta rodando
Write-Host ""
Write-Host "[4/4] Verificando status do container..." -ForegroundColor Cyan

$containerStatus = docker ps --filter "name=postgres-casa-barbeiro" --format "{{.Status}}" 2>&1

if ($containerStatus) {
    Write-Host "✓ Container rodando: $containerStatus" -ForegroundColor Green
} else {
    Write-Host "✗ Container nao esta rodando" -ForegroundColor Red
    Write-Host "  Verifique os logs: docker logs postgres-casa-barbeiro" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuracao Concluida!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Container PostgreSQL esta rodando em:" -ForegroundColor Yellow
Write-Host "  Host: localhost" -ForegroundColor White
Write-Host "  Porta: 5432" -ForegroundColor White
Write-Host "  Database: casa_do_barbeiro" -ForegroundColor White
Write-Host "  Usuario: postgres" -ForegroundColor White
Write-Host "  Senha: postgres" -ForegroundColor White
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Yellow
Write-Host "  npx prisma db push --accept-data-loss" -ForegroundColor White
Write-Host "  pnpm run dev" -ForegroundColor White
Write-Host ""

