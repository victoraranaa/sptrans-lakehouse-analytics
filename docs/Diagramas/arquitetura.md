# Arquitetura do Projeto SPTrans Lakehouse

## Visão Geral

O projeto implementa um pipeline de dados quase em tempo real para monitorar a operação da frota de ônibus da cidade de São Paulo, utilizando a API Olho Vivo (SPTrans) e arquivos GTFS como fontes de dados, organizados em um data lakehouse baseado em ferramentas open source.

A arquitetura é composta pelos seguintes componentes principais:

1. Fonte de Dados
   - API Olho Vivo (SPTrans): fornece, em formato JSON, a posição dos veículos em operação.
   - GTFS (General Transit Feed Specification): fornece informações estáticas sobre as linhas (rotas).

2. Ingestão e Orquestração
   - Apache NiFi:
     - Executa requisições periódicas à API Olho Vivo.
     - Salva os arquivos retornados diretamente no MinIO, nas camadas Raw/Bronze.
     - Permite configurar e visualizar o fluxo de forma gráfica.

3. Data Lake (MinIO)
   - Utilizado como armazenamento compatível com S3.
   - Bucket principal: `lake`, organizado em:
     - `raw/`: dados brutos da API.
     - `bronze/`: dados JSON consolidados/organizados.
     - `gtfs/`: arquivos estáticos, como `routes.txt`.
     - `silver/`: dados tratados, prontos para análise.
     - `gold/`: camadas analíticas e views de negócio.

4. Catálogo e Processamento SQL
   - Hive + Trino:
     - Conectados ao MinIO via S3A.
     - Responsáveis por expor os dados como tabelas e views:
       - Bronze: leitura direta dos arquivos JSON.
       - Silver:
         - `vw_sptrans_posicoes_flat`: normalização das posições.
         - `sptrans_posicoes_flat`: tabela física populada por script.
         - `silver_gtfs.routes`: tabela GTFS de rotas.
         - `vw_sptrans_posicoes_enriquecida`: junção entre posições e GTFS.
       - Gold:
         - `vw_sptrans_posicoes_ultimas`: última posição por veículo.
         - `vw_sptrans_linha_resumo`: resumo agregado por linha.

5. Consumo e Análises
   - As views da camada Gold disponibilizam indicadores prontos para:
     - Execução de consultas SQL no Trino.
     - Exportação de dados para ferramentas de visualização (ex.: Power BI).
   - Para fins deste trabalho, os KPIs são demonstrados via consultas SQL e exportações pontuais.

## Fluxo Resumido

1. NiFi consome periodicamente a API Olho Vivo e grava os dados no MinIO (`lake/raw` e `lake/bronze`).
2. As tabelas e views no Trino/Hive leem esses dados e constroem a camada Silver.
3. Um script (`scripts/refresh_silver.ps1`) executa o comando de materialização da Silver física.
4. A camada Silver é enriquecida com dados GTFS (`hive.silver_gtfs.routes`).
5. As views Gold consolidam as informações para consulta e geração de indicadores.
