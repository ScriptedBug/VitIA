import os
from dotenv import load_dotenv

load_dotenv()

    # --- Variables para el cliente de API (supabase-py) ---
    # (Tu app móvil las usará, pero tu backend probablemente no)
DATABASE_URL = os.getenv("DATABASE_URL")

    # --- Variable para SQLAlchemy (¡ESTA ES LA IMPORTANTE!) ---
    # (Esta es la que 'models.py' y 'supabase_client.py' necesitan)
SUPABASE_DB_URL = os.getenv("SUPABASE_DB_URL")


    # --- Depuración ---
print("[DEBUG] DATABASE_URL (para SQLAlchemy):", "Cargada..." if DATABASE_URL else "¡¡NO ENCONTRADA!!")
