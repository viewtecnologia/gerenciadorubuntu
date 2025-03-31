from app import app, db
import os
import sqlite3

def backup_db():
    """Criar backup do banco de dados antes da migração"""
    if os.path.exists('instance/deploy_manager.db'):
        db_path = 'instance/deploy_manager.db'
        backup_path = 'instance/deploy_manager.db.bak'
        
        # Copiar o arquivo
        with open(db_path, 'rb') as src, open(backup_path, 'wb') as dst:
            dst.write(src.read())
        
        print(f"Backup do banco de dados criado em {backup_path}")
    else:
        print("Banco de dados não encontrado para backup")

def migrate_database():
    """Adicionar as novas colunas às tabelas existentes"""
    
    # Primeiro fazer backup do banco de dados
    backup_db()
    
    try:
        # Conexão com o banco de dados SQLite
        conn = sqlite3.connect('instance/deploy_manager.db')
        cursor = conn.cursor()
        
        # Verificar se as colunas já existem
        cursor.execute("PRAGMA table_info(application)")
        columns = cursor.fetchall()
        column_names = [column[1] for column in columns]
        
        # Adicionar coluna memory_limit se não existir
        if 'memory_limit' not in column_names:
            cursor.execute("ALTER TABLE application ADD COLUMN memory_limit INTEGER DEFAULT 256")
            print("Coluna memory_limit adicionada")
            
        # Adicionar coluna cpu_limit se não existir
        if 'cpu_limit' not in column_names:
            cursor.execute("ALTER TABLE application ADD COLUMN cpu_limit INTEGER DEFAULT 50")
            print("Coluna cpu_limit adicionada")
            
        # Adicionar coluna disk_limit se não existir
        if 'disk_limit' not in column_names:
            cursor.execute("ALTER TABLE application ADD COLUMN disk_limit INTEGER DEFAULT 1024")
            print("Coluna disk_limit adicionada")
            
        # Adicionar coluna app_type se não existir
        if 'app_type' not in column_names:
            cursor.execute("ALTER TABLE application ADD COLUMN app_type VARCHAR(20)")
            print("Coluna app_type adicionada")
            
        # Adicionar coluna auto_restart se não existir
        if 'auto_restart' not in column_names:
            cursor.execute("ALTER TABLE application ADD COLUMN auto_restart BOOLEAN DEFAULT 1")
            print("Coluna auto_restart adicionada")
        
        # Salvar as alterações
        conn.commit()
        print("Migração concluída com sucesso")
        
    except Exception as e:
        print(f"Erro durante a migração: {e}")
        
    finally:
        # Fechar a conexão
        if conn:
            conn.close()

if __name__ == "__main__":
    migrate_database()