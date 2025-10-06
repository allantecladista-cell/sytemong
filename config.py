class Config:
    # Configurações de Banco de Dados para AMBIENTE LOCAL (Desenvolvimento)
    DB_HOST = "localhost"
    DB_NAME = "ongdb"
    DB_USER = "allanvieira"
    DB_PASSWORD = "@Piroca16"
    DB_PORT = 5432

    # Chave Secreta de fallback para desenvolvimento local. 
    # Em produção, a chave será lida da Variável de Ambiente do Render (mais seguro).
    SECRET_KEY_FALLBACK = "@piroca16"