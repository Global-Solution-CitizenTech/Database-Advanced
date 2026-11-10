// ====================================================================
// FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
// CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
// DISCIPLINA: Mastering Relational and Non-Relational Database
// REQUISITO 5: Estrutura MongoDB — Coleção 'bairros_monitoramento' (Painel Territorial)
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
// 1. Via Linha de Comando (mongosh) a partir da pasta 'mongodb/':
//    cd Database-Advanced/mongodb
//    mongosh "mongodb+srv://<usuario>:<senha>@zelafix.t2rxvpu.mongodb.net/zelafix" setup_mongodb_bairros.js
//    (Credenciais de acesso disponíveis no README.md e no arquivo .env)
// 2. No MongoDB Compass (aba inferior ">_MONGOSH"):
//    process.chdir("<caminho_do_repositorio>/Database-Advanced/mongodb")
//    load("setup_mongodb_bairros.js")
// ====================================================================

const log = typeof console !== "undefined" && console.log ? console.log : print;

// 1. Seleciona o banco oficial da aplicação
const dbName = "zelafix";
const dbTarget = typeof db !== "undefined" && db.getSiblingDB ? db.getSiblingDB(dbName) : db;

log("====================================================================");
log(">>> [MongoDB ZelaFix] Conectado ao banco de dados: " + dbName);
log("====================================================================");

// 2. Remove coleção preexistente para recriação limpa e idempotente
try {
  dbTarget.bairros_monitoramento.drop();
  log(">>> Coleção antiga 'bairros_monitoramento' removida para recriação limpa.");
} catch (e) {
  // Ignora se a coleção ainda não existia
}

// 3. Criação da coleção com Validador de Schema JSON ($jsonSchema)
dbTarget.createCollection("bairros_monitoramento", {
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
        id_bairro: {
          bsonType: ["int", "long", "double"],
          description: "Identificador numérico do bairro de origem no Oracle (obrigatório e único)."
        },
        nome_bairro: {
          bsonType: "string",
          description: "Nome do distrito/bairro da cidade de São Paulo."
        },
        cidade: {
          bsonType: "string",
          description: "Município de atuação da zeladoria."
        },
        estado: {
          bsonType: "string",
          description: "Unidade Federativa."
        },
        subprefeitura: {
          bsonType: "string",
          description: "Órgão regional responsável pela administração do território."
        },
        zona: {
          bsonType: "string",
          description: "Região geográfica da capital paulista (Central, Oeste, Leste, Norte, Sul)."
        },
        populacao_estimada: {
          bsonType: ["int", "long", "double"],
          description: "População residente estimada do distrito."
        },
        metricas: {
          bsonType: "object",
          required: ["chamados_totais", "chamados_pendentes", "chamados_concluidos", "total_apoios"],
          description: "Indicadores operacionais consolidados de zeladoria urbana.",
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
          enum: ["CRITICO", "ALERTA", "ESTAVEL"],
          description: "Classificação analítica do risco territorial de desassistência urbana."
        },
        indicadores_principais: {
          bsonType: "array",
          description: "Principais demandas recorrentes de zeladoria no território.",
          items: { bsonType: "string" }
        },
        atualizado_em: {
          bsonType: ["string", "date"],
          description: "Data/hora ISO da última apuração das métricas territoriais."
        }
      }
    }
  }
});
log(">>> Coleção 'bairros_monitoramento' criada com sucesso com $jsonSchema Validator.");

// 4. Criação de Índices Estratégicos
dbTarget.bairros_monitoramento.createIndex(
  { "id_bairro": 1 },
  { unique: true, name: "idx_id_bairro_unique" }
);

dbTarget.bairros_monitoramento.createIndex(
  { "criticidade": 1 },
  { name: "idx_criticidade_bairro" }
);

dbTarget.bairros_monitoramento.createIndex(
  { "subprefeitura": 1 },
  { name: "idx_subprefeitura" }
);

dbTarget.bairros_monitoramento.createIndex(
  { "zona": 1, "nome_bairro": 1 },
  { name: "idx_zona_nome" }
);

log(">>> Índices estratégicos criados para a coleção 'bairros_monitoramento'.");

// 5. Carga de Dados a partir de 'bairros_dataset.json'
const fs = require("fs");
const path = require("path");

function resolverCaminhoDataset(nomeArquivo) {
  const caminhos = [
    typeof __dirname !== "undefined" ? path.resolve(__dirname, nomeArquivo) : null,
    typeof __dirname !== "undefined" ? path.resolve(__dirname, "mongodb", nomeArquivo) : null,
    typeof process !== "undefined" && process.cwd ? path.resolve(process.cwd(), nomeArquivo) : null,
    typeof process !== "undefined" && process.cwd ? path.resolve(process.cwd(), "mongodb", nomeArquivo) : null,
    typeof process !== "undefined" && process.cwd ? path.resolve(process.cwd(), "Database-Advanced", "mongodb", nomeArquivo) : null,
    path.resolve("C:/Users/Enzo/new_backup/FIAP/_Projetos/Global_Solution_2/Database-Advanced/mongodb", nomeArquivo)
  ].filter(Boolean);

  for (const c of caminhos) {
    try {
      if (fs.existsSync(c)) return c;
    } catch (e) {}
  }
  return null;
}

const caminhoJson = resolverCaminhoDataset("bairros_dataset.json");

if (!caminhoJson) {
  throw new Error("ERRO CRÍTICO: Arquivo 'bairros_dataset.json' não encontrado. Execute a partir da pasta 'Database-Advanced/mongodb/'.");
}

log(">>> Dataset localizado em: " + caminhoJson);

const conteudoBruto = fs.readFileSync(caminhoJson, "utf8");
const dadosParsed = JSON.parse(conteudoBruto);

const datasetBairros = dadosParsed.map(item => ({
  ...item,
  id_bairro: typeof NumberInt !== "undefined" ? NumberInt(item.id_bairro) : item.id_bairro,
  populacao_estimada: typeof NumberInt !== "undefined" ? NumberInt(item.populacao_estimada) : item.populacao_estimada,
  atualizado_em: typeof ISODate !== "undefined" ? ISODate(item.atualizado_em) : new Date(item.atualizado_em),
  metricas: {
    ...item.metricas,
    chamados_totais: typeof NumberInt !== "undefined" ? NumberInt(item.metricas.chamados_totais) : item.metricas.chamados_totais,
    chamados_pendentes: typeof NumberInt !== "undefined" ? NumberInt(item.metricas.chamados_pendentes) : item.metricas.chamados_pendentes,
    chamados_concluidos: typeof NumberInt !== "undefined" ? NumberInt(item.metricas.chamados_concluidos) : item.metricas.chamados_concluidos,
    total_apoios: typeof NumberInt !== "undefined" ? NumberInt(item.metricas.total_apoios) : item.metricas.total_apoios
  }
}));

const resultadoCarga = dbTarget.bairros_monitoramento.insertMany(datasetBairros);
const totalInseridos = resultadoCarga.insertedCount || Object.keys(resultadoCarga.insertedIds || {}).length;
log(">>> Carga concluída com sucesso! Documentos inseridos na coleção 'bairros_monitoramento': " + totalInseridos);

// 6. Consulta de Verificação Imediata
log("====================================================================");
log(">>> Verificação da Carga de Bairros Monitorados:");
dbTarget.bairros_monitoramento.find({}, {
  id_bairro: 1,
  nome_bairro: 1,
  subprefeitura: 1,
  zona: 1,
  criticidade: 1,
  "metricas.chamados_pendentes": 1,
  "metricas.total_apoios": 1
}).forEach(doc => {
  log(" - [ID " + doc.id_bairro + "] " + doc.nome_bairro + " (" + doc.zona + ") | Subprefeitura: " + doc.subprefeitura + " | Pendentes: " + doc.metricas.chamados_pendentes + " | Votos: " + doc.metricas.total_apoios + " | Criticidade: " + doc.criticidade);
});
log("====================================================================");
