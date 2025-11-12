# Passo a Passo do Projeto – SPTrans Lakehouse Analytics

## 1. Objetivo Geral

O projeto visa construir um pipeline de dados quase em tempo real para monitorar a frota de ônibus da cidade de São Paulo, consumindo dados da API Olho Vivo (SPTrans) e integrando com informações estáticas do GTFS (General Transit Feed Specification).  
O ambiente foi desenvolvido com ferramentas open-source e tem como foco demonstrar o uso prático de conceitos de Engenharia de Dados, como ingestão, armazenamento em camadas (Raw → Bronze → Silver → Gold) e consultas analíticas.

---

## 2. Arquitetura da Solução

O pipeline foi estruturado em cinco componentes principais, conforme o diagrama de arquitetura (Figura 1):

1. SPTrans - API Olho Vivo** – fornece dados dinâmicos de posição dos ônibus em formato JSON.
2. Apache NiFi** – realiza a ingestão periódica dos dados e grava no MinIO.
3. MinIO (Data Lake)** – armazena os dados nas camadas *raw*, *bronze*, *silver*, *gold*.
4. Hive + Trino** – criam um catálogo de metadados e expõem as tabelas e views SQL.
5. Camada de Consumo** – consultas SQL e visualizações analíticas (CSV/BI).
 
[Arquitetura do Projeto](image.png)
- `docs/Prints/Arquitetura_Projeto.png`  
  *Figura 1 – Arquitetura geral do SPTrans Lakehouse Analytics.*


## 3. Ingestão de Dados (Apache NiFi)

### 3.1 Fluxo de ingestão

O Apache NiFi foi utilizado para orquestrar a coleta dos dados da API Olho Vivo e gravá-los diretamente no MinIO.  
O fluxo principal é composto pelos seguintes processadores:

| `InvokeHTTP` - Chama periodicamente a API SPTrans. - Saída: JSON bruto |
| `UpdateAttribute` - Define metadados (timestamp, path, etc.). |
| `PutS3Object (Raw)` - Grava a resposta bruta no bucket `lake/raw/sptrans/posicao/` - Saída: Arquivo bruto |
| `PutS3Object (Bronze)` - Grava JSON consolidado em `lake/bronze/sptrans_posicoes/` - Saída: Arquivo estruturado |

![Fluxo do NiFi](NiFi_Flow.png)
- `docs/prints/nifi_flow.png` – *Fluxo NiFi completo mostrando os processadores.*

![NiFi - Config do PutS3Object (raw)](NiFi_puts3_config.png)
- `docs/prints/nifi_puts3_config.png` – *Exemplo da Configuração do PutS3Object (raw) apontando para o bucket MinIO.*

### 3.2 Estrutura no MinIO

Após a execução do NiFi, os dados ficam armazenados no bucket `lake`, com a seguinte estrutura:

Lake/
- raw/sptrans/posicao/
- bronze/sptrans_posicoes/
- gtfs/routes/
- silver/
- gold/

Cada pasta representa uma camada lógica de maturidade dos dados:

- Camada: Raw
  Origem: Saída bruta da API Olho Vivo.
  Finalidade: Registro fiel do JSON original para auditoria e reprocessamento.
- Camada: Bronze
  Origem: Saída tratada pelo NiFi.
  Finalidade: Dados consolidados e organizados, ainda em formato semi-estruturado.
- Camada: GTFS
  Origem: Upload manual dos arquivos `routes.txt` (e futuros `stops`, `trips`, etc.).  
  Finalidade: Metadados estáticos sobre as linhas e rotas.
- Camada: Silver  
  Origem: Derivada de consultas SQL (flatten + enriquecimento). 
  Finalidade: Dados limpos e normalizados, prontos para análise.
- Camada: Gold 
  Origem: Views SQL analíticas. 
  Finalidade: Indicadores e KPIs consolidados. |

![Bucket 'Lake'](MiniO_bucket.png)
- `docs/prints/minio_bucket.png` – *Visualização do bucket `lake` no painel do MinIO com as pastas Raw, Bronze, Silver, Gold.*


## 4. Preparação das Camadas Silver e Gold

### 4.1 Criação da camada Silver (tratamento e normalização)

A camada Silver tem como objetivo estruturar os JSONs vindos do Bronze, extraindo cada veículo e seus atributos (linha, horário, latitude, longitude etc.).

O processo foi feito em duas etapas:

1. View lógica de transformação (vw_sptrans_posicoes_flat)** – realiza o *flatten* do JSON.  
2. Tabela física (sptrans_posicoes_flat)** – materializa os dados tratados para otimizar consultas.

Script SQL:
`sql/create_views_silver.sql`

![Tabela Silver](trino_silver_flat.png)
- `docs/prints/trino_silver_flat.png` – *Consulta à view Silver mostrando os dados.*

O carregamento da Silver física é executado via script:

- Powershell
#cd C:\Users\victo\projetos\sptrans-tcc
#powershell -ExecutionPolicy Bypass -File .\scripts\refresh_silver.ps1

O script `refresh_silver.ps1` executa dentro do container do Trino um comando `INSERT INTO ... SELECT FROM vw_sptrans_posicoes_flat`, materializando os dados tratados na tabela física `hive.
silver.sptrans_posicoes_flat`.  

Esse processo simula a automação de um job recorrente (por exemplo, via agendador do sistema operacional ou ferramenta de orquestração), garantindo que a camada Silver esteja sempre atualizada 
a partir dos dados coletados pelo NiFi.

![Refresh Silver](powershell_refresh_silver.png)
- `docs/prints/powershell_refresh_silver.png` – *Execução do script `refresh_silver.ps1` com a mensagem `INSERT: XXXX rows`.*


### 4.2 Integração com GTFS (enriquecimento da Silver)

Para complementar as informações da API Olho Vivo com dados estáticos de referência (nome das linhas, descrição das rotas, tipo de serviço), foi utilizada a base GTFS disponibilizada pela 
SPTrans.

Passos executados:

1. Download do pacote GTFS no portal da SPTrans.
2. Extração do arquivo `routes.txt`.
3. Upload do arquivo para o caminho:

   ```text
   lake/gtfs/routes/routes.txt
