# SPTrans Lakehouse Analytics

> Pipeline de dados quase em tempo real para monitoramento da frota de ônibus da cidade de São Paulo.  
> Desenvolvido com ferramentas open-source como NiFi, MinIO, Trino e Hive, no contexto do MBA em Engenharia de Dados.

---

## Objetivo

Demonstrar a aplicação de conceitos de **Engenharia de Dados** em uma arquitetura **Lakehouse**, integrando:

- Dados dinâmicos da API Olho Vivo (SPTrans)  
- Dados estáticos do GTFS (routes.txt)  
- Processamento em camadas **Raw → Bronze → Silver → Gold
- Consultas SQL e indicadores analíticos em tempo quase real 

---

## Arquitetura

Arquitetura Geral disponível em [`docs/Prints/Arquitetura_Projeto.png`](docs/Prints/Arquitetura_Projeto.png).

**Principais componentes:**
1. **Apache NiFi** – ingestão periódica da API e gravação no MinIO  
2. **MinIO** – armazenamento em camadas do Data Lake  
3. **Hive + Trino** – catálogo e engine SQL para consultas
4. **GTFS** - Enriquecimento dos dados com informações estáticas das rotas
5. **Camada de Consumo** – geração de KPIs e visualização analítica

Decisões de arquitetura disponível em:
[`docs/decisoes_arquitetura.md`](docs/decisoes_arquitetura.md).

---

## Indicadores Analíticos (KPIs)

1. **Frota atual por linha** – veículos em operação na última captura  
2. **Linhas com maior número de veículos distintos** – análise histórica  
3. **Evolução temporal da frota** – variação diária e horária  

Scripts SQL disponíveis em [`scripts/queries_kpi.sql`](scripts/queries_kpi.sql).

---

## Automação

Atualização da camada *Silver* via PowerShell:

powershell -ExecutionPolicy Bypass -File .\scripts\refresh_silver.ps1
Esse processo materializa os dados limpos na tabela hive.silver.sptrans_posicoes_flat.

Estrutura do Repositório
sptrans-lakehouse-analytics/
- docker/              # Containers e ambiente local
- docs/                # Diagramas, prints e documentação
- scripts/             # Scripts SQL e PowerShell
- sql/                 # Scripts auxiliares

---

## Documentação Completa

Leia o guia técnico completo com todos os passos, prints e descrições em:
[`docs/passo_a_passo.md`](docs/passo_a_passo.md).

Catálogo de metadados disponível em:
[`docs/Catalogo_metadados.md`](docs/Catalogo_metadados.md).

Decisões de arquitetura disponível em:
[`docs/decisoes_arquitetura.md`](docs/decisoes_arquitetura.md).


## 👨‍💻 Autor

Victor André Andia Arana
MBA em Analytics & Big Data – Engenharia de Dados
