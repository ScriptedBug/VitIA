from sqlalchemy.orm import Session
from . import models, schemas

# --- CRUD para Variedades ---

def get_variedad_by_name(db: Session, nombre: str):
    """
    Obtiene una variedad por su nombre.
    """
    return db.query(models.Variedad).filter(models.Variedad.nombre == nombre).first()

def get_variedad(db: Session, variedad_id: int):
    
    return db.query(models.Variedad).filter(models.Variedad.id == variedad_id).first()

def get_variedades(db: Session, skip: int = 0, limit: int = 100):
    
    return db.query(models.Variedad).offset(skip).limit(limit).all()

def create_variedad(db: Session, variedad: schemas.VariedadCreate):
    """
    Crea una nueva variedad en la base de datos.
    """
    # 1. Convierte el schema Pydantic (variedad) 
    #    en un modelo SQLAlchemy (db_variedad)
    db_variedad = models.Variedad(
        nombre=variedad.nombre,
        descripcion=variedad.descripcion,
        region_origen=variedad.region_origen,
        color_uva=variedad.color_uva,
        imagen_referencia=variedad.imagen_referencia
    )
    
    # 2. Añade la nueva variedad a la sesión
    db.add(db_variedad)
    # 3. Confirma (guarda) los cambios en la DB
    db.commit()
    # 4. Refresca el objeto para obtener el 'id' generado por la DB
    db.refresh(db_variedad)
    
    return db_variedad