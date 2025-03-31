#!/bin/bash

# Gerenciador de Deploy Replit - Script de Instalação
# Para Ubuntu 24.04
# Desenvolvido por View Tecnologia

# Cores para melhor visualização
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

# Versão do instalador
VERSION="1.0.0"
REPO_URL="https://github.com/viewtecnologia/gerenciadorubuntu/archive/refs/heads/main.zip"

# Diretórios de instalação
INSTALL_DIR="/opt/replit-deploy"
APP_DIR="${INSTALL_DIR}/app"
APPS_DIR="${INSTALL_DIR}/apps"
LOG_DIR="/var/log/replit-deploy"
VENV_DIR="${INSTALL_DIR}/venv"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${GREEN}Gerenciador de Deploy Replit - Instalador v${VERSION}${BLUE}                ║${NC}"
echo -e "${BLUE}║  ${GREEN}Para Ubuntu 24.04${BLUE}                                              ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Este script irá instalar o Gerenciador de Deploy Replit no seu servidor."
echo -e "É necessário ter privilégios de root para continuar."
echo ""

# Verificar se está executando como root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Erro: Este script precisa ser executado como root ou com sudo.${NC}"
  echo -e "Por favor, execute novamente com: sudo bash install.sh"
  exit 1
fi

# Verificar versão do Ubuntu
check_ubuntu_version() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [ "$ID" = "ubuntu" ]; then
      ubuntu_version=$(lsb_release -rs)
      if [[ "$ubuntu_version" != "24.04" ]]; then
        echo -e "${YELLOW}Aviso: Este script foi projetado para Ubuntu 24.04, mas você está usando Ubuntu $ubuntu_version.${NC}"
        echo "A instalação pode não funcionar corretamente."
        read -p "Continuar mesmo assim? (s/n): " continue_install
        if [[ "$continue_install" != "s" && "$continue_install" != "S" ]]; then
          echo "Instalação cancelada."
          exit 1
        fi
      fi
    else
      echo -e "${YELLOW}Aviso: Este script foi projetado para Ubuntu, mas você está usando $NAME.${NC}"
      echo "A instalação pode não funcionar corretamente."
      read -p "Continuar mesmo assim? (s/n): " continue_install
      if [[ "$continue_install" != "s" && "$continue_install" != "S" ]]; then
        echo "Instalação cancelada."
        exit 1
      fi
    fi
  else
    echo -e "${YELLOW}Aviso: Não foi possível determinar a versão do sistema operacional.${NC}"
    echo "A instalação pode não funcionar corretamente."
    read -p "Continuar mesmo assim? (s/n): " continue_install
    if [[ "$continue_install" != "s" && "$continue_install" != "S" ]]; then
      echo "Instalação cancelada."
      exit 1
    fi
  fi
}

# Função para mostrar progresso
progress() {
  echo -e "${GREEN}➤ $1${NC}"
}

# Configurar credenciais iniciais
setup_credentials() {
  # Gerar uma senha aleatória para o banco de dados
  DB_PASSWORD=$(openssl rand -hex 8)
  
  # Solicitar informações do usuário admin
  echo ""
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  ${GREEN}Configuração do Usuário Administrador${BLUE}                         ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  
  # Definir valores padrão
  DEFAULT_USERNAME="viewtecnologia"
  DEFAULT_EMAIL="admin@viewtecnologia.com.br"
  
  read -p "Nome de usuário para conta de administrador [${DEFAULT_USERNAME}]: " admin_username
  admin_username=${admin_username:-$DEFAULT_USERNAME}
  
  read -p "E-mail para conta de administrador [${DEFAULT_EMAIL}]: " admin_email
  admin_email=${admin_email:-$DEFAULT_EMAIL}
  
  read -sp "Senha para conta de administrador (deixe em branco para gerar automática): " admin_password
  echo ""
  
  if [ -z "$admin_password" ]; then
    admin_password=$(openssl rand -hex 6)
    echo -e "${YELLOW}Senha gerada automaticamente: ${admin_password}${NC}"
    echo -e "${YELLOW}Anote esta senha, pois não será mostrada novamente!${NC}"
  fi
  
  # Confirmar informações
  echo ""
  echo "Configurando com as seguintes informações:"
  echo "- Usuário: $admin_username"
  echo "- E-mail: $admin_email"
  echo "- Senha: $admin_password"
  echo ""
  echo "IMPORTANTE: Anote a senha mostrada acima, pois ela não será exibida novamente!"
  echo ""
  sleep 5  # Dar tempo para o usuário anotar a senha
}

# Instalar dependências do sistema
install_system_dependencies() {
  progress "Passo 1: Atualizando pacotes do sistema"
  apt update 
  apt upgrade -y
  
  progress "Passo 2: Instalando dependências necessárias"
  apt install -y python3 python3-pip python3-venv python3-dev libpq-dev \
                 postgresql postgresql-contrib nginx git unzip curl wget \
                 build-essential ufw certbot python3-certbot-nginx
}

# Configurar PostgreSQL
setup_database() {
  progress "Passo 3: Configurando banco de dados PostgreSQL"
  
  # Iniciar e habilitar PostgreSQL
  systemctl start postgresql
  systemctl enable postgresql
  
  # Criar usuário e banco de dados
  sudo -u postgres psql -c "CREATE USER replit_deploy WITH PASSWORD '${DB_PASSWORD}';"
  sudo -u postgres psql -c "CREATE DATABASE replit_deploy;"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE replit_deploy TO replit_deploy;"
  sudo -u postgres psql -c "ALTER USER replit_deploy WITH SUPERUSER;"
  
  # Configurar acesso
  echo "host    replit_deploy    replit_deploy    127.0.0.1/32    md5" >> /etc/postgresql/16/main/pg_hba.conf
  
  # Reiniciar PostgreSQL para aplicar as alterações
  systemctl restart postgresql
}

# Configurar diretórios da aplicação
setup_app_directories() {
  progress "Passo 4: Configurando diretórios da aplicação"
  
  # Criar diretórios principais
  mkdir -p ${INSTALL_DIR}
  mkdir -p ${APPS_DIR}
  mkdir -p ${LOG_DIR}
  
  # Permissões
  chmod 755 ${INSTALL_DIR}
  chmod 755 ${APPS_DIR}
  chmod 755 ${LOG_DIR}
}

# Baixar e instalar aplicação
download_and_install_app() {
  progress "Passo 5: Baixando e instalando a aplicação"
  
  # Baixar código do repositório 
  cd /tmp
  wget ${REPO_URL} -O replit-deploy.zip
  unzip replit-deploy.zip
  mv gerenciadorubuntu-main ${APP_DIR}
  
  # Criar ambiente virtual Python
  python3 -m venv ${VENV_DIR}
  source ${VENV_DIR}/bin/activate
  
  # Instalar dependências Python
  pip install --upgrade pip
  pip install flask flask-login flask-sqlalchemy flask-wtf psycopg2-binary gunicorn email-validator requests
  
  # Criar arquivo de configuração
  cat > ${APP_DIR}/.env << EOF
# Configurações do aplicativo
SECRET_KEY=$(openssl rand -hex 32)
SESSION_SECRET=$(openssl rand -hex 32)
DATABASE_URL=postgresql://replit_deploy:${DB_PASSWORD}@localhost/replit_deploy
APP_ENV=production
DEBUG=False
EOF

  # Criar arquivo de configuração do gunicorn
  cat > ${APP_DIR}/gunicorn_config.py << EOF
bind = "0.0.0.0:5000"
workers = 3
timeout = 120
accesslog = "${LOG_DIR}/access.log"
errorlog = "${LOG_DIR}/error.log"
capture_output = True
EOF

  # Criar script de inicialização
  cat > ${APP_DIR}/start.sh << EOF
#!/bin/bash
source ${VENV_DIR}/bin/activate
cd ${APP_DIR}
export FLASK_APP=main.py
export PYTHONPATH=${APP_DIR}
export DATABASE_URL=postgresql://replit_deploy:${DB_PASSWORD}@localhost/replit_deploy
export SESSION_SECRET=\$(cat ${APP_DIR}/.env | grep SESSION_SECRET | cut -d= -f2)

# Tentar iniciar o aplicativo em modo de produção
exec gunicorn --config gunicorn_config.py main:app
EOF

  chmod +x ${APP_DIR}/start.sh
}

# Configurar usuário administrador inicial
setup_admin_user() {
  progress "Passo 6: Configurando usuário administrador inicial"
  
  # Criar script para adicionar usuário administrador
  cat > ${APP_DIR}/create_admin.py << EOF
import os
import sys
from werkzeug.security import generate_password_hash
from datetime import datetime
import psycopg2

# Configurações do banco de dados
DB_USER = "replit_deploy"
DB_PASS = "${DB_PASSWORD}"
DB_NAME = "replit_deploy"
DB_HOST = "localhost"

# Detalhes do usuário
ADMIN_USER = "${admin_username}"
ADMIN_EMAIL = "${admin_email}"
ADMIN_PASS = "${admin_password}"

try:
    # Conectar ao banco de dados
    conn = psycopg2.connect(
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASS,
        host=DB_HOST
    )
    conn.autocommit = True
    cursor = conn.cursor()
    
    # Verificar se a tabela de usuários existe, caso contrário criar
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS "user" (
        id SERIAL PRIMARY KEY,
        username VARCHAR(64) UNIQUE NOT NULL,
        email VARCHAR(120) UNIQUE NOT NULL,
        password_hash VARCHAR(256) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
    """)
    
    # Verificar se o usuário já existe
    cursor.execute("SELECT id FROM \"user\" WHERE username = %s", (ADMIN_USER,))
    user = cursor.fetchone()
    
    if not user:
        # Criar senha hash
        password_hash = generate_password_hash(ADMIN_PASS)
        
        # Inserir usuário
        cursor.execute(
            "INSERT INTO \"user\" (username, email, password_hash, created_at) VALUES (%s, %s, %s, %s)",
            (ADMIN_USER, ADMIN_EMAIL, password_hash, datetime.utcnow())
        )
        print("Usuário administrador criado com sucesso!")
    else:
        print("Usuário administrador já existe!")
        
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f"Erro ao criar usuário administrador: {e}")
    sys.exit(1)
EOF

  # Executar script para criar usuário
  cd ${APP_DIR}
  ${VENV_DIR}/bin/python create_admin.py
  rm ${APP_DIR}/create_admin.py
}

# Configurar serviço systemd
setup_systemd_service() {
  progress "Passo 7: Configurando serviço systemd"
  
  # Criar arquivo de serviço
  cat > /etc/systemd/system/replit-deploy.service << EOF
[Unit]
Description=Gerenciador de Deploy Replit
After=network.target postgresql.service

[Service]
User=root
Group=root
WorkingDirectory=${APP_DIR}
ExecStart=${APP_DIR}/start.sh
Restart=always
StandardOutput=append:${LOG_DIR}/manager.log
StandardError=append:${LOG_DIR}/manager-error.log
Environment="PATH=${VENV_DIR}/bin"
Environment="PYTHONPATH=${APP_DIR}"

[Install]
WantedBy=multi-user.target
EOF

  # Recarregar systemd, habilitar e iniciar serviço
  systemctl daemon-reload
  systemctl enable replit-deploy.service
  systemctl start replit-deploy.service
}

# Configurar Nginx
setup_nginx() {
  progress "Passo 8: Configurando Nginx como proxy reverso"
  
  # Criar configuração
  cat > /etc/nginx/sites-available/replit-deploy << EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;
        send_timeout 300;
    }
}
EOF

  # Habilitar site
  ln -sf /etc/nginx/sites-available/replit-deploy /etc/nginx/sites-enabled/
  rm -f /etc/nginx/sites-enabled/default
  
  # Testar configuração
  nginx -t
  
  # Reiniciar Nginx
  systemctl restart nginx
}

# Configurar firewall
setup_firewall() {
  progress "Passo 9: Configurando firewall"
  
  # Configurar ufw
  ufw allow 'Nginx Full'
  ufw allow 'OpenSSH'
  
  # Habilitar firewall se não estiver ativo
  ufw status | grep -q "Status: active" || ufw --force enable
}

# Verificar status da instalação
check_installation_status() {
  progress "Verificando status da instalação"
  
  # Verificar se o servico está rodando
  systemctl status replit-deploy.service > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${YELLOW}AVISO: O serviço replit-deploy.service não está rodando corretamente.${NC}"
    echo -e "Tentando reiniciar..."
    systemctl restart replit-deploy.service
    sleep 3
  fi
  
  # Verificar se a aplicação está ouvindo na porta 5000
  netstat -tuln | grep :5000 > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${YELLOW}AVISO: A aplicação não está escutando na porta 5000.${NC}"
    echo -e "Verificando logs..."
    tail -n 20 ${LOG_DIR}/manager-error.log
    echo ""
    echo -e "Tentando corrigir o problema..."
    
    # Reiniciar o serviço
    systemctl restart replit-deploy.service
    sleep 5
    
    # Verificar novamente
    netstat -tuln | grep :5000 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo -e "${RED}Erro: A aplicação ainda não está funcionando.${NC}"
      echo -e "Verifique os logs em ${LOG_DIR}/manager-error.log"
    else
      echo -e "${GREEN}A aplicação está agora funcionando corretamente.${NC}"
    fi
  else
    echo -e "${GREEN}A aplicação está rodando e escutando na porta 5000.${NC}"
  fi
  
  # Verificar configuração do Nginx
  nginx -t > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo -e "${YELLOW}AVISO: A configuração do Nginx tem erros.${NC}"
    nginx -t
    echo -e "Tentando corrigir..."
    
    # Recriar configuração do Nginx
    setup_nginx
  else
    echo -e "${GREEN}A configuração do Nginx está correta.${NC}"
  fi
  
  # Verificar se os arquivos da aplicação existem
  if [ ! -f "${APP_DIR}/main.py" ]; then
    echo -e "${RED}ERRO: O arquivo main.py não existe no diretório de instalação!${NC}"
    echo "Arquivos encontrados em ${APP_DIR}:"
    ls -la ${APP_DIR}
    
    echo -e "${YELLOW}Tentando reparar problemas com arquivos da aplicação...${NC}"
    
    # Tente baixar novamente o código-fonte
    cd /tmp
    rm -rf gerenciadorubuntu-main replit-deploy.zip
    wget ${REPO_URL} -O replit-deploy.zip
    unzip replit-deploy.zip
    if [ -d "gerenciadorubuntu-main" ]; then
      echo -e "${GREEN}Código-fonte baixado com sucesso. Copiando arquivos...${NC}"
      cp -r gerenciadorubuntu-main/* ${APP_DIR}/
      
      # Verificar novamente
      if [ -f "${APP_DIR}/main.py" ]; then
        echo -e "${GREEN}Arquivo main.py encontrado após reparo!${NC}"
        # Reiniciar serviço
        systemctl restart replit-deploy.service
        sleep 5
      else
        # Tentar criar um arquivo main.py simples para testar
        echo -e "${YELLOW}Arquivo main.py ainda não existe. Criando arquivo mínimo para teste...${NC}"
        cat > ${APP_DIR}/main.py << EOF
from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return 'Gerenciador de Deploy Replit - Instalação em progresso. Por favor, verifique os logs.'

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
EOF
        # Reiniciar serviço
        systemctl restart replit-deploy.service
        sleep 5
      fi
    else
      echo -e "${RED}Falha ao baixar o código-fonte novamente.${NC}"
    fi
  else
    echo -e "${GREEN}Arquivos da aplicação encontrados corretamente.${NC}"
  fi
}

# Finalizar instalação
finalize_installation() {
  # Verificar status da instalação
  check_installation_status
  
  # Obter endereço IP do servidor
  SERVER_IP=$(hostname -I | awk '{print $1}')
  
  echo ""
  echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║  ${GREEN}Instalação Concluída com Sucesso!${BLUE}                            ║${NC}"
  echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${GREEN}O Gerenciador de Deploy Replit foi instalado e configurado.${NC}"
  echo ""
  echo -e "Você pode acessar a aplicação em: ${YELLOW}http://${SERVER_IP}${NC}"
  echo -e "Login: ${YELLOW}${admin_username}${NC}"
  echo -e "Senha: ${YELLOW}${admin_password}${NC}"
  echo ""
  echo -e "${GREEN}Informações de Banco de Dados:${NC}"
  echo -e "Usuário BD: ${YELLOW}replit_deploy${NC}"
  echo -e "Senha BD: ${YELLOW}${DB_PASSWORD}${NC}"
  echo -e "Nome BD: ${YELLOW}replit_deploy${NC}"
  echo ""
  echo -e "${GREEN}Comandos úteis:${NC}"
  echo -e "- Verificar status do serviço: ${YELLOW}systemctl status replit-deploy.service${NC}"
  echo -e "- Reiniciar o serviço: ${YELLOW}systemctl restart replit-deploy.service${NC}"
  echo -e "- Visualizar logs: ${YELLOW}tail -f ${LOG_DIR}/manager.log${NC}"
  echo ""
  echo -e "${YELLOW}IMPORTANTE:${NC} Recomendamos configurar HTTPS para maior segurança."
  echo -e "Você pode usar o Certbot para certificados gratuitos com o comando:"
  echo -e "${YELLOW}certbot --nginx -d seu-dominio.com${NC}"
  echo ""
  echo -e "${GREEN}Obrigado por instalar o Gerenciador de Deploy Replit!${NC}"
  
  # Salvar informações em um arquivo local para referência
  cat > ${INSTALL_DIR}/install_info.txt << EOF
Gerenciador de Deploy Replit - Informações da Instalação
======================================================
Data de Instalação: $(date)
Diretório de Instalação: ${INSTALL_DIR}
Diretório da Aplicação: ${APP_DIR}
Diretório de Logs: ${LOG_DIR}

Informações de Acesso:
- URL: http://${SERVER_IP}
- Login: ${admin_username}
- Senha: ${admin_password}

Banco de Dados:
- Usuário: replit_deploy
- Senha: ${DB_PASSWORD}
- Nome: replit_deploy
- Host: localhost

Comandos Úteis:
- systemctl status replit-deploy.service
- systemctl restart replit-deploy.service
- systemctl stop replit-deploy.service
- systemctl start replit-deploy.service
- tail -f ${LOG_DIR}/manager.log
EOF

  chmod 600 ${INSTALL_DIR}/install_info.txt
}

# Função principal
main() {
  check_ubuntu_version
  setup_credentials
  install_system_dependencies
  setup_database
  setup_app_directories
  download_and_install_app
  setup_admin_user
  setup_systemd_service
  setup_nginx
  setup_firewall
  finalize_installation
}

# Executar instalação
main

exit 0
