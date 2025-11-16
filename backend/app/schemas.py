# --- En tu archivo /app/schemas.py ---

from pydantic import BaseModel, ConfigDict, EmailStr
from typing import Optional, List, Dict, Any
from datetime import datetime

# -----------------------------------------------------
# Configuración Base de Pydantic
# -----------------------------------------------------

class BaseConfig(BaseModel):
    """Configuración base para todos los esquemas.
    
    from_attributes=True (antes orm_mode) le dice a Pydantic
    que lea los datos incluso si son de un modelo de SQLAlchemy
    (ej. usuario.id) y no solo un diccionario (ej. usuario['id']).
    """
    model_config = ConfigDict(from_attributes=True)

# -----------------------------------------------------
# Esquemas: Variedad (Biblioteca)
# -----------------------------------------------------

class VariedadBase(BaseModel):
    """Campos base que comparte una Variedad."""
    nombre: str
    descripcion: str
    # Usamos 'Any' para el JSONB, o puedes ser más específico
    # con List[str] para links_imagenes y Dict[str, Any] para info_extra
    links_imagenes: Optional[List[str]] = None 
    info_extra: Optional[Dict[str, Any]] = None

class VariedadCreate(VariedadBase):
    """Esquema para crear una nueva Variedad (usado por un admin)."""
    # No necesita campos extra, hereda todo de Base
    pass

# --- En tu archivo /app/schemas.py ---
# ... (junto a tus otras clases de Variedad) ...

class VariedadUpdate(BaseModel):
    """
    Esquema para actualizar una Variedad.
    Todos los campos son opcionales para permitir 
    actualizaciones parciales (método PATCH).
    """
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    links_imagenes: Optional[List[str]] = None
    info_extra: Optional[Dict[str, Any]] = None

class Variedad(VariedadBase, BaseConfig):
    """Esquema para LEER una Variedad (lo que se devuelve al usuario)."""
    id_variedad: int

# -----------------------------------------------------
# Esquemas: Coleccion (Personal del Usuario)
# -----------------------------------------------------

class ColeccionBase(BaseModel):
    """Campo base para un item de la colección."""
    path_foto_usuario: str

class ColeccionCreate(ColeccionBase):
    """Esquema para crear un item en la colección.
    
    En tu endpoint, probablemente recibirás el id_variedad 
    por separado, no en este body.
    """
    id_variedad: int
    # El id_usuario se obtendrá del token de autenticación,
    # no se le pide al usuario.

class Coleccion(ColeccionBase, BaseConfig):
    """Esquema para LEER un item de la colección."""
    id_coleccion: int
    fecha_captura: datetime
    
    # --- Relación Anidada ---
    # Al leer un item de la colección, queremos ver
    # la información completa de la variedad, no solo su ID.
    variedad: Variedad 

# -----------------------------------------------------
# Esquemas: Publicacion (Foro)
# -----------------------------------------------------

class PublicacionBase(BaseModel):
    """Campos base para una publicación del foro."""
    titulo: str
    texto: str
    links_fotos: Optional[List[str]] = None

class PublicacionCreate(PublicacionBase):
    """Esquema para CREAR una publicación."""
    # El id_usuario se obtendrá del token, no del body
    pass

# --- Esquema intermedio para el autor ---
class AutorPublicacion(BaseConfig):
    """Un esquema reducido para mostrar solo info pública del autor."""
    id_usuario: int
    nombre: str
    apellidos: str

class Publicacion(PublicacionBase, BaseConfig):
    """Esquema para LEER una publicación."""
    id_publicacion: int
    fecha_publicacion: datetime
    
    # --- Relación Anidada ---
    # Mostramos la información del autor usando el esquema reducido
    autor: AutorPublicacion

# -----------------------------------------------------
# Esquemas: Usuario
# -----------------------------------------------------

class UsuarioBase(BaseModel):
    """Campos base del usuario."""
    email: EmailStr  # Pydantic valida que sea un email válido
    nombre: str
    apellidos: str

class UsuarioCreate(UsuarioBase):
    """Esquema para CREAR un usuario (registro)."""
    # El usuario envía 'password', NO 'password_hash'
    password: str

class Usuario(UsuarioBase, BaseConfig):
    """Esquema para LEER la info de un usuario (perfil)."""
    id_usuario: int
    es_premium: bool
    fecha_registro: datetime
    
    # --- Relaciones Anidadas ---
    # Al ver el perfil de un usuario, mostramos sus publicaciones
    # y los items de su colección.
    publicaciones: List[Publicacion] = []
    coleccion: List[Coleccion] = []

# -----------------------------------------------------
# Esquemas: Autenticación (Login)
# -----------------------------------------------------

class Token(BaseModel):
    """Esquema para devolver un Token JWT al usuario."""
    access_token: str
    token_type: str

class TokenData(BaseModel):
    """Esquema para los datos contenidos dentro del Token JWT."""
    email: Optional[str] = None
    id_usuario: Optional[int] = None