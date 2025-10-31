from fastapi import FastAPI
from .routes.routes_health import router as health_router
from .routes.routes_variedad_biblioteca import router as variedad_router


app = FastAPI(title="Viñas Backend")


# Registrar rutas
app.include_router(health_router, prefix="/health", tags=["health"])
app.include_router(variedad_router, prefix="/variedades", tags=["variedades"])