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

// 1. Tenta ler 'chamados_dataset.json' dinamicamente; se colado direto no Compass >_MONGOSH (sem contexto de pasta), usa fallback embutido portátil.
//    O dataset é resolvido ANTES de dropar a coleção, então o banco nunca fica vazio por falha de caminho.
//    O fallback é cópia fiel de 'chamados_dataset.json' (mesmos 8 chamados).
const caminhoJson = resolverCaminhoDataset("chamados_dataset.json");
const DATASET_FALLBACK = [
  {
    "id_chamado": 1,
    "titulo": "Poste com lâmpada apagada em via principal",
    "descricao": "Poste de iluminação pública em frente ao número 1106 apagado há 4 noites consecutivas, gerando sensação de insegurança aos pedestres.",
    "categoria": "ILUMINACAO_PUBLICA",
    "status_atual": "EM_EXECUCAO",
    "dt_abertura": "2026-10-28T19:40:00Z",
    "total_votos": 2,
    "cidadao": {
      "id_usuario": 1,
      "nome": "Carlos Alberto Silva",
      "email": "carlos.silva@email.com"
    },
    "localizacao": {
      "rua": "Avenida Paulista",
      "numero": "1106",
      "referencia": "Próximo ao MASP",
      "bairro": "Bela Vista",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01311000"
    },
    "historico": [
      {
        "ordem": 1,
        "data": "2026-10-28T19:40:00Z",
        "status": "PENDENTE",
        "observacao": "Chamado aberto pelo cidadão via aplicativo ZelaFix.",
        "responsavel": "Carlos Alberto Silva"
      },
      {
        "ordem": 2,
        "data": "2026-10-29T10:00:00Z",
        "status": "EM_EXECUCAO",
        "observacao": "Ordem de serviço nº 4022 emitida e encaminhada à concessionária de energia.",
        "responsavel": "Eng. Roberto Santos"
      }
    ],
    "votos": [
      {
        "id_usuario": 2,
        "nome": "Mariana Oliveira Souza",
        "dt_voto": "2026-10-29T09:00:00Z"
      },
      {
        "id_usuario": 4,
        "nome": "Fernanda Costa Lima",
        "dt_voto": "2026-10-29T18:45:00Z"
      }
    ],
    "triagem_ia": {
      "prioridade": "ALTA",
      "parecer": "Risco de segurança noturna identificado pela triagem inteligente.",
      "orgao_sugerido": "ILUMINACAO_PUBLICA"
    }
  },
  {
    "id_chamado": 2,
    "titulo": "Buraco profundo na faixa da direita da via",
    "descricao": "Cratera aberta no asfalto com risco iminente de acidente com motociclistas e danos a veículos.",
    "categoria": "VIAS_E_PAVIMENTACAO",
    "status_atual": "EM_ANALISE",
    "dt_abertura": "2026-10-30T08:15:00Z",
    "total_votos": 2,
    "cidadao": {
      "id_usuario": 2,
      "nome": "Mariana Oliveira Souza",
      "email": "mariana.souza@email.com"
    },
    "localizacao": {
      "rua": "Rua dos Pinheiros",
      "numero": "450",
      "referencia": "Esquina com Rua Fradique Coutinho",
      "bairro": "Pinheiros",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "05422000"
    },
    "historico": [
      {
        "ordem": 1,
        "data": "2026-10-30T08:15:00Z",
        "status": "PENDENTE",
        "observacao": "Chamado registrado aguardando vistoria da equipe de tapa-buraco.",
        "responsavel": "Mariana Oliveira Souza"
      },
      {
        "ordem": 2,
        "data": "2026-10-31T14:30:00Z",
        "status": "EM_ANALISE",
        "observacao": "Vistoria técnica presencial realizada; incluído na programação do recapeamento semanal.",
        "responsavel": "Coordenador Lucas Mendes"
      }
    ],
    "votos": [
      {
        "id_usuario": 1,
        "nome": "Carlos Alberto Silva",
        "dt_voto": "2026-10-30T09:30:00Z"
      },
      {
        "id_usuario": 4,
        "nome": "Fernanda Costa Lima",
        "dt_voto": "2026-10-30T14:15:00Z"
      }
    ],
    "triagem_ia": {
      "prioridade": "URGENTE",
      "parecer": "Risco elevado de sinistro de trânsito em via arterial.",
      "orgao_sugerido": "SECRETARIA_OBRAS"
    }
  },
  {
    "id_chamado": 3,
    "titulo": "Bueiro entupido com transbordamento de águas pluviais",
    "descricao": "Boca de lobo completamente obstruída por folhas e lixo acumulado. Em dias de chuva média ocorre alagamento da calçada.",
    "categoria": "DRENAGEM_E_ESGOTO",
    "status_atual": "CONCLUIDO",
    "dt_abertura": "2026-10-25T14:10:00Z",
    "total_votos": 0,
    "cidadao": {
      "id_usuario": 1,
      "nome": "Carlos Alberto Silva",
      "email": "carlos.silva@email.com"
    },
    "localizacao": {
      "rua": "Praça da Sé",
      "numero": "100",
      "referencia": "Em frente à Catedral da Sé",
      "bairro": "Sé",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01001000"
    },
    "historico": [
      {
        "ordem": 1,
        "data": "2026-10-25T14:10:00Z",
        "status": "PENDENTE",
        "observacao": "Abertura de chamado de galeria pluvial.",
        "responsavel": "Carlos Alberto Silva"
      },
      {
        "ordem": 2,
        "data": "2026-10-26T09:00:00Z",
        "status": "EM_ANALISE",
        "observacao": "Vistoria identificou acúmulo de detritos.",
        "responsavel": "Eng. Roberto Santos"
      },
      {
        "ordem": 3,
        "data": "2026-10-27T16:30:00Z",
        "status": "CONCLUIDO",
        "observacao": "Equipe de hidrojateamento concluiu a desobstrução e remoção de sedimentos da galeria.",
        "responsavel": "Eng. Roberto Santos"
      }
    ],
    "votos": [],
    "triagem_ia": {
      "prioridade": "ALTA",
      "parecer": "Obstrução de galeria pluvial com risco de alagamento local.",
      "orgao_sugerido": "SANEAMENTO_BASICO"
    }
  },
  {
    "id_chamado": 4,
    "titulo": "Descarte irregular de entulho e móveis velhos",
    "descricao": "Grande volume de entulho de construção civil e sofás descartados irregularmente bloqueando passagem de pedestres e cadeirantes.",
    "categoria": "LIMPEZA_URBANA",
    "status_atual": "PENDENTE",
    "dt_abertura": "2026-11-01T10:20:00Z",
    "total_votos": 2,
    "cidadao": {
      "id_usuario": 4,
      "nome": "Fernanda Costa Lima",
      "email": "fernanda.costa@email.com"
    },
    "localizacao": {
      "rua": "Rua da Mooca",
      "numero": "1500",
      "referencia": "Ao lado da estação Mooca",
      "bairro": "Mooca",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "03104001"
    },
    "historico": [
      {
        "ordem": 1,
        "data": "2026-11-01T10:20:00Z",
        "status": "PENDENTE",
        "observacao": "Registro de descarte irregular de entulho na calçada.",
        "responsavel": "Fernanda Costa Lima"
      }
    ],
    "votos": [
      {
        "id_usuario": 1,
        "nome": "Carlos Alberto Silva",
        "dt_voto": "2026-11-01T11:00:00Z"
      },
      {
        "id_usuario": 2,
        "nome": "Mariana Oliveira Souza",
        "dt_voto": "2026-11-01T14:20:00Z"
      }
    ],
    "triagem_ia": {
      "prioridade": "MEDIA",
      "parecer": "Obstrução de calçada e proliferação de vetores.",
      "orgao_sugerido": "SUBPREFEITURA"
    }
  },
  {
    "id_chamado": 5,
    "titulo": "Galho de grande porte com risco de queda sobre fiação elétrica",
    "descricao": "Galho seco de árvore centenária encostando diretamente nos cabos da rede elétrica com estalos em dias de vento forte.",
    "categoria": "ARVORES_E_PARQUES",
    "status_atual": "EM_ANALISE",
    "dt_abertura": "2026-11-02T11:45:00Z",
    "total_votos": 2,
    "cidadao": {
      "id_usuario": 1,
      "nome": "Carlos Alberto Silva",
      "email": "carlos.silva@email.com"
    },
    "localizacao": {
      "rua": "Avenida Cruzeiro do Sul",
      "numero": "2500",
      "referencia": "Em frente ao Metrô Santana",
      "bairro": "Santana",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "02030000"
    },
    "historico": [
      {
        "ordem": 1,
        "data": "2026-11-02T11:45:00Z",
        "status": "PENDENTE",
        "observacao": "Abertura de chamado de arborização com risco em fiação.",
        "responsavel": "Carlos Alberto Silva"
      },
      {
        "ordem": 2,
        "data": "2026-11-02T14:00:00Z",
        "status": "EM_ANALISE",
        "observacao": "Equipe técnica encaminhou protocolo urgente para Enel.",
        "responsavel": "Eng. Roberto Santos"
      }
    ],
    "votos": [
      {
        "id_usuario": 2,
        "nome": "Mariana Oliveira Souza",
        "dt_voto": "2026-11-02T12:00:00Z"
      },
      {
        "id_usuario": 4,
        "nome": "Fernanda Costa Lima",
        "dt_voto": "2026-11-02T13:10:00Z"
      }
    ],
    "triagem_ia": {
      "prioridade": "URGENTE",
      "parecer": "Interferência de arborização em rede de média tensão.",
      "orgao_sugerido": "DEFESA_CIVIL"
    }
  },
  {
    "id_chamado": 6,
    "titulo": "Semáforo de pedestres apagado em cruzamento escolar",
    "descricao": "Sinalização semafórica piscando em amarelo intermitente no cruzamento de fluxo de estudantes da escola local.",
    "categoria": "SINALIZACAO_E_TRANSITO",
    "status_atual": "CONCLUIDO",
    "dt_abertura": "2026-10-26T07:30:00Z",
    "total_votos": 0,
    "cidadao": {
      "id_usuario": 2,
      "nome": "Mariana Oliveira Souza",
      "email": "mariana.souza@email.com"
    },
    "localizacao": {
      "rua": "Avenida Paulista",
      "numero": "1106",
      "referencia": "Próximo ao MASP",
      "bairro": "Bela Vista",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01311000"
    },
    "historico": [
      {
        "ordem": 1,
        "data": "2026-10-26T07:30:00Z",
        "status": "PENDENTE",
        "observacao": "Semáforo com defeito comunicado por munícipe.",
        "responsavel": "Mariana Oliveira Souza"
      },
      {
        "ordem": 2,
        "data": "2026-10-26T15:00:00Z",
        "status": "CONCLUIDO",
        "observacao": "Equipe semafórica da CET realizou a substituição da controladora digital.",
        "responsavel": "Coordenador Lucas Mendes"
      }
    ],
    "votos": [],
    "triagem_ia": {
      "prioridade": "URGENTE",
      "parecer": "Risco a pedestres e crianças em travessia de faixa escolar.",
      "orgao_sugerido": "CET_TRANSITO"
    }
  },
  {
    "id_chamado": 7,
    "titulo": "Vazamento contínuo de água limpa no meio-fio",
    "descricao": "Cavalete ou tubulação rompida jorrando água limpa continuamente há 2 dias com erosão da sarjeta.",
    "categoria": "DRENAGEM_E_ESGOTO",
    "status_atual": "EM_EXECUCAO",
    "dt_abertura": "2026-11-03T16:50:00Z",
    "total_votos": 0,
    "cidadao": {
      "id_usuario": 4,
      "nome": "Fernanda Costa Lima",
      "email": "fernanda.costa@email.com"
    },
    "localizacao": {
      "rua": "Rua dos Pinheiros",
      "numero": "450",
      "referencia": "Esquina com Rua Fradique Coutinho",
      "bairro": "Pinheiros",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "05422000"
    },
    "historico": [
      {
        "ordem": 1,
        "data": "2026-11-03T16:50:00Z",
        "status": "PENDENTE",
        "observacao": "Comunicação de vazamento contínuo de água tratada.",
        "responsavel": "Fernanda Costa Lima"
      },
      {
        "ordem": 2,
        "data": "2026-11-04T08:30:00Z",
        "status": "EM_EXECUCAO",
        "observacao": "Técnicos em campo efetuando abertura de vala para reparo do cavalete.",
        "responsavel": "Eng. Roberto Santos"
      }
    ],
    "votos": [],
    "triagem_ia": {
      "prioridade": "ALTA",
      "parecer": "Desperdício de recurso hídrico e erosão asfáltica superficial.",
      "orgao_sugerido": "SANEAMENTO_BASICO"
    }
  },
  {
    "id_chamado": 8,
    "titulo": "Pichação em patrimônio histórico tombado",
    "descricao": "Vandalismo com tintas na fachada lateral do monumento público da praça.",
    "categoria": "LIMPEZA_URBANA",
    "status_atual": "REJEITADO",
    "dt_abertura": "2026-11-04T09:10:00Z",
    "total_votos": 0,
    "cidadao": {
      "id_usuario": 1,
      "nome": "Carlos Alberto Silva",
      "email": "carlos.silva@email.com"
    },
    "localizacao": {
      "rua": "Praça da Sé",
      "numero": "100",
      "referencia": "Em frente à Catedral da Sé",
      "bairro": "Sé",
      "cidade": "São Paulo",
      "estado": "SP",
      "cep": "01001000"
    },
    "historico": [
      {
        "ordem": 1,
        "data": "2026-11-04T09:10:00Z",
        "status": "PENDENTE",
        "observacao": "Abertura de denúncia de pichação.",
        "responsavel": "Carlos Alberto Silva"
      },
      {
        "ordem": 2,
        "data": "2026-11-04T11:20:00Z",
        "status": "REJEITADO",
        "observacao": "Solicitação indeferida por duplicidade de protocolo já cadastrado na concessionária.",
        "responsavel": "Eng. Roberto Santos"
      }
    ],
    "votos": [],
    "triagem_ia": {
      "prioridade": "BAIXA",
      "parecer": "Dano estético em fachada pública.",
      "orgao_sugerido": "SUBPREFEITURA"
    }
  }
];

const dadosParsed = caminhoJson
  ? JSON.parse(fs.readFileSync(caminhoJson, "utf8"))
  : DATASET_FALLBACK;

// 2. Seleciona o banco oficial da aplicação (equivale ao comando "use zelafix" do mongosh interativo)
const dbName = "zelafix";
const dbTarget = typeof db !== "undefined" && db.getSiblingDB ? db.getSiblingDB(dbName) : db;

log("====================================================================");
log(">>> [MongoDB ZelaFix] Conectado ao banco de dados: " + dbName);
log(caminhoJson
  ? ">>> Dataset localizado em: " + caminhoJson
  : ">>> Modo colagem interativa (Compass >_MONGOSH): carregando 8 chamados do fallback portátil embutido.");
log("====================================================================");

// 3. Remove coleção preexistente para recriação limpa e idempotente
try {
  dbTarget.chamados.drop();
  log(">>> Coleção antiga 'chamados' removida para recriação limpa.");
} catch (e) {
  // Ignora se a coleção ainda não existia
}

// 4. Criação da coleção 'chamados' com Validador de Schema JSON ($jsonSchema)
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
          enum: ["ILUMINACAO_PUBLICA", "VIAS_E_PAVIMENTACAO", "DRENAGEM_E_ESGOTO", "LIMPEZA_URBANA", "ARVORES_E_PARQUES", "SINALIZACAO_E_TRANSITO"],
          description: "Categoria do serviço público (alinhada ao CategoriaEnum)."
        },
        status_atual: {
          bsonType: "string",
          enum: ["PENDENTE", "EM_ANALISE", "EM_EXECUCAO", "CONCLUIDO", "REJEITADO"],
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
              status: {
                bsonType: "string",
                enum: ["PENDENTE", "EM_ANALISE", "EM_EXECUCAO", "CONCLUIDO", "REJEITADO"]
              },
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
            prioridade: {
              bsonType: "string",
              enum: ["BAIXA", "MEDIA", "ALTA", "URGENTE"]
            },
            parecer: { bsonType: "string" },
            orgao_sugerido: {
              bsonType: "string",
              enum: ["SECRETARIA_OBRAS", "CET_TRANSITO", "ILUMINACAO_PUBLICA", "DEFESA_CIVIL", "SUBPREFEITURA", "SANEAMENTO_BASICO"]
            }
          }
        }
      }
    }
  }
});
log(">>> Coleção 'chamados' criada com sucesso com $jsonSchema Validator.");

// 5. Criação de Índices Estratégicos
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

// 6. Carga de Dados a partir de 'chamados_dataset.json'
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
})();
