import datetime
from app import db
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    
    # Relationships
    applications = db.relationship('Application', backref='owner', lazy='dynamic')
    logs = db.relationship('DeploymentLog', backref='user', lazy='dynamic')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
        
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def __repr__(self):
        return f'<User {self.username}>'

class Application(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    replit_url = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(20), default='stopped')  # running, stopped, error
    port = db.Column(db.Integer, nullable=True)
    install_path = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    last_deployed = db.Column(db.DateTime, nullable=True)
    
    # Recursos (resources)
    memory_limit = db.Column(db.Integer, default=256)  # em MB
    cpu_limit = db.Column(db.Integer, default=50)  # em percentual (%)
    disk_limit = db.Column(db.Integer, default=1024)  # em MB
    
    # Tipo de aplicação
    app_type = db.Column(db.String(20), nullable=True)  # python, node, ruby, go, etc.
    auto_restart = db.Column(db.Boolean, default=True)
    
    # Foreign keys
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Relationships
    logs = db.relationship('DeploymentLog', backref='application', lazy='dynamic')
    domain_configs = db.relationship('DomainConfig', backref='application', lazy='dynamic')
    backups = db.relationship('Backup', backref='application', lazy='dynamic')
    
    def __repr__(self):
        return f'<Application {self.name}>'

class DomainConfig(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    domain_name = db.Column(db.String(255), nullable=False)
    is_active = db.Column(db.Boolean, default=True)
    ssl_enabled = db.Column(db.Boolean, default=False)
    ssl_cert_path = db.Column(db.String(255), nullable=True)
    ssl_key_path = db.Column(db.String(255), nullable=True)
    ssl_expiry = db.Column(db.DateTime, nullable=True)
    ddns_provider = db.Column(db.String(50), nullable=True)  # cloudflare, namecheap, duckdns, etc.
    ddns_token = db.Column(db.String(255), nullable=True)
    ddns_username = db.Column(db.String(255), nullable=True)
    ddns_password = db.Column(db.String(255), nullable=True)
    ddns_last_updated = db.Column(db.DateTime, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    
    # Foreign keys
    application_id = db.Column(db.Integer, db.ForeignKey('application.id'), nullable=False)
    
    def __repr__(self):
        return f'<DomainConfig {self.domain_name}>'

class Backup(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    backup_path = db.Column(db.String(255), nullable=False)
    backup_size = db.Column(db.Integer, nullable=True)  # em bytes
    created_at = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    description = db.Column(db.Text, nullable=True)
    status = db.Column(db.String(20), default='completed')  # completed, failed, in_progress
    
    # Foreign keys
    application_id = db.Column(db.Integer, db.ForeignKey('application.id'), nullable=False)
    
    def __repr__(self):
        return f'<Backup {self.id} for App {self.application_id}>'

class DeploymentLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    action = db.Column(db.String(50), nullable=False)  # deploy, start, stop, restart, backup, ssl, ddns
    status = db.Column(db.String(20), nullable=False)  # success, failed
    message = db.Column(db.Text, nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.datetime.utcnow)
    
    # Foreign keys
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    application_id = db.Column(db.Integer, db.ForeignKey('application.id'), nullable=False)
    
    def __repr__(self):
        return f'<DeploymentLog {self.action} - {self.status}>'
