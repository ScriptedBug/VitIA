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
# Funciones CRUD para Coleccion (Personal)
# -----------------------------------------------------

def create_coleccion_item(db: Session, item: schemas.ColeccionCreate, id_usuario: int):
    """Crea un nuevo item en la colección de un usuario."""
    # **item.model_dump() coge 'path_foto_usuario' y 'id_variedad' del schema
    db_item = models.Coleccion(
        **item.model_dump(),
        id_usuario=id_usuario  # Añadimos el ID del usuario autenticado
    )
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

def get_user_coleccion(db: Session, id_usuario: int, skip: int = 0, limit: int = 100):
    """Obtiene una lista paginada de la colección de un usuario."""
    return db.query(models.Coleccion)\
             .filter(models.Coleccion.id_usuario == id_usuario)\
             .offset(skip)\
             .limit(limit)\
             .all()

def get_coleccion_item(db: Session, id_coleccion: int, id_usuario: int):
    """
    Obtiene un item específico de la colección,
    asegurándose de que pertenece al usuario.
    """
    return db.query(models.Coleccion).filter(
        models.Coleccion.id_coleccion == id_coleccion,
        models.Coleccion.id_usuario == id_usuario
    ).first()

def delete_coleccion_item(db: Session, id_coleccion: int, id_usuario: int):
    """
    Elimina un item de la colección,
    asegurándose de que pertenece al usuario.
    """
    db_item = get_coleccion_item(db, id_coleccion, id_usuario)
    
    if db_item:
        db.delete(db_item)
        db.commit()
    return db_item

def update_coleccion_item(
    db: Session, 
    db_item: models.Coleccion, 
    item_update: schemas.ColeccionUpdate
):
    """
    Actualiza un item de la colección.
    Usa model_dump(exclude_unset=True) para actualizar solo los campos enviados.
    """
    update_data = item_update.model_dump(exclude_unset=True)
    
    for key, value in update_data.items():
        setattr(db_item, key, value)
    
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item

# -----------------------------------------------------
# Funciones CRUD para Usuario (NUEVAS)
# -----------------------------------------------------

def get_user(db: Session, id_usuario: int):
    """Obtiene un usuario por su ID."""
    return db.query(models.Usuario).filter(models.Usuario.id_usuario == id_usuario).first()

def get_user_by_email(db: Session, email: str):
    """Obtiene un usuario por su email."""
    return db.query(models.Usuario).filter(models.Usuario.email == email).first()

def create_user(db: Session, user: schemas.UsuarioCreate, hashed_password: str):
    """Crea un nuevo usuario con la contraseña ya hasheada."""
    db_user = models.Usuario(
        email=user.email,
        nombre=user.nombre,
        apellidos=user.apellidos,
        password_hash=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def update_user(db: Session, db_user: models.Usuario, user_update: schemas.UsuarioUpdate):
    """
    Actualiza un usuario.
    Usa model_dump(exclude_unset=True) para actualizar solo los campos enviados.
    """
    update_data = user_update.model_dump(exclude_unset=True)
    
    for key, value in update_data.items():
        setattr(db_user, key, value)
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user


def delete_user(db: Session, id_usuario: int):
    """
    Elimina un usuario de la base de datos.
    """
    db_user = get_user(db, id_usuario=id_usuario)
    if db_user:
        db.delete(db_user)
        db.commit()
    return db_user

# -----------------------------------------------------
# Funciones CRUD para Publicaciones (Foro)
# -----------------------------------------------------

def create_publicacion(db: Session, publicacion: schemas.PublicacionCreate, id_usuario: int):
    """Crea una nueva publicación en el foro."""
    db_publicacion = models.Publicacion(
        **publicacion.model_dump(),
        id_usuario=id_usuario
    )
    db.add(db_publicacion)
    db.commit()
    db.refresh(db_publicacion)
    return db_publicacion

def get_publicacion(db: Session, id_publicacion: int):
    """Obtiene una publicación por su ID."""
    return db.query(models.Publicacion).filter(models.Publicacion.id_publicacion == id_publicacion).first()

def delete_publicacion(db: Session, db_publicacion: models.Publicacion):
    """Elimina una publicación de la base de datos."""
    db.delete(db_publicacion)
    db.commit()
    return db_publicacion

def get_publicaciones(db: Session, skip: int = 0, limit: int = 100):
    """Obtiene una lista paginada de todas las publicaciones del foro."""
    return db.query(models.Publicacion)\
             .order_by(models.Publicacion.fecha_publicacion.desc())\
             .offset(skip)\
             .limit(limit)\
             .all()

def get_user_publicaciones(db: Session, id_usuario: int, skip: int = 0, limit: int = 100):
    """Obtiene una lista paginada de las publicaciones de un usuario específico."""
    return db.query(models.Publicacion)\
             .filter(models.Publicacion.id_usuario == id_usuario)\
             .order_by(models.Publicacion.fecha_publicacion.desc())\
             .offset(skip)\
             .limit(limit)\
             .all()