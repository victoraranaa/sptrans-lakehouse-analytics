# Demonstração Funcional – SPTrans Lakehouse Analytics

Este roteiro descreve a execução completa do pipeline, desde a ingestão dos dados da API Olho Vivo até a consulta dos indicadores analíticos no Trino.

---

## 1. Contexto da Demonstração
Objetivo: comprovar que o pipeline realiza ingestão, processamento e entrega de dados analíticos em near real time.

Ferramentas envolvidas:
- Apache NiFi – coleta e grava os dados brutos e tratados no MinIO.  
- MinIO – armazena as camadas Raw → Bronze → Silver → Gold.  
- Trino + Hive – estrutura e consulta os dados via SQL.  
- PowerShell Script (`refresh_silver.ps1`) – atualiza a tabela física da camada Silver.  

---

## 2. Passo a passo do fluxo

1 – Ingestão (NiFi) - Executar o fluxo `OlhoVivo_Posicoes` no NiFi. Gera arquivos JSON na pasta `lake/raw/sptrans/posicao/`. - print `docs/prints/nifi_flow.png`
2 – Tratamento (NiFi → Bronze) - JSON consolidado é gravado em `lake/bronze/sptrans_posicoes/`. - print `docs/prints/nifi_puts3_config.png`
3 – Atualização da Silver - Rodar o script:  ```powershell powershell -ExecutionPolicy Bypass -File .\scripts\refresh_silver.ps1``` - print `docs/prints/powershell_refresh_silver.png`
4 – Enriquecimento (GTFS) - View `vw_sptrans_posicoes_enriquecida` faz o join com o GTFS (`routes.txt`). - print `docs/prints/trino_silver_enriquecida.png`
5 – Geração das Views Gold - `vw_sptrans_posicoes_ultimas` e `vw_sptrans_linha_resumo` agregam as métricas. - print `docs/prints/trino_gold_resumo.png`
6 – Consulta Analítica (Trino) - Executar as consultas SQL de KPI e demonstrar os resultados em tempo real. - prints dos KPIs

---

## 3. Consultas-chave para demonstração

As consultas a seguir estão em `sql/demo/` (podem ser executadas no Trino CLI):

### 3.1 Últimas posições por linha
sql
SELECT linha_codigo,
       route_long_name,
       COUNT(*) AS qtd_veiculos_atuais
FROM hive.gold.vw_sptrans_posicoes_ultimas
WHERE em_operacao = true
GROUP BY 1, 2
ORDER BY qtd_veiculos_atuais DESC
LIMIT 10;

### 3.2 Disponibilidade por janela de tempo (últimos 60 min)
sql
SELECT route_long_name,
       COUNT(DISTINCT prefixo_veiculo) AS veiculos_distintos,
       MAX(ts_posicao)                 AS ultima_posicao
FROM hive.silver.vw_sptrans_posicoes_enriquecida
WHERE ts_posicao > current_timestamp - interval '60' minute
GROUP BY 1
ORDER BY veiculos_distintos DESC
LIMIT 10;

### 3.3 Verificação de qualidade dos dados
sql
SELECT COUNT(*) AS registros_nulos,
       COUNT(DISTINCT linha_codigo) AS linhas_afetadas
FROM hive.silver.vw_sptrans_posicoes_enriquecida
WHERE latitude IS NULL OR longitude IS NULL;
