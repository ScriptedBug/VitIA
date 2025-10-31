"""
Este archivo contiene los modelos de SQLAlchemy.

Cada clase aquí representa una tabla en tu base de datos (Supabase/PostgreSQL).
Estos modelos son utilizados por el ORM (SQLAlchemy) para interactuar
directamente con la base de datos (leer, escribir, actualizar).

- Difiere de 'schemas.py' (Pydantic), que es para la validación de la API.
- Los tipos de datos (Column, Integer, String, DECIMAL) deben coincidir
  con los de tu base de datos.
- Las 'relationships' definen cómo se conectan las tablas (ej. un usuario
  tiene muchas parcelas).
"""

from sqlalchemy import (
    Column, Integer, String, Boolean, ForeignKey, 
    DECIMAL, TEXT, TIMESTAMP
)
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func # Para server_default='now()'

# Importamos 'Base' de nuestro archivo 'supabase_client.py'
from .supabase_client import Base 

# --- Modelo para 'perfiles' ---
# Esta tabla "extiende" auth.users
class Perfil(Base):
    __tablename__ = "perfiles"

    # 'id' es la clave primaria y también una clave foránea
    # al 'id' de la tabla 'auth.users' de Supabase.
    id = Column(UUID(as_uuid=True), primary_key=True, index=True)
    nombre = Column(String(100), nullable=True)
    es_premium = Column(Boolean, server_default="false", default=False)
    fecha_registro = Column(TIMESTAMP(timezone=False), server_default=func.now())

    # --- Relaciones (inversas) ---
    # Un perfil (usuario) puede tener múltiples parcelas y fotos
    parcelas = relationship("Parcela", back_populates="usuario")
    fotos = relationship("Foto", back_populates="usuario")

# --- Modelo para 'variedades' ---
# Este es un catálogo global
class Variedad(Base):
    __tablename__ = "variedades"

    id = Column(Integer, primary_key=True, index=True)
    nombre = Column(String(100), unique=True, nullable=False)
    descripcion = Column(TEXT, nullable=True)
    region_origen = Column(String(150), nullable=True)
    color_uva = Column(String(50), nullable=True)
    imagen_referencia = Column(TEXT, nullable=True)

    # (Opcional) Relaciones inversas si quisiéramos ver qué fotos
    # o clasificaciones usan esta variedad.
    # fotos_predichas = relationship("Foto", back_populates="variedad_predicha")
    # clasificaciones_predichas = relationship("Clasificacion", back_populates="variedad_predicha")

# --- Modelo para 'parcelas' ---
class Parcela(Base):
    __tablename__ = "parcelas"

    id = Column(Integer, primary_key=True, index=True)
    # Establecemos la relación con 'perfiles.id'
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("perfiles.id", ondelete="CASCADE"), nullable=False, index=True)
    nombre = Column(String(150), nullable=False)
    descripcion = Column(TEXT, nullable=True)
    ubicacion = Column(String(255), nullable=True)
    latitud = Column(DECIMAL(9, 6), nullable=True)
    longitud = Column(DECIMAL(9, 6), nullable=True)
    fecha_creacion = Column(TIMESTAMP(timezone=False), server_default=func.now())

    # --- Relaciones ---
    # 'usuario' vincula esta parcela de vuelta al perfil/usuario
    usuario = relationship("Perfil", back_populates="parcelas")
    # 'fotos' vincula esta parcela a todas sus fotos
    fotos = relationship("Foto", back_populates="parcela")

# --- Modelo para 'fotos' ---
class Foto(Base):
    __tablename__ = "fotos"

    id = Column(Integer, primary_key=True, index=True)
    usuario_id = Column(UUID(as_uuid=True), ForeignKey("perfiles.id", ondelete="CASCADE"), nullable=False, index=True)
    parcela_id = Column(Integer, ForeignKey("parcelas.id", ondelete="SET NULL"), nullable=True)
    ruta_imagen = Column(TEXT, nullable=False)
    latitud = Column(DECIMAL(9, 6), nullable=True)
    longitud = Column(DECIMAL(9, 6), nullable=True)
    fecha_captura = Column(TIMESTAMP(timezone=False), server_default=func.now())
    variedad_predicha_id = Column(Integer, ForeignKey("variedades.id"), nullable=True)
    probabilidad = Column(DECIMAL(5, 4), nullable=True)
    procesada = Column(Boolean, server_default="false", default=False)

    # --- Relaciones ---
    usuario = relationship("Perfil", back_populates="fotos")
    parcela = relationship("Parcela", back_populates="fotos")
    variedad_predicha = relationship("Variedad") # Relación simple (solo ida)
    
    # Esta foto puede tener muchas clasificaciones
    clasificaciones = relationship("Clasificacion", back_populates="foto", cascade="all, delete-orphan")

# --- Modelo para 'clasificaciones' ---
class Clasificacion(Base):
    __tablename__ = "clasificaciones"

    id = Column(Integer, primary_key=True, index=True)
    foto_id = Column(Integer, ForeignKey("fotos.id", ondelete="CASCADE"), nullable=False, index=True)
    modelo = Column(String(100), default="vitia_model_v1")
    variedad_predicha_id = Column(Integer, ForeignKey("variedades.id"), nullable=True)
    probabilidad = Column(DECIMAL(5, 4), nullable=True)
    fecha_clasificacion = Column(TIMESTAMP(timezone=False), server_default=func.now())

    # --- Relaciones ---
    foto = relationship("Foto", back_populates="clasificaciones")
    variedad_predicha = relationship("Variedad") # Relación simple (solo ida)

# NOTA SOBRE LAS VISTAS (ej. 'vista_fotos_detalle'):
# SQLAlchemy ORM (este archivo) no define VISTAS.
# Las vistas se consultan directamente desde tu archivo 'crud.py',
# por ejemplo: db.execute(text("SELECT * FROM vista_fotos_detalle"))
# y el resultado se mapea al schema 'schemas.VistaFotosDetalle'.

