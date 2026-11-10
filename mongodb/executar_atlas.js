// ====================================================================
// FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
// CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
// DISCIPLINA: Mastering Relational and Non-Relational Database
// EXECUTOR CLI NATIVO (NODE.JS + MONGODB ATLAS) — PROJETO ZELAFIX
// Conecta no cluster com as credenciais do .env, cria as coleções,
// aplica os schemas de validação, índices, carga e gera os relatórios.
// ====================================================================

require("dotenv").config({ path: __dirname + "/.env" });
const { MongoClient } = require("mongodb");
const fs = require("fs");
const path = require("path");

const log = console.log;

// Função Auxiliar Reutilizável de Formatação de Tabelas CLI
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

async function main() {
  const uri = process.env.MONGODB_URI;
  const dbName = process.env.MONGODB_DATABASE || "zelafix";

  if (!uri) {
    throw new Error("Variável MONGODB_URI não encontrada no arquivo .env");
  }

  log("====================================================================");
  log("  ZELAFIX CITIZENTECH — EXECUÇÃO CLI NO MONGODB ATLAS");
  log("  Cluster: " + uri.replace(/:([^@]+)@/, ":****@"));
  log("  Database: " + dbName);
  log("====================================================================");

  const client = new MongoClient(uri, { serverSelectionTimeoutMS: 10000 });

  try {
    await client.connect();
    log(">>> [CONEXÃO OK] Conectado com sucesso ao MongoDB Atlas!");

    const db = client.db(dbName);

    // ================================================================
    // ETAPA 1: SETUP DA COLEÇÃO 'CHAMADOS'
    // ================================================================
    log("\n--------------------------------------------------------------------");
    log(">>> [ETAPA 1/3] Configurando Coleção 'chamados'...");
    log("--------------------------------------------------------------------");

    // 1.1 Remove coleção anterior para idempotência
    try {
      await db.collection("chamados").drop();
      log(" - Coleção antiga 'chamados' removida.");
    } catch (e) {
      // Ignora se não existia
    }

    // 1.2 Cria com $jsonSchema Validator
    await db.createCollection("chamados", {
      validator: {
        $jsonSchema: {
          bsonType: "object",
          required: [
            "id_chamado",
            "titulo",
            "descricao",
            "categoria",
            "status_atual",
            "dt_abertura",
            "total_votos",
            "cidadao",
            "localizacao",
            "historico"
          ],
          properties: {
            id_chamado: { bsonType: ["int", "long", "double"] },
            titulo: { bsonType: "string" },
            descricao: { bsonType: "string" },
            categoria: { bsonType: "string" },
            status_atual: {
              bsonType: "string",
              enum: ["ABERTO", "EM_ANALISE", "EM_EXECUCAO", "CONCLUIDO", "REJEITADO"]
            },
            dt_abertura: { bsonType: ["string", "date"] },
            total_votos: { bsonType: ["int", "long", "double"] },
            cidadao: {
              bsonType: "object",
              required: ["id_usuario", "nome", "email"],
              properties: {
                id_usuario: { bsonType: ["int", "long", "double"] },
                nome: { bsonType: "string" },
                email: { bsonType: "string" }
              }
            },
            localizacao: {
              bsonType: "object",
              required: ["rua", "numero", "bairro", "cidade", "estado", "cep"],
              properties: {
                rua: { bsonType: "string" },
                numero: { bsonType: "string" },
                referencia: { bsonType: "string" },
                bairro: { bsonType: "string" },
                cidade: { bsonType: "string" },
                estado: { bsonType: "string" },
                cep: { bsonType: "string" }
              }
            },
            historico: {
              bsonType: "array",
              items: {
                bsonType: "object",
                required: ["data", "status", "observacao", "responsavel"],
                properties: {
                  ordem: { bsonType: ["int", "long", "double"] },
                  data: { bsonType: ["string", "date"] },
                  status: { bsonType: "string" },
                  observacao: { bsonType: "string" },
                  responsavel: { bsonType: "string" }
                }
              }
            },
            votos: {
              bsonType: "array",
              items: {
                bsonType: "object",
                required: ["id_usuario", "nome", "dt_voto"],
                properties: {
                  id_usuario: { bsonType: ["int", "long", "double"] },
                  nome: { bsonType: "string" },
                  dt_voto: { bsonType: ["string", "date"] }
                }
              }
            },
            triagem_ia: {
              bsonType: "object",
              properties: {
                prioridade: { bsonType: "string" },
                parecer: { bsonType: "string" },
                orgao_sugerido: { bsonType: "string" }
              }
            }
          }
        }
      }
    });
    log(" - Coleção 'chamados' criada com validador $jsonSchema.");

    // 1.3 Cria Índices Estratégicos
    await db.collection("chamados").createIndex({ "id_chamado": 1 }, { unique: true, name: "idx_id_chamado_unique" });
    await db.collection("chamados").createIndex({ "status_atual": 1, "localizacao.bairro": 1 }, { name: "idx_status_bairro" });
    await db.collection("chamados").createIndex({ "total_votos": -1 }, { name: "idx_total_votos" });
    await db.collection("chamados").createIndex({ "titulo": "text", "descricao": "text" }, { name: "idx_busca_textual_chamado", default_language: "portuguese" });
    log(" - Índices estratégicos criados para 'chamados'.");

    // 1.4 Carga do Dataset
    const chamadosJsonPath = path.resolve(__dirname, "chamados_dataset.json");
    const chamadosRaw = JSON.parse(fs.readFileSync(chamadosJsonPath, "utf8"));
    const chamadosDocs = chamadosRaw.map(item => ({
      ...item,
      dt_abertura: new Date(item.dt_abertura),
      historico: item.historico.map(h => ({ ...h, data: new Date(h.data) })),
      votos: (item.votos || []).map(v => ({ ...v, dt_voto: new Date(v.dt_voto) }))
    }));
    const resChamados = await db.collection("chamados").insertMany(chamadosDocs);
    log(` - Carga realizada: ${resChamados.insertedCount} documentos inseridos em 'chamados'.`);


    // ================================================================
    // ETAPA 2: SETUP DA COLEÇÃO 'BAIRROS_MONITORAMENTO'
    // ================================================================
    log("\n--------------------------------------------------------------------");
    log(">>> [ETAPA 2/3] Configurando Coleção 'bairros_monitoramento'...");
    log("--------------------------------------------------------------------");

    // 2.1 Remove coleção anterior
    try {
      await db.collection("bairros_monitoramento").drop();
      log(" - Coleção antiga 'bairros_monitoramento' removida.");
    } catch (e) {}

    // 2.2 Cria com $jsonSchema Validator
    await db.createCollection("bairros_monitoramento", {
      validator: {
        $jsonSchema: {
          bsonType: "object",
          required: [
            "id_bairro",
            "nome_bairro",
            "cidade",
            "subprefeitura",
            "zona",
            "metricas",
            "criticidade"
          ],
          properties: {
            id_bairro: { bsonType: ["int", "long", "double"] },
            nome_bairro: { bsonType: "string" },
            cidade: { bsonType: "string" },
            estado: { bsonType: "string" },
            subprefeitura: { bsonType: "string" },
            zona: { bsonType: "string" },
            populacao_estimada: { bsonType: ["int", "long", "double"] },
            metricas: {
              bsonType: "object",
              required: ["chamados_totais", "chamados_pendentes", "chamados_concluidos", "total_apoios"],
              properties: {
                chamados_totais: { bsonType: ["int", "long", "double"] },
                chamados_pendentes: { bsonType: ["int", "long", "double"] },
                chamados_concluidos: { bsonType: ["int", "long", "double"] },
                total_apoios: { bsonType: ["int", "long", "double"] },
                tempo_medio_resolucao_horas: { bsonType: ["int", "long", "double"] }
              }
            },
            criticidade: {
              bsonType: "string",
              enum: ["CRITICO", "ALERTA", "ESTAVEL"]
            },
            indicadores_principais: {
              bsonType: "array",
              items: { bsonType: "string" }
            },
            atualizado_em: { bsonType: ["string", "date"] }
          }
        }
      }
    });
    log(" - Coleção 'bairros_monitoramento' criada com validador $jsonSchema.");

    // 2.3 Índices Estratégicos
    await db.collection("bairros_monitoramento").createIndex({ "id_bairro": 1 }, { unique: true, name: "idx_id_bairro_unique" });
    await db.collection("bairros_monitoramento").createIndex({ "criticidade": 1 }, { name: "idx_criticidade_bairro" });
    await db.collection("bairros_monitoramento").createIndex({ "subprefeitura": 1 }, { name: "idx_subprefeitura" });
    await db.collection("bairros_monitoramento").createIndex({ "zona": 1, "nome_bairro": 1 }, { name: "idx_zona_nome" });
    log(" - Índices estratégicos criados para 'bairros_monitoramento'.");

    // 2.4 Carga do Dataset
    const bairrosJsonPath = path.resolve(__dirname, "bairros_dataset.json");
    const bairrosRaw = JSON.parse(fs.readFileSync(bairrosJsonPath, "utf8"));
    const bairrosDocs = bairrosRaw.map(item => ({
      ...item,
      atualizado_em: new Date(item.atualizado_em)
    }));
    const resBairros = await db.collection("bairros_monitoramento").insertMany(bairrosDocs);
    log(` - Carga realizada: ${resBairros.insertedCount} documentos inseridos em 'bairros_monitoramento'.`);


    // ================================================================
    // ETAPA 3: CONSULTAS ANALÍTICAS E RELATÓRIOS DO EDITAL
    // ================================================================
    log("\n--------------------------------------------------------------------");
    log(">>> [ETAPA 3/3] Executando os 3 Relatórios Analíticos Obrigatórios...");
    log("--------------------------------------------------------------------");

    // RELATÓRIO 1: Ranking de Chamados Ativos Mais Apoiados
    const rel1 = await db.collection("chamados").find(
      { status_atual: { $nin: ["CONCLUIDO", "REJEITADO"] } },
      {
        projection: {
          _id: 0,
          id_chamado: 1,
          titulo: 1,
          categoria: 1,
          status_atual: 1,
          total_votos: 1,
          "localizacao.bairro": 1
        }
      }
    ).sort({ total_votos: -1, id_chamado: 1 }).toArray();

    imprimirTabela(
      ">>> RELATÓRIO 1: Ocorrências Ativas com Maior Apoio Comunitário (Filtro: Ativos | Order: total_votos DESC)",
      [
        { label: "ID", key: "id_chamado", width: 5, align: "right" },
        { label: "TÍTULO DA OCORRÊNCIA", key: "titulo", width: 44, align: "left" },
        { label: "BAIRRO", get: d => d.localizacao?.bairro || "", width: 14, align: "left" },
        { label: "CATEGORIA", key: "categoria", width: 22, align: "left" },
        { label: "STATUS", key: "status_atual", width: 12, align: "left" },
        { label: "APOIOS", key: "total_votos", width: 8, align: "right" }
      ],
      rel1
    );

    // RELATÓRIO 2: Volume por Categoria Urbana (Aggregation Pipeline)
    const rel2 = await db.collection("chamados").aggregate([
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
      rel2
    );

    // RELATÓRIO 3: Diagnóstico Territorial de Pendência por Bairro (Aggregation Pipeline)
    const rel3 = await db.collection("chamados").aggregate([
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
      rel3
    );

    log("\n====================================================================");
    log("  >>> SUCESSO TOTAL: 13 DOCUMENTOS CARREGADOS NO ATLAS E RELATÓRIOS OK! <<<");
    log("====================================================================");

  } catch (err) {
    console.error("\n[ERRO CRÍTICO NA EXECUÇÃO]:", err);
    process.exit(1);
  } finally {
    await client.close();
    log(" - Conexão com MongoDB Atlas encerrada com sucesso.");
  }
}

main();
