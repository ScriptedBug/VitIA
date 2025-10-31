"""
Este archivo contiene todos los schemas de Pydantic para la validación
de datos de entrada y salida de la API.

- 'Base':    Campos comunes, compartidos por Create y Read.
- 'Create':  Campos requeridos al crear un nuevo objeto (entrada API).
- 'Update':  Campos que se pueden actualizar (entrada API).
- (Clase principal, ej: 'Perfil'): Modelo de lectura (salida API), 
           normalmente incluye 'id' y campos generados por la BD.
"""

from pydantic import BaseModel
from uuid import UUID
from datetime import datetime
from typing import Optional # Usado en versiones antiguas de Python

# --- Schemas para 'perfiles' ---

class PerfilBase(BaseModel):
    # El nombre puede ser opcional al principio
    nombre: str | None = None 
    
    # es_premium y fecha_registro son gestionados por la BD o lógica interna.
    # No los pedimos en 'Create' o 'Update' por defecto.

class PerfilUpdate(BaseModel):
    # El único campo que el usuario puede actualizar
    nombre: str | None = None

class Perfil(PerfilBase):
    # Modelo de lectura (salida API)
    id: UUID
    es_premium: bool
    fecha_registro: datetime

    class Config:
        orm_mode = True

# --- Schemas para 'variedades' ---

class VariedadBase(BaseModel):
    nombre: str
    descripcion: str | None = None
    region_origen: str | None = None
    color_uva: str | None = None
    imagen_referencia: str | None = None

class VariedadCreate(VariedadBase):
    # Para crear una variedad (quizás un admin)
    pass

class VariedadUpdate(BaseModel):
    # Hacemos todos los campos opcionales
    nombre: str | None = None
    descripcion: str | None = None
    region_origen: str | None = None
    color_uva: str | None = None
    imagen_referencia: str | None = None

class Variedad(VariedadBase):
    # Modelo de lectura (salida API)
    id: int

    class Config:
        orm_mode = True

# --- Schemas para 'parcelas' ---

class ParcelaBase(BaseModel):
    nombre: str
    descripcion: str | None = None
    ubicacion: str | None = None
    # Usamos float para lat/lon en la API, es más fácil que Decimal
    latitud: float | None = None
    longitud: float | None = None

class ParcelaCreate(ParcelaBase):
    # Modelo de entrada (POST)
    # 'usuario_id' se obtendrá del token, no del body.
    # 'fecha_creacion' e 'id' los pone la BD.
    pass

class ParcelaUpdate(BaseModel):
    # Modelo de entrada (PUT/PATCH)
    # Hacemos todos los campos opcionales
    nombre: str | None = None
    descripcion: str | None = None
    ubicacion: str | None = None
    latitud: float | None = None
    longitud: float | None = None

class Parcela(ParcelaBase):
    # Modelo de lectura (salida API)
    id: int
    usuario_id: UUID
    fecha_creacion: datetime

    class Config:
        orm_mode = True

# --- Schemas para 'fotos' ---

class FotoBase(BaseModel):
    ruta_imagen: str # URL del storage
    parcela_id: int | None = None
    latitud: float | None = None
    longitud: float | None = None
    
    # La fecha de captura podría venir del móvil
    fecha_captura: datetime | None = None 

class FotoCreate(FotoBase):
    # Modelo de entrada (POST)
    # 'usuario_id' vendrá del token
    # Los campos de IA (prediccion, prob, procesada) se rellenan después
    pass

class FotoUpdate(BaseModel):
    # Schema para cuando la IA procesa la foto
    variedad_predicha_id: int | None = None
    probabilidad: float | None = None # Usamos float, no Decimal
    procesada: bool | None = None
    # También permitimos cambiar la parcela
    parcela_id: int | None = None

class Foto(FotoBase):
    # Modelo de lectura (salida API)
    id: int
    usuario_id: UUID
    variedad_predicha_id: int | None = None
    probabilidad: float | None = None
    procesada: bool
    # La fecha_captura tendrá un valor de la BD si no se proveyó
    fecha_captura: datetime

    class Config:
        orm_mode = True

# --- Schemas para 'clasificaciones' ---

class ClasificacionBase(BaseModel):
    foto_id: int
    modelo: str | None = "vitia_model_v1"
    variedad_predicha_id: int | None = None
    probabilidad: float | None = None # Usamos float

class ClasificacionCreate(ClasificacionBase):
    # Modelo de entrada (POST)
    pass

class Clasificacion(ClasificacionBase):
    # Modelo de lectura (salida API)
    id: int
    fecha_clasificacion: datetime

    class Config:
        orm_mode = True

# --- Schemas para VISTAS ('vista_fotos_detalle') ---

class VistaFotosDetalle(BaseModel):
    # Este es un modelo de SOLO LECTURA
    foto_id: int
    parcela: str | None = None
    variedad_predicha: str | None = None
    probabilidad: float | None = None
    ruta_imagen: str
    latitud: float | None = None
    longitud: float | None = None
    fecha_captura: datetime

    class Config:
        orm_mode = True
