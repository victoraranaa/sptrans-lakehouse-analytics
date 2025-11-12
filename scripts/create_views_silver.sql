-- View Silver: Flatten da Bronze
CREATE OR REPLACE VIEW hive.silver.vw_sptrans_posicoes_flat AS
WITH bronzes AS (
    SELECT
        json_parse(json) AS j
    FROM hive.bronze.sptrans_posicoes
),
linhas AS (
    SELECT
        json_extract_scalar(j, '$.hr') AS hora_ref,
        linha
    FROM bronzes
    CROSS JOIN UNNEST(
        CAST(json_extract(j, '$.l') AS array(json))
    ) AS t(linha)
),
veiculos AS (
    SELECT
        hora_ref,
        json_extract_scalar(linha, '$.c')      AS linha_codigo,
        CAST(json_extract_scalar(linha, '$.cl') AS integer) AS linha_id,
        CAST(json_extract_scalar(linha, '$.sl') AS integer) AS sentido,
        json_extract_scalar(linha, '$.lt0')    AS terminal_origem,
        json_extract_scalar(linha, '$.lt1')    AS terminal_destino,
        CAST(json_extract_scalar(linha, '$.qv') AS integer) AS qtde_veiculos,
        v AS veh
    FROM linhas
    CROSS JOIN UNNEST(
        CAST(json_extract(linha, '$.vs') AS array(json))
    ) AS u(v)
)
SELECT
    CAST(current_timestamp AS timestamp)                                      AS dt_ingest,
    hora_ref,
    linha_codigo,
    linha_id,
    sentido,
    terminal_origem,
    terminal_destino,
    qtde_veiculos,
    CAST(json_extract_scalar(veh, '$.p')  AS integer)                         AS prefixo_veiculo,
    CAST(json_extract_scalar(veh, '$.a')  AS boolean)                         AS em_operacao,
    CAST(from_iso8601_timestamp(json_extract_scalar(veh, '$.ta')) AS timestamp) AS ts_posicao,
    CAST(json_extract_scalar(veh, '$.py') AS double)                          AS latitude,
    CAST(json_extract_scalar(veh, '$.px') AS double)                          AS longitude
FROM veiculos;

-- Validação:
-- SELECT * FROM hive.silver.vw_sptrans_posicoes_flat LIMIT 5;



-- View Silver: Enriquecida com GTFS
CREATE OR REPLACE VIEW hive.silver.vw_sptrans_posicoes_enriquecida AS
SELECT
    p.dt_ingest,
    p.ts_posicao,
    p.hora_ref,
    p.linha_codigo,
    r.route_short_name,
    r.route_long_name,
    p.linha_id,
    p.sentido,
    p.terminal_origem,
    p.terminal_destino,
    p.qtde_veiculos,
    p.prefixo_veiculo,
    p.em_operacao,
    p.latitude,
    p.longitude
FROM hive.silver.sptrans_posicoes_flat p
LEFT JOIN hive.silver_gtfs.routes r
    ON r.route_short_name = p.linha_codigo;

-- Validação:
-- SELECT * FROM hive.silver_gtfs.routes LIMIT 5;
-- SELECT * FROM hive.silver.vw_sptrans_posicoes_enriquecida LIMIT 5;