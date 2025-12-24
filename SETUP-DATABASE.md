# 🗄️ Guia de Configuração do Banco de Dados

Este guia explica como configurar automaticamente o PostgreSQL e Prisma para o projeto.

## 🚀 Configuração Automática (Recomendado)

Execute o script PowerShell que configura tudo automaticamente:

```powershell
# Opção 1: Usando npm/pnpm
pnpm run setup:db
# ou
npm run setup:db

# Opção 2: Executar diretamente
powershell -ExecutionPolicy Bypass -File ./setup-database.ps1
```

### O que o script faz:

1. ✅ Verifica se o PostgreSQL está rodando
2. ✅ Tenta iniciar o serviço PostgreSQL se necessário
3. ✅ Verifica se a porta 5432 está disponível
4. ✅ Cria/atualiza o arquivo `.env` com `DATABASE_URL`
5. ✅ Testa a conexão com o banco de dados
6. ✅ Cria o banco de dados se não existir
7. ✅ Gera o Prisma Client
8. ✅ Aplica o schema do banco de dados

### Parâmetros Opcionais

Você pode personalizar a configuração passando parâmetros:

```powershell
.\setup-database.ps1 -PostgresUser "meu_usuario" -PostgresPassword "minha_senha" -DatabaseName "meu_banco"
```

## 📋 Pré-requisitos

### Opção 1: PostgreSQL Local

1. **Instalar PostgreSQL:**
   - Baixe em: https://www.postgresql.org/download/windows/
   - Durante a instalação, anote a senha do usuário `postgres`

2. **Verificar instalação:**
   ```powershell
   # Verificar se o serviço está rodando
   Get-Service | Where-Object { $_.Name -like "*postgresql*" }
   ```

### Opção 2: Docker (Mais Fácil)

Se você tem Docker instalado:

```powershell
docker run --name postgres-casa-barbeiro `
  -e POSTGRES_PASSWORD=postgres `
  -e POSTGRES_DB=casa_do_barbeiro `
  -p 5432:5432 `
  -d postgres
```

## 🔧 Configuração Manual

Se preferir configurar manualmente:

### 1. Criar arquivo `.env`

Crie um arquivo `.env` na pasta `aparatus` com:

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/casa_do_barbeiro?schema=public"
```

**Ajuste os valores:**
- `postgres` (primeiro): usuário do PostgreSQL
- `postgres` (segundo): senha do PostgreSQL
- `casa_do_barbeiro`: nome do banco de dados
- `localhost:5432`: host e porta

### 2. Criar o banco de dados

```powershell
# Conectar ao PostgreSQL
psql -U postgres

# Criar o banco de dados
CREATE DATABASE casa_do_barbeiro;

# Sair
\q
```

### 3. Aplicar o schema

```powershell
cd aparatus

# Gerar Prisma Client
npx prisma generate

# Aplicar schema (escolha uma opção)
npx prisma db push
# ou
npx prisma migrate dev
```

## 🛠️ Comandos Úteis

```powershell
# Configurar banco de dados
pnpm run setup:db

# Aplicar mudanças no schema
pnpm run db:push

# Criar nova migração
pnpm run db:migrate

# Abrir Prisma Studio (interface visual)
pnpm run db:studio

# Gerar Prisma Client
pnpm run db:generate
```

## ❌ Solução de Problemas

### Erro: "Can't reach database server at localhost:5432"

**Soluções:**

1. **Verificar se PostgreSQL está rodando:**
   ```powershell
   Get-Service | Where-Object { $_.Name -like "*postgresql*" }
   ```

2. **Iniciar o serviço:**
   ```powershell
   Start-Service postgresql-x64-XX  # Substitua XX pela versão
   ```

3. **Verificar porta:**
   ```powershell
   netstat -an | findstr :5432
   ```

4. **Verificar arquivo .env:**
   - Certifique-se de que o arquivo `.env` existe
   - Verifique se `DATABASE_URL` está correta
   - Verifique se não há espaços extras ou aspas incorretas

### Erro: "password authentication failed"

- Verifique se a senha no `.env` está correta
- Tente redefinir a senha do PostgreSQL

### Erro: "database does not exist"

- Execute o script `setup-database.ps1` novamente
- Ou crie o banco manualmente usando `psql`

## 📚 Recursos Adicionais

- [Documentação do Prisma](https://www.prisma.io/docs)
- [Documentação do PostgreSQL](https://www.postgresql.org/docs/)
- [Prisma Studio](https://www.prisma.io/studio) - Interface visual para o banco de dados

## 🎯 Próximos Passos

Após configurar o banco de dados:

1. ✅ Execute `pnpm run dev` para iniciar o servidor
2. ✅ Execute `pnpm run db:studio` para visualizar o banco de dados
3. ✅ Comece a desenvolver sua aplicação!

