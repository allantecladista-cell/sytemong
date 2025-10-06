
-- 1. ONG
CREATE TABLE ongs (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    cnpj VARCHAR(18) UNIQUE,
    telefone VARCHAR(20),
    email VARCHAR(100),
    endereco TEXT
);

-- 2. Funcionários
CREATE TABLE funcionarios (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    genero VARCHAR(20),
    cpf VARCHAR(14) UNIQUE NOT NULL,
    rg VARCHAR(20),
    data_nascimento DATE,
    nacionalidade VARCHAR(50),
    estado_civil VARCHAR(30),
    escolaridade VARCHAR(50),
    cargo VARCHAR(50),
    data_admissao DATE,
    telefone VARCHAR(20),
    telefone2 VARCHAR(20),
    email VARCHAR(100),
    endereco TEXT,
    cidade VARCHAR(50),
    estado VARCHAR(2),
    cep VARCHAR(10),
    id_ong INT REFERENCES ongs(id),
    observacoes TEXT
);

-- 3. Alunos
CREATE TABLE alunos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    genero VARCHAR(30) CHECK (genero IN (
        'masculino', 
        'feminino', 
        'não binário', 
        'prefere não informar', 
        'outro'
    )),
    cpf VARCHAR(14),
    rg VARCHAR(20),
    data_nascimento DATE,
    nacionalidade VARCHAR(50),
    cor_raca VARCHAR(30),
    telefone_aluno VARCHAR(20),
    email VARCHAR(100),
    endereco TEXT,
    cidade VARCHAR(50),
    estado VARCHAR(2),
    cep VARCHAR(10),
    filiacao_1_nome VARCHAR(100),
    filiacao_1_parentesco VARCHAR(50),
    filiacao_2_nome VARCHAR(100),
    filiacao_2_parentesco VARCHAR(50),
    nome_responsavel VARCHAR(100),
    parentesco_responsavel VARCHAR(50),
    telefone_responsavel VARCHAR(20),
    email_responsavel VARCHAR(100),
    escola_atual VARCHAR(100),
    grau_escolar VARCHAR(50),
    turno_escolar VARCHAR(20),
    observacoes_escolares TEXT,
    possui_deficiencia BOOLEAN DEFAULT FALSE,
    tipo_deficiencia VARCHAR(100),
    observacoes TEXT,
    id_ong INT REFERENCES ongs(id),
    UNIQUE(cpf, data_nascimento, nome)
);

-- 4. Oficinas
CREATE TABLE oficinas (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    dia_semana VARCHAR(20),
    horario TIME,
    local VARCHAR(100),
    id_professor INT REFERENCES funcionarios(id),
    id_ong INT REFERENCES ongs(id)
);

-- 5. Inscrições
CREATE TABLE inscricoes (
    id SERIAL PRIMARY KEY,
    id_aluno INT REFERENCES alunos(id),
    id_oficina INT REFERENCES oficinas(id),
    data_inscricao DATE DEFAULT CURRENT_DATE,
    UNIQUE(id_aluno, id_oficina)
);

-- 6. Presenças
CREATE TABLE presencas (
    id SERIAL PRIMARY KEY,
    id_inscricao INT REFERENCES inscricoes(id),
    data DATE NOT NULL,
    presente BOOLEAN DEFAULT FALSE,
    observacao TEXT,
    UNIQUE(id_inscricao, data)
);

-- 7. Relacionamentos entre alunos
CREATE TABLE relacionamentos (
    id SERIAL PRIMARY KEY,
    id_aluno1 INT REFERENCES alunos(id),
    id_aluno2 INT REFERENCES alunos(id),
    tipo_relacao VARCHAR(50),
    observacao TEXT,
    CHECK (id_aluno1 <> id_aluno2),
    UNIQUE(id_aluno1, id_aluno2)
);

-- 8. Anamnese do aluno
CREATE TABLE anamnese_aluno (
    id SERIAL PRIMARY KEY,
    id_aluno INT REFERENCES alunos(id) ON DELETE CASCADE,
    possui_problema_saude BOOLEAN,
    descricao_problema_saude TEXT,
    faz_uso_medicamentos BOOLEAN,
    quais_medicamentos TEXT,
    possui_alegia BOOLEAN,
    tipo_alegia TEXT,
    restricoes_alimentares TEXT,
    vacinacao_em_dia BOOLEAN,
    acompanhamento_medico BOOLEAN,
    nome_unidade_saude VARCHAR(100),
    contato_emergencia_nome VARCHAR(100),
    contato_emergencia_parentesco VARCHAR(50),
    contato_emergencia_telefone VARCHAR(20),
    data_preenchimento DATE DEFAULT CURRENT_DATE,
    observacoes_gerais TEXT
);
