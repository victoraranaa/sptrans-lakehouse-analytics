# Decisões de Arquitetura — SPTrans Lakehouse Analytics

## Visão Geral
O projeto constrói um pipeline simples em near real time (a cada 120seg) para acompanhar a frota de ônibus de São Paulo usando a API Olho Vivo (SPTrans).  
Os dados são salvos em formato JSON no MinIO, e as consultas são feitas via Trino/Hive.

---

## Ferramentas Utilizadas

- Apache NiFi:
    -Faz a ingestão e salva os dados no MinIO 
    -Ferramenta visual, fácil de usar e sem necessidade de programação 
    -Pode ficar confuso se o fluxo tiver muitos blocos
- MinIO (Data Lake):
    -Guarda os arquivos das camadas Raw, Bronze, Silver e Gold 
    -Simula o Amazon S3 localmente, fácil de rodar em Docker 
    -Armazenamento local precisa de backup manual
- Formato JSON:
    -Armazena todos os dados (em todas as camadas) 
    -Compatível com NiFi e fácil de consultar no Trino
    -Ocupa mais espaço que formatos binários (como Parquet)
- Hive + Trino:
    -Consulta os dados via SQL
    -Necessário criar as tabelas manualmente apontando para os diretórios JSON
- GTFS (dados estáticos):
    -Complementa os dados do Olho Vivo com informações de rotas 
    -Fornece nomes e descrições das linhas 
    -Precisa atualização manual quando há nova versão

---

## Organização em Camadas

| Camada | Descrição | Exemplo de pasta |
|--------|------------|------------------|
- Raw - Dados brutos da API Olho Vivo - `lake/raw/sptrans/posicao/`
- Bronze - Dados limpos e estruturados pelo NiFi - `lake/bronze/sptrans_posicoes/`
- Silver - Dados enriquecidos com GTFS - `lake/silver/vw_sptrans_posicoes_enriquecida/`
- Gold - Views analíticas e KPIs - `lake/gold/vw_sptrans_posicoes_ultimas/`

---

## Boas Práticas Adotadas
- Simplicidade: evitar ferramentas complexas (sem Airflow ou Spark).  
- Padronização: tudo em JSON e organizado por camadas.  
- Backup: cópia do bucket `lake/` (Componente PutFile do NiFi exportando dados para armazenamento local).  
- Documentação: scripts SQL e prints salvos em `docs/`.

---

## Próximos Passos Futuros
- Migrar de JSON para Parquet (menor e mais rápido).  
- Automatizar o refresh da camada Silver com agendamento.  
- Criar validações de dados no NiFi (ex.: latitude fora da cidade).  
- Integrar o Trino com uma ferramenta de visualização (ex.: Power BI ou Superset).
