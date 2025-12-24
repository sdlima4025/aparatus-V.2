# 🐳 Configuração do PostgreSQL com Docker

Este guia explica como instalar o Docker e configurar o PostgreSQL para o projeto.

## 📥 Passo 1: Instalar Docker Desktop

1. **Baixe o Docker Desktop para Windows:**
   - Acesse: https://www.docker.com/products/docker-desktop/
   - Clique em "Download for Windows"
   - Execute o instalador `Docker Desktop Installer.exe`

2. **Durante a instalação:**
   - ✅ Marque "Use WSL 2 instead of Hyper-V" (se disponível)
   - ✅ Siga as instruções na tela
   - ⚠️ **IMPORTANTE**: Reinicie o computador quando solicitado

3. **Após reiniciar:**
   - Abra o Docker Desktop
   - Aguarde até que o status mostre "Docker Desktop is running"
   - Você verá um ícone de baleia no canto inferior direito da barra de tarefas

## 🚀 Passo 2: Criar Container PostgreSQL

Após o Docker estar rodando, execute no PowerShell:

```powershell
cd aparatus
.\setup-docker.ps1
```

Ou execute manualmente:

```powershell
docker run --name postgres-casa-barbeiro `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=casa_do_barbeiro `
  -p 5432:5432 `
  -d postgres
```

## ✅ Passo 3: Verificar se está rodando

```powershell
docker ps
```

Você deve ver o container `postgres-casa-barbeiro` na lista.

## 🗄️ Passo 4: Aplicar Schema do Prisma

```powershell
cd aparatus
npx prisma db push --accept-data-loss
```

## 🛠️ Comandos Úteis do Docker

```powershell
# Ver containers rodando
docker ps

# Ver todos os containers (incluindo parados)
docker ps -a

# Parar o container
docker stop postgres-casa-barbeiro

# Iniciar o container
docker start postgres-casa-barbeiro

# Ver logs do container
docker logs postgres-casa-barbeiro

# Remover o container (CUIDADO: apaga os dados)
docker rm -f postgres-casa-barbeiro
```

## ❌ Solução de Problemas

### Erro: "Docker daemon is not running"
- Abra o Docker Desktop
- Aguarde até que apareça "Docker Desktop is running"

### Erro: "port 5432 is already allocated"
- Alguém já está usando a porta 5432
- Pare o container: `docker stop postgres-casa-barbeiro`
- Ou use outra porta: `-p 5433:5432` (e atualize o .env)

### Erro: "container name already exists"
- Remova o container antigo: `docker rm -f postgres-casa-barbeiro`
- Execute o comando novamente

## 📚 Próximos Passos

Após configurar:

1. ✅ Execute `npx prisma db push` para criar as tabelas
2. ✅ Execute `pnpm run dev` para iniciar o servidor
3. ✅ Execute `pnpm run db:studio` para visualizar o banco

