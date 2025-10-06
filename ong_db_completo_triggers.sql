-- SQL completo para ONG com triggers e todas as tabelas

-- =====================================
-- DROP TABLES ANTIGAS (CASCADE PARA DEPENDÊNCIAS)
-- =====================================
DROP TABLE IF EXISTS presencas CASCADE;
DROP TABLE IF EXISTS inscricoes CASCADE;
DROP TABLE IF EXISTS oficinas CASCADE;
DROP TABLE IF EXISTS anamnese_aluno CASCADE;
DROP TABLE IF EXISTS relacionamentos CASCADE;
DROP TABLE IF EXISTS alunos CASCADE;
DROP TABLE IF EXISTS funcionarios CASCADE;
DROP TABLE IF EXISTS ongs CASCADE;
DROP TABLE IF EXISTS notificacoes CASCADE;

-- =====================================
-- TABELA ONGs
-- =====================================
CREATE TABLE ongs (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    endereco VARCHAR(300),
    telefone VARCHAR(50),
    email VARCHAR(100),
    responsaveis JSONB
);

-- =====================================
-- TABELA FUNCIONÁRIOS
-- =====================================
CREATE TABLE funcionarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    data_nascimento DATE,
    estado_civil VARCHAR(50),
    nome_pais VARCHAR(200),
    endereco VARCHAR(300),
    telefone VARCHAR(50),
    email VARCHAR(100),
    cpf VARCHAR(20) UNIQUE,
    rg VARCHAR(20),
    ctps VARCHAR(50),
    titulo_eleitor VARCHAR(50),
    pis VARCHAR(50),
    cnh VARCHAR(50),
    reservista VARCHAR(50),
    cargo VARCHAR(50),
    data_admissao DATE,
    salario NUMERIC(10,2),
    contato_emergencia JSONB
);

-- =====================================
-- TABELA ALUNOS
-- =====================================
CREATE TABLE alunos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    data_nascimento DATE NOT NULL,
    sexo VARCHAR(20),
    cpf VARCHAR(20) UNIQUE,
    rg VARCHAR(20),
    endereco VARCHAR(300),
    telefones JSONB,
    email VARCHAR(100),
    responsaveis JSONB,
    contato_emergencia JSONB,
    escolaridade VARCHAR(100),
    profissao VARCHAR(100),
    informacoes_socioeconomicas JSONB,
    observacoes JSONB,
    id_ong INT REFERENCES ongs(id),
    CONSTRAINT check_profissao_maior CHECK (
        profissao IS NULL OR date_part('year', age(data_nascimento)) >= 18
    )
);

-- =====================================
-- TABELA ANAMNESE
-- =====================================
CREATE TABLE anamnese_aluno (
    id SERIAL PRIMARY KEY,
    id_aluno INT REFERENCES alunos(id),
    queixa_principal TEXT,
    historico_condicao TEXT,
    antecedentes_pessoais TEXT,
    antecedentes_familiares TEXT,
    habitos_vida TEXT,
    aspectos_psicossociais TEXT,
    consideracoes_adicionais TEXT
);

-- =====================================
-- TABELA OFICINAS / TURMAS
-- =====================================
CREATE TABLE oficinas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(200) NOT NULL,
    faixa_etaria_min INT,
    faixa_etaria_max INT,
    horario TIME,
    id_instrutor INT REFERENCES funcionarios(id),
    descricao TEXT
);

-- =====================================
-- TABELA INSCRIÇÕES
-- =====================================
CREATE TABLE inscricoes (
    id SERIAL PRIMARY KEY,
    id_aluno INT REFERENCES alunos(id),
    id_oficina INT REFERENCES oficinas(id),
    data_inscricao DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'ativo',
    CONSTRAINT status_valido CHECK (status IN ('ativo','cancelado','concluido'))
);

-- =====================================
-- TABELA PRESENÇAS
-- =====================================
CREATE TABLE presencas (
    id SERIAL PRIMARY KEY,
    id_inscricao INT REFERENCES inscricoes(id),
    data_aula DATE NOT NULL,
    chegou_aula BOOLEAN DEFAULT FALSE
);

-- =====================================
-- TABELA RELACIONAMENTOS
-- =====================================
CREATE TABLE relacionamentos (
    id SERIAL PRIMARY KEY,
    id_aluno INT REFERENCES alunos(id),
    id_funcionario INT REFERENCES funcionarios(id),
    tipo_relacionamento VARCHAR(100)
);

-- =====================================
-- TABELA NOTIFICAÇÕES
-- =====================================
CREATE TABLE notificacoes (
    id SERIAL PRIMARY KEY,
    id_oficina INT REFERENCES oficinas(id),
    mensagem TEXT,
    data_criacao TIMESTAMP DEFAULT NOW(),
    visualizada BOOLEAN DEFAULT FALSE
);

-- =====================================
-- TRIGGERS
-- =====================================

-- 1️⃣ Trigger: Aviso de alteração de horário da oficina
CREATE OR REPLACE FUNCTION aviso_horario_oficina()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notificacoes (id_oficina, mensagem, data_criacao)
    VALUES (NEW.id, 'O horário da turma foi alterado. Avisar os responsáveis.', NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_horario_oficina
AFTER UPDATE OF horario ON oficinas
FOR EACH ROW
EXECUTE FUNCTION aviso_horario_oficina();

-- 2️⃣ Trigger: Bloqueio de alunos sensíveis
CREATE OR REPLACE FUNCTION bloquear_alunos_sensiveis()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.observacoes->>'sensible' = 'true' THEN
        RAISE EXCEPTION 'Acesso bloqueado: aluno sensível';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_bloquear_aluno
BEFORE UPDATE OR DELETE ON alunos
FOR EACH ROW
EXECUTE FUNCTION bloquear_alunos_sensiveis();

-- 3️⃣ Trigger: Registrar chegada do aluno automaticamente
CREATE OR REPLACE FUNCTION registrar_chegada()
RETURNS TRIGGER AS $$
BEGIN
    NEW.chegou_aula := TRUE;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_chegada_aula
BEFORE INSERT ON presencas
FOR EACH ROW
EXECUTE FUNCTION registrar_chegada();
