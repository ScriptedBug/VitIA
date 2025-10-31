from fastapi import FastAPI
from .routes.routes_health import router as health_router


app = FastAPI(title="Viñas Backend")


# Registrar rutas
app.include_router(health_router, prefix="/health", tags=["health"])