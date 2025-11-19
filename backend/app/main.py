from fastapi import FastAPI
from .routes.routes_health import router as health_router
from .routes.routes_variedad_biblioteca import router as variedad_router
from .routes.routes_coleccion import router as coleccion_router
from .routes.routes_auth import router as auth_router
from .routes.routes_users import router as users_router
from .routes.routes_publicacion import router as publicacion_router
from .routes.routes_comentarios import router as comentario_router
from .routes import ml_routes


app = FastAPI(title="VitIA Backend")


# Registrar rutas
app.include_router(health_router, prefix="/health", tags=["health"])
app.include_router(variedad_router)
app.include_router(coleccion_router)
app.include_router(auth_router)  
app.include_router(users_router)
app.include_router(publicacion_router)
app.include_router(comentario_router)
app.include_router(ml_routes.router)