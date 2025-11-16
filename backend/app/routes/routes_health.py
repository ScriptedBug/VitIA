from fastapi import APIRouter
from ..database import get_db


router = APIRouter()


@router.get("/ping")
def ping():
    client = get_db()
    connected = bool(client)
    return {"status": "ok", "supabase_connected": connected}