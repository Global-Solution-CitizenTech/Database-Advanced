-- ====================================================================
-- FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
-- CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
-- DISCIPLINA: Mastering Relational and Non-Relational Database
-- REQUISITO 6: Relatórios Oracle equivalentes às 3 consultas do MongoDB
-- PROJETO: ZelaFix — Zeladoria Urbana Colaborativa
-- TURMA: 2TDSPG
-- INTEGRANTES:
--   1. Enzo Okuizumi Miranda de Souza   - RM: 561432
--   2. Gustavo Keiji Okada              - RM: 563428
--   3. Lucas Barros Gouveia             - RM: 566422
--   4. Luna de Carvalho Guimarães       - RM: 562290
--   5. Milton Jakson de Sousa Marcelino - RM: 564836
--
-- PRÉ-REQUISITO: executar antes 2TDSPG_2026_CodigoSql_ZelaFix.sql e 2TDSPG_2026_Pacotes_ZelaFix.sql
-- (as consultas usam pkg_chamado_gestao.fn_obter_status_atual). O script de pacotes termina com
-- ROLLBACK, então os dados aqui são exatamente as sementes originais.
-- COMO COMPARAR: execute com "Run Script" (F5) e confira com a saída de consultas_relatorios_mongodb.js.
-- ====================================================================

-- --------------------------------------------------------------------
-- RELATÓRIO 1: Ocorrências Ativas com Maior Apoio Comunitário (equivale ao find + sort do MongoDB)
-- --------------------------------------------------------------------
PROMPT
PROMPT >>> RELATÓRIO 1: Ocorrências Ativas com Maior Apoio Comunitário (equivale ao find + sort do MongoDB)
SELECT c.id_chamado, c.titulo, cat.nm_categoria, b.nm_bairro,
       COUNT(v.id_voto) AS total_votos,
       pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) AS status_atual
  FROM chamado c
  JOIN categoria cat ON cat.id_categoria = c.categoria_id_categoria
  JOIN endereco e ON e.id_endereco = c.endereco_id_endereco
  JOIN bairro b ON b.id_bairro = e.bairro_id_bairro
  LEFT JOIN voto_chamado v ON v.chamado_id_chamado = c.id_chamado
 WHERE pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) NOT IN ('CONCLUIDO', 'REJEITADO')
 GROUP BY c.id_chamado, c.titulo, cat.nm_categoria, b.nm_bairro,
          pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado)
 ORDER BY total_votos DESC, c.id_chamado ASC;

-- --------------------------------------------------------------------
-- RELATÓRIO 2: Volume de Ocorrências por Categoria Urbana (equivale ao $group + $sort do MongoDB)
-- --------------------------------------------------------------------
PROMPT
PROMPT >>> RELATÓRIO 2: Volume de Ocorrências por Categoria Urbana (equivale ao $group + $sort do MongoDB)
SELECT cat.nm_categoria AS categoria,
       COUNT(c.id_chamado) AS total_ocorrencias,
       SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) IN ('PENDENTE', 'EM_ANALISE', 'EM_EXECUCAO') THEN 1 ELSE 0 END) AS ocorrencias_abertas,
       SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) = 'CONCLUIDO' THEN 1 ELSE 0 END) AS ocorrencias_concluidas,
       SUM(NVL(v.qtd_votos, 0)) AS total_votos_acumulados
  FROM categoria cat
  LEFT JOIN chamado c ON c.categoria_id_categoria = cat.id_categoria
  LEFT JOIN (SELECT chamado_id_chamado, COUNT(*) AS qtd_votos
               FROM voto_chamado
              GROUP BY chamado_id_chamado) v ON v.chamado_id_chamado = c.id_chamado
 GROUP BY cat.nm_categoria
 ORDER BY total_ocorrencias DESC, total_votos_acumulados DESC, cat.nm_categoria ASC;

-- --------------------------------------------------------------------
-- RELATÓRIO 3: Diagnóstico Territorial de Pendência por Bairro (equivale ao $group + $project + $sort do MongoDB)
-- --------------------------------------------------------------------
PROMPT
PROMPT >>> RELATÓRIO 3: Diagnóstico Territorial de Pendência por Bairro (equivale ao $group + $project + $sort do MongoDB)
SELECT b.nm_bairro AS bairro,
       c.nm_cidade AS cidade,
       COUNT(ch.id_chamado) AS total_chamados,
       SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) IN ('PENDENTE', 'EM_ANALISE', 'EM_EXECUCAO') THEN 1 ELSE 0 END) AS chamados_pendentes,
       SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) = 'CONCLUIDO' THEN 1 ELSE 0 END) AS chamados_resolvidos,
       ROUND((SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) IN ('PENDENTE', 'EM_ANALISE', 'EM_EXECUCAO') THEN 1 ELSE 0 END) / COUNT(ch.id_chamado)) * 100, 1) AS taxa_pendencia_pct,
       SUM(NVL(v.qtd_votos, 0)) AS votos_totais
  FROM bairro b
  JOIN cidade c ON c.id_cidade = b.cidade_id_cidade
  JOIN endereco e ON e.bairro_id_bairro = b.id_bairro
  JOIN chamado ch ON ch.endereco_id_endereco = e.id_endereco
  LEFT JOIN (SELECT chamado_id_chamado, COUNT(*) AS qtd_votos
               FROM voto_chamado
              GROUP BY chamado_id_chamado) v ON v.chamado_id_chamado = ch.id_chamado
 GROUP BY b.nm_bairro, c.nm_cidade
 ORDER BY chamados_pendentes DESC, votos_totais DESC, b.nm_bairro ASC;
