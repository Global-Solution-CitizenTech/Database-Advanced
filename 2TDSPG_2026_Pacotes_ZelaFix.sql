-- ====================================================================
-- FIAP GRADUAÇÃO — GLOBAL SOLUTION 2026/2
-- CITIZENTECH: TECNOLOGIA COM O CIDADÃO NO CENTRO DA INOVAÇÃO
-- DISCIPLINA: Mastering Relational and Non-Relational Database
-- REQUISITOS: 2 Pacotes PL/SQL, 2 Funções, 2 Procedimentos, 2 Triggers e 2 Blocos Anônimos
-- PROJETO: ZelaFix — Zeladoria Urbana Colaborativa
-- MODELAGEM: 100% Fiel a citizenTech.ddl (Sem Views, Aderência Curricular Estrita)
-- TURMA: 2TDSPG (2º Ano ADS - Turmas de Fevereiro)
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
-- Ciclo de vida do chamado, abertura atômica, histórico de status e auditoria DML
-- ====================================================================
CREATE OR REPLACE PACKAGE pkg_chamado_gestao AS

    -- Exceções padronizadas com códigos ORA de negócio
    e_parametro_invalido     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_parametro_invalido, -20001);

    e_chamado_inexistente    EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_chamado_inexistente, -20002);

    e_usuario_inexistente    EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_usuario_inexistente, -20003);

    e_status_inexistente     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_status_inexistente, -20004);

    e_usuario_nao_gestor     EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_usuario_nao_gestor, -20005);

    -- 1.1 Procedimento de Abertura Atômica de Chamado Urbano
    -- Insere o chamado e grava atomicamente o 1º histórico com status 'ABERTO' (3FN)
    PROCEDURE pr_abrir_chamado (
        p_titulo              IN  VARCHAR2,
        p_descricao           IN  VARCHAR2,
        p_foto                IN  BLOB,
        p_id_usuario          IN  NUMBER,
        p_id_endereco         IN  NUMBER,
        p_id_categoria        IN  NUMBER,
        p_id_chamado_gerado   OUT NUMBER
    );

    -- 1.2 Procedimento de Transição e Atualização de Status da Zeladoria
    PROCEDURE pr_atualizar_status_chamado (
        p_id_chamado          IN NUMBER,
        p_id_status           IN NUMBER,
        p_id_usuario_fiscal   IN NUMBER,
        p_observacoes         IN VARCHAR2
    );

    -- 1.3 Função que obtém o nome do status atual vigente do chamado (3FN via MAX de HIST_CHAMADO)
    -- Substitui integralmente a necessidade de VIEW, atendendo aos requisitos de FUNCTION do edital
    FUNCTION fn_obter_status_atual (
        p_id_chamado IN NUMBER
    ) RETURN VARCHAR2;

    -- 1.4 Procedimento Modular de Gravação de Auditoria DML (invocado pela trigger)
    PROCEDURE pr_registrar_auditoria_chamado (
        p_tipo_operacao  IN VARCHAR2,
        p_old_id         IN NUMBER,
        p_old_titulo     IN VARCHAR2,
        p_old_categoria  IN NUMBER,
        p_old_usuario    IN NUMBER,
        p_new_id         IN NUMBER,
        p_new_titulo     IN VARCHAR2,
        p_new_categoria  IN NUMBER,
        p_new_usuario    IN NUMBER
    );

END pkg_chamado_gestao;
/


-- ====================================================================
-- PACOTE 1: CORPO (PACKAGE BODY - PKG_CHAMADO_GESTAO)
-- ====================================================================
CREATE OR REPLACE PACKAGE BODY pkg_chamado_gestao AS

    -- 1.1 Implementação da Abertura Atômica
    PROCEDURE pr_abrir_chamado (
        p_titulo              IN  VARCHAR2,
        p_descricao           IN  VARCHAR2,
        p_foto                IN  BLOB,
        p_id_usuario          IN  NUMBER,
        p_id_endereco         IN  NUMBER,
        p_id_categoria        IN  NUMBER,
        p_id_chamado_gerado   OUT NUMBER
    ) IS
        v_existe_usr   NUMBER;
        v_existe_end   NUMBER;
        v_existe_cat   NUMBER;
        v_id_status_ab NUMBER;
        v_novo_id      NUMBER;
    BEGIN
        -- Validações básicas de integridade
        IF p_titulo IS NULL OR LENGTH(TRIM(p_titulo)) < 5 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Título do chamado é obrigatório e deve ter ao menos 5 caracteres.');
        END IF;

        IF p_descricao IS NULL OR LENGTH(TRIM(p_descricao)) < 10 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Descrição detalhada é obrigatória (mínimo de 10 caracteres).');
        END IF;

        IF p_foto IS NULL OR DBMS_LOB.GETLENGTH(p_foto) = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'A evidência fotográfica (BLOB) é obrigatória para abertura do chamado.');
        END IF;

        -- Validação de existência de chaves estrangeiras
        SELECT COUNT(1) INTO v_existe_usr FROM usuario WHERE id_usuario = p_id_usuario;
        IF v_existe_usr = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Usuário com id ' || p_id_usuario || ' não encontrado.');
        END IF;

        SELECT COUNT(1) INTO v_existe_end FROM endereco WHERE id_endereco = p_id_endereco;
        IF v_existe_end = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Endereço com id ' || p_id_endereco || ' não encontrado.');
        END IF;

        SELECT COUNT(1) INTO v_existe_cat FROM categoria WHERE id_categoria = p_id_categoria;
        IF v_existe_cat = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Categoria com id ' || p_id_categoria || ' não encontrada.');
        END IF;

        -- Localiza o id do status inicial 'ABERTO'
        SELECT id_status INTO v_id_status_ab FROM status WHERE nm_status = 'ABERTO';

        -- Inserção da entidade central CHAMADO (apenas colunas de citizenTech.ddl)
        INSERT INTO chamado (
            titulo, descricao, foto, dt_abertura,
            usuario_id_usuario, endereco_id_endereco, categoria_id_categoria
        ) VALUES (
            TRIM(p_titulo), TRIM(p_descricao), p_foto, SYSDATE,
            p_id_usuario, p_id_endereco, p_id_categoria
        ) RETURNING id_chamado INTO v_novo_id;

        -- Inserção atômica do 1º Histórico de Status (Garantia de 3FN estrita)
        INSERT INTO hist_chamado (
            dt_mudanca, observacoes, chamado_id_chamado, usuario_id_usuario, status_id_status
        ) VALUES (
            SYSDATE, 'Chamado registrado pelo cidadão via aplicativo ZelaFix.', v_novo_id, p_id_usuario, v_id_status_ab
        );

        p_id_chamado_gerado := v_novo_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Status inicial ABERTO não cadastrado no sistema.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20006, 'Erro na abertura do chamado: ' || SQLERRM);
    END pr_abrir_chamado;


    -- 1.2 Implementação da Transição de Status
    PROCEDURE pr_atualizar_status_chamado (
        p_id_chamado          IN NUMBER,
        p_id_status           IN NUMBER,
        p_id_usuario_fiscal   IN NUMBER,
        p_observacoes         IN VARCHAR2
    ) IS
        v_existe_chamado NUMBER;
        v_existe_status  NUMBER;
        v_cargo_usuario  VARCHAR2(10);
        v_nome_status    VARCHAR2(20);
    BEGIN
        IF p_id_chamado IS NULL OR p_id_chamado <= 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'ID do chamado inválido.');
        END IF;

        -- Valida chamado
        SELECT COUNT(1) INTO v_existe_chamado FROM chamado WHERE id_chamado = p_id_chamado;
        IF v_existe_chamado = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Chamado com id ' || p_id_chamado || ' não encontrado.');
        END IF;

        -- Valida status
        SELECT COUNT(1), MAX(nm_status) 
          INTO v_existe_status, v_nome_status 
          FROM status 
         WHERE id_status = p_id_status;
        IF v_existe_status = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Status com id ' || p_id_status || ' não cadastrado.');
        END IF;

        -- Valida se usuário tem perfil de GESTOR
        BEGIN
            SELECT cargo INTO v_cargo_usuario FROM usuario WHERE id_usuario = p_id_usuario_fiscal;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20003, 'Usuário fiscal não encontrado.');
        END;

        IF v_cargo_usuario <> 'GESTOR' THEN
            RAISE_APPLICATION_ERROR(-20005, 'Operação restrita: Apenas gestores públicos podem alterar o status do chamado.');
        END IF;

        -- Insere nova evolução no histórico
        INSERT INTO hist_chamado (
            dt_mudanca, observacoes, chamado_id_chamado, usuario_id_usuario, status_id_status
        ) VALUES (
            SYSDATE, NVL(TRIM(p_observacoes), 'Atualização de status para ' || v_nome_status),
            p_id_chamado, p_id_usuario_fiscal, p_id_status
        );
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20007, 'Erro ao atualizar status do chamado: ' || SQLERRM);
    END pr_atualizar_status_chamado;


    -- 1.3 Implementação da Função de Consulta de Status Atual (Sem View, 100% Curricular)
    FUNCTION fn_obter_status_atual (
        p_id_chamado IN NUMBER
    ) RETURN VARCHAR2 IS
        PRAGMA UDF; -- Otimização nativa Oracle 12c+ (elimina context-switch SQL/PLSQL)
        v_nm_status VARCHAR2(20);
    BEGIN
        IF p_id_chamado IS NULL OR p_id_chamado <= 0 THEN
            RETURN 'INVALIDO';
        END IF;

        SELECT s.nm_status
          INTO v_nm_status
          FROM hist_chamado h
          JOIN status s ON s.id_status = h.status_id_status
         WHERE h.chamado_id_chamado = p_id_chamado
           AND h.id_hist = (
               SELECT MAX(h2.id_hist)
                 FROM hist_chamado h2
                WHERE h2.chamado_id_chamado = p_id_chamado
           );

        RETURN v_nm_status;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'SEM_HISTORICO';
        WHEN OTHERS THEN
            RETURN 'ERRO';
    END fn_obter_status_atual;


    -- 1.4 Gravação Modular de Auditoria DML
    PROCEDURE pr_registrar_auditoria_chamado (
        p_tipo_operacao  IN VARCHAR2,
        p_old_id         IN NUMBER,
        p_old_titulo     IN VARCHAR2,
        p_old_categoria  IN NUMBER,
        p_old_usuario    IN NUMBER,
        p_new_id         IN NUMBER,
        p_new_titulo     IN VARCHAR2,
        p_new_categoria  IN NUMBER,
        p_new_usuario    IN NUMBER
    ) IS
        v_old_json VARCHAR2(4000);
        v_new_json VARCHAR2(4000);
    BEGIN
        IF p_tipo_operacao IN ('UPDATE', 'DELETE') THEN
            v_old_json := JSON_OBJECT(
                'id_chamado'   VALUE p_old_id,
                'titulo'       VALUE p_old_titulo,
                'id_categoria' VALUE p_old_categoria,
                'id_usuario'   VALUE p_old_usuario
            );
        END IF;

        IF p_tipo_operacao IN ('INSERT', 'UPDATE') THEN
            v_new_json := JSON_OBJECT(
                'id_chamado'   VALUE p_new_id,
                'titulo'       VALUE p_new_titulo,
                'id_categoria' VALUE p_new_categoria,
                'id_usuario'   VALUE p_new_usuario
            );
        END IF;

        INSERT INTO auditoria_dml_chamado (
            nome_usuario, tipo_operacao, data_hora_operacao, valores_anteriores, valores_novos
        ) VALUES (
            USER, p_tipo_operacao, SYSTIMESTAMP, v_old_json, v_new_json
        );
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Falha silenciosa na auditoria DML de chamado: ' || SQLERRM);
    END pr_registrar_auditoria_chamado;

END pkg_chamado_gestao;
/


-- ====================================================================
-- PACOTE 2: ESPECIFICAÇÃO (PACKAGE SPECIFICATION - PKG_ENGAJAMENTO_CIDADAO)
-- Colaboração comunitária, apuração de votos, criticidade por bairro e relatórios JSON
-- ====================================================================
CREATE OR REPLACE PACKAGE pkg_engajamento_cidadao AS

    -- Exceções padronizadas
    e_voto_duplicado         EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_voto_duplicado, -20010);

    e_chamado_fechado        EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_chamado_fechado, -20011);

    e_autovoto_proibido      EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_autovoto_proibido, -20012);

    -- 2.1 Procedimento para Registrar Apoio/Voto Comunitário em Chamado (N:M)
    PROCEDURE pr_registrar_voto (
        p_id_chamado       IN  NUMBER,
        p_id_usuario       IN  NUMBER,
        p_id_voto_gerado   OUT NUMBER
    );

    -- 2.2 Função para Calcular o Total de Votos de um Chamado
    FUNCTION fn_calcular_total_votos (
        p_id_chamado IN NUMBER
    ) RETURN NUMBER;

    -- 2.3 Função para Classificar a Criticidade de um Bairro com base em chamados e votos
    FUNCTION fn_classificar_criticidade_bairro (
        p_id_bairro IN NUMBER
    ) RETURN VARCHAR2;

    -- 2.4 Procedimento para Exportar Relatório de Engajamento por Bairro em JSON Nativo (CLOB)
    -- Equivalência Relacional -> Não Relacional (MongoDB Document)
    PROCEDURE pr_relatorio_engajamento_json (
        p_id_bairro        IN  NUMBER,
        p_relatorio_json   OUT CLOB
    );

END pkg_engajamento_cidadao;
/


-- ====================================================================
-- PACOTE 2: CORPO (PACKAGE BODY - PKG_ENGAJAMENTO_CIDADAO)
-- ====================================================================
CREATE OR REPLACE PACKAGE BODY pkg_engajamento_cidadao AS

    -- 2.1 Implementação do Registro de Voto
    PROCEDURE pr_registrar_voto (
        p_id_chamado       IN  NUMBER,
        p_id_usuario       IN  NUMBER,
        p_id_voto_gerado   OUT NUMBER
    ) IS
        v_autor_chamado   NUMBER;
        v_status_atual    VARCHAR2(20);
        v_novo_id_voto    NUMBER;
    BEGIN
        IF p_id_chamado IS NULL OR p_id_usuario IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001, 'IDs de chamado e usuário são obrigatórios para registrar voto.');
        END IF;

        -- Valida se o chamado existe e quem é o autor
        BEGIN
            SELECT usuario_id_usuario INTO v_autor_chamado FROM chamado WHERE id_chamado = p_id_chamado;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20002, 'Chamado não encontrado.');
        END;

        -- Regra cívica anti-autofavorecimento: autor não vota no próprio chamado
        IF v_autor_chamado = p_id_usuario THEN
            RAISE_APPLICATION_ERROR(-20012, 'Integridade cívica: O munícipe autor não pode votar no próprio chamado.');
        END IF;

        -- Valida se o chamado está aberto ou em andamento
        v_status_atual := pkg_chamado_gestao.fn_obter_status_atual(p_id_chamado);
        IF v_status_atual IN ('CONCLUIDO', 'REJEITADO') THEN
            RAISE_APPLICATION_ERROR(-20011, 'Votação encerrada: Não é permitido votar em chamado com status ' || v_status_atual || '.');
        END IF;

        -- Insere o voto na associativa N:M
        INSERT INTO voto_chamado (
            dt_voto, chamado_id_chamado, usuario_id_usuario
        ) VALUES (
            SYSDATE, p_id_chamado, p_id_usuario
        ) RETURNING id_voto INTO v_novo_id_voto;

        p_id_voto_gerado := v_novo_id_voto;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            RAISE_APPLICATION_ERROR(-20010, 'Munícipe já registrou apoio anteriormente neste chamado.');
        WHEN OTHERS THEN
            RAISE;
    END pr_registrar_voto;


    -- 2.2 Implementação do Total de Votos
    FUNCTION fn_calcular_total_votos (
        p_id_chamado IN NUMBER
    ) RETURN NUMBER IS
        PRAGMA UDF; -- Aceleração direta no motor SQL (elimina overhead de troca de contexto)
        v_total NUMBER := 0;
    BEGIN
        IF p_id_chamado IS NULL OR p_id_chamado <= 0 THEN
            RETURN 0;
        END IF;

        SELECT COUNT(1)
          INTO v_total
          FROM voto_chamado
         WHERE chamado_id_chamado = p_id_chamado;

        RETURN v_total;
    END fn_calcular_total_votos;


    -- 2.3 Implementação da Classificação de Criticidade do Bairro
    -- Otimizado para realizar a apuração territorial em passagem única com agregação analítica
    FUNCTION fn_classificar_criticidade_bairro (
        p_id_bairro IN NUMBER
    ) RETURN VARCHAR2 IS
        PRAGMA UDF;
        v_chamados_abertos NUMBER := 0;
        v_total_votos      NUMBER := 0;
    BEGIN
        IF p_id_bairro IS NULL OR p_id_bairro <= 0 THEN
            RETURN 'DESCONHECIDO';
        END IF;

        -- Varredura única agregada por território: apura pendências e apoios acumulados
        SELECT NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) NOT IN ('CONCLUIDO', 'REJEITADO') THEN 1 ELSE 0 END), 0),
               NVL(SUM(pkg_engajamento_cidadao.fn_calcular_total_votos(c.id_chamado)), 0)
          INTO v_chamados_abertos, v_total_votos
          FROM chamado c
          JOIN endereco e ON e.id_endereco = c.endereco_id_endereco
         WHERE e.bairro_id_bairro = p_id_bairro;

        -- Regra de decisão analítica de governança urbana
        IF v_chamados_abertos >= 3 OR v_total_votos >= 5 THEN
            RETURN 'CRITICO';
        ELSIF v_chamados_abertos >= 1 OR v_total_votos >= 2 THEN
            RETURN 'ALERTA';
        ELSE
            RETURN 'ESTAVEL';
        END IF;
    END fn_classificar_criticidade_bairro;


    -- 2.4 Implementação do Relatório de Engajamento em JSON Nativo (CLOB)
    PROCEDURE pr_relatorio_engajamento_json (
        p_id_bairro        IN  NUMBER,
        p_relatorio_json   OUT CLOB
    ) IS
        v_nome_bairro      VARCHAR2(50);
        v_nome_cidade      VARCHAR2(50);
        v_criticidade      VARCHAR2(20);
    BEGIN
        -- Dados cadastrais do bairro
        SELECT b.nm_bairro, c.nm_cidade
          INTO v_nome_bairro, v_nome_cidade
          FROM bairro b
          JOIN cidade c ON c.id_cidade = b.cidade_id_cidade
         WHERE b.id_bairro = p_id_bairro;

        v_criticidade := fn_classificar_criticidade_bairro(p_id_bairro);

        -- Gera JSON consolidado nativo Oracle
        SELECT JSON_OBJECT(
            'idBairro'        VALUE p_id_bairro,
            'nomeBairro'      VALUE v_nome_bairro,
            'cidade'          VALUE v_nome_cidade,
            'nivelCriticidade' VALUE v_criticidade,
            'dataExtracao'    VALUE TO_CHAR(SYSDATE, 'YYYY-MM-DD"T"HH24:MI:SS'),
            'chamados'        VALUE NVL((
                SELECT JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'idChamado'    VALUE c.id_chamado,
                        'titulo'       VALUE c.titulo,
                        'statusAtual'  VALUE pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado),
                        'totalVotos'   VALUE fn_calcular_total_votos(c.id_chamado),
                        'dtAbertura'   VALUE TO_CHAR(c.dt_abertura, 'YYYY-MM-DD')
                    ) ORDER BY fn_calcular_total_votos(c.id_chamado) DESC
                )
                FROM chamado c
                JOIN endereco e ON e.id_endereco = c.endereco_id_endereco
                WHERE e.bairro_id_bairro = p_id_bairro
            ), JSON_ARRAY())
            RETURNING CLOB PRETTY
        )
        INTO p_relatorio_json
        FROM dual;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Bairro com id ' || p_id_bairro || ' não encontrado.');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20020, 'Erro ao gerar relatório JSON de engajamento: ' || SQLERRM);
    END pr_relatorio_engajamento_json;

END pkg_engajamento_cidadao;
/


-- ====================================================================
-- PARTE 3: TRIGGERS (DISPARADORES PL/SQL)
-- ====================================================================

-- 3.1 Trigger de Auditoria DML na Tabela CHAMADO
-- Dispara em qualquer alteração, delegando a execução para a procedure empacotada
CREATE OR REPLACE TRIGGER trg_audit_chamado
AFTER INSERT OR UPDATE OR DELETE ON chamado
FOR EACH ROW
BEGIN
    pkg_chamado_gestao.pr_registrar_auditoria_chamado(
        p_tipo_operacao  => CASE 
                               WHEN INSERTING THEN 'INSERT' 
                               WHEN UPDATING  THEN 'UPDATE' 
                               ELSE 'DELETE' 
                            END,
        p_old_id         => :OLD.id_chamado,
        p_old_titulo     => :OLD.titulo,
        p_old_categoria  => :OLD.categoria_id_categoria,
        p_old_usuario    => :OLD.usuario_id_usuario,
        p_new_id         => :NEW.id_chamado,
        p_new_titulo     => :NEW.titulo,
        p_new_categoria  => :NEW.categoria_id_categoria,
        p_new_usuario    => :NEW.usuario_id_usuario
    );
END trg_audit_chamado;
/

-- 3.2 Trigger de Validação Cívica de Voto
-- Valida antes da inserção na tabela associativa VOTO_CHAMADO
CREATE OR REPLACE TRIGGER trg_valida_voto_chamado
BEFORE INSERT ON voto_chamado
FOR EACH ROW
DECLARE
    v_autor_chamado NUMBER;
    v_status_atual  VARCHAR2(20);
BEGIN
    -- Busca autor do chamado
    SELECT usuario_id_usuario
      INTO v_autor_chamado
      FROM chamado
     WHERE id_chamado = :NEW.chamado_id_chamado;

    IF v_autor_chamado = :NEW.usuario_id_usuario THEN
        RAISE_APPLICATION_ERROR(-20012, 'Não é permitido votar no próprio chamado cadastrado.');
    END IF;

    -- Valida se o chamado não está encerrado
    v_status_atual := pkg_chamado_gestao.fn_obter_status_atual(:NEW.chamado_id_chamado);
    IF v_status_atual IN ('CONCLUIDO', 'REJEITADO') THEN
        RAISE_APPLICATION_ERROR(-20011, 'Votação encerrada para este chamado (status: ' || v_status_atual || ').');
    END IF;
END trg_valida_voto_chamado;
/


-- ====================================================================
-- PARTE 4: DOIS BLOCOS ANÔNIMOS PL/SQL (CURSORES, IF/ELSIF E LOOP)
-- ====================================================================

-- BLOCO ANÔNIMO 1: Processamento em Lote e Diagnóstico Territorial de Bairros
-- Utiliza Cursor Explícito, LOOP de Repetição e Estruturas de Decisão IF/ELSIF/ELSE
DECLARE
    -- Cursor explícito com consolidação agregada por bairro
    CURSOR c_analise_territorial IS
        SELECT b.id_bairro,
               b.nm_bairro,
               c.nm_cidade,
               COUNT(ch.id_chamado) AS total_chamados,
               NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) = 'CONCLUIDO' THEN 1 ELSE 0 END), 0) AS total_concluidos,
               NVL(SUM(CASE WHEN pkg_chamado_gestao.fn_obter_status_atual(ch.id_chamado) NOT IN ('CONCLUIDO', 'REJEITADO') THEN 1 ELSE 0 END), 0) AS total_pendentes
          FROM bairro b
          JOIN cidade c ON c.id_cidade = b.cidade_id_cidade
          LEFT JOIN endereco e ON e.bairro_id_bairro = b.id_bairro
          LEFT JOIN chamado ch ON ch.endereco_id_endereco = e.id_endereco
         GROUP BY b.id_bairro, b.nm_bairro, c.nm_cidade
         ORDER BY total_pendentes DESC, b.nm_bairro ASC;

    v_reg            c_analise_territorial%ROWTYPE;
    v_criticidade    VARCHAR2(20);
    v_taxa_resolucao NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================================');
    DBMS_OUTPUT.PUT_LINE('RELATÓRIO DE MONITORAMENTO TERRITORIAL URBANO (ZELAFIX - ODS 11)');
    DBMS_OUTPUT.PUT_LINE('====================================================================');

    OPEN c_analise_territorial;
    LOOP
        FETCH c_analise_territorial INTO v_reg;
        EXIT WHEN c_analise_territorial%NOTFOUND;

        -- Calcula taxa de resolução percentual
        IF v_reg.total_chamados > 0 THEN
            v_taxa_resolucao := ROUND((v_reg.total_concluidos / v_reg.total_chamados) * 100, 1);
        ELSE
            v_taxa_resolucao := 100.0;
        END IF;

        -- Avaliação da criticidade via Função Empacotada
        v_criticidade := pkg_engajamento_cidadao.fn_classificar_criticidade_bairro(v_reg.id_bairro);

        -- Estrutura Condicional com Tomada de Decisão Operacional
        IF v_criticidade = 'CRITICO' THEN
            DBMS_OUTPUT.PUT_LINE('[URGÊNCIA MÁXIMA] Bairro: ' || RPAD(v_reg.nm_bairro, 15) || 
                                 ' | Pendentes: ' || LPAD(v_reg.total_pendentes, 2) || 
                                 ' | Taxa Resolução: ' || LPAD(v_taxa_resolucao, 5) || '% | ALOCAÇÃO DE MUTIRÃO IMEDIATO');
        ELSIF v_criticidade = 'ALERTA' THEN
            DBMS_OUTPUT.PUT_LINE('[ATENÇÃO / ALERTA] Bairro: ' || RPAD(v_reg.nm_bairro, 15) || 
                                 ' | Pendentes: ' || LPAD(v_reg.total_pendentes, 2) || 
                                 ' | Taxa Resolução: ' || LPAD(v_taxa_resolucao, 5) || '% | MONITORAR ESCALA SEMANAL');
        ELSE
            DBMS_OUTPUT.PUT_LINE('[OPERACAO NORMAL] Bairro: ' || RPAD(v_reg.nm_bairro, 15) || 
                                 ' | Pendentes: ' || LPAD(v_reg.total_pendentes, 2) || 
                                 ' | Taxa Resolução: ' || LPAD(v_taxa_resolucao, 5) || '% | SITUAÇÃO CONTROLADA');
        END IF;
    END LOOP;
    CLOSE c_analise_territorial;

    DBMS_OUTPUT.PUT_LINE('====================================================================');
END;
/


-- BLOCO ANÔNIMO 2: Auditoria de SLA de Atendimento e Alerta de Chamados Estagnados
-- Percorre chamados abertos há mais de 3 dias sem conclusão, avaliando apoio popular
DECLARE
    CURSOR c_chamados_sla IS
        SELECT c.id_chamado,
               c.titulo,
               c.dt_abertura,
               pkg_chamado_gestao.fn_obter_status_atual(c.id_chamado) AS status_atual,
               pkg_engajamento_cidadao.fn_calcular_total_votos(c.id_chamado) AS total_votos,
               ROUND(SYSDATE - c.dt_abertura, 1) AS dias_em_aberto
          FROM chamado c
         ORDER BY dias_em_aberto DESC;

    v_chamado       c_chamados_sla%ROWTYPE;
    v_qtd_estourada NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('====================================================================');
    DBMS_OUTPUT.PUT_LINE('PAINEL DE AUDITORIA DE SLA DE ATENDIMENTO DA PREFEITURA');
    DBMS_OUTPUT.PUT_LINE('====================================================================');

    FOR v_chamado IN c_chamados_sla LOOP
        -- Filtra apenas chamados que ainda não foram concluídos nem rejeitados
        IF v_chamado.status_atual NOT IN ('CONCLUIDO', 'REJEITADO') THEN
            IF v_chamado.dias_em_aberto >= 3.0 THEN
                v_qtd_estourada := v_qtd_estourada + 1;
                DBMS_OUTPUT.PUT_LINE('ALERTA SLA ESTOURADO: [ID ' || LPAD(v_chamado.id_chamado, 2) || '] ' || 
                                     SUBSTR(v_chamado.titulo, 1, 35) || '...' ||
                                     ' | Dias: ' || v_chamado.dias_em_aberto || 
                                     ' | Apoios: ' || v_chamado.total_votos || 
                                     ' | Status: ' || v_chamado.status_atual);
            ELSE
                DBMS_OUTPUT.PUT_LINE('DENTRO DO PRAZO:      [ID ' || LPAD(v_chamado.id_chamado, 2) || '] ' || 
                                     SUBSTR(v_chamado.titulo, 1, 35) || '...' ||
                                     ' | Dias: ' || v_chamado.dias_em_aberto || 
                                     ' | Status: ' || v_chamado.status_atual);
            END IF;
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('TOTAL DE OCORRÊNCIAS COM SLA COMPROMETIDO: ' || v_qtd_estourada);
    DBMS_OUTPUT.PUT_LINE('====================================================================');
END;
/


-- ====================================================================
-- PARTE 5: BATERIA COMPLETA DE TESTES DE INTEGRAÇÃO (TEST SUITE)
-- ====================================================================

-- 1. Teste de Abertura Atômica de Chamado (Procedure pr_abrir_chamado)
DECLARE
    v_id_gerado     NUMBER;
    v_blob_exemplo  BLOB;
    v_status_check  VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 1: pkg_chamado_gestao.pr_abrir_chamado ===');
    v_blob_exemplo := HEXTORAW('89504E470D0A1A0A0000000D49484452000000010000000108060000001F15C4890000000A49444154789C63000100000500010D0A2DB40000000049454E44AE426082');

    pkg_chamado_gestao.pr_abrir_chamado(
        p_titulo            => 'Teste Automatizado: Vazamento de gás na via pública',
        p_descricao         => 'Forte odor de gás inflamável registrado próximo à escola municipal.',
        p_foto              => v_blob_exemplo,
        p_id_usuario        => 1,
        p_id_endereco       => 1,
        p_id_categoria      => 3,
        p_id_chamado_gerado => v_id_gerado
    );

    v_status_check := pkg_chamado_gestao.fn_obter_status_atual(v_id_gerado);
    DBMS_OUTPUT.PUT_LINE('Chamado gerado com sucesso! ID: ' || v_id_gerado);
    DBMS_OUTPUT.PUT_LINE('Status inicial atômico verificado via FUNCTION em HIST_CHAMADO: ' || v_status_check);
END;
/

-- 2. Teste de Transição de Status por Gestor Público (Procedure pr_atualizar_status_chamado)
DECLARE
    v_novo_status VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 2: pkg_chamado_gestao.pr_atualizar_status_chamado ===');
    -- Gestor ID 3 (Eng. Roberto Santos) atualiza chamado ID 1 para 'EM_EXECUCAO' (Status ID 3)
    pkg_chamado_gestao.pr_atualizar_status_chamado(
        p_id_chamado         => 1,
        p_id_status          => 3,
        p_id_usuario_fiscal  => 3,
        p_observacoes        => 'Equipe terceirizada ILUME em deslocamento com caminhão guindaste.'
    );

    v_novo_status := pkg_chamado_gestao.fn_obter_status_atual(1);
    DBMS_OUTPUT.PUT_LINE('Chamado ID 1 atualizado com sucesso. Status vigente verificado: ' || v_novo_status);
END;
/

-- 3. Teste de Votação/Apoio Comunitário e Contagem (Procedure pr_registrar_voto e fn_calcular_total_votos)
DECLARE
    v_id_voto_novo NUMBER;
    v_total_antes  NUMBER;
    v_total_depois NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 3: pkg_engajamento_cidadao.pr_registrar_voto ===');
    v_total_antes := pkg_engajamento_cidadao.fn_calcular_total_votos(4);
    
    -- Cidadão ID 2 apoia o chamado ID 4 (autor do chamado é ID 4)
    pkg_engajamento_cidadao.pr_registrar_voto(
        p_id_chamado     => 4,
        p_id_usuario     => 2,
        p_id_voto_gerado => v_id_voto_novo
    );

    v_total_depois := pkg_engajamento_cidadao.fn_calcular_total_votos(4);
    DBMS_OUTPUT.PUT_LINE('Voto registrado com ID: ' || v_id_voto_novo);
    DBMS_OUTPUT.PUT_LINE('Chamado ID 4 -> Votos antes: ' || v_total_antes || ' | Votos agora: ' || v_total_depois);
END;
/

-- 4. Teste de Relatório de Engajamento em JSON Nativo (Procedure pr_relatorio_engajamento_json)
DECLARE
    v_relatorio_clob CLOB;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 4: pkg_engajamento_cidadao.pr_relatorio_engajamento_json ===');
    pkg_engajamento_cidadao.pr_relatorio_engajamento_json(
        p_id_bairro      => 1, -- Bela Vista
        p_relatorio_json => v_relatorio_clob
    );
    DBMS_OUTPUT.PUT_LINE('Relatório JSON extraído com sucesso (' || DBMS_LOB.GETLENGTH(v_relatorio_clob) || ' caracteres):');
    DBMS_OUTPUT.PUT_LINE(SUBSTR(v_relatorio_clob, 1, 500) || '...');
END;
/

-- 5. Teste de Verificação dos Registros Gravados pela Trigger de Auditoria (TRG_AUDIT_CHAMADO)
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 5: Evidências da Trilha de Auditoria DML (AUDITORIA_DML_CHAMADO) ===');
    FOR r IN (
        SELECT id_auditoria, nome_usuario, tipo_operacao, data_hora_operacao, valores_novos
          FROM auditoria_dml_chamado
         ORDER BY id_auditoria DESC
         FETCH FIRST 3 ROWS ONLY
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Audit #' || r.id_auditoria || ' | Operação: ' || r.tipo_operacao || 
                             ' | Usuário: ' || r.nome_usuario || ' | Payload: ' || r.valores_novos);
    END LOOP;
END;
/

-- 6. Teste de Violação Cívica Tratada por Exceção (Tentativa de Votar no Próprio Chamado)
DECLARE
    v_dummy NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== TESTE 6: Teste de Exceção de Integridade Cívica (Autovoto) ===');
    -- Cidadão ID 1 tenta votar no chamado ID 1 (ele é o autor)
    pkg_engajamento_cidadao.pr_registrar_voto(
        p_id_chamado     => 1,
        p_id_usuario     => 1,
        p_id_voto_gerado => v_dummy
    );
    DBMS_OUTPUT.PUT_LINE('ERRO: Não deveria ter permitido o autovoto.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Exceção capturada com sucesso conforme o esperado: ' || SQLERRM);
END;
/

-- Desfaz as mutações transitórias da suíte de teste para manter a integridade limpa das sementes
ROLLBACK;

PROMPT ====================================================================;
PROMPT  SUÍTE DE PACOTES PL/SQL, TRIGGERS E TESTES EXECUTADA COM SUCESSO!
PROMPT  Projeto: ZelaFix — Zeladoria Urbana Colaborativa (GS2)
PROMPT ====================================================================;
