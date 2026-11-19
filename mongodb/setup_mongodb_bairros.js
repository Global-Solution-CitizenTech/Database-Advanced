// ====================================================================
// FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
// CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
// DISCIPLINA: Mastering Relational and Non-Relational Database
// REQUISITO 5: Estrutura MongoDB — Coleção 'bairros_monitoramento' (Painel Territorial)
// PROJETO: ZelaFix — Zeladoria Urbana Colaborativa
// TURMA: 2TDSPG
// INTEGRANTES:
//   1. Enzo Okuizumi Miranda de Souza   - RM: 561432
//   2. Gustavo Keiji Okada              - RM: 563428
//   3. Lucas Barros Gouveia             - RM: 566422
//   4. Luna de Carvalho Guimarães       - RM: 562290
//   5. Milton Jakson de Sousa Marcelino - RM: 564836
//
// COMO EXECUTAR (script autossuficiente: os 5 documentos estão embutidos neste arquivo,
// sem depender de caminho de pasta nem de arquivo externo):
// 1. Via Linha de Comando (mongosh):
//    mongosh "mongodb+srv://<usuario>:<senha>@zelafix.t2rxvpu.mongodb.net/zelafix" setup_mongodb_bairros.js
// 2. No MongoDB Compass (aba ">_MONGOSH"; load() e process.chdir() não são suportados no Compass):
//    cole o conteúdo deste arquivo diretamente no console ">_MONGOSH" conectado ao cluster.
// O arquivo bairros_dataset.json é a cópia do mesmo dataset (idêntica ao array embutido)
// para importação manual: Compass > Add Data > Import JSON.
// ====================================================================

(() => {
const log = typeof console !== "undefined" && console.log ? console.log : print;
// Dataset embutido: fonte única de dados deste script (sem leitura de arquivo, sem fallback).
const DATASET_BAIRROS = [
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

// 2. Comando 'use': seleciona (ou cria, no primeiro insert) o database oficial 'zelafix'.
//    use("zelafix") é o equivalente em script do comando de shell 'use zelafix'
//    (a forma sem parênteses não é JavaScript válido dentro de um arquivo .js).
const dbName = "zelafix";
use(dbName);

log("====================================================================");
log(">>> [MongoDB ZelaFix] Conectado ao banco de dados: " + dbName);
log(">>> Dataset embutido no script: 5 documentos para a coleção 'bairros_monitoramento'.");
log("====================================================================");

// 3. Remove coleção preexistente para recriação limpa e idempotente
try {
  db.bairros_monitoramento.drop();
  log(">>> Coleção antiga 'bairros_monitoramento' removida para recriação limpa.");
} catch (e) {
  // Ignora se a coleção ainda não existia
}

// 4. Criação da coleção com Validador de Schema JSON ($jsonSchema)
db.createCollection("bairros_monitoramento", {
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
db.bairros_monitoramento.createIndex(
  { "id_bairro": 1 },
  { unique: true, name: "idx_id_bairro_unique" }
);

db.bairros_monitoramento.createIndex(
  { "criticidade": 1 },
  { name: "idx_criticidade_bairro" }
);

db.bairros_monitoramento.createIndex(
  { "subprefeitura": 1 },
  { name: "idx_subprefeitura" }
);

db.bairros_monitoramento.createIndex(
  { "zona": 1, "nome_bairro": 1 },
  { name: "idx_zona_nome" }
);

log(">>> Índices estratégicos criados para a coleção 'bairros_monitoramento'.");

// 6. Carga de Dados (insertMany)
const datasetBairros = DATASET_BAIRROS.map(item => ({
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

const resultadoCarga = db.bairros_monitoramento.insertMany(datasetBairros);
const totalInseridos = resultadoCarga.insertedCount || Object.keys(resultadoCarga.insertedIds || {}).length;
log(">>> Carga concluída com sucesso! Documentos inseridos na coleção 'bairros_monitoramento': " + totalInseridos);

// 7. Consulta de Verificação Imediata (find)
log("====================================================================");
log(">>> Verificação da Carga de Bairros Monitorados:");
db.bairros_monitoramento.find({}, {
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
