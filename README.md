# Gerenciador de Deploy Replit

Sistema de gerenciamento para implantação automática de aplicações Replit em servidores Ubuntu 24.04, desenvolvido pela View Tecnologia.

## Características

- Interface web amigável em português brasileiro
- Deploy de aplicações a partir de URLs do Replit, repositórios GitHub ou uploads locais
- Gerenciamento de múltiplas aplicações implantadas
- Controle de recursos (memória, CPU, disco)
- Autenticação de usuários
- Logs detalhados de implantação e execução
- Suporte a diversos tipos de aplicação (Python, Node.js, Ruby, Go)
- Interface responsiva acessível de qualquer dispositivo

## Requisitos do Sistema

- Ubuntu 24.04 LTS (recomendado)
- Acesso root ou sudo
- 2GB de RAM mínimo (4GB recomendado)
- 20GB de espaço em disco mínimo
- Conexão com a internet

## Instalação Rápida (Comando Único)

Para instalar o Gerenciador de Deploy Replit em seu servidor, execute o seguinte comando como root ou usuário com privilégios sudo:

```bash
curl -sL https://raw.githubusercontent.com/viewtecnologia/gerenciadorubuntu/main/install.sh | sudo bash
```

Este comando fará o download do script de instalação e o executará automaticamente. Durante o processo, você será solicitado a fornecer algumas informações para configurar o usuário administrador inicial.

## Processo de Instalação

O script de instalação executa as seguintes etapas:

1. Verifica a versão do sistema operacional
2. Solicita informações para o usuário administrador
3. Atualiza o sistema e instala dependências
4. Configura o banco de dados PostgreSQL
5. Configura os diretórios da aplicação
6. Baixa e instala a aplicação
7. Configura o usuário administrador inicial
8. Configura o serviço systemd
9. Configura o Nginx como proxy reverso
10. Configura o firewall (UFW)
11. Finaliza a instalação e exibe informações de acesso

## Acessando o Gerenciador

Após a instalação, você pode acessar o Gerenciador de Deploy Replit usando seu navegador:

```
http://IP-DO-SEU-SERVIDOR
```

Faça login com as credenciais de administrador fornecidas durante a instalação. 

## Comandos Úteis

**Verificar status do serviço:**
```bash
systemctl status replit-deploy.service
```

**Reiniciar o serviço:**
```bash
systemctl restart replit-deploy.service
```

**Parar o serviço:**
```bash
systemctl stop replit-deploy.service
```

**Iniciar o serviço:**
```bash
systemctl start replit-deploy.service
```

**Visualizar logs:**
```bash
tail -f /var/log/replit-deploy/manager.log
```

## Uso Básico

### Implantar uma Nova Aplicação

1. Acesse a interface web e faça login
2. Clique no botão "Implantar Nova Aplicação"
3. Informe um nome para a aplicação
4. Escolha a origem do código:
   - URL do Replit (copie a URL completa do seu projeto Replit)
   - URL do GitHub (copie a URL completa do seu repositório GitHub)
   - Upload de Arquivo (envie um arquivo ZIP contendo o código da aplicação)
5. Configure os recursos desejados (memória, CPU, disco)
6. Clique em "Implantar Aplicação"

### Gerenciar Aplicações

A partir do painel de controle, você pode:

- Iniciar/parar/reiniciar aplicações
- Visualizar logs de aplicações
- Monitorar uso de recursos
- Configurar domínios personalizados
- Gerenciar backups
- Configurar certificados SSL

## Segurança

Para maior segurança, recomendamos:

1. Configurar HTTPS usando Let's Encrypt/Certbot:
   ```bash
   certbot --nginx -d seu-dominio.com
   ```

2. Manter o sistema e a aplicação atualizados regularmente

## Suporte

Para suporte técnico ou dúvidas, entre em contato:

- E-mail: suporte@viewtecnologia.com.br
- Website: https://www.viewtecnologia.com.br

## Licença

© 2025 View Tecnologia. Todos os direitos reservados.