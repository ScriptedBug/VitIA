# --- En tu archivo /app/crud.py ---

from sqlalchemy.orm import Session
from . import models, schemas

# -----------------------------------------------------
# Funciones CRUD para Variedad (Biblioteca)
# -----------------------------------------------------

def get_variedad(db: Session, id_variedad: int):
    """Obtiene una variedad específica por su ID."""
    return db.query(models.Variedad).filter(models.Variedad.id_variedad == id_variedad).first()

def get_variedad_by_nombre(db: Session, nombre: str):
    """Obtiene una variedad específica por su nombre (para evitar duplicados)."""
    return db.query(models.Variedad).filter(models.Variedad.nombre == nombre).first()

def get_variedades(db: Session, skip: int = 0, limit: int = 100):
    """Obtiene una lista paginada de todas las variedades."""
    return db.query(models.Variedad).offset(skip).limit(limit).all()

def create_variedad(db: Session, variedad: schemas.VariedadCreate):
    """Crea una nueva variedad en la base de datos."""
    db_variedad = models.Variedad(**variedad.model_dump())
    db.add(db_variedad)
    db.commit()
    db.refresh(db_variedad)
    return db_variedad

def update_variedad(db: Session, db_variedad: models.Variedad, variedad_update: schemas.VariedadUpdate):
    """
    Actualiza una variedad existente.
    Usa model_dump(exclude_unset=True) para solo actualizar los campos
    que se enviaron en la petición (clave para PATCH).
    """
    update_data = variedad_update.model_dump(exclude_unset=True)
    
    for key, value in update_data.items():
        setattr(db_variedad, key, value)
    
    db.add(db_variedad) # Opcional si ya está en la sesión
    db.commit()
    db.refresh(db_variedad)
    return db_variedad

def delete_variedad(db: Session, id_variedad: int):
    """Elimina una variedad de la base de datos."""
    db_variedad = db.query(models.Variedad).filter(models.Variedad.id_variedad == id_variedad).first()
    if db_variedad:
        db.delete(db_variedad)
        db.commit()
    return db_variedad

# -----------------------------------------------------
# ... Aquí irían las funciones CRUD para Usuario, Coleccion, etc. ...
# -----------------------------------------------------