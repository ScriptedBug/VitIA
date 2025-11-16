# --- Archivo NUEVO: /app/routes/routes_publicacion.py ---

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

# Importaciones relativas
from .. import crud, models, schemas
from ..database import get_db
from ..auth import get_current_user  # Importamos nuestra dependencia de autenticación

router = APIRouter(
    prefix="/publicaciones",
    tags=["Publicaciones (Foro)"]
)

@router.post("/",
    response_model=schemas.Publicacion,
    status_code=status.HTTP_201_CREATED,
    summary="Crear una nueva publicación en el foro"
)
def create_publicacion_endpoint(
    publicacion: schemas.PublicacionCreate,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Crea un nuevo post en el foro, asociado al usuario autenticado.
    
    - **titulo**: Título del post (requerido).
    - **texto**: Contenido del post (requerido).
    - **links_fotos**: Lista opcional de URLs de fotos (JSONB).
    """
    # Llama a la función CRUD, pasando el ID del usuario desde el token
    return crud.create_publicacion(
        db=db, 
        publicacion=publicacion, 
        id_usuario=current_user.id_usuario
    )

@router.get("/",
    response_model=List[schemas.Publicacion],
    summary="Obtener todas las publicaciones del foro (Feed)"
)
def read_publicaciones_endpoint(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """
    Obtiene una lista paginada de todas las publicaciones de todos los usuarios,
    ordenadas por fecha (la más reciente primero).
    
    Este es el endpoint principal para visualizar el "feed" del foro.
    """
    publicaciones = crud.get_publicaciones(db, skip=skip, limit=limit)
    return publicaciones

@router.get("/me",
    response_model=List[schemas.Publicacion],
    summary="Obtener todas las publicaciones del usuario actual"
)
def read_user_publicaciones_endpoint(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user),
    skip: int = 0,
    limit: int = 100
):
    """
    Obtiene una lista paginada de todas las publicaciones
    creadas por el usuario actualmente autenticado.
    
    Ordenadas por fecha (la más reciente primero).
    """
    return crud.get_user_publicaciones(
        db=db, 
        id_usuario=current_user.id_usuario, 
        skip=skip, 
        limit=limit
    )

@router.delete("/{id_publicacion}",
    response_model=schemas.Publicacion,
    summary="Eliminar una publicación del foro"
)
def delete_publicacion_endpoint(
    id_publicacion: int,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Elimina una publicación.
    
    - Solo el autor original de la publicación puede eliminarla.
    """
    # 1. Obtener la publicación
    db_publicacion = crud.get_publicacion(db, id_publicacion=id_publicacion)
    
    # 2. Verificar si existe
    if db_publicacion is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Publicación no encontrada"
        )
    
    # 3. Verificar que el usuario es el autor (¡Importante!)
    if db_publicacion.id_usuario != current_user.id_usuario:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="No tienes permiso para eliminar esta publicación"
        )
    
    # 4. Eliminar la publicación
    return crud.delete_publicacion(db=db, db_publicacion=db_publicacion)

# Nota: De momento no incluimos GET (obtener todas las publicaciones)
# pero sería el siguiente paso lógico para construir el foro.