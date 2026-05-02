-- ============================================================
-- PROJETO 04 — MARKETING ANALYTICS / PERFORMANCE DE CAMPANHAS
-- ============================================================

CREATE TABLE IF NOT EXISTS campanhas (
    campanha_id      SERIAL        PRIMARY KEY,
    nome_campanha    VARCHAR(100)  NOT NULL,
    canal            VARCHAR(50)   NOT NULL,
    data_inicio      DATE          NOT NULL,
    data_fim         DATE,
    investimento     DECIMAL(12,2) NOT NULL,
    impressoes       INT           DEFAULT 0,
    cliques          INT           DEFAULT 0,
    leads            INT           DEFAULT 0,
    conversoes       INT           DEFAULT 0,
    receita_gerada   DECIMAL(12,2) DEFAULT 0,
    publico_alvo     VARCHAR(80),
    objetivo         VARCHAR(80)
);

-- ROI, CAC e ROAS por campanha
SELECT
    nome_campanha,
    canal,
    investimento,
    impressoes,
    cliques,
    leads,
    conversoes,
    receita_gerada,
    -- Taxas do funil
    ROUND(100.0 * cliques / NULLIF(impressoes, 0), 2)        AS ctr_pct,
    ROUND(100.0 * leads   / NULLIF(cliques, 0), 2)           AS taxa_lead_pct,
    ROUND(100.0 * conversoes / NULLIF(leads, 0), 2)          AS taxa_conversao_pct,
    -- Métricas de custo
    ROUND(investimento / NULLIF(cliques, 0), 2)              AS cpc,
    ROUND(investimento / NULLIF(leads, 0), 2)                AS cpl,
    ROUND(investimento / NULLIF(conversoes, 0), 2)           AS cac,
    -- Retorno
    ROUND(receita_gerada / NULLIF(investimento, 0), 2)       AS roas,
    ROUND((receita_gerada - investimento) / NULLIF(investimento, 0) * 100, 1) AS roi_pct,
    CASE
        WHEN receita_gerada / NULLIF(investimento, 0) >= 3   THEN 'ESCALAR'
        WHEN receita_gerada / NULLIF(investimento, 0) >= 1.5 THEN 'MANTER'
        WHEN receita_gerada / NULLIF(investimento, 0) >= 1   THEN 'OTIMIZAR'
        ELSE 'PAUSAR'
    END                                                       AS recomendacao
FROM campanhas
ORDER BY roi_pct DESC NULLS LAST;

-- Comparativo de performance por canal agregado
SELECT
    canal,
    COUNT(*)                                        AS total_campanhas,
    SUM(investimento)                               AS investimento_total,
    SUM(conversoes)                                 AS conversoes_total,
    SUM(receita_gerada)                             AS receita_total,
    ROUND(AVG(100.0 * cliques / NULLIF(impressoes,0)), 2) AS ctr_medio_pct,
    ROUND(SUM(investimento) / NULLIF(SUM(conversoes),0), 2) AS cac_medio,
    ROUND(SUM(receita_gerada) / NULLIF(SUM(investimento),0), 2) AS roas_medio,
    -- LTV estimado (receita / conversões * fator de recompra = 2.3x)
    ROUND(SUM(receita_gerada) / NULLIF(SUM(conversoes),0) * 2.3, 2) AS ltv_estimado
FROM campanhas
GROUP BY canal
ORDER BY roas_medio DESC NULLS LAST;

-- Top campanhas por receita com CTE e window functions
WITH ranked_campaigns AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY canal ORDER BY receita_gerada DESC) AS rank_canal,
        ROW_NUMBER() OVER (ORDER BY receita_gerada DESC)                    AS rank_geral,
        SUM(receita_gerada) OVER ()                                         AS receita_total_geral,
        SUM(receita_gerada) OVER (PARTITION BY canal)                       AS receita_por_canal
    FROM campanhas
)
SELECT
    rank_geral,
    nome_campanha,
    canal,
    receita_gerada,
    investimento,
    ROUND(100.0 * receita_gerada / receita_total_geral, 1)   AS share_receita_pct,
    ROUND(receita_gerada / NULLIF(investimento,0), 2)        AS roas
FROM ranked_campaigns
WHERE rank_geral <= 10
ORDER BY rank_geral;


-- ============================================================
-- PROJETO 05 — LOGÍSTICA & OPERAÇÕES / SLA DE ENTREGAS
-- ============================================================

CREATE TABLE IF NOT EXISTS entregas (
    entrega_id        SERIAL        PRIMARY KEY,
    pedido_id         INT           NOT NULL,
    data_pedido       DATE          NOT NULL,
    data_despacho     DATE,
    data_entrega_prev DATE          NOT NULL,
    data_entrega_real DATE,
    transportadora    VARCHAR(80)   NOT NULL,
    uf_destino        CHAR(2)       NOT NULL,
    regiao            VARCHAR(30)   NOT NULL,
    prazo_sla_dias    INT           NOT NULL,
    status_entrega    VARCHAR(30)   NOT NULL
        CHECK (status_entrega IN ('Entregue no Prazo','Entregue com Atraso','Em Trânsito','Extraviado')),
    dias_atraso       INT           GENERATED ALWAYS AS (
        CASE WHEN data_entrega_real > data_entrega_prev
             THEN data_entrega_real - data_entrega_prev
             ELSE 0 END
    ) STORED,
    avaliacao_nps     INT           CHECK (avaliacao_nps BETWEEN 0 AND 10)
);

-- KPIs de SLA por transportadora
SELECT
    transportadora,
    COUNT(*)                                                          AS total_entregas,
    SUM(CASE WHEN status_entrega = 'Entregue no Prazo'  THEN 1 ELSE 0 END) AS entregues_prazo,
    SUM(CASE WHEN status_entrega = 'Entregue com Atraso' THEN 1 ELSE 0 END) AS entregues_atraso,
    SUM(CASE WHEN status_entrega = 'Extraviado'          THEN 1 ELSE 0 END) AS extraviados,
    ROUND(
        100.0 * SUM(CASE WHEN status_entrega = 'Entregue no Prazo' THEN 1 ELSE 0 END)
        / COUNT(*), 1
    )                                                                 AS sla_cumprido_pct,
    ROUND(AVG(CASE WHEN dias_atraso > 0 THEN dias_atraso END), 1)     AS atraso_medio_dias,
    ROUND(AVG(avaliacao_nps), 1)                                      AS nps_medio,
    CASE
        WHEN ROUND(100.0 * SUM(CASE WHEN status_entrega = 'Entregue no Prazo' THEN 1 ELSE 0 END)
                   / COUNT(*), 1) >= 92 THEN 'APROVADA'
        WHEN ROUND(100.0 * SUM(CASE WHEN status_entrega = 'Entregue no Prazo' THEN 1 ELSE 0 END)
                   / COUNT(*), 1) >= 80 THEN 'ATENÇÃO'
        ELSE 'REPROVADA'
    END                                                               AS status_contratual
FROM entregas
WHERE status_entrega IN ('Entregue no Prazo', 'Entregue com Atraso', 'Extraviado')
GROUP BY transportadora
ORDER BY sla_cumprido_pct DESC;

-- Análise de SLA por região e UF
SELECT
    regiao,
    uf_destino,
    COUNT(*)                                                          AS total_entregas,
    ROUND(
        100.0 * SUM(CASE WHEN status_entrega = 'Entregue no Prazo' THEN 1 ELSE 0 END)
        / COUNT(*), 1
    )                                                                 AS sla_pct,
    ROUND(AVG(prazo_sla_dias), 1)                                     AS prazo_medio_prometido,
    ROUND(AVG(
        CASE WHEN data_entrega_real IS NOT NULL
             THEN data_entrega_real - data_pedido END
    ), 1)                                                             AS lead_time_real_medio,
    ROUND(AVG(avaliacao_nps), 1)                                      AS nps_regiao
FROM entregas
GROUP BY regiao, uf_destino
ORDER BY regiao, sla_pct;

-- Análise por dia da semana (identificar padrão de atraso)
SELECT
    TO_CHAR(data_pedido, 'Day')                                       AS dia_semana,
    EXTRACT(DOW FROM data_pedido)                                     AS num_dia,
    COUNT(*)                                                          AS total_pedidos,
    ROUND(
        100.0 * SUM(CASE WHEN status_entrega = 'Entregue com Atraso' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0), 1
    )                                                                 AS taxa_atraso_pct,
    ROUND(AVG(CASE WHEN dias_atraso > 0 THEN dias_atraso END), 1)     AS atraso_medio_dias
FROM entregas
GROUP BY TO_CHAR(data_pedido, 'Day'), EXTRACT(DOW FROM data_pedido)
ORDER BY num_dia;

-- NPS logístico: promotores, neutros e detratores
WITH nps_base AS (
    SELECT
        transportadora,
        avaliacao_nps,
        CASE
            WHEN avaliacao_nps >= 9 THEN 'Promotor'
            WHEN avaliacao_nps >= 7 THEN 'Neutro'
            ELSE 'Detrator'
        END AS categoria_nps
    FROM entregas
    WHERE avaliacao_nps IS NOT NULL
)
SELECT
    transportadora,
    COUNT(*)                                                           AS total_avaliacoes,
    ROUND(100.0 * SUM(CASE WHEN categoria_nps = 'Promotor'  THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_promotores,
    ROUND(100.0 * SUM(CASE WHEN categoria_nps = 'Neutro'    THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_neutros,
    ROUND(100.0 * SUM(CASE WHEN categoria_nps = 'Detrator'  THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_detratores,
    ROUND(
        100.0 * SUM(CASE WHEN categoria_nps = 'Promotor' THEN 1 ELSE 0 END) / COUNT(*)
      - 100.0 * SUM(CASE WHEN categoria_nps = 'Detrator' THEN 1 ELSE 0 END) / COUNT(*),
        1
    )                                                                  AS nps_score
FROM nps_base
GROUP BY transportadora
ORDER BY nps_score DESC;
