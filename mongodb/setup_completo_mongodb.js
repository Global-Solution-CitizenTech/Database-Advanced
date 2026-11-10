// ====================================================================
// FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
// CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
// DISCIPLINA: Mastering Relational and Non-Relational Database
// SCRIPT MESTRE: Orquestração Completa do Ambiente NoSQL MongoDB
// PROJETO: ZelaFix — Zeladoria Urbana Colaborativa
// TURMA: 2TDSPG
// INTEGRANTES:
//   1. Enzo Okuizumi                    - RM: 561432
//   2. Gustavo Okada                    - RM: 563428
//   3. Lucas Barros Gouveia             - RM: 566422
//   4. Luna de Carvalho Guimarães       - RM: 562290
//   5. Milton Jakson de Sousa Marcelino - RM: 564836
//
// COMO EXECUTAR EM COMANDO ÚNICO:
// 1. Via Linha de Comando (mongosh):
//    cd Database-Advanced/mongodb
//    mongosh "mongodb+srv://<usuario>:<senha>@zelafix.t2rxvpu.mongodb.net/zelafix" setup_completo_mongodb.js
//    (Credenciais de acesso disponíveis no README.md e no arquivo .env)
// 2. No MongoDB Compass (aba inferior ">_MONGOSH"):
//    process.chdir("<caminho_do_repositorio>/Database-Advanced/mongodb")
//    load("setup_completo_mongodb.js")
// ====================================================================

const log = typeof console !== "undefined" && console.log ? console.log : print;

log("====================================================================");
log("  ZELAFIX CITIZENTECH — INICIALIZAÇÃO COMPLETA DO MONGODB ATLAS");
log("  Execução Sequencial Automatizada (Setup Chamados -> Bairros -> Relatórios)");
log("====================================================================");

const fs = require("fs");
const path = require("path");

function resolverScript(nomeArquivo) {
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

// 1. Executa Setup da Coleção Chamados
const scriptChamados = resolverScript("setup_mongodb_chamados.js");
if (scriptChamados) {
  log("\n>>> [ETAPA 1/3] Executando Setup da Coleção 'chamados'...");
  if (typeof load !== "undefined") {
    load(scriptChamados);
  } else {
    require(scriptChamados);
  }
}

// 2. Executa Setup da Coleção Bairros
const scriptBairros = resolverScript("setup_mongodb_bairros.js");
if (scriptBairros) {
  log("\n>>> [ETAPA 2/3] Executando Setup da Coleção 'bairros_monitoramento'...");
  if (typeof load !== "undefined") {
    load(scriptBairros);
  } else {
    require(scriptBairros);
  }
}

// 3. Executa os Relatórios Analíticos
const scriptRelatorios = resolverScript("consultas_relatorios_mongodb.js");
if (scriptRelatorios) {
  log("\n>>> [ETAPA 3/3] Executando Consultas e Relatórios Analíticos...");
  if (typeof load !== "undefined") {
    load(scriptRelatorios);
  } else {
    require(scriptRelatorios);
  }
}

log("\n====================================================================");
log("  >>> INICIALIZAÇÃO COMPLETA DO MONGODB FINALIZADA COM SUCESSO! <<<");
log("====================================================================");
