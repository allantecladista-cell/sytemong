from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, Image
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors
import datetime
import os

def gerar_ficha_aluno(aluno, output_path):
    """
    Gera um PDF profissional da ficha de cadastro do aluno.
    aluno: dicionário com todas as informações do cadastro
    output_path: caminho do arquivo PDF a ser gerado
    """
    doc = SimpleDocTemplate(output_path, pagesize=A4)
    styles = getSampleStyleSheet()
    elements = []

    # Logotipo da ONG (opcional)
    logo_path = "logo_ong.png"
    if os.path.exists(logo_path):
        logo = Image(logo_path, width=80, height=80)
        elements.append(logo)

    # Título
    elements.append(Spacer(1, 10))
    elements.append(Paragraph("<b>FICHA DE CADASTRO DO ALUNO</b>", styles['Title']))
    elements.append(Spacer(1, 20))

    # Dados do aluno
    dados_aluno = [
        ["<b>Nome</b>", aluno.get("nome", "")],
        ["<b>Gênero</b>", aluno.get("genero", "")],
        ["<b>Data de Nascimento</b>", aluno.get("data_nascimento", "")],
        ["<b>CPF</b>", aluno.get("cpf", "")],
        ["<b>Pai</b>", aluno.get("pai", "")],
        ["<b>Mãe</b>", aluno.get("mae", "")],
        ["<b>Telefone</b>", aluno.get("telefone", "")],
        ["<b>Email</b>", aluno.get("email", "")],
        ["<b>Endereço</b>", aluno.get("endereco", "")],
        ["<b>Escolaridade</b>", aluno.get("escolaridade", "")],
        ["<b>Escola</b>", aluno.get("escola", "")],
        ["<b>Turno</b>", aluno.get("turno", "")]
    ]

    # Dados do responsável
    dados_responsavel = [
        ["<b>Nome do Responsável</b>", aluno.get("nome_responsavel", "")],
        ["<b>Telefone</b>", aluno.get("telefone_responsavel", "")],
        ["<b>Email</b>", aluno.get("email_responsavel", "")],
        ["<b>Parentesco</b>", aluno.get("parentesco", "")]
    ]

    # Combina tudo em uma tabela
    tabela_dados = dados_aluno + [["", ""]] + dados_responsavel  # linha em branco separando

    tabela = Table(tabela_dados, colWidths=[180, 340])
    tabela.setStyle(TableStyle([
        ('GRID', (0, 0), (-1, -1), 0.5, colors.grey),
        ('BACKGROUND', (0, 0), (0, len(dados_aluno)-1), colors.lightgrey),
        ('BACKGROUND', (0, len(dados_aluno)+1), (0, -1), colors.lightgrey),
        ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
        ('FONTNAME', (0, 0), (-1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 11),
    ]))
    elements.append(tabela)
    elements.append(Spacer(1, 40))

    # Assinatura
    elements.append(Paragraph("Assinatura do responsável:", styles['Normal']))
    elements.append(Spacer(1, 30))
    elements.append(Paragraph("__________________________________________", styles['Normal']))
    elements.append(Spacer(1, 50))

    # Rodapé
    data_hoje = datetime.date.today().strftime('%d/%m/%Y')
    rodape = Paragraph(f"<i>Gerado por Sistema da ONG - {data_hoje}</i>", styles['Normal'])
    elements.append(rodape)

    doc.build(elements)
