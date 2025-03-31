from app import app, db
from models import User

def create_default_user():
    with app.app_context():
        # Verifica se o usuário já existe
        existing_user = User.query.filter_by(username='viewtecnologia').first()
        if existing_user:
            print("Usuário padrão 'viewtecnologia' já existe!")
            return
        
        # Cria o usuário padrão
        default_user = User(
            username='viewtecnologia',
            email='admin@gerenciador.com'
        )
        default_user.set_password('Rai2804@2804')
        
        # Adiciona e salva no banco de dados
        db.session.add(default_user)
        db.session.commit()
        
        print("Usuário padrão 'viewtecnologia' criado com sucesso!")

if __name__ == '__main__':
    create_default_user()