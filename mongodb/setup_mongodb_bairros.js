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
// 2. No MongoDB Compass (aba ">_MONGOSH" — load() e process.chdir() não são suportados no Compass):
//    Cole o conteúdo deste arquivo diretamente no console ">_MONGOSH" conectado ao cluster.
// ====================================================================

(() => {
const log = typeof console !== "undefined" && console.log ? console.log : print;
const fs = require("fs");
const path = require("path");

function resolverCaminhoDataset(nomeArquivo) {
  const caminhos = [];

  if (typeof __dirname !== "undefined" && __dirname) {
    caminhos.push(path.resolve(__dirname, nomeArquivo));
    caminhos.push(path.resolve(__dirname, "mongodb", nomeArquivo));
  }

  // Extrai a pasta do script via stack trace quando invocado via mongosh CLI
  try {
    const stack = (new Error().stack || "").split("\n");
    for (const linha of stack) {
      const match = linha.match(/(?:at\s+|@|\()([A-Za-z]:[\\/][^:\n\r]+|\/[^:\n\r]+)/);
      if (match && match[1]) {
        const arq = match[1].replace(/:\d+(:\d+)?\)?$/, "").trim();
        if (arq.endsWith(".js") && fs.existsSync(arq)) {
          const dir = path.dirname(arq);
          caminhos.push(path.resolve(dir, nomeArquivo));
          caminhos.push(path.resolve(dir, "mongodb", nomeArquivo));
        }
      }
    }
  } catch (e) {}

  if (typeof process !== "undefined" && process.cwd) {
    let dir = process.cwd();
    for (let i = 0; i < 4; i++) {
      caminhos.push(path.resolve(dir, nomeArquivo));
      caminhos.push(path.resolve(dir, "mongodb", nomeArquivo));
      caminhos.push(path.resolve(dir, "Database-Advanced", "mongodb", nomeArquivo));
      const pai = path.dirname(dir);
      if (pai === dir) break;
      dir = pai;
    }
  }

  for (const c of caminhos) {
    try {
      if (fs.existsSync(c)) return c;
    } catch (e) {}
  }
  return null;
}

// 1. Tenta ler 'bairros_dataset.json' dinamicamente; se colado direto no Compass >_MONGOSH (sem contexto de pasta), usa fallback embutido portátil
const caminhoJson = resolverCaminhoDataset("bairros_dataset.json");
const DATASET_FALLBACK = [
  {
    "id_bairro": 1,
    "nome_bairro": "Bela Vista",
    "cidade": "São Paulo",
    "estado": "SP",
    "subprefeitura": "Subprefeitura Sé",
    "zona": "Central",
    "populacao_estimada": 76000,
    "metricas": {
      "chamados_totais": 2,
      "chamados_pendentes": 1,
      "chamados_concluidos": 1,
      "total_apoios": 2,
      "tempo_medio_resolucao_horas": 7.5
    },
    "criticidade": "ALERTA",
    "indicadores_principais": [
      "ILUMINACAO_PUBLICA",
      "SINALIZACAO_E_TRANSITO"
    ],
    "atualizado_em": "2026-11-04T12:00:00Z"
  },
  {
    "id_bairro": 2,
    "nome_bairro": "Pinheiros",
    "cidade": "São Paulo",
    "estado": "SP",
    "subprefeitura": "Subprefeitura Pinheiros",
    "zona": "Oeste",
    "populacao_estimada": 65000,
    "metricas": {
      "chamados_totais": 2,
      "chamados_pendentes": 2,
      "chamados_concluidos": 0,
      "total_apoios": 2,
      "tempo_medio_resolucao_horas": 0.0
    },
    "criticidade": "ALERTA",
    "indicadores_principais": [
      "VIAS_E_PAVIMENTACAO",
      "DRENAGEM_E_ESGOTO"
    ],
    "atualizado_em": "2026-11-04T12:00:00Z"
  },
  {
    "id_bairro": 3,
    "nome_bairro": "Sé",
    "cidade": "São Paulo",
    "estado": "SP",
    "subprefeitura": "Subprefeitura Sé",
    "zona": "Central",
    "populacao_estimada": 28000,
    "metricas": {
      "chamados_totais": 2,
      "chamados_pendentes": 0,
      "chamados_concluidos": 1,
      "total_apoios": 0,
      "tempo_medio_resolucao_horas": 50.3
    },
    "criticidade": "NORMAL",
    "indicadores_principais": [
      "DRENAGEM_E_ESGOTO",
      "LIMPEZA_URBANA"
    ],
    "atualizado_em": "2026-11-04T12:00:00Z"
  },
  {
    "id_bairro": 4,
    "nome_bairro": "Mooca",
    "cidade": "São Paulo",
    "estado": "SP",
    "subprefeitura": "Subprefeitura Mooca",
    "zona": "Leste",
    "populacao_estimada": 75000,
    "metricas": {
      "chamados_totais": 1,
      "chamados_pendentes": 1,
      "chamados_concluidos": 0,
      "total_apoios": 2,
      "tempo_medio_resolucao_horas": 0.0
    },
    "criticidade": "ALERTA",
    "indicadores_principais": [
      "LIMPEZA_URBANA"
    ],
    "atualizado_em": "2026-11-04T12:00:00Z"
  },
  {
    "id_bairro": 5,
    "nome_bairro": "Santana",
    "cidade": "São Paulo",
    "estado": "SP",
    "subprefeitura": "Subprefeitura Santana/Tucuruvi",
    "zona": "Norte",
    "populacao_estimada": 118000,
    "metricas": {
      "chamados_totais": 1,
      "chamados_pendentes": 1,
      "chamados_concluidos": 0,
      "total_apoios": 2,
      "tempo_medio_resolucao_horas": 0.0
    },
    "criticidade": "ALERTA",
    "indicadores_principais": [
      "ARVORES_E_PARQUES"
    ],
    "atualizado_em": "2026-11-04T12:00:00Z"
  }
];

const dadosParsed = caminhoJson
  ? JSON.parse(fs.readFileSync(caminhoJson, "utf8"))
  : DATASET_FALLBACK;

// 2. Seleciona o banco oficial da aplicação
const dbName = "zelafix";
const dbTarget = typeof db !== "undefined" && db.getSiblingDB ? db.getSiblingDB(dbName) : db;

log("====================================================================");
log(">>> [MongoDB ZelaFix] Conectado ao banco de dados: " + dbName);
log(caminhoJson
  ? ">>> Dataset localizado em: " + caminhoJson
  : ">>> Modo colagem interativa (Compass >_MONGOSH): carregando 5 bairros do fallback portátil embutido.");
log("====================================================================");

// 3. Remove coleção preexistente para recriação limpa e idempotente
try {
  dbTarget.bairros_monitoramento.drop();
  log(">>> Coleção antiga 'bairros_monitoramento' removida para recriação limpa.");
} catch (e) {
  // Ignora se a coleção ainda não existia
}

// 4. Criação da coleção com Validador de Schema JSON ($jsonSchema)
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
          enum: ["CRITICO", "ALERTA", "NORMAL"],
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

// 5. Criação de Índices Estratégicos
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

// 6. Carga de Dados a partir de 'bairros_dataset.json'
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
})();
