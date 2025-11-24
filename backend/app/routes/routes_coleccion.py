# --- Reemplaza el contenido de /app/routes/routes_coleccion.py con esto ---

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List

# Importaciones relativas
from .. import crud, models, schemas
from ..database import get_db
from ..auth import get_current_user  # <-- ¡Importamos el REAL!
from ..services.imagekit_service import upload_image_to_imagekit
from datetime import datetime

router = APIRouter(
    prefix="/coleccion",
    tags=["Colección (Personal)"]
)

# -----------------------------------------------------
# ENDPOINTS PARA COLECCIÓN (Ahora con autenticación real)
# -----------------------------------------------------

@router.post("/", 
    response_model=schemas.Coleccion,
    status_code=status.HTTP_201_CREATED,
    summary="Añadir un item a la colección personal"
)
def create_coleccion_item_endpoint(
    item: schemas.ColeccionCreate,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user) # <-- Dependencia real
):
    return crud.create_coleccion_item(db=db, item=item, id_usuario=current_user.id_usuario)


@router.get("/",
    response_model=List[schemas.Coleccion],
    summary="Obtener la colección personal del usuario"
)
def read_user_coleccion_endpoint(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user) # <-- Dependencia real
):
    return crud.get_user_coleccion(db=db, id_usuario=current_user.id_usuario, skip=skip, limit=limit)


@router.get("/{id_coleccion}",
    response_model=schemas.Coleccion,
    summary="Obtener un item específico de la colección"
)
def read_coleccion_item_endpoint(
    id_coleccion: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user) # <-- Dependencia real
):
    db_item = crud.get_coleccion_item(db=db, id_coleccion=id_coleccion, id_usuario=current_user.id_usuario)
    if db_item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item de colección no encontrado o no pertenece al usuario"
        )
    return db_item


@router.patch("/{id_coleccion}",
    response_model=schemas.Coleccion,
    summary="Actualizar un item de la colección (Parcial)"
)
def update_coleccion_item_endpoint(
    id_coleccion: int,
    item_update: schemas.ColeccionUpdate,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user) # <-- Dependencia real
):
    """
    Actualiza un item de la colección (ej. cambiar la foto o la variedad).
    Solo el propietario puede actualizar.
    """
    db_item = crud.get_coleccion_item(db=db, id_coleccion=id_coleccion, id_usuario=current_user.id_usuario)
    if db_item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item de colección no encontrado o no pertenece al usuario"
        )
    
    return crud.update_coleccion_item(db=db, db_item=db_item, item_update=item_update)


@router.delete("/{id_coleccion}",
    response_model=schemas.Coleccion,
    summary="Eliminar un item de la colección"
)
def delete_coleccion_item_endpoint(
    id_coleccion: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user) # <-- Dependencia real
):
    db_item = crud.delete_coleccion_item(db=db, id_coleccion=id_coleccion, id_usuario=current_user.id_usuario)
    if db_item is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Item de colección no encontrado o no pertenece al usuario"
        )
    return db_item

@router.post("/upload", response_model=schemas.Coleccion)
async def create_coleccion_with_image(
    file: UploadFile = File(...),
    id_variedad: int = Form(...),
    notas: str = Form(None),
    latitud: float = Form(None),
    longitud: float = Form(None),
    current_user: models.Usuario = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Recibe una imagen y datos, sube la imagen a ImageKit y guarda el registro en BD.
    """
    # 1. Leer el archivo
    file_bytes = await file.read()
    
    try:
        # 2. Subir a ImageKit
        image_url = upload_image_to_imagekit(file_bytes, file.filename)
    except Exception as e:
        raise HTTPException(status_code=500, detail="Error al subir la imagen al servidor de archivos")

    # 3. Crear registro en la Base de Datos (Neon)
    nuevo_item = models.Coleccion(
        id_usuario=current_user.id_usuario,
        id_variedad=id_variedad,
        path_foto_usuario=image_url, # Guardamos la URL de ImageKit, no la foto
        fecha_captura=datetime.utcnow(),
        notas=notas,
        latitud=latitud,
        longitud=longitud
    )
    
    db.add(nuevo_item)
    db.commit()
    db.refresh(nuevo_item)
    
    return nuevo_item