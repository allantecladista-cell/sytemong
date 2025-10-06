--
-- PostgreSQL database dump
--

\restrict o2dXw7mn7wjerrHGNPcf9acouyghhfBFWKFghdYxHrJBuqktFxVTnB4UGLPPXPy

-- Dumped from database version 14.19 (Homebrew)
-- Dumped by pg_dump version 14.19 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: atualizar_idade(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.atualizar_idade() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.data_nascimento IS NOT NULL THEN
        NEW.idade := DATE_PART('year', AGE(NEW.data_nascimento));
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.atualizar_idade() OWNER TO postgres;

--
-- Name: aviso_horario_oficina(); Type: FUNCTION; Schema: public; Owner: allanvieira
--

CREATE FUNCTION public.aviso_horario_oficina() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO notificacoes (id_oficina, mensagem, data_criacao)
    VALUES (NEW.id, 'O horário da turma foi alterado. Avisar os responsáveis.', NOW());
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.aviso_horario_oficina() OWNER TO allanvieira;

--
-- Name: bloquear_alunos_sensiveis(); Type: FUNCTION; Schema: public; Owner: allanvieira
--

CREATE FUNCTION public.bloquear_alunos_sensiveis() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.observacoes->>'sensible' = 'true' THEN
        RAISE EXCEPTION 'Acesso bloqueado: aluno sensível';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.bloquear_alunos_sensiveis() OWNER TO allanvieira;

--
-- Name: registrar_chegada(); Type: FUNCTION; Schema: public; Owner: allanvieira
--

CREATE FUNCTION public.registrar_chegada() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.chegou_aula := TRUE;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.registrar_chegada() OWNER TO allanvieira;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: alunos; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.alunos (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    data_nascimento date DEFAULT '1900-01-01'::date NOT NULL,
    sexo character varying(20),
    cpf character varying(20),
    rg character varying(20),
    endereco character varying(300),
    telefones jsonb,
    email character varying(100),
    responsaveis jsonb,
    contato_emergencia jsonb,
    escolaridade character varying(100),
    profissao character varying(100),
    informacoes_socioeconomicas jsonb,
    observacoes jsonb,
    id_ong integer,
    ativo boolean DEFAULT true,
    ong_id integer,
    genero character varying(20),
    pai character varying(100),
    mae character varying(100),
    telefone character varying(20),
    escola character varying(100),
    turno character varying(20),
    nome_responsavel character varying(100),
    telefone_responsavel character varying(20),
    email_responsavel character varying(100),
    parentesco character varying(50),
    estado_civil text,
    cep text,
    celular character varying,
    estuda character varying,
    trabalha character varying,
    necessidade_especial character varying,
    necessidade_detalhe character varying,
    rg_responsavel character varying,
    cpf_responsavel character varying,
    nome_social text,
    idade integer,
    numero text,
    bairro text,
    obs_estuda text,
    alergia text,
    alergia_detalhe text,
    tipo_responsavel text,
    termo text,
    CONSTRAINT check_profissao_maior CHECK (((profissao IS NULL) OR (date_part('year'::text, age((data_nascimento)::timestamp with time zone)) >= (18)::double precision)))
);


ALTER TABLE public.alunos OWNER TO allanvieira;

--
-- Name: alunos_atividades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alunos_atividades (
    id integer NOT NULL,
    id_aluno integer NOT NULL,
    id_atividade integer NOT NULL,
    tipo_atividade character varying(20) NOT NULL,
    ativo boolean DEFAULT true,
    data_cadastro timestamp without time zone DEFAULT now(),
    CONSTRAINT alunos_atividades_tipo_atividade_check CHECK (((tipo_atividade)::text = ANY ((ARRAY['Curso'::character varying, 'Oficina'::character varying])::text[])))
);


ALTER TABLE public.alunos_atividades OWNER TO postgres;

--
-- Name: alunos_atividades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.alunos_atividades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alunos_atividades_id_seq OWNER TO postgres;

--
-- Name: alunos_atividades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.alunos_atividades_id_seq OWNED BY public.alunos_atividades.id;


--
-- Name: alunos_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.alunos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alunos_id_seq OWNER TO allanvieira;

--
-- Name: alunos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.alunos_id_seq OWNED BY public.alunos.id;


--
-- Name: anamnese_aluno; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.anamnese_aluno (
    id integer NOT NULL,
    id_aluno integer,
    queixa_principal text,
    historico_condicao text,
    antecedentes_pessoais text,
    antecedentes_familiares text,
    habitos_vida text,
    aspectos_psicossociais text,
    consideracoes_adicionais text
);


ALTER TABLE public.anamnese_aluno OWNER TO allanvieira;

--
-- Name: anamnese_aluno_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.anamnese_aluno_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.anamnese_aluno_id_seq OWNER TO allanvieira;

--
-- Name: anamnese_aluno_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.anamnese_aluno_id_seq OWNED BY public.anamnese_aluno.id;


--
-- Name: atividades; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.atividades (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    id_categoria integer NOT NULL,
    descricao text,
    ativo boolean DEFAULT true,
    criado_em timestamp without time zone DEFAULT now(),
    tipo text NOT NULL,
    nome_display character varying(200),
    classe text,
    CONSTRAINT atividades_tipo_check CHECK ((tipo = ANY (ARRAY['curso'::text, 'oficina'::text])))
);


ALTER TABLE public.atividades OWNER TO postgres;

--
-- Name: atividades_dias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.atividades_dias (
    id integer NOT NULL,
    id_atividade integer NOT NULL,
    id_dia integer NOT NULL
);


ALTER TABLE public.atividades_dias OWNER TO postgres;

--
-- Name: atividades_dias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.atividades_dias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.atividades_dias_id_seq OWNER TO postgres;

--
-- Name: atividades_dias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.atividades_dias_id_seq OWNED BY public.atividades_dias.id;


--
-- Name: atividades_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.atividades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.atividades_id_seq OWNER TO postgres;

--
-- Name: atividades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.atividades_id_seq OWNED BY public.atividades.id;


--
-- Name: atividades_unificadas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.atividades_unificadas (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    tipo character varying(20) NOT NULL,
    id_atividade integer,
    id_instrutor integer NOT NULL,
    faixa_etaria_min integer,
    faixa_etaria_max integer,
    duracao interval,
    data_inicio date,
    data_fim date,
    descricao text,
    limite_alunos integer,
    ativo boolean DEFAULT true,
    criado_em timestamp without time zone DEFAULT now(),
    horario time without time zone
);


ALTER TABLE public.atividades_unificadas OWNER TO postgres;

--
-- Name: atividades_unificadas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.atividades_unificadas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.atividades_unificadas_id_seq OWNER TO postgres;

--
-- Name: atividades_unificadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.atividades_unificadas_id_seq OWNED BY public.atividades_unificadas.id;


--
-- Name: categorias; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categorias (
    id integer NOT NULL,
    nome character varying(100) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.categorias OWNER TO postgres;

--
-- Name: categorias_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categorias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.categorias_id_seq OWNER TO postgres;

--
-- Name: categorias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categorias_id_seq OWNED BY public.categorias.id;


--
-- Name: cursos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cursos (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    id_atividade integer NOT NULL,
    id_instrutor integer,
    duracao interval,
    data_inicio date,
    data_fim date,
    descricao text,
    ativo boolean DEFAULT true,
    criado_em timestamp without time zone DEFAULT now(),
    limite_alunos integer DEFAULT 0,
    horario time without time zone,
    faixa_etaria text
);


ALTER TABLE public.cursos OWNER TO postgres;

--
-- Name: cursos_dias; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.cursos_dias (
    id integer NOT NULL,
    id_curso integer,
    id_dia integer
);


ALTER TABLE public.cursos_dias OWNER TO allanvieira;

--
-- Name: cursos_dias_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.cursos_dias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cursos_dias_id_seq OWNER TO allanvieira;

--
-- Name: cursos_dias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.cursos_dias_id_seq OWNED BY public.cursos_dias.id;


--
-- Name: cursos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cursos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cursos_id_seq OWNER TO postgres;

--
-- Name: cursos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cursos_id_seq OWNED BY public.cursos.id;


--
-- Name: dias_semana; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.dias_semana (
    id integer NOT NULL,
    nome character varying(10) NOT NULL
);


ALTER TABLE public.dias_semana OWNER TO allanvieira;

--
-- Name: dias_semana_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.dias_semana_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dias_semana_id_seq OWNER TO allanvieira;

--
-- Name: dias_semana_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.dias_semana_id_seq OWNED BY public.dias_semana.id;


--
-- Name: funcionarios; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.funcionarios (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    data_nascimento date,
    estado_civil character varying(50),
    endereco character varying(300),
    telefone character varying(50),
    email character varying(100),
    cpf character varying(20),
    rg character varying(20),
    ctps character varying(50),
    titulo_eleitor character varying(50),
    pis character varying(50),
    cnh character varying(50),
    reservista character varying(50),
    cargo character varying(50),
    data_admissao date,
    salario numeric(10,2),
    contato_emergencia jsonb,
    ativo boolean DEFAULT true,
    ong_id integer DEFAULT 1,
    pai character varying(200),
    mae character varying(200),
    contato_emergencia_nome text,
    contato_emergencia_telefone text
);


ALTER TABLE public.funcionarios OWNER TO allanvieira;

--
-- Name: funcionarios_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.funcionarios_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.funcionarios_id_seq OWNER TO allanvieira;

--
-- Name: funcionarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.funcionarios_id_seq OWNED BY public.funcionarios.id;


--
-- Name: inscricoes; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.inscricoes (
    id integer NOT NULL,
    id_aluno integer,
    id_oficina integer,
    data_inscricao date DEFAULT CURRENT_DATE,
    status character varying(20) DEFAULT 'ativo'::character varying,
    CONSTRAINT status_valido CHECK (((status)::text = ANY ((ARRAY['ativo'::character varying, 'cancelado'::character varying, 'concluido'::character varying])::text[])))
);


ALTER TABLE public.inscricoes OWNER TO allanvieira;

--
-- Name: inscricoes_cursos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inscricoes_cursos (
    id integer NOT NULL,
    id_aluno integer NOT NULL,
    id_curso integer NOT NULL,
    data_inscricao date DEFAULT now(),
    data_conclusao date,
    aprovado boolean,
    status character varying(50) DEFAULT 'Ativo'::character varying,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.inscricoes_cursos OWNER TO postgres;

--
-- Name: inscricoes_cursos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inscricoes_cursos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inscricoes_cursos_id_seq OWNER TO postgres;

--
-- Name: inscricoes_cursos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inscricoes_cursos_id_seq OWNED BY public.inscricoes_cursos.id;


--
-- Name: inscricoes_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.inscricoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inscricoes_id_seq OWNER TO allanvieira;

--
-- Name: inscricoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.inscricoes_id_seq OWNED BY public.inscricoes.id;


--
-- Name: inscricoes_oficinas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inscricoes_oficinas (
    id integer NOT NULL,
    id_aluno integer NOT NULL,
    id_oficina integer NOT NULL,
    data_inscricao date DEFAULT now(),
    status character varying(50) DEFAULT 'Ativo'::character varying,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.inscricoes_oficinas OWNER TO postgres;

--
-- Name: inscricoes_oficinas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inscricoes_oficinas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.inscricoes_oficinas_id_seq OWNER TO postgres;

--
-- Name: inscricoes_oficinas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inscricoes_oficinas_id_seq OWNED BY public.inscricoes_oficinas.id;


--
-- Name: notificacoes; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.notificacoes (
    id integer NOT NULL,
    id_oficina integer,
    mensagem text,
    data_criacao timestamp without time zone DEFAULT now(),
    visualizada boolean DEFAULT false
);


ALTER TABLE public.notificacoes OWNER TO allanvieira;

--
-- Name: notificacoes_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.notificacoes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notificacoes_id_seq OWNER TO allanvieira;

--
-- Name: notificacoes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.notificacoes_id_seq OWNED BY public.notificacoes.id;


--
-- Name: oficinas; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.oficinas (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    faixa_etaria_min integer,
    faixa_etaria_max integer,
    horario time without time zone,
    id_instrutor integer,
    descricao text,
    limite_alunos integer DEFAULT 0,
    id_atividade integer
);


ALTER TABLE public.oficinas OWNER TO allanvieira;

--
-- Name: oficinas_dias; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.oficinas_dias (
    id integer NOT NULL,
    id_oficina integer,
    id_dia integer
);


ALTER TABLE public.oficinas_dias OWNER TO allanvieira;

--
-- Name: oficinas_dias_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.oficinas_dias_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oficinas_dias_id_seq OWNER TO allanvieira;

--
-- Name: oficinas_dias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.oficinas_dias_id_seq OWNED BY public.oficinas_dias.id;


--
-- Name: oficinas_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.oficinas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.oficinas_id_seq OWNER TO allanvieira;

--
-- Name: oficinas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.oficinas_id_seq OWNED BY public.oficinas.id;


--
-- Name: ongs; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.ongs (
    id integer NOT NULL,
    nome character varying(200) NOT NULL,
    endereco character varying(300),
    telefone character varying(50),
    email character varying(100),
    responsaveis jsonb,
    ativo boolean DEFAULT true
);


ALTER TABLE public.ongs OWNER TO allanvieira;

--
-- Name: ongs_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.ongs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ongs_id_seq OWNER TO allanvieira;

--
-- Name: ongs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.ongs_id_seq OWNED BY public.ongs.id;


--
-- Name: participacao_cursos; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.participacao_cursos (
    id integer NOT NULL,
    id_aluno integer,
    id_curso integer,
    data_inicio date DEFAULT now(),
    data_fim date,
    aprovado boolean,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.participacao_cursos OWNER TO postgres;

--
-- Name: participacao_cursos_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.participacao_cursos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.participacao_cursos_id_seq OWNER TO postgres;

--
-- Name: participacao_cursos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.participacao_cursos_id_seq OWNED BY public.participacao_cursos.id;


--
-- Name: participacao_oficinas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.participacao_oficinas (
    id integer NOT NULL,
    id_aluno integer,
    id_oficina integer,
    data_inicio date DEFAULT now(),
    data_fim date,
    status character varying(50) DEFAULT 'ativo'::character varying,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.participacao_oficinas OWNER TO postgres;

--
-- Name: participacao_oficinas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.participacao_oficinas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.participacao_oficinas_id_seq OWNER TO postgres;

--
-- Name: participacao_oficinas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.participacao_oficinas_id_seq OWNED BY public.participacao_oficinas.id;


--
-- Name: presencas; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.presencas (
    id integer NOT NULL,
    id_inscricao integer,
    data_aula date NOT NULL,
    chegou_aula boolean DEFAULT false
);


ALTER TABLE public.presencas OWNER TO allanvieira;

--
-- Name: presencas_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.presencas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.presencas_id_seq OWNER TO allanvieira;

--
-- Name: presencas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.presencas_id_seq OWNED BY public.presencas.id;


--
-- Name: relacionamentos; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.relacionamentos (
    id integer NOT NULL,
    id_aluno integer,
    id_funcionario integer,
    tipo_relacionamento character varying(100)
);


ALTER TABLE public.relacionamentos OWNER TO allanvieira;

--
-- Name: relacionamentos_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.relacionamentos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.relacionamentos_id_seq OWNER TO allanvieira;

--
-- Name: relacionamentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.relacionamentos_id_seq OWNED BY public.relacionamentos.id;


--
-- Name: senhas; Type: TABLE; Schema: public; Owner: allanvieira
--

CREATE TABLE public.senhas (
    id integer NOT NULL,
    usuario character varying(100) NOT NULL,
    senha character varying(200) NOT NULL,
    nivel integer NOT NULL,
    ativo boolean DEFAULT true,
    ong_id integer,
    cargo character varying(50)
);


ALTER TABLE public.senhas OWNER TO allanvieira;

--
-- Name: senhas_id_seq; Type: SEQUENCE; Schema: public; Owner: allanvieira
--

CREATE SEQUENCE public.senhas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.senhas_id_seq OWNER TO allanvieira;

--
-- Name: senhas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: allanvieira
--

ALTER SEQUENCE public.senhas_id_seq OWNED BY public.senhas.id;


--
-- Name: usuarios_acesso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuarios_acesso (
    id integer NOT NULL,
    id_funcionario integer NOT NULL,
    tipo_usuario character varying(20) NOT NULL,
    login character varying(100) NOT NULL,
    senha character varying(255) NOT NULL,
    criado_em timestamp without time zone DEFAULT now()
);


ALTER TABLE public.usuarios_acesso OWNER TO postgres;

--
-- Name: usuarios_acesso_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuarios_acesso_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.usuarios_acesso_id_seq OWNER TO postgres;

--
-- Name: usuarios_acesso_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuarios_acesso_id_seq OWNED BY public.usuarios_acesso.id;


--
-- Name: alunos id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.alunos ALTER COLUMN id SET DEFAULT nextval('public.alunos_id_seq'::regclass);


--
-- Name: alunos_atividades id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alunos_atividades ALTER COLUMN id SET DEFAULT nextval('public.alunos_atividades_id_seq'::regclass);


--
-- Name: anamnese_aluno id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.anamnese_aluno ALTER COLUMN id SET DEFAULT nextval('public.anamnese_aluno_id_seq'::regclass);


--
-- Name: atividades id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades ALTER COLUMN id SET DEFAULT nextval('public.atividades_id_seq'::regclass);


--
-- Name: atividades_dias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades_dias ALTER COLUMN id SET DEFAULT nextval('public.atividades_dias_id_seq'::regclass);


--
-- Name: atividades_unificadas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades_unificadas ALTER COLUMN id SET DEFAULT nextval('public.atividades_unificadas_id_seq'::regclass);


--
-- Name: categorias id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias ALTER COLUMN id SET DEFAULT nextval('public.categorias_id_seq'::regclass);


--
-- Name: cursos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cursos ALTER COLUMN id SET DEFAULT nextval('public.cursos_id_seq'::regclass);


--
-- Name: cursos_dias id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.cursos_dias ALTER COLUMN id SET DEFAULT nextval('public.cursos_dias_id_seq'::regclass);


--
-- Name: dias_semana id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.dias_semana ALTER COLUMN id SET DEFAULT nextval('public.dias_semana_id_seq'::regclass);


--
-- Name: funcionarios id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.funcionarios ALTER COLUMN id SET DEFAULT nextval('public.funcionarios_id_seq'::regclass);


--
-- Name: inscricoes id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.inscricoes ALTER COLUMN id SET DEFAULT nextval('public.inscricoes_id_seq'::regclass);


--
-- Name: inscricoes_cursos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscricoes_cursos ALTER COLUMN id SET DEFAULT nextval('public.inscricoes_cursos_id_seq'::regclass);


--
-- Name: inscricoes_oficinas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscricoes_oficinas ALTER COLUMN id SET DEFAULT nextval('public.inscricoes_oficinas_id_seq'::regclass);


--
-- Name: notificacoes id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.notificacoes ALTER COLUMN id SET DEFAULT nextval('public.notificacoes_id_seq'::regclass);


--
-- Name: oficinas id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas ALTER COLUMN id SET DEFAULT nextval('public.oficinas_id_seq'::regclass);


--
-- Name: oficinas_dias id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas_dias ALTER COLUMN id SET DEFAULT nextval('public.oficinas_dias_id_seq'::regclass);


--
-- Name: ongs id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.ongs ALTER COLUMN id SET DEFAULT nextval('public.ongs_id_seq'::regclass);


--
-- Name: participacao_cursos id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participacao_cursos ALTER COLUMN id SET DEFAULT nextval('public.participacao_cursos_id_seq'::regclass);


--
-- Name: participacao_oficinas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participacao_oficinas ALTER COLUMN id SET DEFAULT nextval('public.participacao_oficinas_id_seq'::regclass);


--
-- Name: presencas id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.presencas ALTER COLUMN id SET DEFAULT nextval('public.presencas_id_seq'::regclass);


--
-- Name: relacionamentos id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.relacionamentos ALTER COLUMN id SET DEFAULT nextval('public.relacionamentos_id_seq'::regclass);


--
-- Name: senhas id; Type: DEFAULT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.senhas ALTER COLUMN id SET DEFAULT nextval('public.senhas_id_seq'::regclass);


--
-- Name: usuarios_acesso id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios_acesso ALTER COLUMN id SET DEFAULT nextval('public.usuarios_acesso_id_seq'::regclass);


--
-- Data for Name: alunos; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.alunos (id, nome, data_nascimento, sexo, cpf, rg, endereco, telefones, email, responsaveis, contato_emergencia, escolaridade, profissao, informacoes_socioeconomicas, observacoes, id_ong, ativo, ong_id, genero, pai, mae, telefone, escola, turno, nome_responsavel, telefone_responsavel, email_responsavel, parentesco, estado_civil, cep, celular, estuda, trabalha, necessidade_especial, necessidade_detalhe, rg_responsavel, cpf_responsavel, nome_social, idade, numero, bairro, obs_estuda, alergia, alergia_detalhe, tipo_responsavel, termo) FROM stdin;
4	Tatia Inácio	2005-03-25	\N	182.812.897-08	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	1	t	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
8	Rafael Costa	2009-11-10	\N	321.654.987-00	\N	Rua C, 789	\N	rafael@gmail.com	\N	\N	6ª série	\N	\N	\N	\N	t	1	Masculino	Paulo Costa	Juliana Costa	21983456789	Escola Municipal C	Matutino	Paulo Costa	21983456789	paulo@gmail.com	Pai	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
9	Mariana Oliveira	2012-01-05	\N	456.789.123-00	\N	Rua D, 101	\N	mariana@gmail.com	\N	\N	3ª série	\N	\N	\N	\N	t	1	Feminino	Ricardo Oliveira	Fernanda Oliveira	21981239876	Escola Municipal D	Vespertino	Fernanda Oliveira	21981239876	fernanda@gmail.com	Mãe	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
10	Gabriel Souza	2010-05-30	\N	654.321.987-00	\N	Rua E, 202	\N	gabriel@gmail.com	\N	\N	5ª série	\N	\N	\N	\N	t	1	Masculino	Eduardo Souza	Paula Souza	21987659874	Escola Municipal E	Matutino	Eduardo Souza	21987659874	eduardo@gmail.com	Pai	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
6	Lucas Almeida silva	2008-12-23	\N	123.456.789-00	\N	None	\N	lucas@gmail.com	\N	\N	None	\N	\N	\N	\N	t	1	2010-03-15	None	Rua A, 123	None	5ª série	Manhã	None	None	none@none	True	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
12	ALLAN SILVA VIEIRA	1981-02-09	\N	052.871.867-81	\N	Rua Paulo Pires, 99	\N	allantecladista@gmail.com	\N	\N		\N	\N	\N	\N	t	1	Masculino			21997660146		\N					\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
13	Rafael dos Santos Vieira	2002-12-18	\N	111.222.333-44	\N		\N	rafael@gmail.com	\N	\N		\N	\N	\N	\N	t	1	Masculino	Allan Vieira	Renata dos Santos Vieira			Integral					\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
7	Beatriz Santos	2011-07-22	\N	987.654.321-00	\N	Rua B, 456	\N	beatriz@gmail.com	\N	\N	4ª série	\N	\N	\N	\N	t	1	Feminino	Carlos Santos	Ana Santos	21981234568	Escola Municipal B	Integral	Ana Santos	21981234567	ana@gmail.com	Mãe	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N
14	Rafael dos Santos Vieira	2002-12-18	Masculino	456.589.012-04	114453566	Rua Paulo Pires, 99	\N	allantecladista@gmail.com	\N	\N	\N	Maqueiro	\N	\N	\N	t	1	\N	\N	\N	2125901115	Unisuam	\N	Rafael dos Santos	\N	\N	\N	Solteiro	20750330	21997660146	Sim	Sim	Sim	TDH	13456778943	432567234-21	\N	22	\N	\N		Sim	Sinusute	Outros	EU E/O MEU RESPONSÁVEL, ASSUMO TOTAL RESPONSABILIDADE...
5	Tatiana a Inácio	1900-01-01	\N	052.871.887-81	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	125	\N	\N	\N	\N	\N	\N	\N
\.


--
-- Data for Name: alunos_atividades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alunos_atividades (id, id_aluno, id_atividade, tipo_atividade, ativo, data_cadastro) FROM stdin;
2	7	2	Oficina	t	2025-10-03 14:03:03.168469
4	7	4	Oficina	f	2025-10-03 14:03:03.168469
6	7	4	Oficina	f	2025-10-03 14:03:03.168469
3	7	3	Curso	f	2025-10-03 14:03:03.168469
7	7	3	Curso	t	2025-10-03 16:29:12.109584
1	7	1	Oficina	f	2025-10-03 14:03:03.168469
8	7	1	Oficina	f	2025-10-03 17:36:47.255002
9	7	1	Oficina	t	2025-10-03 17:37:22.712462
10	7	4	Oficina	t	2025-10-03 17:37:29.889663
11	6	4	Oficina	t	2025-10-04 00:05:02.779011
12	10	4	Oficina	t	2025-10-04 00:06:29.817681
\.


--
-- Data for Name: anamnese_aluno; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.anamnese_aluno (id, id_aluno, queixa_principal, historico_condicao, antecedentes_pessoais, antecedentes_familiares, habitos_vida, aspectos_psicossociais, consideracoes_adicionais) FROM stdin;
\.


--
-- Data for Name: atividades; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.atividades (id, nome, id_categoria, descricao, ativo, criado_em, tipo, nome_display, classe) FROM stdin;
2	futebol	2	\N	t	2025-09-29 17:44:00.129508	oficina	Futebol	\N
13	Futebol	2	\N	t	2025-10-02 00:54:55.169687	oficina	\N	\N
14	Futsal	2	\N	t	2025-10-02 01:12:53.005833	oficina	\N	\N
17	Futebol Básico	1	Oficina de futebol para iniciantes	t	2025-10-02 01:26:48.878968	oficina	Futebol Básico	\N
18	Curso de Piano	2	Curso de piano iniciante	t	2025-10-02 01:26:48.880559	curso	Curso de Piano	\N
21	barbeiro	4	\N	t	2025-10-02 18:44:30.978919	curso	\N	\N
22	Fut007	2	\N	t	2025-10-03 13:45:03.025432	oficina	\N	\N
1	danca de salao	1	\N	t	2025-09-29 17:44:00.129508	curso	Danca De Salao	\N
3	alfabetizacao	3	\N	t	2025-09-29 17:44:00.129508	curso	Alfabetizacao	\N
4	informatica basica	4	\N	t	2025-09-29 17:44:00.129508	curso	Informatica Basica	\N
9	voleibol	2	\N	t	2025-10-01 14:05:56.192614	oficina	Voleibol	\N
11	informatica	3	\N	t	2025-10-01 14:44:43.061357	curso	Informatica	\N
\.


--
-- Data for Name: atividades_dias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.atividades_dias (id, id_atividade, id_dia) FROM stdin;
1	1	6
2	1	7
3	2	2
4	2	4
5	4	3
6	4	5
\.


--
-- Data for Name: atividades_unificadas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.atividades_unificadas (id, nome, tipo, id_atividade, id_instrutor, faixa_etaria_min, faixa_etaria_max, duracao, data_inicio, data_fim, descricao, limite_alunos, ativo, criado_em, horario) FROM stdin;
3	curso de DJ	curso	\N	2	7	100	\N	\N	\N	\N	30	t	2025-10-03 12:44:42.103406	11:00:00
4	Fute004	Oficina	\N	3	9	100	\N	\N	\N		30	t	2025-10-03 13:46:15.552227	10:00:00
2	voley004	Oficina	\N	4	13	15	\N	\N	\N		30	t	2025-10-02 21:20:23.181783	09:00:00
1	Fut1	Oficina	\N	2	7	15	\N	\N	\N		30	t	2025-10-02 01:44:18.733651	10:00:00
\.


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.categorias (id, nome, descricao, ativo, criado_em) FROM stdin;
1	Arte	\N	t	2025-09-29 17:44:00.12167
2	Esporte	\N	t	2025-09-29 17:44:00.12167
3	Pedagógico	\N	t	2025-09-29 17:44:00.12167
4	Profissionalizante	\N	t	2025-09-29 17:44:00.12167
\.


--
-- Data for Name: cursos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.cursos (id, nome, id_atividade, id_instrutor, duracao, data_inicio, data_fim, descricao, ativo, criado_em, limite_alunos, horario, faixa_etaria) FROM stdin;
1	Dança de Salão	1	2	30 days	2025-09-29	2025-10-29	Curso de dança para todos	t	2025-09-29 17:50:18.787863	30	\N	6 - 12
2	Alfabetização	2	2	90 days	2025-09-29	2025-12-29	Curso de alfabetização	t	2025-09-29 17:50:18.787863	30	\N	6 - 12
3	alfa001	3	2	00:00:30	2025-10-02	2025-11-03		t	2025-10-02 00:08:01.611656	30	\N	\N
\.


--
-- Data for Name: cursos_dias; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.cursos_dias (id, id_curso, id_dia) FROM stdin;
1	1	1
2	1	3
3	1	5
4	2	1
5	2	3
6	2	5
7	3	1
8	3	2
9	3	3
10	3	4
11	3	5
\.


--
-- Data for Name: dias_semana; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.dias_semana (id, nome) FROM stdin;
1	Segunda
2	Terça
3	Quarta
4	Quinta
5	Sexta
6	Sábado
7	Domingo
\.


--
-- Data for Name: funcionarios; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.funcionarios (id, nome, data_nascimento, estado_civil, endereco, telefone, email, cpf, rg, ctps, titulo_eleitor, pis, cnh, reservista, cargo, data_admissao, salario, contato_emergencia, ativo, ong_id, pai, mae, contato_emergencia_nome, contato_emergencia_telefone) FROM stdin;
1	ALLAN SILVA VIEIRA	\N	\N	\N	\N	\N	052.871.887-81	\N	\N	\N	\N	\N	\N	Professor	\N	\N	\N	f	1	\N	\N	\N	\N
2	Allan Silva	1985-06-15	Solteiro	Rua A, 123, Rio de Janeiro	21988887777	allan@example.com	123.456.789-00	MG123456	12345	123456789	1234567890	123456	123456	Professor	2025-01-01	3500.00	{"nome": "Carlos Silva", "telefone": "21999998888"}	t	1	José Silva	Maria Silva	\N	\N
3	Maria Oliveira	1990-09-20	Casada	Rua B, 456, Rio de Janeiro	21987776655	maria@example.com	987.654.321-00	MG654321	54321	987654321	0987654321	654321	654321	Secretaria	2025-02-15	2800.00	{"nome": "Paulo Oliveira", "telefone": "21998887766"}	t	1	Antonio Oliveira	Lúcia Oliveira	\N	\N
5	Juliana Souza	1995-12-01	Solteira	Rua D, 321, Rio de Janeiro	21985554433	juliana@example.com	555.666.777-88	MG556677	98765	556677889	3344556677	556677	556677	Assistente	2025-04-20	2500.00	{"nome": "Roberta Souza", "telefone": "21986665544"}	t	1	Marcelo Souza	Patrícia Souza	\N	\N
6	Pedro Santos	1988-07-25	Divorciado	Rua E, 654, Rio de Janeiro	21984443322	pedro@example.com	999.888.777-66	MG998877	34567	998877665	4455667788	998877	998877	Motorista	2025-05-10	2200.00	{"nome": "Ricardo Santos", "telefone": "21985554433"}	t	1	Joaquim Santos	Clara Santos	\N	\N
7	Tatiana a Inácio	\N	\N	\N	\N	\N		\N	\N	\N	\N	\N	\N	secretaria	\N	\N	\N	t	1	\N	\N		
4	Carlos Pereira Silva	1982-03-10	Casado	Rua C, 789, Rio de Janeiro	21986665544	carlos@example.com	111.222.333-44	MG112233	67890	112233445	2233445566	112233	112233	Coordenador	2025-03-05	4200.00	{"nome": "Fernanda Pereira", "telefone": "21987776655"}	t	1	Roberto Pereira	Ana Pereira silva	ALLAN VIEIRA	21997660146
\.


--
-- Data for Name: inscricoes; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.inscricoes (id, id_aluno, id_oficina, data_inscricao, status) FROM stdin;
\.


--
-- Data for Name: inscricoes_cursos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inscricoes_cursos (id, id_aluno, id_curso, data_inscricao, data_conclusao, aprovado, status, criado_em) FROM stdin;
\.


--
-- Data for Name: inscricoes_oficinas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.inscricoes_oficinas (id, id_aluno, id_oficina, data_inscricao, status, criado_em) FROM stdin;
\.


--
-- Data for Name: notificacoes; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.notificacoes (id, id_oficina, mensagem, data_criacao, visualizada) FROM stdin;
\.


--
-- Data for Name: oficinas; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.oficinas (id, nome, faixa_etaria_min, faixa_etaria_max, horario, id_instrutor, descricao, limite_alunos, id_atividade) FROM stdin;
1	Teclado Intermediário	12	16	11:00:00	2	Oficina de teclado para alunos intermediários	0	\N
2	Piano Avançado	12	18	14:00:00	2	Oficina de piano para alunos avançados	0	\N
3	Dança de Salão	\N	\N	10:00:00	2	Oficina aberta para todas as idades	0	\N
6	Voleibol001	7	9	\N	1		30	9
7	Volebol001	7	9	\N	1		30	9
8	Futebol002	10	12	09:00:00	1		30	2
9	Voleibol003	12	14	10:00:00	1		30	9
\.


--
-- Data for Name: oficinas_dias; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.oficinas_dias (id, id_oficina, id_dia) FROM stdin;
1	8	1
2	8	3
3	1	1
4	1	3
5	2	1
6	2	3
7	3	1
8	3	3
9	6	1
10	6	3
11	7	1
12	7	3
13	9	1
14	9	2
15	9	3
16	9	4
17	9	5
18	9	6
\.


--
-- Data for Name: ongs; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.ongs (id, nome, endereco, telefone, email, responsaveis, ativo) FROM stdin;
1	ONG Exemplo	Rua Exemplo, 123	(21) 99999-9999	contato@ongexemplo.org	["Fulano", "Ciclano"]	t
2	ONG Exemplo	Rua Exemplo, 123	(21) 99999-9999	contato@ongexemplo.org	["Fulano", "Ciclano"]	t
\.


--
-- Data for Name: participacao_cursos; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participacao_cursos (id, id_aluno, id_curso, data_inicio, data_fim, aprovado, criado_em) FROM stdin;
7	4	1	2025-09-29	2025-10-29	\N	2025-09-29 17:51:22.764023
8	5	1	2025-09-29	2025-10-29	\N	2025-09-29 17:51:22.764023
9	4	1	2025-09-29	\N	\N	2025-09-29 19:19:16.962703
\.


--
-- Data for Name: participacao_oficinas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.participacao_oficinas (id, id_aluno, id_oficina, data_inicio, data_fim, status, criado_em) FROM stdin;
4	4	1	2025-09-29	\N	ativo	2025-09-29 17:48:13.10509
5	5	1	2025-09-29	\N	ativo	2025-09-29 17:48:13.10509
6	4	1	2025-09-29	\N	ativo	2025-09-29 17:49:02.600432
7	5	1	2025-09-29	\N	ativo	2025-09-29 17:49:02.600432
8	8	2	2025-09-29	\N	ativo	2025-09-29 17:49:02.600432
9	9	2	2025-09-29	\N	ativo	2025-09-29 17:49:02.600432
10	4	1	2025-09-29	\N	ativo	2025-09-29 19:19:07.950625
\.


--
-- Data for Name: presencas; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.presencas (id, id_inscricao, data_aula, chegou_aula) FROM stdin;
\.


--
-- Data for Name: relacionamentos; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.relacionamentos (id, id_aluno, id_funcionario, tipo_relacionamento) FROM stdin;
\.


--
-- Data for Name: senhas; Type: TABLE DATA; Schema: public; Owner: allanvieira
--

COPY public.senhas (id, usuario, senha, nivel, ativo, ong_id, cargo) FROM stdin;
1	Allan	@Piroca16	0	t	1	programador
\.


--
-- Data for Name: usuarios_acesso; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.usuarios_acesso (id, id_funcionario, tipo_usuario, login, senha, criado_em) FROM stdin;
1	1	professor	allan.prof	senha123	2025-10-01 10:38:10.943737
\.


--
-- Name: alunos_atividades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.alunos_atividades_id_seq', 12, true);


--
-- Name: alunos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.alunos_id_seq', 14, true);


--
-- Name: anamnese_aluno_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.anamnese_aluno_id_seq', 1, false);


--
-- Name: atividades_dias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.atividades_dias_id_seq', 6, true);


--
-- Name: atividades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.atividades_id_seq', 22, true);


--
-- Name: atividades_unificadas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.atividades_unificadas_id_seq', 4, true);


--
-- Name: categorias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.categorias_id_seq', 11, true);


--
-- Name: cursos_dias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.cursos_dias_id_seq', 11, true);


--
-- Name: cursos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.cursos_id_seq', 3, true);


--
-- Name: dias_semana_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.dias_semana_id_seq', 7, true);


--
-- Name: funcionarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.funcionarios_id_seq', 7, true);


--
-- Name: inscricoes_cursos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inscricoes_cursos_id_seq', 1, false);


--
-- Name: inscricoes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.inscricoes_id_seq', 1, false);


--
-- Name: inscricoes_oficinas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.inscricoes_oficinas_id_seq', 1, false);


--
-- Name: notificacoes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.notificacoes_id_seq', 1, false);


--
-- Name: oficinas_dias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.oficinas_dias_id_seq', 18, true);


--
-- Name: oficinas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.oficinas_id_seq', 9, true);


--
-- Name: ongs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.ongs_id_seq', 2, true);


--
-- Name: participacao_cursos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.participacao_cursos_id_seq', 9, true);


--
-- Name: participacao_oficinas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.participacao_oficinas_id_seq', 10, true);


--
-- Name: presencas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.presencas_id_seq', 1, false);


--
-- Name: relacionamentos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.relacionamentos_id_seq', 1, false);


--
-- Name: senhas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: allanvieira
--

SELECT pg_catalog.setval('public.senhas_id_seq', 7, true);


--
-- Name: usuarios_acesso_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.usuarios_acesso_id_seq', 1, true);


--
-- Name: alunos_atividades alunos_atividades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alunos_atividades
    ADD CONSTRAINT alunos_atividades_pkey PRIMARY KEY (id);


--
-- Name: alunos alunos_cpf_key; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.alunos
    ADD CONSTRAINT alunos_cpf_key UNIQUE (cpf);


--
-- Name: alunos alunos_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.alunos
    ADD CONSTRAINT alunos_pkey PRIMARY KEY (id);


--
-- Name: anamnese_aluno anamnese_aluno_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.anamnese_aluno
    ADD CONSTRAINT anamnese_aluno_pkey PRIMARY KEY (id);


--
-- Name: atividades_dias atividades_dias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades_dias
    ADD CONSTRAINT atividades_dias_pkey PRIMARY KEY (id);


--
-- Name: atividades atividades_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades
    ADD CONSTRAINT atividades_pkey PRIMARY KEY (id);


--
-- Name: atividades_unificadas atividades_unificadas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades_unificadas
    ADD CONSTRAINT atividades_unificadas_pkey PRIMARY KEY (id);


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- Name: cursos_dias cursos_dias_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.cursos_dias
    ADD CONSTRAINT cursos_dias_pkey PRIMARY KEY (id);


--
-- Name: cursos cursos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cursos
    ADD CONSTRAINT cursos_pkey PRIMARY KEY (id);


--
-- Name: dias_semana dias_semana_nome_key; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.dias_semana
    ADD CONSTRAINT dias_semana_nome_key UNIQUE (nome);


--
-- Name: dias_semana dias_semana_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.dias_semana
    ADD CONSTRAINT dias_semana_pkey PRIMARY KEY (id);


--
-- Name: funcionarios funcionarios_cpf_key; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.funcionarios
    ADD CONSTRAINT funcionarios_cpf_key UNIQUE (cpf);


--
-- Name: funcionarios funcionarios_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.funcionarios
    ADD CONSTRAINT funcionarios_pkey PRIMARY KEY (id);


--
-- Name: inscricoes_cursos inscricoes_cursos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscricoes_cursos
    ADD CONSTRAINT inscricoes_cursos_pkey PRIMARY KEY (id);


--
-- Name: inscricoes_oficinas inscricoes_oficinas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscricoes_oficinas
    ADD CONSTRAINT inscricoes_oficinas_pkey PRIMARY KEY (id);


--
-- Name: inscricoes inscricoes_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.inscricoes
    ADD CONSTRAINT inscricoes_pkey PRIMARY KEY (id);


--
-- Name: notificacoes notificacoes_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.notificacoes
    ADD CONSTRAINT notificacoes_pkey PRIMARY KEY (id);


--
-- Name: oficinas_dias oficinas_dias_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas_dias
    ADD CONSTRAINT oficinas_dias_pkey PRIMARY KEY (id);


--
-- Name: oficinas oficinas_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas
    ADD CONSTRAINT oficinas_pkey PRIMARY KEY (id);


--
-- Name: ongs ongs_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.ongs
    ADD CONSTRAINT ongs_pkey PRIMARY KEY (id);


--
-- Name: participacao_cursos participacao_cursos_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participacao_cursos
    ADD CONSTRAINT participacao_cursos_pkey PRIMARY KEY (id);


--
-- Name: participacao_oficinas participacao_oficinas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participacao_oficinas
    ADD CONSTRAINT participacao_oficinas_pkey PRIMARY KEY (id);


--
-- Name: presencas presencas_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.presencas
    ADD CONSTRAINT presencas_pkey PRIMARY KEY (id);


--
-- Name: relacionamentos relacionamentos_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.relacionamentos
    ADD CONSTRAINT relacionamentos_pkey PRIMARY KEY (id);


--
-- Name: senhas senhas_pkey; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.senhas
    ADD CONSTRAINT senhas_pkey PRIMARY KEY (id);


--
-- Name: senhas senhas_usuario_key; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.senhas
    ADD CONSTRAINT senhas_usuario_key UNIQUE (usuario);


--
-- Name: atividades unique_nome_atividade; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades
    ADD CONSTRAINT unique_nome_atividade UNIQUE (nome);


--
-- Name: categorias unique_nome_categoria; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT unique_nome_categoria UNIQUE (nome);


--
-- Name: oficinas unique_nome_oficina; Type: CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas
    ADD CONSTRAINT unique_nome_oficina UNIQUE (nome);


--
-- Name: usuarios_acesso usuarios_acesso_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios_acesso
    ADD CONSTRAINT usuarios_acesso_login_key UNIQUE (login);


--
-- Name: usuarios_acesso usuarios_acesso_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios_acesso
    ADD CONSTRAINT usuarios_acesso_pkey PRIMARY KEY (id);


--
-- Name: alunos trigger_bloquear_aluno; Type: TRIGGER; Schema: public; Owner: allanvieira
--

CREATE TRIGGER trigger_bloquear_aluno BEFORE DELETE OR UPDATE ON public.alunos FOR EACH ROW EXECUTE FUNCTION public.bloquear_alunos_sensiveis();


--
-- Name: alunos trigger_calcular_idade; Type: TRIGGER; Schema: public; Owner: allanvieira
--

CREATE TRIGGER trigger_calcular_idade BEFORE INSERT OR UPDATE ON public.alunos FOR EACH ROW EXECUTE FUNCTION public.atualizar_idade();


--
-- Name: presencas trigger_chegada_aula; Type: TRIGGER; Schema: public; Owner: allanvieira
--

CREATE TRIGGER trigger_chegada_aula BEFORE INSERT ON public.presencas FOR EACH ROW EXECUTE FUNCTION public.registrar_chegada();


--
-- Name: oficinas trigger_horario_oficina; Type: TRIGGER; Schema: public; Owner: allanvieira
--

CREATE TRIGGER trigger_horario_oficina AFTER UPDATE OF horario ON public.oficinas FOR EACH ROW EXECUTE FUNCTION public.aviso_horario_oficina();


--
-- Name: alunos_atividades alunos_atividades_id_aluno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alunos_atividades
    ADD CONSTRAINT alunos_atividades_id_aluno_fkey FOREIGN KEY (id_aluno) REFERENCES public.alunos(id) ON DELETE CASCADE;


--
-- Name: alunos_atividades alunos_atividades_id_atividade_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alunos_atividades
    ADD CONSTRAINT alunos_atividades_id_atividade_fkey FOREIGN KEY (id_atividade) REFERENCES public.atividades_unificadas(id) ON DELETE CASCADE;


--
-- Name: alunos alunos_id_ong_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.alunos
    ADD CONSTRAINT alunos_id_ong_fkey FOREIGN KEY (id_ong) REFERENCES public.ongs(id);


--
-- Name: anamnese_aluno anamnese_aluno_id_aluno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.anamnese_aluno
    ADD CONSTRAINT anamnese_aluno_id_aluno_fkey FOREIGN KEY (id_aluno) REFERENCES public.alunos(id);


--
-- Name: atividades_dias atividades_dias_id_atividade_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades_dias
    ADD CONSTRAINT atividades_dias_id_atividade_fkey FOREIGN KEY (id_atividade) REFERENCES public.atividades_unificadas(id);


--
-- Name: atividades_dias atividades_dias_id_dia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades_dias
    ADD CONSTRAINT atividades_dias_id_dia_fkey FOREIGN KEY (id_dia) REFERENCES public.dias_semana(id);


--
-- Name: atividades atividades_id_categoria_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.atividades
    ADD CONSTRAINT atividades_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categorias(id);


--
-- Name: cursos_dias cursos_dias_id_curso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.cursos_dias
    ADD CONSTRAINT cursos_dias_id_curso_fkey FOREIGN KEY (id_curso) REFERENCES public.cursos(id);


--
-- Name: cursos_dias cursos_dias_id_dia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.cursos_dias
    ADD CONSTRAINT cursos_dias_id_dia_fkey FOREIGN KEY (id_dia) REFERENCES public.dias_semana(id);


--
-- Name: cursos cursos_id_atividade_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cursos
    ADD CONSTRAINT cursos_id_atividade_fkey FOREIGN KEY (id_atividade) REFERENCES public.atividades(id);


--
-- Name: cursos cursos_id_instrutor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cursos
    ADD CONSTRAINT cursos_id_instrutor_fkey FOREIGN KEY (id_instrutor) REFERENCES public.funcionarios(id);


--
-- Name: alunos fk_ongs; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.alunos
    ADD CONSTRAINT fk_ongs FOREIGN KEY (ong_id) REFERENCES public.ongs(id);


--
-- Name: funcionarios funcionarios_ong_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.funcionarios
    ADD CONSTRAINT funcionarios_ong_id_fkey FOREIGN KEY (ong_id) REFERENCES public.ongs(id);


--
-- Name: inscricoes_cursos inscricoes_cursos_id_aluno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscricoes_cursos
    ADD CONSTRAINT inscricoes_cursos_id_aluno_fkey FOREIGN KEY (id_aluno) REFERENCES public.alunos(id);


--
-- Name: inscricoes_cursos inscricoes_cursos_id_curso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscricoes_cursos
    ADD CONSTRAINT inscricoes_cursos_id_curso_fkey FOREIGN KEY (id_curso) REFERENCES public.cursos(id);


--
-- Name: inscricoes inscricoes_id_aluno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.inscricoes
    ADD CONSTRAINT inscricoes_id_aluno_fkey FOREIGN KEY (id_aluno) REFERENCES public.alunos(id);


--
-- Name: inscricoes inscricoes_id_oficina_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.inscricoes
    ADD CONSTRAINT inscricoes_id_oficina_fkey FOREIGN KEY (id_oficina) REFERENCES public.oficinas(id);


--
-- Name: inscricoes_oficinas inscricoes_oficinas_id_aluno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscricoes_oficinas
    ADD CONSTRAINT inscricoes_oficinas_id_aluno_fkey FOREIGN KEY (id_aluno) REFERENCES public.alunos(id);


--
-- Name: inscricoes_oficinas inscricoes_oficinas_id_oficina_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inscricoes_oficinas
    ADD CONSTRAINT inscricoes_oficinas_id_oficina_fkey FOREIGN KEY (id_oficina) REFERENCES public.oficinas(id);


--
-- Name: notificacoes notificacoes_id_oficina_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.notificacoes
    ADD CONSTRAINT notificacoes_id_oficina_fkey FOREIGN KEY (id_oficina) REFERENCES public.oficinas(id);


--
-- Name: oficinas_dias oficinas_dias_id_dia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas_dias
    ADD CONSTRAINT oficinas_dias_id_dia_fkey FOREIGN KEY (id_dia) REFERENCES public.dias_semana(id);


--
-- Name: oficinas_dias oficinas_dias_id_oficina_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas_dias
    ADD CONSTRAINT oficinas_dias_id_oficina_fkey FOREIGN KEY (id_oficina) REFERENCES public.oficinas(id);


--
-- Name: oficinas oficinas_id_atividade_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas
    ADD CONSTRAINT oficinas_id_atividade_fkey FOREIGN KEY (id_atividade) REFERENCES public.atividades(id);


--
-- Name: oficinas oficinas_id_instrutor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.oficinas
    ADD CONSTRAINT oficinas_id_instrutor_fkey FOREIGN KEY (id_instrutor) REFERENCES public.funcionarios(id);


--
-- Name: participacao_cursos participacao_cursos_id_aluno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participacao_cursos
    ADD CONSTRAINT participacao_cursos_id_aluno_fkey FOREIGN KEY (id_aluno) REFERENCES public.alunos(id);


--
-- Name: participacao_cursos participacao_cursos_id_curso_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participacao_cursos
    ADD CONSTRAINT participacao_cursos_id_curso_fkey FOREIGN KEY (id_curso) REFERENCES public.cursos(id);


--
-- Name: participacao_oficinas participacao_oficinas_id_aluno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participacao_oficinas
    ADD CONSTRAINT participacao_oficinas_id_aluno_fkey FOREIGN KEY (id_aluno) REFERENCES public.alunos(id);


--
-- Name: participacao_oficinas participacao_oficinas_id_oficina_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.participacao_oficinas
    ADD CONSTRAINT participacao_oficinas_id_oficina_fkey FOREIGN KEY (id_oficina) REFERENCES public.oficinas(id);


--
-- Name: presencas presencas_id_inscricao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.presencas
    ADD CONSTRAINT presencas_id_inscricao_fkey FOREIGN KEY (id_inscricao) REFERENCES public.inscricoes(id);


--
-- Name: relacionamentos relacionamentos_id_aluno_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.relacionamentos
    ADD CONSTRAINT relacionamentos_id_aluno_fkey FOREIGN KEY (id_aluno) REFERENCES public.alunos(id);


--
-- Name: relacionamentos relacionamentos_id_funcionario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.relacionamentos
    ADD CONSTRAINT relacionamentos_id_funcionario_fkey FOREIGN KEY (id_funcionario) REFERENCES public.funcionarios(id);


--
-- Name: senhas senhas_ong_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: allanvieira
--

ALTER TABLE ONLY public.senhas
    ADD CONSTRAINT senhas_ong_id_fkey FOREIGN KEY (ong_id) REFERENCES public.ongs(id);


--
-- Name: usuarios_acesso usuarios_acesso_id_funcionario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuarios_acesso
    ADD CONSTRAINT usuarios_acesso_id_funcionario_fkey FOREIGN KEY (id_funcionario) REFERENCES public.funcionarios(id);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: renoduarte
--

GRANT USAGE ON SCHEMA public TO allanvieira;


--
-- Name: TABLE alunos_atividades; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.alunos_atividades TO allanvieira;


--
-- Name: SEQUENCE alunos_atividades_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.alunos_atividades_id_seq TO allanvieira;


--
-- Name: TABLE atividades; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.atividades TO allanvieira;


--
-- Name: TABLE atividades_dias; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.atividades_dias TO allanvieira;


--
-- Name: SEQUENCE atividades_dias_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.atividades_dias_id_seq TO allanvieira;


--
-- Name: SEQUENCE atividades_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.atividades_id_seq TO allanvieira;


--
-- Name: TABLE atividades_unificadas; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.atividades_unificadas TO allanvieira;


--
-- Name: SEQUENCE atividades_unificadas_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.atividades_unificadas_id_seq TO allanvieira;


--
-- Name: TABLE categorias; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.categorias TO allanvieira;


--
-- Name: SEQUENCE categorias_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.categorias_id_seq TO allanvieira;


--
-- Name: TABLE cursos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.cursos TO allanvieira;


--
-- Name: SEQUENCE cursos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.cursos_id_seq TO allanvieira;


--
-- Name: TABLE inscricoes_cursos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.inscricoes_cursos TO allanvieira;


--
-- Name: SEQUENCE inscricoes_cursos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.inscricoes_cursos_id_seq TO allanvieira;


--
-- Name: TABLE inscricoes_oficinas; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.inscricoes_oficinas TO allanvieira;


--
-- Name: SEQUENCE inscricoes_oficinas_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.inscricoes_oficinas_id_seq TO allanvieira;


--
-- Name: TABLE participacao_cursos; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.participacao_cursos TO allanvieira;


--
-- Name: SEQUENCE participacao_cursos_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.participacao_cursos_id_seq TO allanvieira;


--
-- Name: TABLE participacao_oficinas; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.participacao_oficinas TO allanvieira;


--
-- Name: SEQUENCE participacao_oficinas_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.participacao_oficinas_id_seq TO allanvieira;


--
-- Name: TABLE usuarios_acesso; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON TABLE public.usuarios_acesso TO allanvieira;


--
-- Name: SEQUENCE usuarios_acesso_id_seq; Type: ACL; Schema: public; Owner: postgres
--

GRANT ALL ON SEQUENCE public.usuarios_acesso_id_seq TO allanvieira;


--
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON SEQUENCES  TO allanvieira;


--
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES  TO allanvieira;


--
-- PostgreSQL database dump complete
--

\unrestrict o2dXw7mn7wjerrHGNPcf9acouyghhfBFWKFghdYxHrJBuqktFxVTnB4UGLPPXPy

