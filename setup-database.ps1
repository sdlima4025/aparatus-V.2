# Script de Configuração Automática do Banco de Dados
# Este script verifica e configura o PostgreSQL e Prisma automaticamente

param(
    [string]$PostgresUser = "postgres",
    [string]$PostgresPassword = "postgres",
    [string]$DatabaseName = "casa_do_barbeiro",
    [string]$Host = "localhost",
    [int]$Port = 5432
)

$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$envPath = Join-Path $scriptPath ".env"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuração do Banco de Dados" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Função para escrever mensagens coloridas
function Write-Step {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Step {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "→ $Message" -ForegroundColor Yellow
}

# 1. Verificar se o PostgreSQL está rodando
Write-Host "[1/6] Verificando se o PostgreSQL está rodando..." -ForegroundColor Cyan

$postgresRunning = $false
$postgresProcess = Get-Process -Name postgres -ErrorAction SilentlyContinue

if ($postgresProcess) {
    Write-Step "PostgreSQL está rodando (PID: $($postgresProcess.Id))"
    $postgresRunning = $true
} else {
    Write-Info "PostgreSQL não está rodando. Tentando iniciar o serviço..."
    
    # Tentar iniciar o serviço PostgreSQL
    $services = Get-Service | Where-Object { $_.Name -like "*postgresql*" }
    
    if ($services) {
        foreach ($service in $services) {
            Write-Info "Encontrado serviço: $($service.Name)"
            if ($service.Status -ne "Running") {
                try {
                    Start-Service -Name $service.Name
                    Write-Step "Serviço $($service.Name) iniciado com sucesso"
                    $postgresRunning = $true
                    Start-Sleep -Seconds 3
                    break
                } catch {
                    Write-Error-Step "Não foi possível iniciar o serviço $($service.Name): $_"
                }
            } else {
                Write-Step "Serviço $($service.Name) já está rodando"
                $postgresRunning = $true
            }
        }
    } else {
        Write-Error-Step "Nenhum serviço PostgreSQL encontrado"
        Write-Host ""
        Write-Host "Opções:" -ForegroundColor Yellow
        Write-Host "  1. Instale o PostgreSQL: https://www.postgresql.org/download/windows/" -ForegroundColor White
        Write-Host "  2. Ou use Docker: docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres" -ForegroundColor White
        Write-Host ""
        exit 1
    }
}

if (-not $postgresRunning) {
    Write-Error-Step "Não foi possível iniciar o PostgreSQL. Por favor, inicie manualmente."
    exit 1
}

# 2. Verificar se a porta 5432 está disponível
Write-Host ""
Write-Host "[2/6] Verificando porta $Port..." -ForegroundColor Cyan

$portInUse = netstat -an | Select-String ":$Port" | Select-String "LISTENING"

if ($portInUse) {
    Write-Step "Porta $Port está em uso (PostgreSQL provavelmente está rodando)"
} else {
    Write-Error-Step "Porta $Port não está em uso. PostgreSQL pode não estar configurado corretamente."
    Write-Host "  Verifique se o PostgreSQL está configurado para usar a porta $Port" -ForegroundColor Yellow
}

# 3. Verificar/criar arquivo .env
Write-Host ""
Write-Host "[3/6] Verificando arquivo .env..." -ForegroundColor Cyan

$databaseUrl = "postgresql://${PostgresUser}:${PostgresPassword}@${Host}:${Port}/${DatabaseName}?schema=public"

if (Test-Path $envPath) {
    Write-Step "Arquivo .env encontrado"
    
    # Verificar se DATABASE_URL existe
    $envContent = Get-Content $envPath -Raw
    if ($envContent -match "DATABASE_URL") {
        Write-Step "DATABASE_URL já existe no arquivo .env"
        # Atualizar DATABASE_URL se necessário
        $envContent = $envContent -replace 'DATABASE_URL="[^"]*"', "DATABASE_URL=`"$databaseUrl`""
        $envContent = $envContent -replace "DATABASE_URL=[^\r\n]*", "DATABASE_URL=`"$databaseUrl`""
        Set-Content -Path $envPath -Value $envContent -NoNewline
        Write-Step "DATABASE_URL atualizado"
    } else {
        Write-Info "Adicionando DATABASE_URL ao arquivo .env"
        Add-Content -Path $envPath -Value "`nDATABASE_URL=`"$databaseUrl`""
        Write-Step "DATABASE_URL adicionado"
    }
} else {
    Write-Info "Criando arquivo .env..."
    Set-Content -Path $envPath -Value "DATABASE_URL=`"$databaseUrl`""
    Write-Step "Arquivo .env criado com sucesso"
}

# 4. Testar conexão com o banco de dados
Write-Host ""
Write-Host "[4/6] Testando conexão com o banco de dados..." -ForegroundColor Cyan

# Verificar se psql está disponível
$psqlPath = Get-Command psql -ErrorAction SilentlyContinue

if ($psqlPath) {
    Write-Info "Testando conexão usando psql..."
    
    # Testar conexão ao PostgreSQL (sem banco específico)
    $env:PGPASSWORD = $PostgresPassword
    $testConnection = & psql -h $Host -p $Port -U $PostgresUser -d postgres -c "SELECT version();" 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Step "Conexão com PostgreSQL estabelecida com sucesso"
    } else {
        Write-Error-Step "Falha ao conectar ao PostgreSQL"
        Write-Host "  Erro: $testConnection" -ForegroundColor Red
        Write-Host ""
        Write-Host "Verifique:" -ForegroundColor Yellow
        Write-Host "  - Usuário e senha estão corretos?" -ForegroundColor White
        Write-Host "  - PostgreSQL está configurado para aceitar conexões locais?" -ForegroundColor White
        Write-Host "  - pg_hba.conf permite conexões do localhost?" -ForegroundColor White
        exit 1
    }
} else {
    Write-Info "psql não encontrado. Pulando teste de conexão direta."
    Write-Info "O Prisma testará a conexão na próxima etapa."
}

# 5. Criar banco de dados se não existir
Write-Host ""
Write-Host "[5/6] Verificando se o banco de dados existe..." -ForegroundColor Cyan

if ($psqlPath) {
    $env:PGPASSWORD = $PostgresPassword
    $dbExists = & psql -h $Host -p $Port -U $PostgresUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DatabaseName'" 2>&1
    
    if ($dbExists -match "1") {
        Write-Step "Banco de dados '$DatabaseName' já existe"
    } else {
        Write-Info "Criando banco de dados '$DatabaseName'..."
        $createDb = & psql -h $Host -p $Port -U $PostgresUser -d postgres -c "CREATE DATABASE $DatabaseName;" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Step "Banco de dados '$DatabaseName' criado com sucesso"
        } else {
            Write-Error-Step "Falha ao criar banco de dados: $createDb"
            Write-Host "  Tentando continuar... O Prisma pode criar o banco automaticamente." -ForegroundColor Yellow
        }
    }
} else {
    Write-Info "psql não encontrado. O Prisma tentará criar o banco se necessário."
}

# 6. Executar migrações do Prisma
Write-Host ""
Write-Host "[6/6] Configurando Prisma..." -ForegroundColor Cyan

Set-Location $scriptPath

# Verificar se node_modules existe
if (-not (Test-Path "node_modules")) {
    Write-Info "Instalando dependências..."
    if (Test-Path "pnpm-lock.yaml") {
        pnpm install
    } elseif (Test-Path "yarn.lock") {
        yarn install
    } else {
        npm install
    }
}

# Gerar Prisma Client
Write-Info "Gerando Prisma Client..."
try {
    npx prisma generate
    Write-Step "Prisma Client gerado com sucesso"
} catch {
    Write-Error-Step "Erro ao gerar Prisma Client: $_"
}

# Executar migrações ou push
Write-Info "Aplicando schema do banco de dados..."
try {
    # Tentar db push primeiro (mais simples para desenvolvimento)
    npx prisma db push --accept-data-loss
    Write-Step "Schema do banco de dados aplicado com sucesso"
} catch {
    Write-Error-Step "Erro ao aplicar schema: $_"
    Write-Info "Tentando criar migração..."
    try {
        npx prisma migrate dev --name init
        Write-Step "Migração criada e aplicada com sucesso"
    } catch {
        Write-Error-Step "Erro ao criar migração: $_"
        Write-Host ""
        Write-Host "Tente executar manualmente:" -ForegroundColor Yellow
        Write-Host "  npx prisma db push" -ForegroundColor White
        Write-Host "  ou" -ForegroundColor White
        Write-Host "  npx prisma migrate dev" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Configuração Concluída!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor Yellow
Write-Host "  1. Verifique o arquivo .env em: $envPath" -ForegroundColor White
Write-Host "  2. Execute 'npm run dev' para iniciar o servidor" -ForegroundColor White
Write-Host "  3. Use 'npx prisma studio' para visualizar o banco de dados" -ForegroundColor White
Write-Host ""

