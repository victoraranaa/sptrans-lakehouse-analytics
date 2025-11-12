# Catálogo de Metadados — SPTrans Lakehouse Analytics

## Estrutura do Data Lake (MinIO)

lake/
- raw/
    - sptrans/posicao/ → dados brutos da API
- bronze/
    - sptrans_posicoes/ → dados tratados no NiFi
- silver/
    - vw_sptrans_posicoes_enriquecida/ → dados enriquecidos com GTFS
- gold/
    - vw_sptrans_posicoes_ultimas/ → última posição de cada veículo
    - vw_sptrans_linha_resumo/ → resumo histórico por linha


---

## Tabelas e Views

### Camada Bronze — `sptrans_posicoes`
| Campo            | Tipo        | Descrição                              |
|------------------|-------------|----------------------------------------|
| dt_ingest        | timestamp   | Momento da ingestão                    |
| hora_ref         | string      | Horário de referência da API           |
| linha_codigo     | string      | Código da linha (ex: 4310-10)          |
| linha_id         | int         | Identificador da linha                 |
| sentido          | int         | 1 ou 2                                 |
| terminal_origem  | string      | Terminal inicial                       |
| terminal_destino | string      | Terminal final                         |
| qtde_veiculos    | int         | Quantidade de veículos ativos          |
| veiculos         | array(json) | Lista de veículos com posição e status |

---

### Camada Silver — `vw_sptrans_posicoes_enriquecida`
| Campo           | Tipo      | Descrição                              |
|-----------------|-----------|----------------------------------------|
| dt_ingest       | timestamp | Momento da carga                       |
| ts_posicao      | timestamp | Data/hora da posição                   |
| linha_codigo    | string    | Código da linha                        |
| route_long_name | string    | Nome completo da linha (GTFS)          |
| prefixo_veiculo | string    | Prefixo do veículo                     |
| em_operacao     | boolean   | Indica se o veículo está em circulação |
| latitude        | double    | Coordenada Y                           |
| longitude       | double    | Coordenada X                           |

---

### Camada Gold — Views analíticas
| View                          | Finalidade                                           | Fonte  |
|-------------------------------|------------------------------------------------------|--------|
| `vw_sptrans_posicoes_ultimas` | Última posição de cada veículo ativo                 | Silver |
| `vw_sptrans_linha_resumo`     | Quantidade de veículos distintos e período observado | Silver |

---

## KPIs
| KPI                                | Descrição                                | Fonte  |
|------------------------------------|------------------------------------------|--------|
| Frota atual por linha              | Veículos ativos por linha                | Gold   |
| Linhas com mais veículos distintos | Total de veículos únicos observados      | Gold   |
| Evolução temporal                  | Quantidade de veículos ao longo do tempo | Silver |


