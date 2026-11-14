# Database-Advanced — 🏙️ ZelaFix (CitizenTech)
> Engenharia de Banco de Dados Relacional em 3FN Estrita, Empacotamento Avançado em Packages PL/SQL (`PKG_CHAMADO_GESTAO` e `PKG_ENGAJAMENTO_CIDADAO`), Trilha de Auditoria DML, Persistência Poliglota com MongoDB Atlas e Governança Urbana — FIAP Global Solution 2026/2 — Turma 2TDSPG.

---

## 👥 Integrantes do Projeto

| Nome | RM | Turma | GitHub | LinkedIn |
| :--- | :---: | :---: | :--- | :--- |
| **Enzo Okuizumi** | **561432** | 2TDSPG | [EnzoOkuizumiFiap](https://github.com/EnzoOkuizumiFiap) | [Enzo Okuizumi](https://www.linkedin.com/in/enzo-okuizumi-b60292256/) |
| **Gustavo Okada** | **563428** | 2TDSPG | [Gdev3356](https://github.com/Gdev3356) | [Gustavo Okada](https://www.linkedin.com/in/gustavo-okada-53a3b8359/) |
| **Lucas Barros Gouveia** | **566422** | 2TDSPG | [LuzBGouveia](https://github.com/LuzBGouveia) | [Lucas Barros Gouveia](https://www.linkedin.com/in/lucas-barros-gouveia-09b147355/) |
| **Luna de Carvalho Guimarães** | **562290** | 2TDSPG | [lunaguima](https://github.com/lunaguima) | [Luna Guimarães](https://www.linkedin.com/in/luna-guimar%C3%A3es-b0ba82309/) |
| **Milton Jakson de Sousa Marcelino** | **564836** | 2TDSPG | [MiltonMarcelino](https://github.com/MiltonMarcelino) | [Milton Marcelino](https://www.linkedin.com/in/milton-marcelino-250298142) |

---

## 🔗 Links e Estrutura Oficial de Arquivos da Entrega

* **Repositório GitHub:** https://github.com/Global-Solution-CitizenTech/Database-Advanced
* **Modelagem Data Modeler:** [Pasta `data modeler/`](./data%20modeler) (`citizenTech.dmd` e `citizenTech.ddl`)
* **Script SQL Relacional (DDL 3FN + Carga de Dados):** [`2TDSPG_2026_CodigoSql_ZelaFix.sql`](./2TDSPG_2026_CodigoSql_ZelaFix.sql)
* **Script PL/SQL Avançado (Packages, Triggers, Blocos e Testes):** [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql)
* **Pasta de Artefatos NoSQL MongoDB:** [`mongodb/`](./mongodb)
  * **Dataset de Chamados Enriquecidos:** [`chamados_dataset.json`](./mongodb/chamados_dataset.json)
  * **Dataset de Bairros Monitorados:** [`bairros_dataset.json`](./mongodb/bairros_dataset.json)
  * **Script NoSQL — Coleção `chamados`:** [`setup_mongodb_chamados.js`](./mongodb/setup_mongodb_chamados.js)
  * **Script NoSQL — Coleção `bairros_monitoramento`:** [`setup_mongodb_bairros.js`](./mongodb/setup_mongodb_bairros.js)
  * **Script NoSQL — 3 Consultas e Relatórios Analíticos:** [`consultas_relatorios_mongodb.js`](./mongodb/consultas_relatorios_mongodb.js)

---

## 📐 Modelagem Relacional Oracle (13 Tabelas em 3FN Estrita)

O modelo de dados do **ZelaFix** foi concebido no **Oracle SQL Developer Data Modeler 24.3** em rigorosa **3ª Forma Normal (3FN)**, estruturado para suportar toda a esteira de zeladoria urbana, histórico auditável de status e engajamento comunitário:

### 1. Modelo Lógico
![Modelo Lógico do ZelaFix](./docs/logical.png)

### 2. Modelo Relacional
![Modelo Relacional do ZelaFix](./docs/relational.png)

### Decisões de Normalização, Otimização DBA & Integridade Cívica:
1. **Desacoplamento do Status do Chamado (3FN Estrita + PRAGMA UDF + Otimização O(1)):** O status vigente não é duplicado na tabela `chamado`. A evolução completa vive na tabela `hist_chamado` (`dt_mudanca`, `observacoes`, `status_id_status`). O status atual é obtido pela função empacotada `pkg_chamado_gestao.fn_obter_status_atual(id_chamado)` que resolve em $\mathcal{O}(1)$ via `ORDER BY h.id_hist DESC FETCH FIRST 1 ROW ONLY`, aproveitando diretamente o índice composto `idx_hist_chamado_ativo`. A função é compilada com `PRAGMA UDF`, eliminando a penalidade de troca de contexto SQL/PLSQL.
2. **Índice Composto de Cobertura (`idx_hist_chamado_ativo`):** Criado sobre `(chamado_id_chamado, id_hist DESC, status_id_status)`, permitindo que o Oracle resolva o status atual diretamente no índice em $\mathcal{O}(1)$ (*Index Range Scan*) sem visitar os blocos de dados da tabela nem executar subconsultas aninhadas com MAX.
3. **Desduplicação de Índices e Eficiência de I/O:** O índice para `voto_chamado(chamado_id_chamado)` é suprido pela *leading column* da constraint `UNIQUE voto_chamado_un (chamado_id_chamado, usuario_id_usuario)`, eliminando índices redundantes e reduzindo a sobrecarga de I/O em operações de inserção concorrentes.
4. **Separação de Autoria vs. Apoio Comunitário (N:M):**
   - **Autoria (1:N):** `chamado.usuario_id_usuario` referencia exclusivamente o munícipe que abriu o chamado com foto.
   - **Apoios Comunitários (N:M):** `voto_chamado (chamado_id_chamado, usuario_id_usuario)` é a tabela associativa que permite que a vizinhança apoie a resolução rápida do problema, com a constraint `voto_chamado_un UNIQUE` para impedir autovoto e voto duplicado.
5. **Evidência Fotográfica Binária Nativa (`BLOB`):** A coluna `foto` na tabela `chamado` armazena diretamente os bytes das imagens no Oracle, eliminando riscos de URLs externas quebradas (404) durante a apresentação presencial da banca.
6. **Padronização Estrita de ENUMs (Oracle + MongoDB + Java Spring Boot):** As `CHECK` constraints relacionais e os `$jsonSchema` do MongoDB seguem integralmente os cinco `enums` da API Java:
   - `usuario.cargo`: `CIDADAO`, `GESTOR`, `ADMIN`
   - `categoria.nm_categoria`: `ILUMINACAO_PUBLICA`, `VIAS_E_PAVIMENTACAO`, `DRENAGEM_E_ESGOTO`, `LIMPEZA_URBANA`, `ARVORES_E_PARQUES`, `SINALIZACAO_E_TRANSITO`
   - `status.nm_status`: `PENDENTE`, `EM_ANALISE`, `EM_EXECUCAO`, `CONCLUIDO`, `REJEITADO`
   - `prioridade.nm_prioridade`: `BAIXA`, `MEDIA`, `ALTA`, `URGENTE`
   - `orgao_governo.orgao_governo`: `SECRETARIA_OBRAS`, `CET_TRANSITO`, `ILUMINACAO_PUBLICA`, `DEFESA_CIVIL`, `SUBPREFEITURA`, `SANEAMENTO_BASICO`

---

## 📦 Arquitetura PL/SQL Avançada (Packages, Funções, Procedures e Auditoria)

O arquivo [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql) foi desenvolvido para atender às exigências mais rigorosas da disciplina, eliminando quaisquer atalhos ou funções mágicas:

### 1. Pacote 1: `PKG_CHAMADO_GESTAO` (Ciclo de Vida do Chamado e Serialização Manual)
- **`pr_abrir_chamado`**: Abertura transacional atômica com validações de tamanho mínimo, foto BLOB obrigatória, integridade referencial de chaves estrangeiras (`usuario`, `endereco`, `categoria`, `prioridade`, `orgao_governo`), localização do status `PENDENTE` e gravação simultânea na tabela `chamado` e na linha do tempo `hist_chamado` (3FN estrita) via `RETURNING id_chamado INTO v_novo_id`.
- **`pr_atualizar_status_chamado`**: Validação rigorosa de existência de chamado, status e usuário fiscal, garantindo acesso exclusivo para fiscais com privilégio `cargo = 'GESTOR'`, inserindo nova etapa com observações no histórico auditável.
- **`fn_obter_status_atual`**: Função de alta performance (`PRAGMA UDF`) que resolve o status vigente em $\mathcal{O}(1)$ via ordenação decrescente por `id_hist` aproveitando diretamente o índice de cobertura `idx_hist_chamado_ativo`.
- **`fn_converter_chamado_json` (Conversão 100% Manual)**:
  - **Zero uso de funções nativas do Oracle**: Constrói o documento JSON manualmente em `CLOB` via `DBMS_LOB.CREATETEMPORARY` e `DBMS_LOB.WRITEAPPEND`.
  - Serializa o chamado com objetos aninhados (`categoria`, `prioridade`, `orgaoGoverno`, `cidadao`, `localizacao`), tratamento de caracteres de escape e o array embutido de histórico de status (`historicoStatus`) via cursor explícito.

### 2. Pacote 2: `PKG_ENGAJAMENTO_CIDADAO` (Inteligência Coletiva e Controle Territorial)
- **`pr_registrar_voto`**: Registra o apoio da comunidade ao chamado (relação N:M em `voto_chamado`), bloqueando autovoto (`v_autor = p_id_usuario`), duplicidade e impedindo votos em ocorrências já encerradas (`CONCLUIDO` ou `REJEITADO`).
- **`fn_calcular_total_votos`**: Função `PRAGMA UDF` otimizada sobre a *leading column* do índice único para contagem instantânea de apoios populares.
- **`fn_classificar_criticidade_bairro`**: Algoritmo heurístico que avalia o volume de chamados pendentes vs. resolvidos e votos acumulados no território, classificando em `'CRITICO'`, `'ALERTA'` ou `'NORMAL'`.
- **`pr_relatorio_subtotal_bairros` (Subtotais e Totais Gerais Feitos à Mão)**:
  - Implementa **quebra de grupo clássica (Control Break)** através de cursor explícito ordenado por `(b.nm_bairro, ch.id_chamado)`.
  - **Acumuladores Manuais em Variáveis PL/SQL**: Calcula à mão `v_sub_chamados`, `v_sub_pendentes`, `v_sub_concluidos` e `v_sub_votos` a cada transição de bairro.
  - Ao final do loop, emite o subtotal do último grupo e imprime o **TOTAL GERAL MUNICIPAL** com contagens consolidadas e cálculo manual da **Taxa Geral de Resolução (%)**.
  - **Zero uso de `ROLLUP` ou funções mágicas**: Demonstração completa de lógica algorítmica de acumuladores em PL/SQL.

### 3. Tratamento Específico de Exceções (Zero `WHEN OTHERS` Isolado)
Todas as rotinas implementam blocos `EXCEPTION` robustos com tratamento explícito para:
- `WHEN NO_DATA_FOUND THEN`: Captura registros inexistentes e retorna mensagens claras via `RAISE_APPLICATION_ERROR`.
- `WHEN DUP_VAL_ON_INDEX THEN`: Intercepta violações de unicidade (como repetição de voto comunitário).
- `WHEN VALUE_ERROR THEN`: Trata erros de conversão de tipos de dados ou estouros de buffers.
- `WHEN ZERO_DIVIDE THEN`: Protege cálculos de taxas percentuais quando o divisor for zero.
- **Exceções Customizadas de Negócio**: Declaradas no pacote e associadas a códigos de erro específicos via `PRAGMA EXCEPTION_INIT` (`-20001` a `-20025`), tais como `e_chamado_fechado`, `e_autovoto_proibido`, `e_usuario_nao_gestor`.
- `WHEN OTHERS THEN`: Utilizado exclusivamente como salvaguarda no final dos blocos após todas as exceções específicas terem sido tratadas.

### 4. Trilha de Auditoria DML e Regras de Negócio em Triggers
- **`TRG_AUDIT_CHAMADO`**: Trigger disparada após qualquer `INSERT`, `UPDATE` ou `DELETE` na tabela `CHAMADO`, gravando o usuário conectado (`USER`), carimbo de data/hora (`SYSTIMESTAMP`), operação executada e os snapshots dos dados anteriores (`:OLD`) e novos (`:NEW`) serializados manualmente em JSON na tabela `AUDITORIA_DML_CHAMADO`.
- **`TRG_VALIDA_VOTO_CHAMADO`**: Trigger de validação cívica antes do `INSERT` em `VOTO_CHAMADO`, garantindo no nível do SGBD o bloqueio de autovoto e de votos em chamados já finalizados.

### 5. Dois Blocos Anônimos PL/SQL
- **Bloco Anônimo 1 (Diagnóstico Territorial)**: Processamento em lote com cursor explícito, loop de repetição, estruturas de decisão `IF/ELSIF/ELSE`, invocação de funções empacotadas e cálculo da taxa percentual de resolução urbana.
- **Bloco Anônimo 2 (Painel de Auditoria de SLA)**: Auditoria operacional de ocorrências abertas há mais de 3 dias sem conclusão, avaliando apoio popular e identificando gargalos da zeladoria.

### 6. Bateria de Testes de Integração (Parte 5)
1. **Teste do Pacote 1**: Abertura atômica de chamado com foto BLOB, transição de status por gestor e geração manual de JSON com histórico em CLOB.
2. **Teste do Pacote 2**: Registro de apoio comunitário, totalização de votos e teste provocando a exceção específica de autovoto (`e_autovoto_proibido`).
3. **Teste de Subtotais**: Emissão do relatório territorial com quebra de grupo, subtotais e total geral feitos à mão (`pr_relatorio_subtotal_bairros`).
4. **Teste de Auditoria DML**: Verificação dos registros gerados pela trigger `TRG_AUDIT_CHAMADO` na tabela `AUDITORIA_DML_CHAMADO`.
- Finalizado com comando `ROLLBACK;` para preservação da integridade das sementes de teste.

---

## 🔄 Matriz de Mapeamento: Do Relacional ao MongoDB

A transição do modelo relacional para documentos adota escolhas entre **documentos incorporados (*embedding*)** e **referências (*referencing*)**:

| Conceito / Entidade Relacional (Oracle) | Representação NoSQL (MongoDB) | Padrão Adotado | Justificativa Técnica da Transição |
| :--- | :--- | :---: | :--- |
| `chamado` + `usuario` + `endereco` + `bairro` + `cidade` + `prioridade` + `orgao_governo` | Documento raiz `chamados` com subdocumentos `cidadao`, `localizacao` e `triagem_ia` | **Embedding** | Leituras atômicas: o aplicativo móvel do cidadão recupera todo o contexto do chamado, prioridade e órgão responsável em uma única operação $\mathcal{O}(1)$ sem realizar múltiplos joins. |
| `hist_chamado` (Linha do tempo) | Array embutido `historico: [ { data, status, observacao, responsavel } ]` | **Embedding** | O histórico de status é delimitado e raramente ultrapassa 10 eventos por chamado, tornando ideal a incorporação de acordo com o padrão *Document Versioning*. |
| `voto_chamado` (Apoios populares) | Array embutido `votos: [ { id_usuario, nome, dt_voto } ]` | **Embedding** | Preserva a rastreabilidade de quem apoiou a ocorrência diretamente no documento principal. |
| Total de votos computado | Campo desnormalizado `total_votos: NumberInt` | **Desnormalização Controlada** | No Oracle, a contagem exige `COUNT(v.id_voto)` com `GROUP BY`. No MongoDB, o total é armazenado diretamente para permitir índice ordenado (`{ total_votos: -1 }`) e ranking instantâneo. |
| Gestão Territorial das Subprefeituras | Coleção separada `bairros_monitoramento` | **Referencing Lógico** | Bairros são entidades de análise autônoma com ciclo de vida independente dos chamados. O vínculo é mantido pelo campo lógico `id_bairro`. |

---

## 📊 Relatórios Analíticos: Comparação Direta Oracle SQL vs. MongoDB

### Relatório 1: Ocorrências Ativas com Maior Apoio Comunitário (Radar do Bairro)
> **Objetivo de Negócio:** Priorizar na esteira da Subprefeitura os chamados abertos mais votados pela vizinhança.

* **MongoDB:**
  ```javascript
  db.chamados.find(
    { status_atual: { $nin: ["CONCLUIDO", "REJEITADO"] } },
    { _id: 0, id_chamado: 1, titulo: 1, categoria: 1, "localizacao.bairro": 1, total_votos: 1, status_atual: 1 }
  ).sort({ total_votos: -1, id_chamado: 1 });
  ```
* **Oracle SQL:**
  ```sql
  SELECT c.id_chamado, c.titulo, cat.nm_categoria, b.nm_bairro,
         COUNT(v.id_voto) AS total_votos,
         pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) AS status_atual
    FROM chamado c
    JOIN categoria cat ON cat.id_categoria = c.categoria_id_categoria
    JOIN endereco e ON e.id_endereco = c.endereco_id_endereco
    JOIN bairro b ON b.id_bairro = e.bairro_id_bairro
    LEFT JOIN voto_chamado v ON v.chamado_id_chamado = c.id_chamado
   WHERE pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) NOT IN ('CONCLUIDO', 'REJEITADO')
   GROUP BY c.id_chamado, c.titulo, cat.nm_categoria, b.nm_bairro
   ORDER BY total_votos DESC, c.id_chamado ASC;
  ```

* **Resultado Comparativo Obtido:**

| ID Chamado | Título | Bairro | Categoria | Status Atual | Votos (Apoios) |
| :---: | :--- | :--- | :--- | :---: | :---: |
| **1** | Poste com lâmpada apagada em via principal | Bela Vista | `ILUMINACAO_PUBLICA` | `EM_EXECUCAO` | **2** |
| **2** | Buraco profundo na faixa da direita da via | Pinheiros | `VIAS_E_PAVIMENTACAO` | `EM_ANALISE` | **2** |
| **4** | Descarte irregular de entulho e móveis velhos | Mooca | `LIMPEZA_URBANA` | `PENDENTE` | **2** |
| **5** | Galho de grande porte com risco de queda | Santana | `ARVORES_E_PARQUES` | `EM_ANALISE` | **2** |
| **7** | Vazamento contínuo de água limpa no meio-fio | Pinheiros | `DRENAGEM_E_ESGOTO` | `EM_EXECUCAO` | **0** |

---

### Relatório 2: Agrupamento por Categoria Urbana e Volume de Ocorrências (Aggregation)
> **Objetivo de Negócio:** Mapear os gargalos operacionais e serviços com maior demanda reprimida para planejamento público.

* **MongoDB (Aggregation Pipeline com `$group` e `$sort`):**
  ```javascript
  db.chamados.aggregate([
    {
      $group: {
        _id: "$categoria",
        total_ocorrencias: { $sum: 1 },
        total_votos_acumulados: { $sum: "$total_votos" },
        ocorrencias_abertas: {
          $sum: {
            $cond: [
              { $in: ["$status_atual", ["PENDENTE", "EM_ANALISE", "EM_EXECUCAO"]] },
              1,
              0
            ]
          }
        },
        ocorrencias_concluidas: {
          $sum: {
            $cond: [{ $eq: ["$status_atual", "CONCLUIDO"] }, 1, 0]
          }
        }
      }
    },
    { $sort: { total_ocorrencias: -1, total_votos_acumulados: -1 } }
  ]);
  ```
* **Oracle SQL:**
  ```sql
  SELECT cat.nm_categoria AS categoria,
         COUNT(c.id_chamado) AS total_ocorrencias,
         NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) IN ('PENDENTE', 'EM_ANALISE', 'EM_EXECUCAO') THEN 1 ELSE 0 END), 0) AS ocorrencias_abertas,
         NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) = 'CONCLUIDO' THEN 1 ELSE 0 END), 0) AS ocorrencias_concluidas,
         COUNT(v.id_voto) AS total_votos_acumulados
    FROM categoria cat
    LEFT JOIN chamado c ON c.categoria_id_categoria = cat.id_categoria
    LEFT JOIN voto_chamado v ON v.chamado_id_chamado = c.id_chamado
   GROUP BY cat.nm_categoria
   ORDER BY total_ocorrencias DESC, total_votos_acumulados DESC;
  ```

* **Resultado Comparativo Obtido:**

| Categoria Urbana | Total de Ocorrências | Ocorrências Abertas | Ocorrências Concluídas | Votos Acumulados |
| :--- | :---: | :---: | :---: | :---: |
| **`LIMPEZA_URBANA`** | 2 | 1 | 0 | 2 |
| **`DRENAGEM_E_ESGOTO`** | 2 | 1 | 1 | 0 |
| **`ILUMINACAO_PUBLICA`** | 1 | 1 | 0 | 2 |
| **`VIAS_E_PAVIMENTACAO`** | 1 | 1 | 0 | 2 |
| **`ARVORES_E_PARQUES`** | 1 | 1 | 0 | 2 |
| **`SINALIZACAO_E_TRANSITO`** | 1 | 0 | 1 | 0 |

---

### Relatório 3: Diagnóstico Territorial de Criticidade por Bairro (Aggregation Avançado)
> **Objetivo de Negócio:** Calcular a taxa percentual de pendência territorial para alocação de mutirões da Zeladoria Urbana.

* **MongoDB (Pipeline com `$group`, `$project` com operadores matemáticos e `$sort`):**
  ```javascript
  db.chamados.aggregate([
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
    { $sort: { chamados_pendentes: -1, votos_totais: -1, bairro: 1 } }
  ]);
  ```
* **Oracle SQL:**
  ```sql
  SELECT b.nm_bairro AS bairro,
         c.nm_cidade AS cidade,
         COUNT(ch.id_chamado) AS total_chamados,
         NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) <> 'CONCLUIDO' THEN 1 ELSE 0 END), 0) AS chamados_pendentes,
         NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) = 'CONCLUIDO' THEN 1 ELSE 0 END), 0) AS chamados_resolvidos,
         ROUND((NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) <> 'CONCLUIDO' THEN 1 ELSE 0 END), 0) / COUNT(ch.id_chamado)) * 100, 1) AS taxa_pendencia_pct,
         COUNT(v.id_voto) AS votos_totais
    FROM bairro b
    JOIN cidade c ON c.id_cidade = b.cidade_id_cidade
    JOIN endereco e ON e.bairro_id_bairro = b.id_bairro
    JOIN chamado ch ON ch.endereco_id_endereco = e.id_endereco
    LEFT JOIN voto_chamado v ON v.chamado_id_chamado = ch.id_chamado
   GROUP BY b.nm_bairro, c.nm_cidade
   ORDER BY chamados_pendentes DESC, votos_totais DESC, b.nm_bairro ASC;
  ```

* **Resultado Comparativo Obtido:**

| Bairro | Cidade | Total de Chamados | Pendentes | Resolvidos | Taxa de Pendência (%) | Total de Apoios |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| **Pinheiros** | São Paulo | 2 | **2** | 0 | **100.0%** | 2 |
| **Bela Vista** | São Paulo | 2 | **1** | 1 | **50.0%** | 2 |
| **Mooca** | São Paulo | 1 | **1** | 0 | **100.0%** | 2 |
| **Santana** | São Paulo | 1 | **1** | 0 | **100.0%** | 2 |
| **Sé** | São Paulo | 2 | **1** *(rejeitado)* | 1 | **50.0%** | 0 |

---

## 🚀 Guia Passo a Passo de Execução

### Opção 1: Execução no Oracle Database (SQL Developer / SQLcl / VS Code)

1. **Passo 1 — Carga DDL e Sementes Relacionais:**
   - Execute o script [`2TDSPG_2026_CodigoSql_ZelaFix.sql`](./2TDSPG_2026_CodigoSql_ZelaFix.sql).
   - Ele limpa o ambiente de forma idempotente, cria as 13 tabelas em 3FN (`estado`, `cidade`, `bairro`, `endereco`, `usuario`, `telefone`, `categoria`, `status`, `prioridade`, `orgao_governo`, `chamado`, `hist_chamado`, `voto_chamado`) + tabela de auditoria (`auditoria_dml_chamado`), cria as PKs, FKs, constraints e insere as sementes válidas com `COMMIT`.
2. **Passo 2 — Empacotamento PL/SQL, Triggers e Testes:**
   - Execute o script [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql).
   - Ele compila as packages `PKG_CHAMADO_GESTAO` e `PKG_ENGAJAMENTO_CIDADAO`, as triggers `TRG_AUDIT_CHAMADO` e `TRG_VALIDA_VOTO_CHAMADO`, os 2 blocos anônimos e roda a bateria de testes de integração com `DBMS_OUTPUT` e `ROLLBACK` seguro.

---

### Opção 2: Carga e Consultas no MongoDB (MongoDB Compass ou mongosh)

Todos os artefatos residem na pasta [`mongodb/`](./mongodb).

> 💡 **Nota de Conexão Atlas para Avaliação:** A URI de conexão com o banco na nuvem oficial da disciplina é:
> `mongodb+srv://enzookuizumifiap_db_user:tSzxhkbxANQizqdA@zelafix.t2rxvpu.mongodb.net/zelafix`

#### Execução no MongoDB Compass (Aba `>_MONGOSH`):
1. Abra o **MongoDB Compass** e conecte-se com a URI do cluster acima.
2. Abra a aba inferior **`>_MONGOSH`**.
3. Navegue até o diretório do projeto e execute os scripts modulares na ordem:
   ```javascript
   // 1. Aponta para a pasta do MongoDB
   process.chdir("C:/Users/Enzo/new_backup/FIAP/_Projetos/Global_Solution_2/Database-Advanced/mongodb")

   // 2. Cria validador de schema e popula a coleção 'chamados'
   load("setup_mongodb_chamados.js")

   // 3. Cria validador de schema e popula a coleção 'bairros_monitoramento'
   load("setup_mongodb_bairros.js")

   // 4. Executa os 3 Relatórios Analíticos com Aggregation Pipeline
   load("consultas_relatorios_mongodb.js")
   ```

#### Execução via Linha de Comando (`mongosh`):
```bash
cd Database-Advanced/mongodb

# 1. Carga da Coleção 'chamados'
mongosh "mongodb+srv://enzookuizumifiap_db_user:tSzxhkbxANQizqdA@zelafix.t2rxvpu.mongodb.net/zelafix" setup_mongodb_chamados.js

# 2. Carga da Coleção 'bairros_monitoramento'
mongosh "mongodb+srv://enzookuizumifiap_db_user:tSzxhkbxANQizqdA@zelafix.t2rxvpu.mongodb.net/zelafix" setup_mongodb_bairros.js

# 3. Execução dos 3 Relatórios Analíticos (Aggregation Pipeline)
mongosh "mongodb+srv://enzookuizumifiap_db_user:tSzxhkbxANQizqdA@zelafix.t2rxvpu.mongodb.net/zelafix" consultas_relatorios_mongodb.js
```

---

## 🧪 Evidências de Validação e Integridade

Ao executar [`consultas_relatorios_mongodb.js`](./mongodb/consultas_relatorios_mongodb.js), as saídas no console comprovam a equivalência matemática absoluta com os dados relacionais do Oracle:

```text
====================================================================
  ZELAFIX CITIZENTECH — RELATÓRIOS ANALÍTICOS NoSQL (MONGODB)
  Execução dos 3 Relatórios Obrigatórios (Edital GS2 - Págs 70-76)
====================================================================

--------------------------------------------------------------------
>>> RELATÓRIO 1: Ocorrências Ativas com Maior Apoio Comunitário
--------------------------------------------------------------------
1. [ID 1] Poste com lâmpada apagada em via principal    | Bairro: Bela Vista   | Categoria: ILUMINACAO_PUBLICA     | Status: EM_EXECUCAO  | Apoios: 2
2. [ID 2] Buraco profundo na faixa da direita da via    | Bairro: Pinheiros    | Categoria: VIAS_E_PAVIMENTACAO    | Status: EM_ANALISE   | Apoios: 2
3. [ID 4] Descarte irregular de entulho e móveis velhos | Bairro: Mooca        | Categoria: LIMPEZA_URBANA         | Status: PENDENTE     | Apoios: 2
4. [ID 5] Galho de grande porte com risco de queda      | Bairro: Santana      | Categoria: ARVORES_E_PARQUES      | Status: EM_ANALISE   | Apoios: 2
5. [ID 7] Vazamento contínuo de água limpa no meio-fio  | Bairro: Pinheiros    | Categoria: DRENAGEM_E_ESGOTO      | Status: EM_EXECUCAO  | Apoios: 0

--------------------------------------------------------------------
>>> RELATÓRIO 2 (AGGREGATION): Volume de Ocorrências por Categoria Urbana
--------------------------------------------------------------------
 - Categoria: LIMPEZA_URBANA            | Total:  2 | Pendentes:  1 | Concluídas:  0 | Apoios Acumulados:  2
 - Categoria: DRENAGEM_E_ESGOTO         | Total:  2 | Pendentes:  1 | Concluídas:  1 | Apoios Acumulados:  0
 - Categoria: ILUMINACAO_PUBLICA        | Total:  1 | Pendentes:  1 | Concluídas:  0 | Apoios Acumulados:  2
 - Categoria: VIAS_E_PAVIMENTACAO       | Total:  1 | Pendentes:  1 | Concluídas:  0 | Apoios Acumulados:  2
 - Categoria: ARVORES_E_PARQUES         | Total:  1 | Pendentes:  1 | Concluídas:  0 | Apoios Acumulados:  2
 - Categoria: SINALIZACAO_E_TRANSITO    | Total:  1 | Pendentes:  0 | Concluídas:  1 | Apoios Acumulados:  0

--------------------------------------------------------------------
>>> RELATÓRIO 3 (AGGREGATION AVANÇADO): Diagnóstico de Pendência por Bairro
--------------------------------------------------------------------
 - Bairro: Pinheiros       (São Paulo) | Total:  2 | Pendentes:  2 | Resolvidos:  0 | Taxa Pendência: 100.0% | Apoios:  2
 - Bairro: Bela Vista      (São Paulo) | Total:  2 | Pendentes:  1 | Resolvidos:  1 | Taxa Pendência:  50.0% | Apoios:  2
 - Bairro: Mooca           (São Paulo) | Total:  1 | Pendentes:  1 | Resolvidos:  0 | Taxa Pendência: 100.0% | Apoios:  2
 - Bairro: Santana         (São Paulo) | Total:  1 | Pendentes:  1 | Resolvidos:  0 | Taxa Pendência: 100.0% | Apoios:  2
 - Bairro: Sé              (São Paulo) | Total:  2 | Pendentes:  1 | Resolvidos:  1 | Taxa Pendência:  50.0% | Apoios:  0

====================================================================
  EXECUÇÃO CONCLUÍDA COM SUCESSO! DADOS EM HARMONIA COM O ORACLE.
====================================================================
```
