# Caminho da pasta docker do projeto
$projectPath = "C:\Users\victo\projetos\sptrans-tcc\docker"

# Vai até a pasta
Set-Location $projectPath

# Executa o comando no container do Trino
docker compose exec trino trino --user admin --execute `
"INSERT INTO hive.silver.sptrans_posicoes_flat
SELECT
    cast(current_timestamp as timestamp) AS dt_ingest,
    hora_ref,
    linha_codigo,
    linha_id,
    sentido,
    terminal_origem,
    terminal_destino,
    qtde_veiculos,
    prefixo_veiculo,
    em_operacao,
    ts_posicao,
    latitude,
    longitude
FROM hive.silver.vw_sptrans_posicoes_flat"