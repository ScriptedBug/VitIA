# app/supabase_client.py
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import SUPABASE_DB_URL 

# 1. Tu URL de conexión COMPLETA de Supabase (tipo PostgreSQL)
#    Ej: "postgresql://postgres:TU_CLAVE@db.xyz.supabase.co:5432/postgres"
#    ¡Sácala de tus settings de Supabase, NO de las variables de entorno de la API!
SQLALCHEMY_DATABASE_URL = SUPABASE_DB_URL

# 2. El "motor" de SQLAlchemy
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# 3. El creador de sesiones
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 4. La 'Base' de la que heredan tus modelos en 'app/models.py'
Base = declarative_base()

# 5. La función de Dependencia para tus routers
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()