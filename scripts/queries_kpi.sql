-- 1️) Frota atual por linha (view Gold - últimas posições)
SELECT
    linha_codigo,
    route_long_name,
    COUNT(*) AS qtd_veiculos_atuais
FROM hive.gold.vw_sptrans_posicoes_ultimas
WHERE em_operacao = true
GROUP BY 1, 2
ORDER BY qtd_veiculos_atuais DESC
LIMIT 20;

-- 2️) Linhas com maior quantidade de veículos distintos (resumo histórico)
SELECT
    linha_codigo,
    route_long_name,
    qtd_veiculos_distintos,
    qtd_registros,
    primeira_posicao,
    ultima_posicao
FROM hive.gold.vw_sptrans_linha_resumo
ORDER BY qtd_veiculos_distintos DESC
LIMIT 20;

-- 3️) Evolução temporal de veículos distintos (Silver)
SELECT
    date(ts_posicao) AS dt_ref,
    hora_ref,
    COUNT(DISTINCT prefixo_veiculo) AS qtd_veiculos_distintos
FROM hive.silver.vw_sptrans_posicoes_enriquecida
GROUP BY 1, 2
ORDER BY 1, 2;