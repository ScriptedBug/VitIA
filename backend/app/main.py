from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware # ⬅️ AÑADIR ESTA IMPORTACIÓN
from .routes.routes_health import router as health_router
from .routes.routes_variedad_biblioteca import router as variedad_router
from .routes.routes_coleccion import router as coleccion_router
from .routes.routes_auth import router as auth_router
from .routes.routes_users import router as users_router
from .routes.routes_publicacion import router as publicacion_router
from .routes.routes_comentarios import router as comentario_router
from .routes import ml_routes


app = FastAPI(title="VitIA Backend")

@app.get("/")
def read_root():
    return {"status": "online"}

# ----------------------------------------------------
# 🌍 CONFIGURACIÓN DE CORS PARA PERMITIR CONEXIONES
# ----------------------------------------------------
# Define los orígenes (dominios/direcciones) que tienen permitido acceder a tu API.
# Esto soluciona los errores de conexión de Flutter Web (navegador) y emuladores.
origins = [
    "http://localhost",       # Origen básico de Uvicorn
    "http://localhost:8000",
    "http://127.0.0.1",
    "http://127.0.0.1:8000",  # Origen común de Flutter Web
    "http://10.0.2.2:8000",   # Emulador de Android
    
    # ⚠️ Usar "*" es la manera más sencilla de asegurar el funcionamiento en desarrollo
    # en diferentes máquinas y navegadores, pero debe ser limitado en producción.
    "*", 
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Permitir todos los orígenes en desarrollo
    allow_credentials=True,
    allow_methods=["*"],
    # ⬅️ ASEGURA QUE ESTOS ENCABEZADOS ESTÉN EXPLÍCITAMENTE PERMITIDOS
    allow_headers=["*", "Authorization", "Content-Type", "access-control-allow-origin"],
)
# ----------------------------------------------------
# FIN DE CONFIGURACIÓN DE CORS
# ----------------------------------------------------


# Registrar rutas
app.include_router(health_router, prefix="/health", tags=["health"])
app.include_router(variedad_router)
app.include_router(coleccion_router)
app.include_router(auth_router) 
app.include_router(users_router)
app.include_router(publicacion_router)
app.include_router(comentario_router)
app.include_router(ml_routes.router)