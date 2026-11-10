// ====================================================================
// FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
// CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
// DISCIPLINA: Mastering Relational and Non-Relational Database
// REQUISITO 6: Consultas Analíticas no MongoDB e Comparação com Oracle
// PROJETO: ZelaFix — Zeladoria Urbana Colaborativa
// TURMA: 2TDSPG
// INTEGRANTES:
//   1. Enzo Okuizumi                    - RM: 561432
//   2. Gustavo Okada                    - RM: 563428
//   3. Lucas Barros Gouveia             - RM: 566422
//   4. Luna de Carvalho Guimarães       - RM: 562290
//   5. Milton Jakson de Sousa Marcelino - RM: 564836
//
// COMO EXECUTAR:
// 1. Via Linha de Comando (mongosh):
//    mongosh "mongodb+srv://<usuario>:<senha>@zelafix.t2rxvpu.mongodb.net/zelafix" consultas_relatorios_mongodb.js
//    (Credenciais de acesso disponíveis no README.md e no arquivo .env)
// 2. No MongoDB Compass (aba ">_MONGOSH"):
//    process.chdir("<caminho_do_repositorio>/Database-Advanced/mongodb")
//    load("consultas_relatorios_mongodb.js")
// ====================================================================

const log = typeof console !== "undefined" && console.log ? console.log : print;

// Conecta ao database 'zelafix'
const dbName = "zelafix";
const dbTarget = typeof db !== "undefined" && db.getSiblingDB ? db.getSiblingDB(dbName) : db;

/**
 * Função Auxiliar Reutilizável (DRY): Formatação e renderização de tabelas CLI
 */
function imprimirTabela(titulo, colunas, dados) {
  log("\n" + titulo);
  const borda = "+" + colunas.map(c => "-".repeat(c.width + 2)).join("+") + "+";
  const cabecalho = "|" + colunas.map(c => " " + c.label.padEnd(c.width, " ") + " ").join("|") + "|";

  log(borda);
  log(cabecalho);
  log(borda);

  dados.forEach(d => {
    const linha = "|" + colunas.map(c => {
      let val = typeof c.get === "function" ? c.get(d) : d[c.key];
      val = val !== undefined && val !== null ? String(val) : "";
      if (val.length > c.width) val = val.substring(0, c.width - 3) + "...";
      return c.align === "right"
        ? " " + val.padStart(c.width, " ") + " "
        : " " + val.padEnd(c.width, " ") + " ";
    }).join("|") + "|";
    log(linha);
  });
  log(borda);
}

log("====================================================================");
log("  ZELAFIX CITIZENTECH — RELATÓRIOS ANALÍTICOS NoSQL (MONGODB)");
log("  Execução dos 3 Relatórios Obrigatórios (Edital GS2 - Págs 70-76)");
log("====================================================================");


// --------------------------------------------------------------------
// RELATÓRIO 1: RANKING DE CHAMADOS MAIS APOIADOS PELA COMUNIDADE
// Método: find() com filtro de exclusão ($nin), projeção e ordenação descendente
// Objetivo: Listar as ocorrências ativas com maior engajamento popular
// --------------------------------------------------------------------
const relatorio1 = dbTarget.chamados.find(
  {
    status_atual: { $nin: ["CONCLUIDO", "REJEITADO"] }
  },
  {
    _id: 0,
    id_chamado: 1,
    titulo: 1,
    categoria: 1,
    status_atual: 1,
    total_votos: 1,
    "localizacao.bairro": 1
  }
).sort({ total_votos: -1, id_chamado: 1 }).toArray();

imprimirTabela(
  ">>> RELATÓRIO 1: Ocorrências Ativas com Maior Apoio Comunitário (Filtro: Ativos | Order: total_votos DESC)",
  [
    { label: "ID", key: "id_chamado", width: 5, align: "right" },
    { label: "TÍTULO DA OCORRÊNCIA", key: "titulo", width: 44, align: "left" },
    { label: "BAIRRO", get: d => d.localizacao && d.localizacao.bairro ? d.localizacao.bairro : "", width: 14, align: "left" },
    { label: "CATEGORIA", key: "categoria", width: 22, align: "left" },
    { label: "STATUS", key: "status_atual", width: 12, align: "left" },
    { label: "APOIOS", key: "total_votos", width: 8, align: "right" }
  ],
  relatorio1
);


// --------------------------------------------------------------------
// RELATÓRIO 2: PANORAMA ESTATÍSTICO POR CATEGORIA URBANA (AGGREGATION PIPELINE)
// Operadores: $group com acumuladores ($sum, $cond) e $sort
// Objetivo: Apoiar o planejamento orçamentário municipal mapeando gargalos
// --------------------------------------------------------------------
const relatorio2 = dbTarget.chamados.aggregate([
  {
    $group: {
      _id: "$categoria",
      total_ocorrencias: { $sum: 1 },
      total_votos_acumulados: { $sum: "$total_votos" },
      ocorrencias_abertas: {
        $sum: {
          $cond: [
            { $in: ["$status_atual", ["ABERTO", "EM_ANALISE", "EM_EXECUCAO"]] },
            1,
            0
          ]
        }
      },
      ocorrencias_concluidas: {
        $sum: {
          $cond: [
            { $eq: ["$status_atual", "CONCLUIDO"] },
            1,
            0
          ]
        }
      }
    }
  },
  {
    $sort: {
      total_ocorrencias: -1,
      total_votos_acumulados: -1
    }
  }
]).toArray();

imprimirTabela(
  ">>> RELATÓRIO 2 (AGGREGATION): Volume de Ocorrências e Gargalos por Categoria Urbana",
  [
    { label: "CATEGORIA URBANA", key: "_id", width: 26, align: "left" },
    { label: "TOTAL", key: "total_ocorrencias", width: 7, align: "right" },
    { label: "PENDENTES", key: "ocorrencias_abertas", width: 10, align: "right" },
    { label: "CONCLUÍDAS", key: "ocorrencias_concluidas", width: 11, align: "right" },
    { label: "APOIOS TOTAIS", key: "total_votos_acumulados", width: 14, align: "right" }
  ],
  relatorio2
);


// --------------------------------------------------------------------
// RELATÓRIO 3: DIAGNÓSTICO TERRITORIAL DE CRITICIDADE POR BAIRRO (AGGREGATION PIPELINE)
// Operadores: $group, $project com expressões aritméticas ($multiply, $divide, $round) e $sort
// Objetivo: Identificar distritos com maior taxa de pendência para mutirões
// --------------------------------------------------------------------
const relatorio3 = dbTarget.chamados.aggregate([
  {
    $group: {
      _id: "$localizacao.bairro",
      cidade: { $first: "$localizacao.cidade" },
      total_chamados: { $sum: 1 },
      votos_totais: { $sum: "$total_votos" },
      chamados_pendentes: {
        $sum: {
          $cond: [{ $ne: ["$status_atual", "CONCLUIDO"] }, 1, 0]
        }
      },
      chamados_resolvidos: {
        $sum: {
          $cond: [{ $eq: ["$status_atual", "CONCLUIDO"] }, 1, 0]
        }
      }
    }
  },
  {
    $project: {
      _id: 0,
      bairro: "$_id",
      cidade: 1,
      total_chamados: 1,
      votos_totais: 1,
      chamados_pendentes: 1,
      chamados_resolvidos: 1,
      taxa_pendencia_pct: {
        $round: [
          {
            $multiply: [
              { $divide: ["$chamados_pendentes", "$total_chamados"] },
              100
            ]
          },
          1
        ]
      }
    }
  },
  {
    $sort: {
      chamados_pendentes: -1,
      votos_totais: -1,
      bairro: 1
    }
  }
]).toArray();

imprimirTabela(
  ">>> RELATÓRIO 3 (AGGREGATION AVANÇADO): Diagnóstico Territorial de Pendência por Bairro",
  [
    { label: "BAIRRO", key: "bairro", width: 16, align: "left" },
    { label: "MUNICÍPIO", key: "cidade", width: 12, align: "left" },
    { label: "TOTAL", key: "total_chamados", width: 7, align: "right" },
    { label: "PENDENTES", key: "chamados_pendentes", width: 10, align: "right" },
    { label: "RESOLVIDOS", key: "chamados_resolvidos", width: 11, align: "right" },
    { label: "PENDÊNCIA %", get: d => String(d.taxa_pendencia_pct) + "%", width: 12, align: "right" },
    { label: "APOIOS", key: "votos_totais", width: 8, align: "right" }
  ],
  relatorio3
);

log("\n====================================================================");
log("  EXECUÇÃO CONCLUÍDA COM SUCESSO! DADOS EM HARMONIA COM O ORACLE.");
log("====================================================================");
