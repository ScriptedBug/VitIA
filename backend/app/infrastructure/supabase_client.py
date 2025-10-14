from supabase import create_client
from app.config import SUPABASE_URL, SUPABASE_ANON_KEY

def get_supabase_client():
    try:
        if SUPABASE_URL and SUPABASE_ANON_KEY:
            client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
            return client
        else:
            print("[WARN] Variables de entorno Supabase vacías o no cargadas")
            return None
    except Exception as e:
        print(f"[ERROR] No se pudo crear el cliente Supabase: {e}")
        return None
