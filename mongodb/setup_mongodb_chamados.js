// ====================================================================
// FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
// CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
// DISCIPLINA: Mastering Relational and Non-Relational Database
// REQUISITO 5: Estrutura MongoDB — Coleção 'chamados' (Feed de Ocorrências Enriquecidas)
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
//    mongosh "mongodb+srv://<usuario>:<senha>@zelafix.t2rxvpu.mongodb.net/zelafix" setup_mongodb_chamados.js
//    (Credenciais de acesso disponíveis no README.md e no arquivo .env)
// 2. No MongoDB Compass (aba inferior ">_MONGOSH"):
//    process.chdir("<caminho_do_repositorio>/Database-Advanced/mongodb")
//    load("setup_mongodb_chamados.js")
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
  dbTarget.chamados.drop();
  log(">>> Coleção antiga 'chamados' removida para recriação limpa.");
} catch (e) {
  // Ignora se a coleção ainda não existia
}

// 3. Criação da coleção 'chamados' com Validador de Schema JSON ($jsonSchema)
dbTarget.createCollection("chamados", {
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
        id_chamado: {
          bsonType: ["int", "long", "double"],
          description: "Identificador numérico de origem no Oracle (obrigatório e único)."
        },
        titulo: {
          bsonType: "string",
          description: "Título resumido da ocorrência urbana."
        },
        descricao: {
          bsonType: "string",
          description: "Detalhamento da solicitação de zeladoria."
        },
        categoria: {
          bsonType: "string",
          description: "Categoria do serviço público (ex: Vias e Pavimentação, Iluminação Pública)."
        },
        status_atual: {
          bsonType: "string",
          enum: ["ABERTO", "EM_ANALISE", "EM_EXECUCAO", "CONCLUIDO", "REJEITADO"],
          description: "Status vigente desnormalizado para consultas de alta performance."
        },
        dt_abertura: {
          bsonType: ["string", "date"],
          description: "Data/hora ISO da abertura do chamado pelo munícipe."
        },
        total_votos: {
          bsonType: ["int", "long", "double"],
          description: "Contador desnormalizado de apoios comunitários para ordenação rápida."
        },
        cidadao: {
          bsonType: "object",
          required: ["id_usuario", "nome", "email"],
          description: "Dados embutidos do cidadão autor da denúncia (Embedding).",
          properties: {
            id_usuario: { bsonType: ["int", "long", "double"] },
            nome: { bsonType: "string" },
            email: { bsonType: "string" }
          }
        },
        localizacao: {
          bsonType: "object",
          required: ["rua", "numero", "bairro", "cidade", "estado", "cep"],
          description: "Endereço territorial da ocorrência urbana (Embedding).",
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
          description: "Linha do tempo cronológica com a evolução dos status (Embedding).",
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
          description: "Lista de vizinhos que apoiaram a ocorrência no aplicativo.",
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
          description: "Metadados inteligentes gerados por IA generativa (Spring AI).",
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
log(">>> Coleção 'chamados' criada com sucesso com $jsonSchema Validator.");

// 4. Criação de Índices Estratégicos
dbTarget.chamados.createIndex(
  { "id_chamado": 1 },
  { unique: true, name: "idx_id_chamado_unique" }
);

dbTarget.chamados.createIndex(
  { "status_atual": 1, "localizacao.bairro": 1 },
  { name: "idx_status_bairro" }
);

dbTarget.chamados.createIndex(
  { "total_votos": -1 },
  { name: "idx_total_votos" }
);

dbTarget.chamados.createIndex(
  { "titulo": "text", "descricao": "text" },
  { name: "idx_busca_textual_chamado", default_language: "portuguese" }
);

log(">>> Índices estratégicos criados para a coleção 'chamados'.");

// 5. Carga de Dados a partir de 'chamados_dataset.json'
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

const caminhoJson = resolverCaminhoDataset("chamados_dataset.json");

if (!caminhoJson) {
  throw new Error("ERRO CRÍTICO: Arquivo 'chamados_dataset.json' não encontrado. Execute a partir da pasta 'Database-Advanced/mongodb/'.");
}

log(">>> Dataset localizado em: " + caminhoJson);

const conteudoBruto = fs.readFileSync(caminhoJson, "utf8");
const dadosParsed = JSON.parse(conteudoBruto);

const datasetChamados = dadosParsed.map(item => ({
  ...item,
  id_chamado: typeof NumberInt !== "undefined" ? NumberInt(item.id_chamado) : item.id_chamado,
  total_votos: typeof NumberInt !== "undefined" ? NumberInt(item.total_votos) : item.total_votos,
  dt_abertura: typeof ISODate !== "undefined" ? ISODate(item.dt_abertura) : new Date(item.dt_abertura),
  cidadao: {
    ...item.cidadao,
    id_usuario: typeof NumberInt !== "undefined" ? NumberInt(item.cidadao.id_usuario) : item.cidadao.id_usuario
  },
  historico: item.historico.map(h => ({
    ...h,
    ordem: typeof NumberInt !== "undefined" ? NumberInt(h.ordem) : h.ordem,
    data: typeof ISODate !== "undefined" ? ISODate(h.data) : new Date(h.data)
  })),
  votos: item.votos.map(v => ({
    ...v,
    id_usuario: typeof NumberInt !== "undefined" ? NumberInt(v.id_usuario) : v.id_usuario,
    dt_voto: typeof ISODate !== "undefined" ? ISODate(v.dt_voto) : new Date(v.dt_voto)
  }))
}));

const resultadoCarga = dbTarget.chamados.insertMany(datasetChamados);
const totalInseridos = resultadoCarga.insertedCount || Object.keys(resultadoCarga.insertedIds || {}).length;
log(">>> Carga concluída com sucesso! Documentos inseridos na coleção 'chamados': " + totalInseridos);

// 6. Consulta de Verificação Imediata
log("====================================================================");
log(">>> Verificação da Carga de Chamados:");
dbTarget.chamados.find({}, {
  id_chamado: 1,
  titulo: 1,
  categoria: 1,
  status_atual: 1,
  total_votos: 1,
  "localizacao.bairro": 1
}).forEach(doc => {
  log(" - [ID " + doc.id_chamado + "] " + doc.titulo + " | Bairro: " + doc.localizacao.bairro + " | Status: " + doc.status_atual + " | Votos: " + doc.total_votos);
});
log("====================================================================");
