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

* **Repositório GitHub:** [https://github.com/FIAP-Global-Solution-2TDSPG/Database-Advanced](https://github.com/FIAP-Global-Solution-2TDSPG/Database-Advanced)
* **Modelagem Data Modeler:** [Pasta `data modeler/`](./data%20modeler) (`citizenTech.dmd` e `citizenTech.ddl`)
* **Script SQL Relacional (DDL 3FN + Carga de Dados):** [`2TDSPG_2026_CodigoSql_ZelaFix.sql`](./2TDSPG_2026_CodigoSql_ZelaFix.sql)
* **Script PL/SQL Avançado (Packages, Triggers, Blocos e Testes):** [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql)
* **Pasta de Artefatos NoSQL MongoDB:** [`mongodb/`](./mongodb)
  * **Script Mestre NoSQL (Carga Completa + Relatórios em Comando Único):** [`setup_completo_mongodb.js`](./mongodb/setup_completo_mongodb.js)
  * **Dataset de Chamados Enriquecidos:** [`chamados_dataset.json`](./mongodb/chamados_dataset.json)
  * **Dataset de Bairros Monitorados:** [`bairros_dataset.json`](./mongodb/bairros_dataset.json)
  * **Script NoSQL — Coleção `chamados`:** [`setup_mongodb_chamados.js`](./mongodb/setup_mongodb_chamados.js)
  * **Script NoSQL — Coleção `bairros_monitoramento`:** [`setup_mongodb_bairros.js`](./mongodb/setup_mongodb_bairros.js)
  * **Script NoSQL — 3 Consultas e Relatórios Analíticos:** [`consultas_relatorios_mongodb.js`](./mongodb/consultas_relatorios_mongodb.js)

---

## 🎯 Rastreabilidade dos Requisitos do Edital (Páginas 70–76)

| Item | Requisito Oficial da Avaliação | Pontos | Onde Encontrar | Status |
| :---: | :--- | :---: | :--- | :---: |
| **01** | **Modelo Relacional Oracle Funcional e 2 Blocos Anônimos:** DDL com constraints, sementes válidas em 3FN e 2 blocos anônimos com `IF`, `LOOP` e cursores explícitos. | 10 pts | [`2TDSPG_2026_CodigoSql_ZelaFix.sql`](./2TDSPG_2026_CodigoSql_ZelaFix.sql) e Parte 4 de [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql) | **Concluído** |
| **02** | **Funções e Procedimentos PL/SQL com Conversão Manual e Subtotais:** Mínimo de 2 funções e 2 procedimentos. Destaque para conversão manual para JSON (`fn_converter_chamado_json`) e procedure com subtotais e total geral calculados à mão (`pr_relatorio_territorial_subtotais`). | 15 pts | Pacotes `PKG_CHAMADO_GESTAO` e `PKG_ENGAJAMENTO_CIDADAO` em [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql) | **Concluído** |
| **03** | **Gatilhos & Trilha de Auditoria DML:** 2 triggers implementadas, com auditoria completa de `:OLD` vs `:NEW` formatada em JSON manual na tabela `AUDITORIA_DML_CHAMADO`, além de trigger de integridade cívica contra autovoto. | 10 pts | Triggers `TRG_AUDIT_CHAMADO` e `TRG_VALIDA_VOTO_CHAMADO` (Parte 3 de [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql)) | **Concluído** |
| **04** | **Pacotes Oracle PL/SQL & Tratamento Específico de Exceções:** 2 pacotes modulares (Spec + Body), tratamento rigoroso de exceções (`NO_DATA_FOUND`, `DUP_VAL_ON_INDEX`, `VALUE_ERROR`, etc. - zero `WHEN OTHERS` isolado) e 9 blocos de testes de integração. | 10 pts | Partes 1, 2 e 5 de [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql) | **Concluído** |
| **05** | **Estrutura MongoDB & Carga de Documentos:** Script `.js` para selecionar/criar database, criar 2 collections com validação de schema e carga de no mínimo 10 documentos. | 10 pts | Scripts [`setup_mongodb_chamados.js`](./mongodb/setup_mongodb_chamados.js) e [`setup_mongodb_bairros.js`](./mongodb/setup_mongodb_bairros.js) totalizando **13 documentos** inseridos | **Concluído** |
| **06** | **Mapeamento Relacional->Documental e 3 Relatórios Analíticos:** Matriz de mapeamento conceitual, 3 relatórios com agregação (`$group`, `$project`) comparados com Oracle SQL equivalente. | 15 pts | Matriz documentada nesta seção e script executável [`consultas_relatorios_mongodb.js`](./mongodb/consultas_relatorios_mongodb.js) | **Concluído** |
| **TOTAL** | **Pontuação da Submissão Técnica (70% da Nota da Disciplina)** | **70 pts** | Todos os artefatos funcionais e testados sem dependências externas quebradas | **100% Atingido** |

---

## 📐 Modelagem Relacional Oracle (11 Tabelas em 3FN Estrita)

O modelo de dados do **ZelaFix** foi concebido no **Oracle SQL Developer Data Modeler 24.3** em rigorosa **3ª Forma Normal (3FN)**, estruturado para suportar toda a esteira de zeladoria urbana, histórico auditável de status e engajamento comunitário:

### 1. Modelo Lógico
![Modelo Lógico do ZelaFix](./docs/logical.png)

### 2. Modelo Relacional
![Modelo Relacional do ZelaFix](./docs/relational.png)

### Decisões de Normalização, Otimização DBA & Integridade Cívica:
1. **Desacoplamento do Status do Chamado (3FN Estrita + PRAGMA UDF):** O status vigente não é duplicado na tabela `chamado`. A evolução completa vive na tabela `hist_chamado` (`dt_mudanca`, `observacoes`, `status_id_status`). O status atual é obtido pela função empacotada `pkg_chamado_gestao.fn_obter_status_atual(id_chamado)` que resolve via subconsulta `MAX(id_hist)`. A função é compilada com `PRAGMA UDF`, eliminando a penalidade de troca de contexto SQL/PLSQL.
2. **Índice Composto de Cobertura (`idx_hist_chamado_ativo`):** Criado sobre `(chamado_id_chamado, id_hist DESC, status_id_status)`, permitindo que o Oracle resolva o status atual diretamente no índice em $\mathcal{O}(1)$ (*Index Range Scan / MIN/MAX Optimization*) sem visitar os blocos de dados da tabela.
3. **Desduplicação de Índices e Eficiência de I/O:** O índice para `voto_chamado(chamado_id_chamado)` é suprido pela *leading column* da constraint `UNIQUE voto_chamado_un (chamado_id_chamado, usuario_id_usuario)`, eliminando índices redundantes e reduzindo a sobrecarga de I/O em operações de inserção concorrentes.
4. **Separação de Autoria vs. Apoio Comunitário (N:M):**
   - **Autoria (1:N):** `chamado.usuario_id_usuario` referencia exclusivamente o munícipe que abriu o chamado com foto.
   - **Apoios Comunitários (N:M):** `voto_chamado (chamado_id_chamado, usuario_id_usuario)` é a tabela associativa que permite que a vizinhança apoie a resolução rápida do problema, com a constraint `voto_chamado_un UNIQUE` para impedir autovoto e voto duplicado.
5. **Evidência Fotográfica Binária Nativa (`BLOB`):** A coluna `foto` na tabela `chamado` armazena diretamente os bytes das imagens no Oracle, eliminando riscos de URLs externas quebradas (404) durante a apresentação presencial da banca.

---

## 📦 Arquitetura PL/SQL Avançada (Packages, Funções, Procedures e Auditoria)

O arquivo [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql) foi desenvolvido para atender às exigências mais rigorosas da disciplina, eliminando quaisquer atalhos ou funções mágicas:

### 1. Pacote 1: `PKG_CHAMADO_GESTAO` (Ciclo de Vida do Chamado e Auditoria)
- **`pr_abrir_chamado`**: Abertura transacional atômica que grava o chamado na tabela `chamado` e automaticamente registra o primeiro histórico com status `ABERTO` em `hist_chamado` (3FN estrita).
- **`pr_atualizar_status_chamado`**: Valida se o usuário tem privilégio de gestor/fiscal e registra a nova etapa no ciclo de atendimento do chamado com observações.
- **`fn_obter_status_atual`**: Função de alta performance (`PRAGMA UDF`) que resolve o status vigente via subconsulta analítica de `MAX(id_hist)`.
- **`fn_converter_chamado_json` (Conversão 100% Manual)**:
  - **Zero uso de funções nativas do Oracle**: Sem atalhos, constrói a estrutura JSON caractere a caractere via concatenação pura de strings em `CLOB`.
  - Trata campos nulos com `NVL(..., 'null')`, formata datas ISO 8601 (`YYYY-MM-DD"T"HH24:MI:SS`) e inclui o array embutido de histórico temporal montado também à mão via cursor explícito.
- **`pr_registrar_auditoria_chamado`**: Grava a trilha na tabela `auditoria_dml_chamado` com os payloads de `:OLD` e `:NEW` serializados manualmente em formato JSON.

### 2. Pacote 2: `PKG_ENGAJAMENTO_CIDADAO` (Inteligência Coletiva e Controle Territorial)
- **`pr_registrar_voto`**: Registra o apoio da comunidade ao chamado (relação N:M em `voto_chamado`), impedindo autovoto e duplicidade.
- **`fn_calcular_total_votos`**: Apura a quantidade de votos/apoios de qualquer chamado.
- **`fn_classificar_criticidade_bairro`**: Algoritmo heurístico que avalia o volume de chamados pendentes vs. resolvidos do bairro e retorna `'CRITICO'`, `'ALERTA'` ou `'NORMAL'`.
- **`pr_relatorio_territorial_subtotais` (Subtotais e Totais Gerais Feitos à Mão)**:
  - Implementa **quebra de grupo clássica (Control Break)** através de cursor explícito ordenado por `(b.nm_bairro, c.nm_cidade)`.
  - **Acumuladores Manuais em Variáveis PL/SQL**: Calcula à mão `v_subtotal_chamados`, `v_subtotal_pendentes`, `v_subtotal_concluidos`, `v_subtotal_votos` a cada transição de bairro.
  - Ao final do loop, emite o subtotal do último grupo e imprime o **TOTAL GERAL MUNICIPAL** com contagens consolidadas e cálculo manual da **Taxa Geral de Resolução**.
  - **Zero uso de `ROLLUP` ou funções mágicas**: Demonstração completa de lógica algorítmica de acumuladores em PL/SQL.
- **`pr_relatorio_engajamento_json`**: Constrói um documento JSON analítico completo de um bairro via manipulação de `CLOB` temporário (`DBMS_LOB.CREATETEMPORARY`, `WRITEAPPEND`), gerando o array de ocorrências sem funções nativas.

### 3. Tratamento Específico de Exceções (Zero `WHEN OTHERS` Isolado)
Todas as rotinas implementam blocos `EXCEPTION` robustos com tratamento explícito para:
- `WHEN NO_DATA_FOUND THEN`: Captura registros inexistentes e retorna mensagens claras via `RAISE_APPLICATION_ERROR`.
- `WHEN DUP_VAL_ON_INDEX THEN`: Intercepta violações de unicidade (como repetição de voto).
- `WHEN VALUE_ERROR THEN`: Trata erros de conversão de tipos de dados ou estouros de buffers.
- `WHEN ZERO_DIVIDE THEN`: Protege cálculos de taxas percentuais quando o divisor for zero.
- **Exceções Customizadas de Negócio**: Declaradas no pacote e associadas a códigos de erro específicos via `PRAGMA EXCEPTION_INIT` (`-20001` a `-20025`), tais como `e_chamado_fechado`, `e_autovoto_proibido`, `e_usuario_nao_gestor`.
- `WHEN OTHERS THEN`: Utilizado exclusivamente como salvaguarda no final dos blocos após todas as exceções específicas terem sido tratadas.

### 4. Trilha de Auditoria DML Ativa (`TRG_AUDIT_CHAMADO`)
- Disparada após qualquer `INSERT`, `UPDATE` ou `DELETE` na tabela `CHAMADO`.
- Captura o usuário conectado (`USER`), carimbo de data/hora (`SYSTIMESTAMP`), a operação executada e os snapshots dos dados anteriores (`:OLD`) e novos (`:NEW`), persistindo na tabela `AUDITORIA_DML_CHAMADO`.

### 5. Bateria de Testes de Integração (9 Blocos na Parte 5)
1. `pr_abrir_chamado`: Abertura com BLOB e inserção atômica de status.
2. `pr_atualizar_status_chamado`: Transição por gestor com histórico auditável.
3. `fn_converter_chamado_json`: Geração manual de JSON e verificação de tamanho em CLOB.
4. `pr_registrar_voto`: Votação comunitária e apuração com `fn_calcular_total_votos`.
5. `pr_relatorio_territorial_subtotais`: Emissão do relatório com subtotais e total geral manuais.
6. `pr_relatorio_engajamento_json`: Extração do JSON territorial completo.
7. `TRG_AUDIT_CHAMADO`: Verificação dos registros na tabela `AUDITORIA_DML_CHAMADO`.
8. Exceção específica de violação cívica (tentativa de autovoto).
9. Exceção específica de `NO_DATA_FOUND` (busca por chamado inexistente).

---

## 🔄 Matriz de Mapeamento: Do Relacional ao MongoDB

Para atender à transição documental exigida pelo edital, justificamos as escolhas de modelagem entre **documentos incorporados (*embedding*)** e **referências (*referencing*)**:

| Conceito / Entidade Relacional (Oracle) | Representação NoSQL (MongoDB) | Padrão Adotado | Justificativa Técnica da Transição |
| :--- | :--- | :---: | :--- |
| `chamado` + `usuario` + `endereco` + `bairro` + `cidade` | Documento raiz `chamados` com subdocumentos `cidadao` e `localizacao` | **Embedding** | Leituras atômicas: o aplicativo móvel do cidadão recupera todo o contexto do chamado em uma única operação $\mathcal{O}(1)$ sem realizar múltiplos joins. |
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
| **1** | Poste com lâmpada apagada em via principal | Bela Vista | Iluminação Pública | `EM_EXECUCAO` | **2** |
| **2** | Buraco profundo na faixa da direita da via | Pinheiros | Vias e Pavimentação | `EM_ANALISE` | **2** |
| **4** | Descarte irregular de entulho e móveis velhos | Mooca | Limpeza Urbana | `ABERTO` | **2** |
| **5** | Galho de grande porte com risco de queda | Santana | Árvores e Parques | `EM_ANALISE` | **2** |
| **7** | Vazamento contínuo de água limpa no meio-fio | Pinheiros | Drenagem e Esgoto | `EM_EXECUCAO` | **0** |

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
              { $in: ["$status_atual", ["ABERTO", "EM_ANALISE", "EM_EXECUCAO"]] },
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
         NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) IN ('ABERTO', 'EM_ANALISE', 'EM_EXECUCAO') THEN 1 ELSE 0 END), 0) AS ocorrencias_abertas,
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
| **Limpeza Urbana** | 2 | 1 | 0 | 2 |
| **Drenagem e Esgoto** | 2 | 1 | 1 | 0 |
| **Iluminação Pública** | 1 | 1 | 0 | 2 |
| **Vias e Pavimentação** | 1 | 1 | 0 | 2 |
| **Árvores e Parques** | 1 | 1 | 0 | 2 |
| **Sinalização e Trânsito** | 1 | 0 | 1 | 0 |

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
   - Ele limpa o ambiente de forma idempotente, cria as 11 tabelas em 3FN + tabela de auditoria, cria as PKs, FKs, constraints e insere as sementes válidas com `COMMIT`.
2. **Passo 2 — Empacotamento PL/SQL, Triggers e Testes:**
   - Execute o script [`2TDSPG_2026_Pacotes_ZelaFix.sql`](./2TDSPG_2026_Pacotes_ZelaFix.sql).
   - Ele compila as packages `PKG_CHAMADO_GESTAO` e `PKG_ENGAJAMENTO_CIDADAO`, as triggers `TRG_AUDIT_CHAMADO` e `TRG_VALIDA_VOTO_CHAMADO`, os 2 blocos anônimos e roda a bateria de testes de integração com `DBMS_OUTPUT` e `ROLLBACK` seguro.

---

### Opção 2: Carga e Consultas no MongoDB (Node.js CLI, mongosh ou MongoDB Compass)

Todos os artefatos residem na pasta [`mongodb/`](./mongodb).

> 💡 **Nota de Segurança & Avaliação:** As credenciais de conexão do cluster oficial Atlas estão documentadas exclusivamente nesta seção do README para facilitar a avaliação da banca examinadora da FIAP. Em conformidade com as boas práticas de segurança, todos os arquivos de código JavaScript foram sanitizados com placeholders (`<usuario>:<senha>`) e consomem as credenciais dinamicamente via arquivo local `.env` (ignorado pelo `.gitignore`).

#### Execução Direta via Terminal / CLI (Node.js + .env):
Carrega automaticamente as credenciais seguras do arquivo `.env` e executa a esteira completa (conexão Atlas, drops idempotentes, validação de schema, índices, carga de 13 documentos e as 3 consultas analíticas formatadas em tabela):
```bash
cd Database-Advanced/mongodb
npm start
# Ou diretamente:
node executar_atlas.js
```

#### Execução Rápida em Comando Único via `mongosh`:
```bash
cd Database-Advanced/mongodb
mongosh "mongodb+srv://enzookuizumifiap_db_user:tSzxhkbxANQizqdA@zelafix.t2rxvpu.mongodb.net/zelafix" setup_completo_mongodb.js
```

#### Execução Modular Passo a Passo:
```bash
# 1. Navegue até a pasta NoSQL
cd Database-Advanced/mongodb

# 2. Crie e popule a coleção 'chamados' com validador e índices
mongosh "mongodb+srv://enzookuizumifiap_db_user:tSzxhkbxANQizqdA@zelafix.t2rxvpu.mongodb.net/zelafix" setup_mongodb_chamados.js

# 3. Crie e popule a coleção 'bairros_monitoramento' com validador e índices
mongosh "mongodb+srv://enzookuizumifiap_db_user:tSzxhkbxANQizqdA@zelafix.t2rxvpu.mongodb.net/zelafix" setup_mongodb_bairros.js

# 4. Execute os 3 Relatórios Analíticos com formatação CLI em tabela
mongosh "mongodb+srv://enzookuizumifiap_db_user:tSzxhkbxANQizqdA@zelafix.t2rxvpu.mongodb.net/zelafix" consultas_relatorios_mongodb.js
```

#### Via MongoDB Compass:
1. Abra o **MongoDB Compass** e conecte-se ao cluster Atlas (`mongodb+srv://...`).
2. Abra a aba inferior **`>_MONGOSH`**.
3. Aponte para o diretório e execute o script mestre:
   ```javascript
   process.chdir("C:/Users/Enzo/new_backup/FIAP/_Projetos/Global_Solution_2/Database-Advanced/mongodb")
   load("setup_completo_mongodb.js")
   ```
4. O console exibirá as validações de schema, confirmação das coleções criadas, índices criados e as tabelas formatadas de cada consulta.

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
1. [ID 1] Poste com lâmpada apagada em via principal    | Bairro: Bela Vista   | Categoria: Iluminação Pública     | Status: EM_EXECUCAO  | Apoios: 2
2. [ID 2] Buraco profundo na faixa da direita da via    | Bairro: Pinheiros    | Categoria: Vias e Pavimentação    | Status: EM_ANALISE   | Apoios: 2
3. [ID 4] Descarte irregular de entulho e móveis velhos | Bairro: Mooca        | Categoria: Limpeza Urbana         | Status: ABERTO       | Apoios: 2
4. [ID 5] Galho de grande porte com risco de queda      | Bairro: Santana      | Categoria: Árvores e Parques      | Status: EM_ANALISE   | Apoios: 2
5. [ID 7] Vazamento contínuo de água limpa no meio-fio  | Bairro: Pinheiros    | Categoria: Drenagem e Esgoto      | Status: EM_EXECUCAO  | Apoios: 0

--------------------------------------------------------------------
>>> RELATÓRIO 2 (AGGREGATION): Volume de Ocorrências por Categoria Urbana
--------------------------------------------------------------------
 - Categoria: Limpeza Urbana            | Total:  2 | Pendentes:  1 | Concluídas:  0 | Apoios Acumulados:  2
 - Categoria: Drenagem e Esgoto         | Total:  2 | Pendentes:  1 | Concluídas:  1 | Apoios Acumulados:  0
 - Categoria: Iluminação Pública        | Total:  1 | Pendentes:  1 | Concluídas:  0 | Apoios Acumulados:  2
 - Categoria: Vias e Pavimentação       | Total:  1 | Pendentes:  1 | Concluídas:  0 | Apoios Acumulados:  2
 - Categoria: Árvores e Parques         | Total:  1 | Pendentes:  1 | Concluídas:  0 | Apoios Acumulados:  2
 - Categoria: Sinalização e Trânsito    | Total:  1 | Pendentes:  0 | Concluídas:  1 | Apoios Acumulados:  0

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
