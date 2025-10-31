import os
from dotenv import load_dotenv

load_dotenv()

    # --- Variables para el cliente de API (supabase-py) ---
    # (Tu app móvil las usará, pero tu backend probablemente no)
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
SUPABASE_DB_URL = os.getenv("SUPABASE_DB_URL")

    # --- Variable para SQLAlchemy (¡ESTA ES LA IMPORTANTE!) ---
    # (Esta es la que 'models.py' y 'supabase_client.py' necesitan)
SUPABASE_DB_URL = os.getenv("SUPABASE_DB_URL")


    # --- Depuración ---
print("[DEBUG] SUPABASE_URL (para cliente API):", SUPABASE_URL)
print("[DEBUG] SUPABASE_ANON_KEY (para cliente API):", SUPABASE_ANON_KEY[:8] + "..." if SUPABASE_ANON_KEY else None)
print("[DEBUG] SUPABASE_DB_URL (para SQLAlchemy):", "Cargada..." if SUPABASE_DB_URL else "¡¡NO ENCONTRADA!!")
