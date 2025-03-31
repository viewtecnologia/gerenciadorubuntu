import os
import logging

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


db = SQLAlchemy(model_class=Base)
login_manager = LoginManager()

# create the app
app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", "default_dev_key_change_in_production")

# Configure logging
logging.basicConfig(level=logging.DEBUG)

# configure the database
DATABASE_URL = os.environ.get("DATABASE_URL", "sqlite:///deploy_manager.db")
# Se for o Postgres do Replit, precisamos ajustar a URL
if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

app.config["SQLALCHEMY_DATABASE_URI"] = DATABASE_URL
app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
    "pool_recycle": 300,
    "pool_pre_ping": True,
}
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

# initialize extensions
db.init_app(app)
login_manager.init_app(app)
login_manager.login_view = 'auth.login'

# Register blueprints
with app.app_context():
    # Import models first to ensure they're registered with SQLAlchemy
    from models import User, Application, DeploymentLog
    
    # Create all tables
    db.create_all()
    
    # Import and register blueprints
    from routes.auth import auth_bp
    from routes.dashboard import dashboard_bp
    from routes.deploy import deploy_bp
    
    app.register_blueprint(auth_bp)
    app.register_blueprint(dashboard_bp)
    app.register_blueprint(deploy_bp)
    
    # Set up login manager
    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))
