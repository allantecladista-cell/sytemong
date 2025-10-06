from flask import Flask, render_template, request, redirect, url_for, flash, session
import psycopg2
from psycopg2 import extras
from psycopg2 import errors
from functools import wraps
from werkzeug.security import generate_password_hash, check_password_hash
from config import Config
from datetime import datetime
from datetime import date
import calendar



def calcular_idade(data_nascimento):
    hoje = date.today()
    idade = hoje.year - data_nascimento.year - ((hoje.month, hoje.day) < (data_nascimento.month, data_nascimento.day))
    return idade

app = Flask(__name__)
app.config.from_object(Config)
app.secret_key = "@piroca16"  # chave para sessões

# -------------------- SIMULAÇÃO DE ID DA ONG --------------------
LOGGED_IN_ONG_ID = 1

# -------------------- FUNÇÃO DE CONEXÃO --------------------
def get_db_connection():
    return psycopg2.connect(
        host=Config.DB_HOST,
        database=Config.DB_NAME,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        port=Config.DB_PORT
    )

# -------------------- DECORADOR DE HIERARQUIA --------------------
def acesso_permitido(cargos_permitidos):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if 'user_id' not in session:
                flash('Faça login para acessar.', 'error')
                return redirect(url_for('login'))
            if session.get('cargo') not in cargos_permitidos:
                flash('Acesso negado.', 'error')
                return redirect(url_for('dashboard'))
            return f(*args, **kwargs)
        return decorated_function
    return decorator

# -------------------- LOGIN --------------------
@app.route('/', methods=['GET', 'POST'])
@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        usuario = request.form.get('usuario')
        senha = request.form.get('senha')

        if not usuario or not senha:
            flash("Preencha todos os campos", "danger")
            return redirect(url_for('login'))

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, senha, nivel, cargo, ativo FROM senhas WHERE usuario=%s AND ativo=TRUE",
                    (usuario,)
                )
                user = cur.fetchone()

        # Comparação direta da senha (sem hash)
        if user and user[1] == senha:
            session['user_id'] = user[0]
            session['user'] = usuario
            session['nivel'] = user[2]
            session['cargo'] = user[3]
            flash(f"Bem-vindo, {usuario}!", "success")
            return redirect(url_for('dashboard'))
        else:
            flash("Usuário ou senha incorretos", "danger")
            return redirect(url_for('login'))

    return render_template('index.html')


# -------------------- DASHBOARD --------------------
@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        flash("Faça login primeiro", "warning")
        return redirect(url_for('login'))
    return render_template('dashboard.html', usuario=session.get('user'))

# -------------------- CADASTRO DE ALUNO --------------------
@app.route('/aluno/novo', methods=['GET', 'POST'])
@acesso_permitido(['programador', 'admin', 'secretaria'])
def cadastrar_aluno():
    if request.method == 'POST':
        # Lista completa de campos do formulário
        campos = [
            # Dados pessoais
            'nome', 'nome_social', 'genero', 'data_nascimento', 'cpf', 'rg',
            'pai', 'mae', 'telefone', 'celular', 'email', 'endereco', 'numero', 'bairro', 'cep',
            # Escolaridade / Profissão
            'escolaridade', 'obs_estuda', 'escola', 'estuda', 'trabalha', 'profissao',
            # Saúde
            'necessidade_especial', 'necessidade_detalhe', 'alergia', 'alergia_detalhe',
            # Responsável
            'nome_responsavel', 'tipo_responsavel', 'cpf_responsavel', 'rg_responsavel',
            'telefone_responsavel', 'email_responsavel', 'parentesco', 'turno',
            # Termo
            'termo'
        ]

        # Cria dicionário com os dados do formulário
        dados = {campo: request.form.get(campo) for campo in campos}

        # Insere no banco de dados
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                placeholders = ', '.join(['%s'] * len(campos))  # gera os %s dinamicamente
                colunas = ', '.join(campos)                     # nomes das colunas
                cur.execute(f"""
                    INSERT INTO alunos ({colunas}, ativo, ong_id)
                    VALUES ({placeholders}, TRUE, %s)
                """, (*dados.values(), LOGGED_IN_ONG_ID))
                conn.commit()

        flash("Aluno cadastrado com sucesso!", "success")
        return redirect(url_for('dashboard'))

    return render_template('cadastro_aluno.html')


# -------------------- CADASTRO DE FUNCIONÁRIO --------------------
@app.route('/funcionario/novo', methods=['GET', 'POST'])
@acesso_permitido(['programador', 'admin'])
def cadastrar_funcionario():
    if request.method == 'POST':
        nome = request.form.get('nome')
        cpf = request.form.get('cpf')
        cargo = request.form.get('cargo')
        contato_nome = request.form.get('contato_nome')
        contato_telefone = request.form.get('contato_telefone')

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO funcionarios
                    (nome, cpf, cargo, ativo, ong_id, contato_emergencia_nome, contato_emergencia_telefone)
                    VALUES (%s, %s, %s, TRUE, %s, %s, %s)
                """, (nome, cpf, cargo, LOGGED_IN_ONG_ID, contato_nome, contato_telefone))
                conn.commit()
        flash("Funcionário cadastrado com sucesso!", "success")
        return redirect(url_for('dashboard'))

    return render_template('cadastro_funcionario.html')

# -------------------- PESQUISAR ALUNO --------------------
@app.route('/alunos/buscar', methods=['GET'])
@acesso_permitido(['programador', 'admin', 'secretaria'])
def pesquisar_aluno():
    return render_template('pesquisar_aluno.html')

@app.route('/alunos/pesquisar', methods=['GET', 'POST'])
@acesso_permitido(['programador', 'admin', 'secretaria'])
def buscar_aluno():
    termo = request.form.get('termo', '').strip() if request.method == 'POST' else request.args.get('termo', '').strip()
    alunos = []
    if termo:
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, nome, cpf, ativo
                    FROM alunos
                    WHERE (nome ILIKE %s OR cpf ILIKE %s)
                      AND ong_id = %s
                """, (f'%{termo}%', f'%{termo}%', LOGGED_IN_ONG_ID))
                alunos = cur.fetchall()
    return render_template('buscar_aluno.html', alunos=alunos, termo=termo)

# -------------------- PESQUISAR FUNCIONÁRIO --------------------
@app.route('/funcionarios/buscar', methods=['GET'])
@acesso_permitido(['programador', 'admin'])
def pesquisar_funcionario():
    return render_template('pesquisar_funcionario.html')
# -------------------- BUSCAR FUNCIONÁRIO --------------------

@app.route('/funcionarios/pesquisar', methods=['GET', 'POST'])
@acesso_permitido(['programador', 'admin'])
def buscar_funcionario():
    termo = request.form.get('termo', '').strip() if request.method == 'POST' else ''
    funcionarios = []

    contato_nome = ''
    contato_telefone = ''

    if termo:
        with get_db_connection() as conn:
            with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
                cur.execute("""
                    SELECT *
                    FROM funcionarios
                    WHERE (nome ILIKE %s OR cpf ILIKE %s)
                      AND ong_id = %s
                """, (f'%{termo}%', f'%{termo}%', LOGGED_IN_ONG_ID))
                funcionarios = cur.fetchall()

                # Se encontrou algum funcionário, pega o primeiro para preencher as textboxes
                if funcionarios:
                    contato_nome = funcionarios[0]['contato_emergencia_nome']
                    contato_telefone = funcionarios[0]['contato_emergencia_telefone']

    return render_template(
        'buscar_funcionario.html',
        funcionarios=funcionarios,
        termo=termo,
        contato_nome=contato_nome,
        contato_telefone=contato_telefone
    )

# -------------------- EDIÇÃO DE ALUNO --------------------
@app.route('/aluno/editar/<int:aluno_id>', methods=['GET', 'POST'])
@acesso_permitido(['programador', 'admin', 'secretaria'])
def editar_aluno(aluno_id):
    campos = [
        # Dados pessoais
        'nome', 'nome_social', 'genero', 'data_nascimento', 'cpf', 'rg',
        'pai', 'mae', 'telefone', 'celular', 'email', 'endereco', 'numero', 'bairro', 'cep',
        'sexo', 'estado_civil',
        # Escolaridade / Profissão
        'escolaridade', 'obs_estuda', 'escola', 'estuda', 'trabalha', 'profissao',
        # Saúde
        'necessidade_especial', 'necessidade_detalhe', 'alergia', 'alergia_detalhe',
        # Responsável
        'nome_responsavel', 'tipo_responsavel', 'cpf_responsavel', 'rg_responsavel',
        'telefone_responsavel', 'email_responsavel', 'parentesco', 'turno',
        # Termo
        'termo'
    ]

    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(f"""
                SELECT {', '.join(campos)}
                FROM alunos
                WHERE id = %s AND ong_id = %s
            """, (aluno_id, LOGGED_IN_ONG_ID))
            aluno_data = cur.fetchone()

    if not aluno_data:
        flash("Aluno não encontrado.", "warning")
        return redirect(url_for('cadastrar_aluno'))

    aluno = {k: aluno_data[i] for i, k in enumerate(campos)}

    if request.method == 'POST':
        # Pega os valores atualizados do formulário
        valores = [request.form.get(campo) for campo in campos]

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(f"""
                    UPDATE alunos SET {', '.join([f'{c}=%s' for c in campos])}
                    WHERE id=%s AND ong_id=%s
                """, (*valores, aluno_id, LOGGED_IN_ONG_ID))
                conn.commit()

        flash("Aluno atualizado com sucesso!", "success")
        return redirect(url_for('cadastrar_aluno'))

    return render_template('editar_aluno.html', aluno=aluno, aluno_id=aluno_id)

@app.template_filter('datetimeformat')
def datetimeformat(value):
    try:
        dt = datetime.strptime(value, '%Y-%m-%d')
        return dt.strftime('%d/%m/%Y')
    except:
        return value

# -------------------- EDIÇÃO DE FUNCIONÁRIO --------------------
@app.route('/funcionario/editar/<int:funcionario_id>', methods=['GET', 'POST'])
@acesso_permitido(['programador', 'admin'])
def editar_funcionario(funcionario_id):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            cur.execute("SELECT * FROM funcionarios WHERE id=%s AND ong_id=%s", (funcionario_id, LOGGED_IN_ONG_ID))
            funcionario = cur.fetchone()

    if not funcionario:
        flash('Funcionário não encontrado.', 'error')
        return redirect(url_for('buscar_funcionario'))

    campos = ['nome', 'data_nascimento', 'estado_civil', 'pai', 'mae',
              'endereco', 'telefone', 'email', 'cpf', 'rg', 'ctps',
              'titulo_eleitor', 'pis', 'cnh', 'reservista', 'cargo',
              'data_admissao', 'salario', 'contato_emergencia_nome', 'contato_emergencia_telefone']

    if request.method == 'POST':
        # Pega do form ou mantém o valor antigo se não existir
        valores = [request.form.get(campo) or funcionario.get(campo) for campo in campos]

        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(f"""
                    UPDATE funcionarios SET {', '.join([f'{c}=%s' for c in campos])}
                    WHERE id=%s AND ong_id=%s
                """, (*valores, funcionario_id, LOGGED_IN_ONG_ID))
                conn.commit()

        flash('Funcionário atualizado com sucesso!', 'success')
        return redirect(url_for('buscar_funcionario'))

    return render_template('editar_funcionario.html', funcionario=funcionario, funcionario_id=funcionario_id)

# -------------------- INATIVAR FUNCIONÁRIO --------------------
@app.route('/funcionario/inativar/<int:funcionario_id>', methods=['POST'])
@acesso_permitido(['programador', 'admin'])
def inativar_funcionario(funcionario_id):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE funcionarios
                SET ativo = FALSE
                WHERE id = %s AND ong_id = %s
            """, (funcionario_id, LOGGED_IN_ONG_ID))
            conn.commit()
    flash("Funcionário inativado com sucesso!", "info")
    return redirect(url_for('buscar_funcionario'))

# -------------------- IMPRIMIR FICHA DO ALUNO --------------------

@app.route('/alunos/imprimir/<int:aluno_id>')
@acesso_permitido(['programador', 'admin', 'secretaria'])
def imprimir_aluno(aluno_id):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, nome, cpf, ativo, data_nascimento, email, telefone
                FROM alunos
                WHERE id = %s AND ong_id = %s
            """, (aluno_id, LOGGED_IN_ONG_ID))
            aluno = cur.fetchone()

    if aluno:
        aluno_dict = {
            'id': aluno[0],
            'nome': aluno[1],
            'cpf': aluno[2],
            'ativo': aluno[3],
            'data_nascimento': aluno[4],
            'email': aluno[5],
            'telefone': aluno[6]
        }
        return render_template('relatorio_aluno.html', aluno=aluno_dict)
    else:
        flash("Aluno não encontrado.", "error")
        return redirect(url_for('pesquisar_aluno'))

# -----------------------------



# -------------------- FICHA DE CADASTRO --------------------
@app.route('/alunos/ficha/<int:aluno_id>')
@acesso_permitido(['programador', 'admin', 'secretaria'])
def ficha_de_cadastro(aluno_id):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, nome, cpf, ativo, data_nascimento, email, telefone,
                       celular, genero, pai, mae, rg, estado_civil, endereco,
                       escolaridade, escola, turno, estuda, obs_estuda,
                       trabalha, profissao, necessidade_especial, alergia,
                       nome_responsavel, tipo_responsavel, cpf_responsavel, rg_responsavel,
                       numero
                FROM alunos
                WHERE id = %s AND ong_id = %s
            """, (aluno_id, LOGGED_IN_ONG_ID))
            aluno = cur.fetchone()

    if aluno:
        campos = ['id','nome','cpf','ativo','data_nascimento','email','telefone','celular',
                  'genero','pai','mae','rg','estado_civil','endereco','escolaridade','escola','turno',
                  'estuda','obs_estuda','trabalha','profissao','necessidade_especial','alergia',
                  'nome_responsavel','tipo_responsavel','cpf_responsavel','rg_responsavel','numero']

        # transforma a tupla em dict, substituindo None por string vazia
        aluno_dict = {k: aluno[i] if aluno[i] is not None else '' for i, k in enumerate(campos)}

        # calcula idade
        if aluno_dict['data_nascimento']:
            hoje = date.today()
            nascimento = aluno_dict['data_nascimento']
            idade = hoje.year - nascimento.year - ((hoje.month, hoje.day) < (nascimento.month, nascimento.day))
            aluno_dict['idade'] = idade
        else:
            aluno_dict['idade'] = ''

        return render_template('ficha_de_cadastro.html', aluno=aluno_dict)
    else:
        flash("Aluno não encontrado.", "error")
        return redirect(url_for('pesquisar_aluno'))


# -------------------- CADASTRO DE CATEGORIA --------------------
@app.route('/cadastrar_categoria', methods=['GET', 'POST'])
def cadastrar_categoria():
    if request.method == 'POST':
        nome = request.form.get('nome')
        try:
            with get_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("INSERT INTO categorias (nome) VALUES (%s)", (nome,))
                    conn.commit()
            flash("Categoria cadastrada com sucesso!", "success")
        except errors.UniqueViolation:
            flash("Essa categoria já existe!", "warning")
        return redirect(url_for('cadastrar_categoria'))
    return render_template('cadastrar_categoria.html')

# -------------------- CADASTRO DE OFICINA --------------------
@app.route('/cadastrar_oficina', methods=['GET', 'POST'])
def cadastrar_oficina():
    conn = get_db_connection()
    cur = conn.cursor()

    # Buscar instrutores ativos
    cur.execute("SELECT id, nome FROM funcionarios WHERE ativo = TRUE ORDER BY nome")
    instrutores = cur.fetchall()

    # Buscar atividades já cadastradas como Oficina
    cur.execute("""
        SELECT id, nome_display 
        FROM atividades 
        WHERE tipo = 'oficina' AND ativo = TRUE 
          AND nome_display IS NOT NULL AND nome_display <> ''
        ORDER BY nome_display
    """)
    atividades = cur.fetchall()

    # Buscar dias da semana para checkboxes
    cur.execute("SELECT id, nome FROM dias_semana ORDER BY id")
    dias = cur.fetchall()

    if request.method == 'POST':
        nome = request.form['nome']
        id_instrutor = request.form['id_instrutor']
        faixa_min = request.form.get('faixa_etaria_min')
        faixa_max = request.form.get('faixa_etaria_max')
        horario = request.form.get('horario')
        descricao = request.form.get('descricao')
        limite = request.form.get('limite_alunos')
        dias_selecionados = request.form.getlist('dias')  # lista de IDs de dias_semana

        # Inserir oficina na tabela unificada
        cur.execute("""
            INSERT INTO atividades_unificadas 
            (nome, tipo, id_instrutor, faixa_etaria_min, faixa_etaria_max, descricao, limite_alunos, horario)
            VALUES (%s, 'Oficina', %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (nome, id_instrutor, faixa_min, faixa_max, descricao, limite, horario))
        atividade_id = cur.fetchone()[0]

        # Inserir dias selecionados
        for d in dias_selecionados:
            cur.execute("""
                INSERT INTO atividades_dias (id_atividade, id_dia)
                VALUES (%s, %s)
            """, (atividade_id, d))

        conn.commit()
        return redirect('/tabela_atividades')

    # GET: renderizar template com instrutores, atividades e dias
    return render_template('cadastrar_oficina.html', instrutores=instrutores, atividades=atividades, dias=dias)



# -------------------- CADASTRO DE ATIVIDADE --------------------
@app.route('/cadastrar_atividade', methods=['GET', 'POST'])
def cadastrar_atividade():
    # Pegar todas as categorias para popular o select
    categorias = []
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            cur.execute("SELECT id, nome FROM categorias ORDER BY nome")
            categorias = cur.fetchall()
            print(categorias)  # DEBUG: conferir se traz as categorias

    if request.method == 'POST':
        nome = request.form['nome'].strip()
        tipo = request.form['tipo'].strip()
        id_categoria = request.form['id_categoria']

        # Validação: campos obrigatórios
        if not nome or not tipo or not id_categoria:
            flash("Preencha todos os campos obrigatórios.", "warning")
            return render_template('cadastrar_atividade.html', categorias=categorias)

        # Bloquear duplicidade: mesmo nome e mesma categoria
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT COUNT(*) FROM atividades
                    WHERE nome = %s AND id_categoria = %s
                """, (nome, id_categoria))
                if cur.fetchone()[0] > 0:
                    flash("Já existe uma atividade com este nome nessa categoria.", "danger")
                    return render_template('cadastrar_atividade.html', categorias=categorias)

                # Inserir nova atividade
                cur.execute("""
                    INSERT INTO atividades (nome, tipo, id_categoria)
                    VALUES (%s, %s, %s)
                """, (nome, tipo, id_categoria))
                conn.commit()

        flash("Atividade cadastrada com sucesso!", "success")
        return redirect(url_for('cadastrar_atividade'))

    return render_template('cadastrar_atividade.html', categorias=categorias)

# --------------------------atividades_por_categoria----------- 

@app.route('/atividades_por_categoria/<int:cat_id>')
def atividades_por_categoria(cat_id):
    tipo = request.args.get('tipo', 'Oficina')
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=extras.RealDictCursor) as cur:
            cur.execute("""
                SELECT id, nome, dias_semana  -- supondo que sua tabela tenha a coluna dias_semana
                FROM atividades_unificadas
                WHERE id_categoria=%s AND tipo=%s AND ativo=TRUE
                ORDER BY nome
            """, (cat_id, tipo))
            atividades = cur.fetchall()

            # Se a coluna dias_semana não existir, podemos criar uma lista fixa ou buscar em outra tabela
            for a in atividades:
                if 'dias_semana' not in a:
                    a['dias_semana'] = ["Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"]

    return jsonify(atividades)

# ---------------- Toggle Atividade ----------------
@app.route('/atividade/<int:id_atividade>/toggle', methods=['POST'])
def toggle_atividade(id_atividade):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Alterna ativo
            cur.execute("""
                UPDATE atividades_unificadas
                SET ativo = NOT ativo
                WHERE id = %s
            """, (id_atividade,))
            conn.commit()
    flash('Status da atividade atualizado com sucesso!', 'success')
    return redirect(url_for('tabela_atividades'))

# ---------------- Deletar Atividade ----------------
@app.route('/atividade/<int:id_atividade>/deletar', methods=['POST'])
def deletar_atividade(id_atividade):
    senha = request.form.get('senha')
    if senha != '1234':
        flash('Senha incorreta! Atividade não deletada.', 'error')
        return redirect(url_for('tabela_atividades'))

    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM atividades_unificadas WHERE id = %s", (id_atividade,))
            conn.commit()
    flash('Atividade deletada com sucesso!', 'success')
    return redirect(url_for('tabela_atividades'))


# ----------------Desativar Atividades do Aluno --------------------

@app.route('/aluno/<int:aluno_id>/atividades/<int:id_atividade>/desativar', methods=['POST'])
def desativar_atividade_aluno(aluno_id, id_atividade):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            # Desativar somente se já estiver ativo
            cur.execute("""
                UPDATE alunos_atividades
                SET ativo = FALSE
                WHERE id_aluno = %s AND id_atividade = %s AND ativo = TRUE
            """, (aluno_id, id_atividade))
            if cur.rowcount > 0:
                flash('Atividade desativada com sucesso!', 'success')
            else:
                flash('Atividade já estava desativada ou não encontrada.', 'warning')
            conn.commit()
    return redirect(url_for('cadastrar_alunos_atividades', aluno_id=aluno_id))


# ------------------ CADASTRAR ATIVIDADES DO ALUNO ------------------
@app.route('/aluno/<int:aluno_id>/atividades', methods=['GET', 'POST'])
def cadastrar_alunos_atividades(aluno_id):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=extras.DictCursor) as cur:
            # ------------------ DADOS DO ALUNO ------------------
            cur.execute("SELECT * FROM alunos WHERE id=%s", (aluno_id,))
            aluno = cur.fetchone()
            if not aluno:
                return "Aluno não encontrado", 404
            
            # Calcular idade real
            nascimento = aluno['data_nascimento']
            hoje = date.today()
            idade = hoje.year - nascimento.year - ((hoje.month, hoje.day) < (nascimento.month, nascimento.day))
            aluno['idade'] = idade  # adiciona idade no dict do aluno

            # ------------------ CADASTRAR ATIVIDADE (POST) ------------------
            if request.method == 'POST':
                tipo_atividade = request.form.get('tipo_atividade')
                id_atividade = None
                if tipo_atividade == 'Oficina':
                    id_atividade = request.form.get('id_atividade')
                elif tipo_atividade == 'Curso':
                    id_atividade = request.form.get('id_curso')

                if id_atividade:
                    cur.execute("""
                        INSERT INTO alunos_atividades (id_aluno, id_atividade, tipo_atividade)
                        VALUES (%s, %s, %s)
                    """, (aluno_id, id_atividade, tipo_atividade))
                    conn.commit()
                    flash(f'{tipo_atividade} cadastrada com sucesso!', 'success')
                return redirect(url_for('cadastrar_alunos_atividades', aluno_id=aluno_id))

            # ------------------ ATIVIDADES DISPONÍVEIS ------------------
            cur.execute("""
                SELECT 
                    a.id,
                    a.nome,
                    a.tipo,
                    a.horario,
                    COALESCE(array_agg(ds.nome ORDER BY ds.id), ARRAY[]::text[]) AS dias_semana
                FROM atividades_unificadas a
                LEFT JOIN atividades_dias ad ON a.id = ad.id_atividade
                LEFT JOIN dias_semana ds ON ad.id_dia = ds.id
                WHERE a.ativo = true
                  AND ((a.faixa_etaria_min <= %s AND a.faixa_etaria_max >= %s)
                       OR a.tipo = 'Curso Livre')
                GROUP BY a.id, a.nome, a.tipo, a.horario
                ORDER BY a.tipo, a.nome
            """, (idade, idade))
            todas_atividades = cur.fetchall()

            # Separar por tipo
            todas_oficinas_filtradas = [a for a in todas_atividades if a['tipo'].lower() == 'oficina']
            todos_cursos_filtrados = [a for a in todas_atividades if a['tipo'].lower() == 'curso']

            # ------------------ ATIVIDADES JÁ CADASTRADAS ------------------
            cur.execute("""
            SELECT 
                a.id, 
                a.nome, 
                a.tipo, 
                a.horario,
                COALESCE(array_agg(ds.nome ORDER BY ds.id), ARRAY[]::text[]) AS dias_semana
            FROM alunos_atividades aa
            JOIN atividades_unificadas a ON aa.id_atividade = a.id
            LEFT JOIN atividades_dias ad ON a.id = ad.id_atividade
            LEFT JOIN dias_semana ds ON ad.id_dia = ds.id
            WHERE aa.id_aluno = %s AND aa.ativo = TRUE
            GROUP BY a.id, a.nome, a.tipo, a.horario
        """, (aluno_id,))
            atividades_cadastradas = cur.fetchall()

            aluno_oficinas = [a for a in atividades_cadastradas if a['tipo'].lower() == 'oficina']
            aluno_cursos = [a for a in atividades_cadastradas if a['tipo'].lower() == 'curso']

            # ------------------ RENDERIZAÇÃO ------------------
            return render_template(
                'cadastrar_alunos_atividades.html',
                aluno=aluno,
                todas_oficinas_filtradas=todas_oficinas_filtradas,
                todos_cursos_filtrados=todos_cursos_filtrados,
                aluno_oficinas=aluno_oficinas,
                aluno_cursos=aluno_cursos
            )


# -------------------- CADASTRO DE CURSO --------------------
@app.route('/cadastrar_curso', methods=['GET', 'POST'])
def cadastrar_curso():
    conn = get_db_connection()
    cur = conn.cursor()

    # Buscar instrutores ativos para o select
    cur.execute("SELECT id, nome FROM funcionarios WHERE ativo = TRUE ORDER BY nome")
    instrutores = cur.fetchall()

    # Buscar atividades já cadastradas como Curso
    cur.execute("""
        SELECT id, nome_display 
        FROM atividades 
        WHERE tipo = 'curso' AND ativo = TRUE 
          AND nome_display IS NOT NULL AND nome_display <> ''
        ORDER BY nome_display
    """)
    atividades = cur.fetchall()

    # Buscar dias da semana para os checkboxes
    cur.execute("SELECT id, nome FROM dias_semana ORDER BY id")
    dias = cur.fetchall()

    if request.method == 'POST':
        nome = request.form['nome']
        id_instrutor = request.form['id_instrutor']
        duracao = request.form.get('duracao')            # intervalo ou texto
        data_inicio = request.form.get('data_inicio')    # date
        data_fim = request.form.get('data_fim')          # date
        descricao = request.form.get('descricao')
        limite = request.form.get('limite_alunos')
        ativo = request.form.get('ativo') == 'on'        # checkbox
        horario = request.form.get('horario')
        dias_selecionados = request.form.getlist('dias')  # lista de IDs de dias_semana

        # Inserir na tabela unificada
        cur.execute("""
            INSERT INTO atividades_unificadas 
            (nome, tipo, id_instrutor, duracao, data_inicio, data_fim, descricao, limite_alunos, ativo, horario)
            VALUES (%s, 'Curso', %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (nome, id_instrutor, duracao, data_inicio, data_fim, descricao, limite, ativo, horario))
        atividade_id = cur.fetchone()[0]

        # Inserir dias na tabela de dias
        for d in dias_selecionados:
            cur.execute("""
                INSERT INTO atividades_dias (id_atividade, id_dia)
                VALUES (%s, %s)
            """, (atividade_id, d))

        conn.commit()
        cur.close()
        conn.close()

        return redirect('/tabela_atividades')

    cur.close()
    conn.close()
    return render_template('cadastrar_curso.html', instrutores=instrutores, atividades=atividades, dias=dias)

# -------------------- EDITAR ATIVIDADES (Categorias, Atividades, Cursos e Oficinas) --------------------

@app.route('/editar_atividades', methods=['GET', 'POST'])
def editar_atividades():
    conn = get_db_connection()
    cur = conn.cursor()

    # Carregar dados
    cur.execute("SELECT id, nome FROM categorias ORDER BY nome")
    categorias = cur.fetchall()

    cur.execute("SELECT id, nome_display, id_categoria FROM atividades ORDER BY nome_display")
    atividades = cur.fetchall()

    cur.execute("SELECT id, nome, id_atividade, id_instrutor, duracao, data_inicio, data_fim, horario, limite_alunos, descricao FROM atividades_unificadas WHERE tipo='Curso' ORDER BY nome")
    cursos = cur.fetchall()

    cur.execute("SELECT id, nome, id_atividade, id_instrutor, faixa_etaria_min, faixa_etaria_max, horario, limite_alunos, descricao FROM atividades_unificadas WHERE tipo='Oficina' ORDER BY nome")
    oficinas = cur.fetchall()

    cur.execute("SELECT id, nome FROM funcionarios WHERE ativo=TRUE ORDER BY nome")
    instrutores = cur.fetchall()

    cur.execute("SELECT id, nome FROM dias_semana ORDER BY id")
    dias = cur.fetchall()

    if request.method == 'POST':
        tipo = request.form['tipo']
        registro_id = request.form['registro_id']

        if tipo == 'categoria':
            nome = request.form['nome']
            cur.execute("UPDATE categorias SET nome=%s WHERE id=%s", (nome, registro_id))

        elif tipo == 'atividade':
            nome_display = request.form['nome_display']
            id_categoria = request.form['id_categoria']
            cur.execute("UPDATE atividades SET nome_display=%s, id_categoria=%s WHERE id=%s", (nome_display, id_categoria, registro_id))

        elif tipo == 'curso':
            nome = request.form['nome']
            id_atividade = request.form['id_atividade']
            id_instrutor = request.form['id_instrutor']
            duracao = request.form.get('duracao')
            data_inicio = request.form.get('data_inicio')
            data_fim = request.form.get('data_fim')
            horario = request.form.get('horario')
            limite = request.form.get('limite_alunos')
            descricao = request.form.get('descricao')
            dias_selecionados = request.form.getlist('dias')

            cur.execute("""
                UPDATE atividades_unificadas 
                SET nome=%s, id_atividade=%s, id_instrutor=%s, duracao=%s, data_inicio=%s, data_fim=%s,
                    horario=%s, limite_alunos=%s, descricao=%s
                WHERE id=%s
            """, (nome, id_atividade, id_instrutor, duracao, data_inicio, data_fim, horario, limite, descricao, registro_id))

            # Atualizar dias
            cur.execute("DELETE FROM atividades_dias WHERE id_atividade=%s", (registro_id,))
            for d in dias_selecionados:
                cur.execute("INSERT INTO atividades_dias (id_atividade, id_dia) VALUES (%s, %s)", (registro_id, d))

        elif tipo == 'oficina':
            nome = request.form['nome']
            id_atividade = request.form['id_atividade']
            id_instrutor = request.form['id_instrutor']
            faixa_min = request.form.get('faixa_etaria_min')
            faixa_max = request.form.get('faixa_etaria_max')
            horario = request.form.get('horario')
            limite = request.form.get('limite_alunos')
            descricao = request.form.get('descricao')
            dias_selecionados = request.form.getlist('dias')

            cur.execute("""
                UPDATE atividades_unificadas 
                SET nome=%s, id_atividade=%s, id_instrutor=%s, faixa_etaria_min=%s, faixa_etaria_max=%s,
                    horario=%s, limite_alunos=%s, descricao=%s
                WHERE id=%s
            """, (nome, id_atividade, id_instrutor, faixa_min, faixa_max, horario, limite, descricao, registro_id))

            cur.execute("DELETE FROM atividades_dias WHERE id_atividade=%s", (registro_id,))
            for d in dias_selecionados:
                cur.execute("INSERT INTO atividades_dias (id_atividade, id_dia) VALUES (%s, %s)", (registro_id, d))

        conn.commit()
        cur.close()
        conn.close()
        return redirect('/editar_atividades')

    cur.close()
    conn.close()
    return render_template('editar_atividades.html', categorias=categorias, atividades=atividades, cursos=cursos, oficinas=oficinas, instrutores=instrutores, dias=dias)



# -------------------- TABELA DE ATIVIDADES --------------------
@app.route('/tabela_atividades')
def tabela_atividades():
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=extras.DictCursor) as cur:
            # -------------------- Oficinas --------------------
            cur.execute("""
                SELECT 
                    a.id,
                    a.nome,
                    a.tipo,
                    a.horario,
                    f.nome as instrutor,
                    a.faixa_etaria_min,
                    a.faixa_etaria_max,
                    COALESCE(array_agg(ds.nome ORDER BY ds.id), ARRAY[]::text[]) AS dias_semana,
                    a.ativo
                FROM atividades_unificadas a
                LEFT JOIN funcionarios f ON a.id_instrutor = f.id
                LEFT JOIN atividades_dias ad ON a.id = ad.id_atividade
                LEFT JOIN dias_semana ds ON ad.id_dia = ds.id
                WHERE a.tipo='Oficina'
                GROUP BY a.id, a.nome, a.tipo, a.horario, f.nome, a.faixa_etaria_min, a.faixa_etaria_max, a.ativo
                ORDER BY a.nome
            """)
            oficinas = cur.fetchall()

            # -------------------- Cursos --------------------
            cur.execute("""
                SELECT 
                    a.id,
                    a.nome,
                    a.tipo,
                    a.horario,
                    f.nome as instrutor,
                    COALESCE(array_agg(ds.nome ORDER BY ds.id), ARRAY[]::text[]) AS dias_semana,
                    a.ativo
                FROM atividades_unificadas a
                LEFT JOIN funcionarios f ON a.id_instrutor = f.id
                LEFT JOIN atividades_dias ad ON a.id = ad.id_atividade
                LEFT JOIN dias_semana ds ON ad.id_dia = ds.id
                WHERE a.tipo='curso'
                GROUP BY a.id, a.nome, a.tipo, a.horario, f.nome, a.ativo
                ORDER BY a.nome
            """)
            cursos = cur.fetchall()

    return render_template('tabela_atividades.html', oficinas=oficinas, cursos=cursos)


# ------------------------toggle_aluno--------------------

@app.route('/toggle_aluno/<int:id_aluno>', methods=['POST'])
def toggle_aluno(id_aluno):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                UPDATE alunos
                SET ativo = NOT ativo
                WHERE id = %s
            """, (id_aluno,))
            conn.commit()
    flash('Status do aluno atualizado!', 'success')
    return redirect(request.referrer or url_for('pesquisar_aluno'))




# --------------------Deletar curso e oficina --------------------

@app.route('/deletar_atividade/<int:id_atividade>', methods=['POST'])
@acesso_permitido(['admin', 'coordenador', 'programador'])
def deletar_atividade_db(id_atividade):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM atividades_unificadas WHERE id = %s", (id_atividade,))
            conn.commit()
    flash('Atividade deletada com sucesso.', 'success')
    return redirect(url_for('tabela_atividades'))


# ----------------Ficha de Chamada --------------------

# ----------------Ficha de Chamada --------------------
@app.route('/ficha_chamada/<int:atividade_id>/<int:mes>')
def ficha_chamada(atividade_id, mes):
    with get_db_connection() as conn:
        with conn.cursor(cursor_factory=extras.DictCursor) as cur:
            # Buscar dados da atividade
            cur.execute("""
                SELECT id, nome, tipo, horario, id_instrutor
                FROM atividades_unificadas
                WHERE id = %s
            """, (atividade_id,))
            atividade = cur.fetchone()

            if not atividade:
                flash("Atividade não encontrada.", "error")
                return redirect(url_for('index'))

            # Buscar dias da semana da atividade
            cur.execute("""
                SELECT ds.nome AS dia_nome
                FROM atividades_dias ad
                JOIN dias_semana ds ON ds.id = ad.id_dia
                WHERE ad.id_atividade = %s
                ORDER BY ds.id
            """, (atividade_id,))
            dias = [d['dia_nome'] for d in cur.fetchall()]

            # Buscar alunos inscritos na atividade (sem repetir)
            cur.execute("""
                SELECT DISTINCT a.id, a.nome
                FROM alunos a
                JOIN alunos_atividades aa ON aa.id_aluno = a.id
                WHERE aa.id_atividade = %s
                ORDER BY a.nome
            """, (atividade_id,))
            alunos = cur.fetchall()

            # Buscar nome do instrutor na tabela FUNCIONARIOS
            cur.execute("""
                SELECT nome AS instrutor_nome
                FROM funcionarios
                WHERE id = %s
            """, (atividade['id_instrutor'],))
            instrutor = cur.fetchone()
            instrutor_nome = instrutor['instrutor_nome'] if instrutor else "Não definido"

    # Determinar mês vigente
    if mes == 0:
        mes = date.today().month

    meses = ["Janeiro","Fevereiro","Março","Abril","Maio","Junho",
             "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"]
    mes_nome = meses[mes-1] if 1 <= mes <= 12 else "Mês inválido"

    return render_template('ficha_chamada.html',
                           atividade=atividade,
                           alunos=alunos,
                           dias_atividade=dias, 
                           mes_nome=mes_nome,
                           instrutor_nome=instrutor_nome)

# -------------------- ACESSO DE FUNCIONÁRIOS --------------------
@app.route('/acesso_funcionarios', methods=['GET', 'POST'])
@acesso_permitido(['programador', 'admin'])
def acesso_funcionarios():
    if request.method == 'POST':
        usuario = request.form['usuario']
        senha = generate_password_hash(request.form['senha'])
        cargo = request.form['cargo']
        nivel = request.form['nivel']
        ativo = True
        with get_db_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO senhas (usuario, senha, cargo, nivel, ativo)
                    VALUES (%s, %s, %s, %s, %s)
                """, (usuario, senha, cargo, nivel, ativo))
                conn.commit()
        flash("Acesso criado com sucesso!", "success")
        return redirect(url_for('acesso_funcionarios'))
    return render_template('acesso_funcionarios.html')

# -------------------- LOGOUT --------------------
@app.route('/logout')
def logout():
    session.clear()
    flash("Você saiu do sistema.", "info")
    return redirect(url_for('login'))

# -------------------- RODAR APP --------------------
if __name__ == '__main__':
    app.run(debug=True, port=5001)
