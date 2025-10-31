from fastapi import APIRouter
from ..supabase_client import get_supabase_client


router = APIRouter()


@router.get("/ping")
def ping():
    client = get_supabase_client()
    connected = bool(client)
    return {"status": "ok", "supabase_connected": connected}