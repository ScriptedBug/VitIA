import os
from dotenv import load_dotenv



load_dotenv()


SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY")
print("[DEBUG] SUPABASE_URL:", SUPABASE_URL)
print("[DEBUG] SUPABASE_ANON_KEY:", SUPABASE_ANON_KEY[:8] + "..." if SUPABASE_ANON_KEY else None)
