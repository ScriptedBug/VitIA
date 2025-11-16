import os
from dotenv import load_dotenv
from pydantic_settings import BaseSettings, SettingsConfigDict

load_dotenv()

class Settings(BaseSettings):
    DATABASE_URL: str
    SECRET_KEY: str
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # Le dice a Pydantic que lea el archivo .env
    model_config = SettingsConfigDict(env_file=".env")

# Creamos una instancia global de la configuración
settings = Settings()

    # --- Variables para el cliente de API (supabase-py) ---
    # (Tu app móvil las usará, pero tu backend probablemente no)
DATABASE_URL = os.getenv("DATABASE_URL")

    # --- Variable para SQLAlchemy (¡ESTA ES LA IMPORTANTE!) ---
    # (Esta es la que 'models.py' y 'supabase_client.py' necesitan)
SUPABASE_DB_URL = os.getenv("SUPABASE_DB_URL")


    # --- Depuración ---
print("[DEBUG] DATABASE_URL (para SQLAlchemy):", "Cargada..." if DATABASE_URL else "¡¡NO ENCONTRADA!!")
