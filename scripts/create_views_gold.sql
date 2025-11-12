-- Garante que o schema GOLD existe
CREATE SCHEMA IF NOT EXISTS hive.gold
WITH (location = 's3a://lake/gold/');

-- View Gold: Última posição por veículo
CREATE OR REPLACE VIEW hive.gold.vw_sptrans_posicoes_ultimas AS
WITH ranked AS (
    SELECT
        p.dt_ingest,
        p.ts_posicao,
        p.hora_ref,
        p.linha_codigo,
        p.route_short_name,
        p.route_long_name,
        p.linha_id,
        p.sentido,
        p.terminal_origem,
        p.terminal_destino,
        p.qtde_veiculos,
        p.prefixo_veiculo,
        p.em_operacao,
        p.latitude,
        p.longitude,
        ROW_NUMBER() OVER (
            PARTITION BY p.linha_codigo, p.prefixo_veiculo
            ORDER BY p.ts_posicao DESC
        ) AS rn
    FROM hive.silver.vw_sptrans_posicoes_enriquecida p
)
SELECT
    dt_ingest,
    ts_posicao,
    hora_ref,
    linha_codigo,
    route_short_name,
    route_long_name,
    linha_id,
    sentido,
    terminal_origem,
    terminal_destino,
    qtde_veiculos,
    prefixo_veiculo,
    em_operacao,
    latitude,
    longitude
FROM ranked
WHERE rn = 1;

-- View Gold: Resumo por linha
CREATE OR REPLACE VIEW hive.gold.vw_sptrans_linha_resumo AS
SELECT
    linha_codigo,
    route_long_name,
    terminal_origem,
    terminal_destino,
    COUNT(DISTINCT prefixo_veiculo) AS qtd_veiculos_distintos,
    COUNT(*)                        AS qtd_registros,
    MIN(ts_posicao)                 AS primeira_posicao,
    MAX(ts_posicao)                 AS ultima_posicao
FROM hive.silver.vw_sptrans_posicoes_enriquecida
GROUP BY
    linha_codigo,
    route_long_name,
    terminal_origem,
    terminal_destino;


-- SELECT * FROM hive.gold.vw_sptrans_linha_resumo LIMIT 5;