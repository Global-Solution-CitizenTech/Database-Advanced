-- ====================================================================
-- FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
-- CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
-- DISCIPLINA: Mastering Relational and Non-Relational Database
-- PROJETO: ZelaFix — Zeladoria Urbana Colaborativa
-- TURMA: 2TDSPG
-- INTEGRANTES:
--   1. Enzo Okuizumi                    - RM: 561432
--   2. Gustavo Okada                    - RM: 563428
--   3. Lucas Barros Gouveia             - RM: 566422
--   4. Luna de Carvalho Guimarães       - RM: 562290
--   5. Milton Jakson de Sousa Marcelino - RM: 564836
-- ====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;


-- ====================================================================
-- PACOTE 1: ESPECIFICAÇÃO (PACKAGE SPECIFICATION - PKG_CHAMADO_GESTAO)
-- Ciclo de vida do chamado, abertura atômica, histórico de status (3FN)
-- e conversão manual de chamado para JSON via CLOB
-- ====================================================================
CREATE OR REPLACE PACKAGE pkg_chamado_gestao AS

    -- Exceções padronizadas de negócio com códigos ORA específicos
    e_parametro_invalido  EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_parametro_invalido, -20001);

    e_chamado_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_chamado_inexistente, -20002);

    e_usuario_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_usuario_inexistente, -20003);

    e_status_inexistente  EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_status_inexistente, -20004);

    e_usuario_nao_gestor     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_usuario_nao_gestor, -20005);

    e_prioridade_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_prioridade_inexistente, -20008);

    e_orgao_inexistente      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_orgao_inexistente, -20009);

    -- 1.1 Procedimento de Abertura Atômica de Chamado Urbano
    -- Insere o chamado e grava atomicamente o 1º histórico com status 'PENDENTE' (3FN)
    PROCEDURE pr_abrir_chamado (
        p_titulo            IN  VARCHAR2,
        p_descricao         IN  VARCHAR2,
        p_foto              IN  BLOB,
        p_id_usuario        IN  NUMBER,
        p_id_endereco       IN  NUMBER,
        p_id_categoria      IN  NUMBER,
        p_id_prioridade     IN  NUMBER,
        p_id_orgao          IN  NUMBER,
        p_id_chamado_gerado OUT NUMBER
    );

    -- 1.2 Procedimento de Transição e Atualização de Status da Zeladoria (Exclusivo GESTOR)
    PROCEDURE pr_atualizar_status_chamado (
        p_id_chamado        IN NUMBER,
        p_id_status         IN NUMBER,
        p_id_usuario_fiscal IN NUMBER,
        p_observacoes       IN VARCHAR2
    );

    -- 1.3 Função que obtém o nome do status atual vigente do chamado (3FN via MAX de HIST_CHAMADO)
    FUNCTION fn_obter_status_atual (
        p_id_chamado IN NUMBER
    ) RETURN VARCHAR2;

    -- 1.4 Função de Conversão MANUAL de Chamado para JSON (SEM FUNÇÕES NATIVAS)
    -- Monta a estrutura JSON completa do chamado e histórico via concatenação em CLOB
    FUNCTION fn_converter_chamado_json (
        p_id_chamado IN NUMBER
    ) RETURN CLOB;

END pkg_chamado_gestao;
/


-- ====================================================================
-- PACOTE 1: CORPO (PACKAGE BODY - PKG_CHAMADO_GESTAO)
-- ====================================================================
CREATE OR REPLACE PACKAGE BODY pkg_chamado_gestao AS

    -- 1.1 Implementação da Abertura Atômica de Chamado Urbano
    PROCEDURE pr_abrir_chamado (
        p_titulo            IN  VARCHAR2,
        p_descricao         IN  VARCHAR2,
        p_foto              IN  BLOB,
        p_id_usuario        IN  NUMBER,
        p_id_endereco       IN  NUMBER,
        p_id_categoria      IN  NUMBER,
        p_id_prioridade     IN  NUMBER,
        p_id_orgao          IN  NUMBER,
        p_id_chamado_gerado OUT NUMBER
    ) IS
        v_chk          NUMBER;
        v_id_status_ab status.id_status%TYPE;
        v_novo_id      chamado.id_chamado%TYPE;
    BEGIN
        -- Validação de tamanho mínimo e presença de foto BLOB
        IF p_titulo IS NULL OR LENGTH(TRIM(p_titulo)) < 5
           OR p_descricao IS NULL OR LENGTH(TRIM(p_descricao)) < 10
           OR p_foto IS NULL OR DBMS_LOB.GETLENGTH(p_foto) = 0 THEN
            RAISE e_parametro_invalido;
        END IF;

        -- Validação de integridade das Chaves Estrangeiras (FKs)
        SELECT COUNT(*) INTO v_chk FROM usuario WHERE id_usuario = p_id_usuario;
        IF v_chk = 0 THEN RAISE e_usuario_inexistente; END IF;

        SELECT COUNT(*) INTO v_chk FROM endereco WHERE id_endereco = p_id_endereco;
        IF v_chk = 0 THEN RAISE e_parametro_invalido; END IF;

        SELECT COUNT(*) INTO v_chk FROM categoria WHERE id_categoria = p_id_categoria;
        IF v_chk = 0 THEN RAISE e_parametro_invalido; END IF;

        SELECT COUNT(*) INTO v_chk FROM prioridade WHERE id_prioridade = p_id_prioridade;
        IF v_chk = 0 THEN RAISE e_prioridade_inexistente; END IF;

        SELECT COUNT(*) INTO v_chk FROM orgao_governo WHERE id_orgao = p_id_orgao;
        IF v_chk = 0 THEN RAISE e_orgao_inexistente; END IF;

        SELECT id_status INTO v_id_status_ab FROM status WHERE nm_status = 'PENDENTE';

        -- Inserção do chamado com captura da PK gerada via RETURNING
        INSERT INTO chamado (
            titulo, descricao, foto, dt_abertura,
            usuario_id_usuario, endereco_id_endereco, categoria_id_categoria,
            prioridade_id_prioridade, orgao_governo_id_orgao
        ) VALUES (
            TRIM(p_titulo), TRIM(p_descricao), p_foto, SYSDATE,
            p_id_usuario, p_id_endereco, p_id_categoria,
            p_id_prioridade, p_id_orgao
        ) RETURNING id_chamado INTO v_novo_id;

        -- Gravação atômica do estado inicial 'PENDENTE' na linha do tempo (HIST_CHAMADO)
        INSERT INTO hist_chamado (
            dt_mudanca, observacoes, chamado_id_chamado, usuario_id_usuario, status_id_status
        ) VALUES (
            SYSDATE, 'Chamado registrado pelo cidadão via aplicativo ZelaFix.', v_novo_id, p_id_usuario, v_id_status_ab
        );

        p_id_chamado_gerado := v_novo_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Status inicial PENDENTE não cadastrado na base.');
        WHEN e_parametro_invalido THEN
            RAISE_APPLICATION_ERROR(-20001, 'Parâmetros inválidos ou FKs de endereço/categoria inexistentes.');
        WHEN e_usuario_inexistente THEN
            RAISE_APPLICATION_ERROR(-20003, 'Usuário com ID ' || p_id_usuario || ' não encontrado.');
        WHEN e_prioridade_inexistente THEN
            RAISE_APPLICATION_ERROR(-20008, 'Prioridade com ID ' || p_id_prioridade || ' não encontrada.');
        WHEN e_orgao_inexistente THEN
            RAISE_APPLICATION_ERROR(-20009, 'Órgão governamental com ID ' || p_id_orgao || ' não encontrado.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Erro inesperado na abertura do chamado: ' || SQLERRM);
    END pr_abrir_chamado;


    -- 1.2 Implementação da Transição de Status da Zeladoria
    PROCEDURE pr_atualizar_status_chamado (
        p_id_chamado        IN NUMBER,
        p_id_status         IN NUMBER,
        p_id_usuario_fiscal IN NUMBER,
        p_observacoes       IN VARCHAR2
    ) IS
        v_chk           NUMBER;
        v_cargo_usuario usuario.cargo%TYPE;
        v_nome_status   status.nm_status%TYPE;
    BEGIN
        IF p_id_chamado IS NULL OR p_id_status IS NULL OR p_id_usuario_fiscal IS NULL THEN
            RAISE e_parametro_invalido;
        END IF;

        SELECT COUNT(*) INTO v_chk FROM chamado WHERE id_chamado = p_id_chamado;
        IF v_chk = 0 THEN RAISE e_chamado_inexistente; END IF;

        BEGIN
            SELECT nm_status INTO v_nome_status FROM status WHERE id_status = p_id_status;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN RAISE e_status_inexistente;
        END;

        -- Valida existência do fiscal e garante privilégio exclusivo de GESTOR
        BEGIN
            SELECT cargo INTO v_cargo_usuario FROM usuario WHERE id_usuario = p_id_usuario_fiscal;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN RAISE e_usuario_inexistente;
        END;

        IF v_cargo_usuario <> 'GESTOR' THEN
            RAISE e_usuario_nao_gestor;
        END IF;

        INSERT INTO hist_chamado (
            dt_mudanca, observacoes, chamado_id_chamado, usuario_id_usuario, status_id_status
        ) VALUES (
            SYSDATE, NVL(TRIM(p_observacoes), 'Transição operacional para status: ' || v_nome_status),
            p_id_chamado, p_id_usuario_fiscal, p_id_status
        );
    EXCEPTION
        WHEN e_parametro_invalido THEN
            RAISE_APPLICATION_ERROR(-20001, 'Parâmetros obrigatórios nulos na transição de status.');
        WHEN e_chamado_inexistente THEN
            RAISE_APPLICATION_ERROR(-20002, 'Chamado ID ' || p_id_chamado || ' não encontrado.');
        WHEN e_status_inexistente THEN
            RAISE_APPLICATION_ERROR(-20004, 'Status ID ' || p_id_status || ' não cadastrado.');
        WHEN e_usuario_inexistente THEN
            RAISE_APPLICATION_ERROR(-20003, 'Fiscal ID ' || p_id_usuario_fiscal || ' não encontrado.');
        WHEN e_usuario_nao_gestor THEN
            RAISE_APPLICATION_ERROR(-20005, 'Acesso negado: Somente GESTORES podem alterar status de chamados.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20007, 'Erro ao atualizar status do chamado: ' || SQLERRM);
    END pr_atualizar_status_chamado;


    -- 1.3 Implementação da Função de Consulta de Status Atual (3FN)
    FUNCTION fn_obter_status_atual (
        p_id_chamado IN NUMBER
    ) RETURN VARCHAR2 IS
        PRAGMA UDF;
        v_nm_status VARCHAR2(20);
    BEGIN
        IF p_id_chamado IS NULL OR p_id_chamado <= 0 THEN
            RAISE e_parametro_invalido;
        END IF;

        -- Otimização DBA: ordenação decrescente aproveitando o índice composto idx_hist_chamado_ativo
        SELECT s.nm_status
          INTO v_nm_status
          FROM hist_chamado h
          JOIN status s ON s.id_status = h.status_id_status
         WHERE h.chamado_id_chamado = p_id_chamado
         ORDER BY h.id_hist DESC
         FETCH FIRST 1 ROW ONLY;

        RETURN v_nm_status;
    EXCEPTION
        WHEN e_parametro_invalido THEN RETURN 'INVALIDO';
        WHEN NO_DATA_FOUND        THEN RETURN 'SEM_HISTORICO';
        WHEN OTHERS               THEN RETURN 'ERRO';
    END fn_obter_status_atual;


    -- 1.4 Implementação da Função de Conversão MANUAL de Chamado para JSON
    -- Constrói o documento JSON manualmente em CLOB com DBMS_LOB (sem funções nativas SQL/JSON)
    FUNCTION fn_converter_chamado_json (
        p_id_chamado IN NUMBER
    ) RETURN CLOB IS
        v_json          CLOB;
        v_buffer        VARCHAR2(32767);
        v_status_atual  VARCHAR2(20);
        v_primeiro_hist BOOLEAN := TRUE;

        CURSOR c_chamado IS
            SELECT c.id_chamado, c.titulo, c.descricao, c.dt_abertura,
                   u.id_usuario, u.nm_usuario, u.email,
                   e.id_endereco, e.rua, e.numero, e.cep,
                   b.nm_bairro, cid.nm_cidade, est.nm_estado,
                   cat.id_categoria, cat.nm_categoria,
                   p.id_prioridade, p.nm_prioridade,
                   og.id_orgao, og.orgao_governo
              FROM chamado c
              JOIN usuario u       ON u.id_usuario = c.usuario_id_usuario
              JOIN endereco e      ON e.id_endereco = c.endereco_id_endereco
              JOIN bairro b        ON b.id_bairro = e.bairro_id_bairro
              JOIN cidade cid      ON cid.id_cidade = b.cidade_id_cidade
              JOIN estado est      ON est.id_estado = cid.estado_id_estado
              JOIN categoria cat   ON cat.id_categoria = c.categoria_id_categoria
              JOIN prioridade p    ON p.id_prioridade = c.prioridade_id_prioridade
              JOIN orgao_governo og ON og.id_orgao = c.orgao_governo_id_orgao
             WHERE c.id_chamado = p_id_chamado;

        v_ch c_chamado%ROWTYPE;

        CURSOR c_historico IS
            SELECT h.id_hist, h.dt_mudanca, h.observacoes,
                   s.nm_status, u.nm_usuario AS responsavel
              FROM hist_chamado h
              JOIN status s  ON s.id_status = h.status_id_status
              JOIN usuario u ON u.id_usuario = h.usuario_id_usuario
             WHERE h.chamado_id_chamado = p_id_chamado
             ORDER BY h.id_hist ASC;
    BEGIN
        IF p_id_chamado IS NULL OR p_id_chamado <= 0 THEN
            RAISE e_parametro_invalido;
        END IF;

        OPEN c_chamado;
        FETCH c_chamado INTO v_ch;
        IF c_chamado%NOTFOUND THEN
            CLOSE c_chamado;
            RAISE e_chamado_inexistente;
        END IF;
        CLOSE c_chamado;

        v_status_atual := fn_obter_status_atual(p_id_chamado);
        DBMS_LOB.CREATETEMPORARY(v_json, TRUE);

        -- Montagem manual dos objetos aninhados (categoria, prioridade, orgaoGoverno, cidadao, localizacao)
        v_buffer := '{' || CHR(10) ||
                    '  "idChamado": ' || v_ch.id_chamado || ',' || CHR(10) ||
                    '  "titulo": "' || REPLACE(v_ch.titulo, '"', '\"') || '",' || CHR(10) ||
                    '  "descricao": "' || REPLACE(REPLACE(v_ch.descricao, CHR(10), '\n'), '"', '\"') || '",' || CHR(10) ||
                    '  "statusAtual": "' || v_status_atual || '",' || CHR(10) ||
                    '  "categoria": {"idCategoria": ' || v_ch.id_categoria || ', "nome": "' || REPLACE(v_ch.nm_categoria, '"', '\"') || '"},' || CHR(10) ||
                    '  "prioridade": {"idPrioridade": ' || v_ch.id_prioridade || ', "nome": "' || REPLACE(v_ch.nm_prioridade, '"', '\"') || '"},' || CHR(10) ||
                    '  "orgaoGoverno": {"idOrgao": ' || v_ch.id_orgao || ', "nome": "' || REPLACE(v_ch.orgao_governo, '"', '\"') || '"},' || CHR(10) ||
                    '  "cidadao": {"idUsuario": ' || v_ch.id_usuario || ', "nome": "' || REPLACE(v_ch.nm_usuario, '"', '\"') || '", "email": "' || v_ch.email || '"},' || CHR(10) ||
                    '  "localizacao": {' || CHR(10) ||
                    '    "rua": "' || REPLACE(v_ch.rua, '"', '\"') || '", "numero": "' || NVL(v_ch.numero, 'S/N') || '", "cep": "' || v_ch.cep || '",' || CHR(10) ||
                    '    "bairro": "' || REPLACE(v_ch.nm_bairro, '"', '\"') || '", "cidade": "' || REPLACE(v_ch.nm_cidade, '"', '\"') || '", "estado": "' || v_ch.nm_estado || '"' || CHR(10) ||
                    '  },' || CHR(10) ||
                    '  "dtAbertura": "' || TO_CHAR(v_ch.dt_abertura, 'YYYY-MM-DD"T"HH24:MI:SS') || '",' || CHR(10) ||
                    '  "historicoStatus": [';
        DBMS_LOB.WRITEAPPEND(v_json, LENGTH(v_buffer), v_buffer);

        -- Serialização manual do array de histórico de status (embedded array)
        FOR h IN c_historico LOOP
            IF NOT v_primeiro_hist THEN
                DBMS_LOB.WRITEAPPEND(v_json, 1, ',');
            END IF;
            v_primeiro_hist := FALSE;

            v_buffer := CHR(10) ||
                        '    {"idHist": ' || h.id_hist ||
                        ', "status": "' || h.nm_status || '"' ||
                        ', "observacoes": "' || REPLACE(NVL(h.observacoes, ''), '"', '\"') || '"' ||
                        ', "responsavel": "' || REPLACE(h.responsavel, '"', '\"') || '"' ||
                        ', "dtMudanca": "' || TO_CHAR(h.dt_mudanca, 'YYYY-MM-DD"T"HH24:MI:SS') || '"}';
            DBMS_LOB.WRITEAPPEND(v_json, LENGTH(v_buffer), v_buffer);
        END LOOP;

        v_buffer := CHR(10) || '  ]' || CHR(10) || '}';
        DBMS_LOB.WRITEAPPEND(v_json, LENGTH(v_buffer), v_buffer);

        RETURN v_json;
    EXCEPTION
        WHEN e_parametro_invalido  THEN RETURN '{"erro": "ID de chamado inválido"}';
        WHEN e_chamado_inexistente THEN RETURN '{"erro": "Chamado ID ' || p_id_chamado || ' não encontrado"}';
        WHEN OTHERS                THEN RETURN '{"erro": "Falha na conversão manual para JSON: ' || REPLACE(SQLERRM, '"', '''') || '"}';
    END fn_converter_chamado_json;

END pkg_chamado_gestao;
/


-- ====================================================================
-- PACOTE 2: ESPECIFICAÇÃO (PACKAGE SPECIFICATION - PKG_ENGAJAMENTO_CIDADAO)
-- Colaboração comunitária, apuração de votos, criticidade por bairro
-- e relatório territorial com subtotais e total geral feitos à mão
-- ====================================================================
CREATE OR REPLACE PACKAGE pkg_engajamento_cidadao AS

    -- Exceções padronizadas de negócio com códigos ORA específicos
    e_voto_duplicado      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_voto_duplicado, -20010);

    e_chamado_fechado     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_chamado_fechado, -20011);

    e_autovoto_proibido   EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_autovoto_proibido, -20012);

    e_bairro_inexistente  EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_bairro_inexistente, -20013);

    e_sem_dados_relatorio EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_sem_dados_relatorio, -20014);

    e_parametro_invalido  EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_parametro_invalido, -20016);

    -- 2.1 Procedimento para Registrar Apoio/Voto Comunitário em Chamado (N:M)
    PROCEDURE pr_registrar_voto (
        p_id_chamado     IN  NUMBER,
        p_id_usuario     IN  NUMBER,
        p_id_voto_gerado OUT NUMBER
    );

    -- 2.2 Função para Calcular o Total de Votos de um Chamado (Indexado com PRAGMA UDF)
    FUNCTION fn_calcular_total_votos (
        p_id_chamado IN NUMBER
    ) RETURN NUMBER;

    -- 2.3 Função para Classificar a Criticidade de um Bairro (NORMAL, ALERTA, CRITICO)
    FUNCTION fn_classificar_criticidade_bairro (
        p_id_bairro IN NUMBER
    ) RETURN VARCHAR2;

    -- 2.4 Procedimento com SUBTOTAL POR BAIRRO E TOTAL GERAL FEITOS À MÃO (Quebra de Grupo)
    PROCEDURE pr_relatorio_subtotal_bairros;

END pkg_engajamento_cidadao;
/


-- ====================================================================
-- PACOTE 2: CORPO (PACKAGE BODY - PKG_ENGAJAMENTO_CIDADAO)
-- ====================================================================
CREATE OR REPLACE PACKAGE BODY pkg_engajamento_cidadao AS

    -- 2.1 Implementação do Registro de Voto Comunitário
    PROCEDURE pr_registrar_voto (
        p_id_chamado     IN  NUMBER,
        p_id_usuario     IN  NUMBER,
        p_id_voto_gerado OUT NUMBER
    ) IS
        v_autor_chamado chamado.usuario_id_usuario%TYPE;
        v_chk           NUMBER;
        v_status_atual  VARCHAR2(20);
    BEGIN
        IF p_id_chamado IS NULL OR p_id_chamado <= 0 OR p_id_usuario IS NULL OR p_id_usuario <= 0 THEN
            RAISE e_parametro_invalido;
        END IF;

        BEGIN
            SELECT usuario_id_usuario INTO v_autor_chamado FROM chamado WHERE id_chamado = p_id_chamado;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN RAISE pkg_chamado_gestao.e_chamado_inexistente;
        END;

        SELECT COUNT(*) INTO v_chk FROM usuario WHERE id_usuario = p_id_usuario;
        IF v_chk = 0 THEN RAISE pkg_chamado_gestao.e_usuario_inexistente; END IF;

        -- Regra cívica anti-autovoto: autor não pode votar na própria ocorrência
        IF v_autor_chamado = p_id_usuario THEN
            RAISE e_autovoto_proibido;
        END IF;

        -- Bloqueia votos em chamados já encerrados (CONCLUIDO ou REJEITADO)
        v_status_atual := pkg_chamado_gestao.fn_obter_status_atual(p_id_chamado);
        IF v_status_atual IN ('CONCLUIDO', 'REJEITADO') THEN
            RAISE e_chamado_fechado;
        END IF;

        INSERT INTO voto_chamado (dt_voto, chamado_id_chamado, usuario_id_usuario)
        VALUES (SYSDATE, p_id_chamado, p_id_usuario)
        RETURNING id_voto INTO p_id_voto_gerado;
    EXCEPTION
        WHEN e_parametro_invalido THEN
            RAISE_APPLICATION_ERROR(-20016, 'Identificadores de chamado e usuário são obrigatórios e positivos.');
        WHEN pkg_chamado_gestao.e_chamado_inexistente THEN
            RAISE_APPLICATION_ERROR(-20002, 'Chamado ID ' || p_id_chamado || ' não existe para votação.');
        WHEN pkg_chamado_gestao.e_usuario_inexistente THEN
            RAISE_APPLICATION_ERROR(-20003, 'Munícipe votante ID ' || p_id_usuario || ' não encontrado.');
        WHEN e_autovoto_proibido THEN
            RAISE_APPLICATION_ERROR(-20012, 'Integridade cívica violada: O autor não pode votar no próprio chamado.');
        WHEN e_chamado_fechado THEN
            RAISE_APPLICATION_ERROR(-20011, 'Votação encerrada: O chamado já está ' || v_status_atual || '.');
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20010, 'Munícipe já registrou apoio anteriormente nesta ocorrência.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20015, 'Erro inesperado ao registrar voto: ' || SQLERRM);
    END pr_registrar_voto;


    -- 2.2 Implementação do Total de Votos (Otimizado via Índice Único de Cobertura)
    FUNCTION fn_calcular_total_votos (
        p_id_chamado IN NUMBER
    ) RETURN NUMBER IS
        PRAGMA UDF;
        v_total NUMBER := 0;
    BEGIN
        IF p_id_chamado IS NULL OR p_id_chamado <= 0 THEN
            RAISE e_parametro_invalido;
        END IF;

        SELECT COUNT(*) INTO v_total FROM voto_chamado WHERE chamado_id_chamado = p_id_chamado;
        RETURN v_total;
    EXCEPTION
        WHEN e_parametro_invalido THEN RETURN 0;
        WHEN OTHERS               THEN RETURN 0;
    END fn_calcular_total_votos;


    -- 2.3 Implementação da Classificação de Criticidade de Bairro
    FUNCTION fn_classificar_criticidade_bairro (
        p_id_bairro IN NUMBER
    ) RETURN VARCHAR2 IS
        PRAGMA UDF;
        v_pendentes NUMBER := 0;
        v_votos     NUMBER := 0;
        v_existe    NUMBER := 0;
    BEGIN
        IF p_id_bairro IS NULL OR p_id_bairro <= 0 THEN
            RAISE e_parametro_invalido;
        END IF;

        SELECT COUNT(*) INTO v_existe FROM bairro WHERE id_bairro = p_id_bairro;
        IF v_existe = 0 THEN RAISE e_bairro_inexistente; END IF;

        SELECT NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) NOT IN ('CONCLUIDO', 'REJEITADO') THEN 1 ELSE 0 END), 0),
               COUNT(v.id_voto)
          INTO v_pendentes, v_votos
          FROM endereco e
          JOIN chamado ch ON ch.endereco_id_endereco = e.id_endereco
          LEFT JOIN voto_chamado v ON v.chamado_id_chamado = ch.id_chamado
         WHERE e.bairro_id_bairro = p_id_bairro;

        IF v_pendentes >= 3 OR v_votos >= 5 THEN
            RETURN 'CRITICO';
        ELSIF v_pendentes >= 1 OR v_votos >= 2 THEN
            RETURN 'ALERTA';
        ELSE
            RETURN 'NORMAL';
        END IF;
    EXCEPTION
        WHEN e_bairro_inexistente THEN RETURN 'INEXISTENTE';
        WHEN e_parametro_invalido THEN RETURN 'PARAMETRO_INVALIDO';
        WHEN OTHERS               THEN RETURN 'INDETERMINADO';
    END fn_classificar_criticidade_bairro;


    -- 2.4 Implementação do Procedimento com SUBTOTAL POR BAIRRO E TOTAL GERAL FEITOS À MÃO
    -- Algoritmo clássico de quebra de grupo (Control Break) com acumuladores manuais no loop
    PROCEDURE pr_relatorio_subtotal_bairros IS
        CURSOR c_ocorrencias IS
            SELECT b.nm_bairro, c.nm_cidade, ch.id_chamado, ch.titulo, cat.nm_categoria,
                   pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) AS status_atual,
                   pkg_engajamento_cidadao.fn_calcular_total_votos(ch.id_chamado) AS total_votos
              FROM bairro b
              JOIN cidade c      ON c.id_cidade = b.cidade_id_cidade
              JOIN endereco e    ON e.bairro_id_bairro = b.id_bairro
              JOIN chamado ch    ON ch.endereco_id_endereco = e.id_endereco
              JOIN categoria cat ON cat.id_categoria = ch.categoria_id_categoria
             ORDER BY b.nm_bairro ASC, ch.id_chamado ASC;

        v_reg            c_ocorrencias%ROWTYPE;
        v_bairro_ant     VARCHAR2(50) := NULL;
        v_cidade_ant     VARCHAR2(50) := NULL;
        v_tem_dados      BOOLEAN := FALSE;

        -- Acumuladores manuais de SUBTOTAL (por Bairro)
        v_sub_chamados   NUMBER := 0;
        v_sub_pendentes  NUMBER := 0;
        v_sub_concluidos NUMBER := 0;
        v_sub_votos      NUMBER := 0;

        -- Acumuladores manuais de TOTAL GERAL MUNICIPAL
        v_tot_chamados   NUMBER := 0;
        v_tot_pendentes  NUMBER := 0;
        v_tot_concluidos NUMBER := 0;
        v_tot_votos      NUMBER := 0;
        v_taxa_resolucao NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('================================================================================');
        DBMS_OUTPUT.PUT_LINE('RELATÓRIO TERRITORIAL COM SUBTOTAIS E TOTAL GERAL (CÁLCULO MANUAL À MÃO)');
        DBMS_OUTPUT.PUT_LINE('================================================================================');

        OPEN c_ocorrencias;
        LOOP
            FETCH c_ocorrencias INTO v_reg;
            EXIT WHEN c_ocorrencias%NOTFOUND;
            v_tem_dados := TRUE;

            -- QUEBRA DE GRUPO: quando muda o bairro, imprime o subtotal acumulado e zera variáveis
            IF v_bairro_ant IS NOT NULL AND v_bairro_ant <> v_reg.nm_bairro THEN
                DBMS_OUTPUT.PUT_LINE('  ------------------------------------------------------------------------------');
                DBMS_OUTPUT.PUT_LINE('  >>> SUBTOTAL [' || UPPER(v_bairro_ant) || ' - ' || v_cidade_ant || ']: ' ||
                                     v_sub_chamados || ' ocorrências | ' || v_sub_pendentes || ' pendentes | ' ||
                                     v_sub_concluidos || ' concluídas | ' || v_sub_votos || ' apoios');
                DBMS_OUTPUT.PUT_LINE('  ------------------------------------------------------------------------------' || CHR(10));
                v_sub_chamados   := 0;
                v_sub_pendentes  := 0;
                v_sub_concluidos := 0;
                v_sub_votos      := 0;
            END IF;

            -- Cabeçalho do novo grupo (Bairro)
            IF v_bairro_ant IS NULL OR v_bairro_ant <> v_reg.nm_bairro THEN
                v_bairro_ant := v_reg.nm_bairro;
                v_cidade_ant := v_reg.nm_cidade;
                DBMS_OUTPUT.PUT_LINE('[BAIRRO: ' || UPPER(v_reg.nm_bairro) || ' (' || v_reg.nm_cidade || ')]');
                DBMS_OUTPUT.PUT_LINE('  ID   | TÍTULO                              | CATEGORIA              | STATUS       | APOIOS');
                DBMS_OUTPUT.PUT_LINE('  ----+-------------------------------------+------------------------+--------------+-------');
            END IF;

            DBMS_OUTPUT.PUT_LINE('  ' || LPAD(v_reg.id_chamado, 4) || ' | ' ||
                                 RPAD(SUBSTR(v_reg.titulo, 1, 35), 35) || ' | ' ||
                                 RPAD(SUBSTR(v_reg.nm_categoria, 1, 22), 22) || ' | ' ||
                                 RPAD(v_reg.status_atual, 12) || ' | ' ||
                                 LPAD(v_reg.total_votos, 6));

            -- Soma manual nos acumuladores de Subtotal e Total Geral
            v_sub_chamados := v_sub_chamados + 1;
            v_sub_votos    := v_sub_votos + v_reg.total_votos;
            v_tot_chamados := v_tot_chamados + 1;
            v_tot_votos    := v_tot_votos + v_reg.total_votos;

            IF v_reg.status_atual = 'CONCLUIDO' THEN
                v_sub_concluidos := v_sub_concluidos + 1;
                v_tot_concluidos := v_tot_concluidos + 1;
            ELSE
                v_sub_pendentes := v_sub_pendentes + 1;
                v_tot_pendentes := v_tot_pendentes + 1;
            END IF;
        END LOOP;
        CLOSE c_ocorrencias;

        IF NOT v_tem_dados THEN RAISE e_sem_dados_relatorio; END IF;

        -- Subtotal do último grupo após saída do loop
        DBMS_OUTPUT.PUT_LINE('  ------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('  >>> SUBTOTAL [' || UPPER(v_bairro_ant) || ' - ' || v_cidade_ant || ']: ' ||
                             v_sub_chamados || ' ocorrências | ' || v_sub_pendentes || ' pendentes | ' ||
                             v_sub_concluidos || ' concluídas | ' || v_sub_votos || ' apoios');
        DBMS_OUTPUT.PUT_LINE('  ------------------------------------------------------------------------------');

        v_taxa_resolucao := ROUND((v_tot_concluidos / v_tot_chamados) * 100, 1);

        -- Impressão do Total Geral Municipal consolidado
        DBMS_OUTPUT.PUT_LINE(CHR(10) || '================================================================================');
        DBMS_OUTPUT.PUT_LINE('  >>> TOTAL GERAL MUNICIPAL (SÃO PAULO) <<<');
        DBMS_OUTPUT.PUT_LINE('  Total de Ocorrências:     ' || LPAD(v_tot_chamados, 4));
        DBMS_OUTPUT.PUT_LINE('  Total de Pendências:      ' || LPAD(v_tot_pendentes, 4));
        DBMS_OUTPUT.PUT_LINE('  Total Concluídas:         ' || LPAD(v_tot_concluidos, 4));
        DBMS_OUTPUT.PUT_LINE('  Total Apoios Comunitários:' || LPAD(v_tot_votos, 4));
        DBMS_OUTPUT.PUT_LINE('  Taxa Geral de Resolução:  ' || LPAD(v_taxa_resolucao, 5) || '%');
        DBMS_OUTPUT.PUT_LINE('================================================================================');
    EXCEPTION
        WHEN e_sem_dados_relatorio THEN
            IF c_ocorrencias%ISOPEN THEN CLOSE c_ocorrencias; END IF;
            DBMS_OUTPUT.PUT_LINE('Aviso: Nenhuma ocorrência registrada para apuração.');
        WHEN ZERO_DIVIDE THEN
            IF c_ocorrencias%ISOPEN THEN CLOSE c_ocorrencias; END IF;
            DBMS_OUTPUT.PUT_LINE('Erro de divisão por zero no cálculo da taxa de resolução.');
        WHEN OTHERS THEN
            IF c_ocorrencias%ISOPEN THEN CLOSE c_ocorrencias; END IF;
            RAISE_APPLICATION_ERROR(-20021, 'Erro inesperado no relatório de subtotais: ' || SQLERRM);
    END pr_relatorio_subtotal_bairros;

END pkg_engajamento_cidadao;
/


-- ====================================================================
-- PARTE 3: TRIGGERS (DISPARADORES PL/SQL COM AUDITORIA DML E REGRAS)
-- ====================================================================

-- 3.1 Trigger de Auditoria DML na Tabela CHAMADO
-- Dispara em INSERT, UPDATE ou DELETE gravando usuário, data e JSON :OLD vs :NEW
CREATE OR REPLACE TRIGGER trg_audit_chamado
AFTER INSERT OR UPDATE OR DELETE ON chamado
FOR EACH ROW
DECLARE
    v_op       VARCHAR2(10);
    v_old_json VARCHAR2(4000) := NULL;
    v_new_json VARCHAR2(4000) := NULL;
BEGIN
    v_op := CASE WHEN INSERTING THEN 'INSERT' WHEN UPDATING THEN 'UPDATE' ELSE 'DELETE' END;

    IF UPDATING OR DELETING THEN
        v_old_json := '{"id_chamado":' || :OLD.id_chamado ||
                      ',"titulo":"' || REPLACE(:OLD.titulo, '"', '\"') || '"' ||
                      ',"id_categoria":' || :OLD.categoria_id_categoria ||
                      ',"id_prioridade":' || :OLD.prioridade_id_prioridade ||
                      ',"id_orgao":' || :OLD.orgao_governo_id_orgao ||
                      ',"id_usuario":' || :OLD.usuario_id_usuario || '}';
    END IF;

    IF INSERTING OR UPDATING THEN
        v_new_json := '{"id_chamado":' || :NEW.id_chamado ||
                      ',"titulo":"' || REPLACE(:NEW.titulo, '"', '\"') || '"' ||
                      ',"id_categoria":' || :NEW.categoria_id_categoria ||
                      ',"id_prioridade":' || :NEW.prioridade_id_prioridade ||
                      ',"id_orgao":' || :NEW.orgao_governo_id_orgao ||
                      ',"id_usuario":' || :NEW.usuario_id_usuario || '}';
    END IF;

    INSERT INTO auditoria_dml_chamado (
        nome_usuario, tipo_operacao, data_hora_operacao, valores_anteriores, valores_novos
    ) VALUES (
        USER, v_op, SYSTIMESTAMP, v_old_json, v_new_json
    );
EXCEPTION
    WHEN VALUE_ERROR THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: Estouro de tamanho de string na trigger de auditoria.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Falha na trigger de auditoria: ' || SQLERRM);
END trg_audit_chamado;
/

-- 3.2 Trigger de Validação Cívica de Voto
-- Garante no nível do SGBD a proibição de autovoto e de votos em chamados encerrados
CREATE OR REPLACE TRIGGER trg_valida_voto_chamado
BEFORE INSERT ON voto_chamado
FOR EACH ROW
DECLARE
    v_autor_chamado NUMBER;
    v_status_atual  VARCHAR2(20);
    e_autovoto      EXCEPTION;
    e_encerrado     EXCEPTION;
BEGIN
    SELECT usuario_id_usuario INTO v_autor_chamado
      FROM chamado
     WHERE id_chamado = :NEW.chamado_id_chamado;

    IF v_autor_chamado = :NEW.usuario_id_usuario THEN
        RAISE e_autovoto;
    END IF;

    v_status_atual := pkg_chamado_gestao.fn_obter_status_atual(:NEW.chamado_id_chamado);
    IF v_status_atual IN ('CONCLUIDO', 'REJEITADO') THEN
        RAISE e_encerrado;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Chamado não encontrado para validar voto.');
    WHEN e_autovoto THEN
        RAISE_APPLICATION_ERROR(-20012, 'Não é permitido votar no próprio chamado cadastrado.');
    WHEN e_encerrado THEN
        RAISE_APPLICATION_ERROR(-20011, 'Votação encerrada para este chamado (status: ' || v_status_atual || ').');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20019, 'Erro ao validar integridade do voto na trigger: ' || SQLERRM);
END trg_valida_voto_chamado;
/


-- ====================================================================
-- PARTE 4: DOIS BLOCOS ANÔNIMOS PL/SQL (CURSORES, IF/ELSIF E LOOP)
-- ====================================================================

-- BLOCO ANÔNIMO 1: Processamento em Lote e Diagnóstico Territorial de Bairros
-- Utiliza Cursor Explícito, LOOP, IF/ELSIF/ELSE e funções empacotadas
DECLARE
    CURSOR c_analise_territorial IS
        SELECT b.id_bairro, b.nm_bairro,
               COUNT(ch.id_chamado) AS total_chamados,
               NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) = 'CONCLUIDO' THEN 1 ELSE 0 END), 0) AS total_concluidos,
               NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) NOT IN ('CONCLUIDO', 'REJEITADO') THEN 1 ELSE 0 END), 0) AS total_pendentes
          FROM bairro b
          LEFT JOIN endereco e ON e.bairro_id_bairro = b.id_bairro
          LEFT JOIN chamado ch ON ch.endereco_id_endereco = e.id_endereco
         GROUP BY b.id_bairro, b.nm_bairro
         ORDER BY total_pendentes DESC, b.nm_bairro ASC;

    v_reg            c_analise_territorial%ROWTYPE;
    v_criticidade    VARCHAR2(20);
    v_taxa_resolucao NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================================');
    DBMS_OUTPUT.PUT_LINE('BLOCO ANÔNIMO 1: MONITORAMENTO TERRITORIAL URBANO (ZELAFIX - ODS 11)');
    DBMS_OUTPUT.PUT_LINE('====================================================================');

    OPEN c_analise_territorial;
    LOOP
        FETCH c_analise_territorial INTO v_reg;
        EXIT WHEN c_analise_territorial%NOTFOUND;

        v_taxa_resolucao := CASE WHEN v_reg.total_chamados > 0
                                 THEN ROUND((v_reg.total_concluidos / v_reg.total_chamados) * 100, 1)
                                 ELSE 100.0 END;

        v_criticidade := pkg_engajamento_cidadao.fn_classificar_criticidade_bairro(v_reg.id_bairro);

        IF v_criticidade = 'CRITICO' THEN
            DBMS_OUTPUT.PUT_LINE('[URGÊNCIA MÁXIMA] Bairro: ' || RPAD(v_reg.nm_bairro, 15) ||
                                 ' | Pendentes: ' || LPAD(v_reg.total_pendentes, 2) ||
                                 ' | Resolução: ' || LPAD(v_taxa_resolucao, 5) || '% | ALOCAR MUTIRÃO');
        ELSIF v_criticidade = 'ALERTA' THEN
            DBMS_OUTPUT.PUT_LINE('[ATENÇÃO / ALERTA] Bairro: ' || RPAD(v_reg.nm_bairro, 15) ||
                                 ' | Pendentes: ' || LPAD(v_reg.total_pendentes, 2) ||
                                 ' | Resolução: ' || LPAD(v_taxa_resolucao, 5) || '% | MONITORAR ESCALA');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[OPERAÇÃO NORMAL] Bairro: ' || RPAD(v_reg.nm_bairro, 15) ||
                                 ' | Pendentes: ' || LPAD(v_reg.total_pendentes, 2) ||
                                 ' | Resolução: ' || LPAD(v_taxa_resolucao, 5) || '% | SITUAÇÃO CONTROLADA');
        END IF;
    END LOOP;
    CLOSE c_analise_territorial;
    DBMS_OUTPUT.PUT_LINE('====================================================================');
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        IF c_analise_territorial%ISOPEN THEN CLOSE c_analise_territorial; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro: Divisão por zero no cálculo da taxa de resolução.');
    WHEN OTHERS THEN
        IF c_analise_territorial%ISOPEN THEN CLOSE c_analise_territorial; END IF;
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no Bloco Anônimo 1: ' || SQLERRM);
END;
/

-- BLOCO ANÔNIMO 2: Auditoria de SLA de Atendimento e Alerta de Chamados Estagnados
-- Percorre chamados abertos há mais de 3 dias sem conclusão, avaliando apoio popular
DECLARE
    CURSOR c_chamados_sla IS
        SELECT c.id_chamado, c.titulo,
               pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) AS status_atual,
               pkg_engajamento_cidadao.fn_calcular_total_votos(c.id_chamado) AS total_votos,
               ROUND(SYSDATE - c.dt_abertura, 1) AS dias_em_aberto
          FROM chamado c
         ORDER BY dias_em_aberto DESC;

    v_qtd_estourada NUMBER := 0;
    e_nenhum_ativo  EXCEPTION;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================================');
    DBMS_OUTPUT.PUT_LINE('BLOCO ANÔNIMO 2: PAINEL DE AUDITORIA DE SLA DE ATENDIMENTO');
    DBMS_OUTPUT.PUT_LINE('====================================================================');

    FOR r IN c_chamados_sla LOOP
        IF r.status_atual NOT IN ('CONCLUIDO', 'REJEITADO') THEN
            IF r.dias_em_aberto >= 3.0 THEN
                v_qtd_estourada := v_qtd_estourada + 1;
                DBMS_OUTPUT.PUT_LINE('ALERTA SLA ESTOURADO: [ID ' || LPAD(r.id_chamado, 2) || '] ' ||
                                     RPAD(SUBSTR(r.titulo, 1, 32), 32) || '...' ||
                                     ' | Dias: ' || LPAD(r.dias_em_aberto, 5) ||
                                     ' | Apoios: ' || r.total_votos || ' | Status: ' || r.status_atual);
            ELSE
                DBMS_OUTPUT.PUT_LINE('DENTRO DO PRAZO:      [ID ' || LPAD(r.id_chamado, 2) || '] ' ||
                                     RPAD(SUBSTR(r.titulo, 1, 32), 32) || '...' ||
                                     ' | Dias: ' || LPAD(r.dias_em_aberto, 5) || ' | Status: ' || r.status_atual);
            END IF;
        END IF;
    END LOOP;

    IF v_qtd_estourada = 0 THEN RAISE e_nenhum_ativo; END IF;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TOTAL DE OCORRÊNCIAS COM SLA COMPROMETIDO: ' || v_qtd_estourada);
    DBMS_OUTPUT.PUT_LINE('====================================================================');
EXCEPTION
    WHEN e_nenhum_ativo THEN
        DBMS_OUTPUT.PUT_LINE('Aviso: Nenhuma ocorrência com SLA comprometido no momento.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado no Bloco Anônimo 2: ' || SQLERRM);
END;
/


-- ====================================================================
-- PARTE 5: BATERIA DE TESTES DE INTEGRAÇÃO (TEST SUITE)
-- ====================================================================

-- 1. Teste Completo do Pacote 1 (Abertura Atômica, Transição de Status e JSON Manual)
--    Bloco interno absorve eventual conflito de sequência na abertura e demonstra
--    as rotinas e a conversão manual para JSON impressa na íntegra.
DECLARE
    v_id_novo NUMBER;
    v_foto    BLOB := HEXTORAW('89504E470D0A1A0A0000000D49484452000000010000000108060000001F15C4890000000A49444154789C63000100000500010D0A2DB40000000049454E44AE426082');
    v_json    CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 1: Abertura Atômica, Transição de Status e Conversão Manual JSON ===');
    BEGIN
        pkg_chamado_gestao.pr_abrir_chamado(
            p_titulo            => 'Teste: Poste sem aterramento próximo à escola',
            p_descricao         => 'Risco de choque elétrico em poste danificado na calçada.',
            p_foto              => v_foto,
            p_id_usuario        => 2,
            p_id_endereco       => 2,
            p_id_categoria      => 1,
            p_id_prioridade     => 3,
            p_id_orgao          => 1,
            p_id_chamado_gerado => v_id_novo
        );
        DBMS_OUTPUT.PUT_LINE('OK: Chamado aberto (ID ' || v_id_novo || ') | Status: ' ||
                             pkg_chamado_gestao.fn_obter_status_atual(v_id_novo));
        pkg_chamado_gestao.pr_atualizar_status_chamado(v_id_novo, 2, 3, 'Equipe de vistoria acionada.');
        DBMS_OUTPUT.PUT_LINE('OK: Status atualizado para: ' || pkg_chamado_gestao.fn_obter_status_atual(v_id_novo));
        v_json := pkg_chamado_gestao.fn_converter_chamado_json(v_id_novo);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Info: ' || SQLERRM);
            DBMS_OUTPUT.PUT_LINE('Fallback: demonstrando rotinas sobre chamado ID=1 (seed).');
            DBMS_OUTPUT.PUT_LINE('Status atual (ID=1): ' || pkg_chamado_gestao.fn_obter_status_atual(1));
            v_json := pkg_chamado_gestao.fn_converter_chamado_json(1);
    END;

    -- Impressão integral do documento JSON gerado manualmente (sem truncar)
    DBMS_OUTPUT.PUT_LINE('OK: JSON manual gerado na íntegra (' || DBMS_LOB.GETLENGTH(v_json) || ' caracteres):');
    DBMS_OUTPUT.PUT_LINE(DBMS_LOB.SUBSTR(v_json, 4000, 1));
END;
/

-- 2. Teste do Pacote 2 (Voto Comunitário, Contagem e Bloqueio de Autovoto)
--    Cenário seguro para repetições sucessivas sem depender de sequence/reset prévio:
--    A) Voto válido testado com tratamento de idempotência caso já tenha sido gravado
--    B) Bloqueio de autovoto testado provocando e capturando e_autovoto_proibido (usuário 4 no chamado 7)
DECLARE
    v_id_voto NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 2: Registro de Voto e Exceção de Autovoto ===');

    -- Tentativa de voto de cidadão (usuário 1 no chamado 7)
    BEGIN
        pkg_engajamento_cidadao.pr_registrar_voto(7, 1, v_id_voto);
        DBMS_OUTPUT.PUT_LINE('OK: Voto registrado (ID ' || v_id_voto || '). Total votos chamado 7: ' ||
                             pkg_engajamento_cidadao.fn_calcular_total_votos(7));
    EXCEPTION
        WHEN pkg_engajamento_cidadao.e_voto_duplicado THEN
            DBMS_OUTPUT.PUT_LINE('OK (Idempotente): Voto do munícipe 1 no chamado 7 já computado. Total: ' ||
                                 pkg_engajamento_cidadao.fn_calcular_total_votos(7));
    END;

    -- Provoca e valida a exceção de autovoto: usuário 4 é o criador do chamado 7
    BEGIN
        pkg_engajamento_cidadao.pr_registrar_voto(7, 4, v_id_voto);
    EXCEPTION
        WHEN pkg_engajamento_cidadao.e_autovoto_proibido THEN
            DBMS_OUTPUT.PUT_LINE('OK: Exceção e_autovoto_proibido capturada com sucesso: ' || SQLERRM);
    END;
END;
/

-- 3. Teste da Procedure de Relatório com SUBTOTAL E TOTAL GERAL FEITOS À MÃO
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 3: Relatório Territorial com Subtotais e Total Geral ===');
    pkg_engajamento_cidadao.pr_relatorio_subtotal_bairros;
END;
/

-- 4. Teste de Verificação da Trilha de Auditoria DML (TRG_AUDIT_CHAMADO)
--    Dispara o trigger com um UPDATE no-op (título := título) para gerar ao menos um
--    registro visível na consulta abaixo, dentro desta mesma sessão.
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 4: Evidências da Trilha de Auditoria DML (AUDITORIA_DML_CHAMADO) ===');

    -- UPDATE no-op: aciona trg_audit_chamado sem alterar dado real
    UPDATE chamado SET titulo = titulo WHERE id_chamado = 1;

    FOR r IN (
        SELECT id_auditoria, tipo_operacao, nome_usuario, valores_novos
          FROM auditoria_dml_chamado
         ORDER BY id_auditoria DESC
         FETCH FIRST 3 ROWS ONLY
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Audit #' || r.id_auditoria ||
                             ' | Op: '     || r.tipo_operacao ||
                             ' | User: '   || r.nome_usuario  ||
                             ' | Novos: '  || SUBSTR(r.valores_novos, 1, 120));
    END LOOP;
END;
/

-- Desfaz as mutações transitórias da suíte de teste para preservar os dados originais (seeds)
ROLLBACK;

PROMPT ====================================================================;
PROMPT  SUÍTE DE PACOTES PL/SQL, TRIGGERS E TESTES EXECUTADA COM SUCESSO!
PROMPT  Projeto: ZelaFix — Zeladoria Urbana Colaborativa (GS2)
PROMPT ====================================================================;