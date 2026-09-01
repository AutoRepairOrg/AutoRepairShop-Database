# 🗄️ AutoRepairShop-Database

Infraestrutura do banco de dados gerenciado (RDS SQL Server) para o sistema de gestão de oficina mecânica.
---

## 📖 Sobre

Este repositório contém a infraestrutura como código (IaC) para provisionamento do banco de dados gerenciado na AWS usando **RDS SQL Server Express**.

O banco de dados armazena:
- 👥 Clientes e administradores
- 🚗 Veículos
- 🔧 Serviços e suprimentos
- 📋 Ordens de serviço

---

## 🛠️ Tecnologias

- **Terraform** 1.6.6 - Infraestrutura como código
- **AWS RDS** - SQL Server Express 15.00
- **AWS Secrets Manager** - Gerenciamento de credenciais
- **GitHub Actions** - CI/CD automático
- **Entity Framework Core** - Migrations (via API)

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────┐
│         AutoRepairShop-Database         │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐ │
│  │    RDS SQL Server Express         │ │
│  │  - Instance: db.t3.micro          │ │
│  │  - Storage: 20 GB (gp2)           │ │
│  │  - Multi-AZ: No                   │ │
│  │  - Backup: 7 dias                 │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │    AWS Secrets Manager            │ │
│  │  - RDS Credentials                │ │
│  │  - Connection String              │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │    Security Group                 │ │
│  │  - Ingress: 1433 (VPC only)       │ │
│  └───────────────────────────────────┘ │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │    DB Subnet Group                │ │
│  │  - Private Subnets (Multi-AZ)     │ │
│  └───────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

---

## ✅ Pré-requisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.6
- [AWS CLI](https://aws.amazon.com/cli/) configurado
- Credenciais AWS com permissões:
  - `rds:*`
  - `ec2:*` (para VPC/Subnets/Security Groups)
  - `secretsmanager:*`

---

## 🚀 Instalação e Deploy

### **Método 1: Via CI/CD (Recomendado)**

1. **Configure os secrets no GitHub:**
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`

2. **Faça um commit em `infra/`:**
   ```bash
   git add infra/main.tf
   git commit -m "feat: atualizar configuração do RDS"
   git push origin master
   ```

3. **O workflow CD irá:**
   - ✅ Validar Terraform
   - ✅ Provisionar RDS
   - ✅ Criar Security Group
   - ✅ Configurar DB Subnet Group
   - ✅ Salvar credenciais no Secrets Manager

---

### **Método 2: Deploy Manual**

```bash
# 1. Clone o repositório
git clone https://github.com/AutoRepairOrg/AutoRepairShop-Database.git
cd AutoRepairShop-Database/infra

# 2. Inicialize o Terraform
terraform init

# 3. Visualize o plano
terraform plan

# 4. Aplique as mudanças
terraform apply

# 5. Obtenha o endpoint do RDS
terraform output rds_endpoint
```

---

## 🔄 CI/CD

### **Workflows**

#### **CI - Validação (Pull Requests)**
```yaml
Trigger: Pull Request → master
Jobs:
  - Terraform Format Check
  - Terraform Init
  - Terraform Validate
```

#### **CD - Deploy (Push to master)**
```yaml
Trigger: Push → master
Jobs:
  - Terraform Init
  - Terraform Plan
  - Terraform Apply
  - Output RDS Endpoint
```

### **Branch Protection**

- ✅ Pull Requests obrigatórios
- ✅ CI deve passar antes do merge
- ✅ Deploy automático após merge

---

## 📁 Estrutura do Projeto

```
AutoRepairShop-Database/
├── .github/
│   └── workflows/
│       ├── ci.yml              # Validação em PRs
│       └── cd.yml              # Deploy em master
├── infra/
│   ├── main.tf                 # RDS + Security Group
│   ├── outputs.tf              # Outputs (endpoint, etc)
│   ├── variables.tf            # Variáveis do Terraform
│   ├── providers.tf            # Providers AWS
│   └── .terraform.lock.hcl     # Lock de versões
├── k8s/
│   ├── namespace.yaml          # Namespace Kubernetes
│   └── (manifestos antigos)    # Removidos após migração
├── migrations/                  # (Gerenciado pela API)
└── README.md                   # Este arquivo
```

---

## 🔐 Variáveis de Ambiente

### **RDS Connection String**

Após o deploy, o endpoint estará disponível em:

```bash
# Via Terraform Output
terraform output rds_endpoint

# Via AWS Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id autorepair/rds-credentials \
  --query SecretString --output text
```

### **Connection String Format**

```
Server=<RDS_ENDPOINT>,1433;
Database=AutoRepairShop;
User Id=admin;
Password=<PASSWORD>;
TrustServerCertificate=True;
```

---

## 🗃️ Migrations

As migrations são gerenciadas pelo **Entity Framework Core** no repositório [AutoRepairShop-Api](https://github.com/AutoRepairOrg/AutoRepairShop-Api).

### **Aplicar Migrations**

```bash
# Via API (automático no startup)
# As migrations rodam automaticamente quando a API inicia

# Ou manualmente
cd AutoRepairShop-Api/src/AutoRepairShop.Infrastructure
dotnet ef database update --project ../AutoRepairShop.Api
```

---

## 📊 Diagrama ER

```
┌─────────────┐       ┌─────────────┐
│   Admins    │       │  Customers  │
├─────────────┤       ├─────────────┤
│ Id (PK)     │       │ Id (PK)     │
│ Username    │       │ Username    │
│ Password    │       │ Password    │
│ Name        │       │ Document    │
│ Department  │       │ Phone       │
└─────────────┘       └─────────────┘
                             │
                             │ 1:N
                             ▼
                      ┌─────────────┐
                      │  Vehicles   │
                      ├─────────────┤
                      │ Id (PK)     │
                      │ CustomerId  │◄────┐
                      │ Plate       │     │
                      │ Brand       │     │
                      │ Model       │     │
                      │ Year        │     │
                      └─────────────┘     │
                             │            │
                             │ 1:N        │
                             ▼            │
                   ┌──────────────────┐   │
                   │ ServiceOrders    │   │
                   ├──────────────────┤   │
                   │ Id (PK)          │   │
                   │ CustomerId       │───┘
                   │ VehicleId        │
                   │ Status           │
                   │ CreatedAt        │
                   │ StartedAt        │
                   │ FinishedAt       │
                   └──────────────────┘
                      │            │
                      │ N:M        │ N:M
                      ▼            ▼
            ┌─────────────┐  ┌─────────────┐
            │  Services   │  │  Supplies   │
            ├─────────────┤  ├─────────────┤
            │ Id (PK)     │  │ Id (PK)     │
            │ Name        │  │ Name        │
            │ Description │  │ Price       │
            │ Price       │  │ Stock       │
            └─────────────┘  └─────────────┘
```

---

## 📝 Justificativa da Escolha - RDS SQL Server

### **Por que RDS?**

✅ **Gerenciamento Automático:**
- Backups automáticos (7 dias de retenção)
- Patches de segurança aplicados automaticamente
- Monitoramento integrado com CloudWatch

✅ **Alta Disponibilidade:**
- Multi-AZ disponível (quando necessário)
- Failover automático
- Snapshots automatizados

✅ **Escalabilidade:**
- Escala vertical sem downtime (change instance type)
- Read replicas disponíveis
- Storage auto-scaling

✅ **Segurança:**
- Criptografia em repouso (KMS)
- Criptografia em trânsito (SSL/TLS)
- Integração com Secrets Manager
- VPC isolation (subnets privadas)

### **Por que SQL Server?**

✅ **Compatibilidade:**
- Aplicação .NET Core já utiliza SQL Server
- Entity Framework Core otimizado para SQL Server
- Migrations existentes compatíveis

✅ **Familiaridade da Equipe:**
- Conhecimento prévio em T-SQL
- Ferramentas de desenvolvimento (SSMS, Azure Data Studio)

✅ **Express Edition:**
- Custo-benefício para MVP
- Até 10 GB de storage por database
- Suficiente para fase inicial

---

## 📄 Licença

Este projeto faz parte do **Tech Challenge - Fase 3** da FIAP.

**Autores:**
- Dhiulia da Silva
- Mateus Pinheiro

---

## 🔗 Links Relacionados

- [AutoRepairShop-Api](https://github.com/AutoRepairOrg/AutoRepairShop-Api) - Aplicação principal
- [AutoRepairShop-Kubernetes](https://github.com/AutoRepairOrg/AutoRepairShop-Kubernetes) - Infraestrutura K8s
- [AutoRepairShop-Lambda](https://github.com/AutoRepairOrg/AutoRepairShop-Lambda) - Autenticação serverless
