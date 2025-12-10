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

from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile, Form
from ..services.imagekit_service import upload_image_to_imagekit

# ... imports ...

@router.post("/",
    response_model=schemas.Publicacion,
    status_code=status.HTTP_201_CREATED,
    summary="Crear una nueva publicación en el foro"
)
async def create_publicacion_endpoint(
    titulo: str = Form(...),
    texto: str = Form(...),
    file: UploadFile = File(None),
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Crea un nuevo post en el foro, asociado al usuario autenticado.
    Soporta subida de imagen (Multipart).
    """
    links_fotos = []
    
    # 1. Si hay archivo, lo subimos
    if file:
        try:
            file_bytes = await file.read()
            # Guardamos en la carpeta específica del Foro
            image_url = upload_image_to_imagekit(file_bytes, file.filename, folder="/vitia/Foro")
            links_fotos.append(image_url)
        except Exception as e:
            print(f"Error subiendo a ImageKit: {e}")
            # Opcional: Fallar o continuar sin imagen. Aquí continuamos pero logueamos.

    # 2. Creamos el objeto esquema manually
    publicacion_create = schemas.PublicacionCreate(
        titulo=titulo,
        texto=texto,
        links_fotos=links_fotos
    )

    # 3. Llama a la función CRUD
    return crud.create_publicacion(
        db=db, 
        publicacion=publicacion_create, 
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

@router.post("/{id_publicacion}/like",
    response_model=schemas.Publicacion,
    summary="Dar like a una publicación"
)
def like_publicacion_endpoint(
    id_publicacion: int,
    db: Session = Depends(get_db),
    # Opcional: current_user: models.Usuario = Depends(get_current_user) si quisieras limitar a usuarios logueados
):
    """
    Incrementa el contador de likes de la publicación.
    """
    publicacion = crud.like_publicacion(db=db, id_publicacion=id_publicacion)
    if not publicacion:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    return publicacion

@router.post("/{id_publicacion}/unlike",
    response_model=schemas.Publicacion,
    summary="Quitar like a una publicación"
)
def unlike_publicacion_endpoint(
    id_publicacion: int,
    db: Session = Depends(get_db),
):
    """
    Decrementa el contador de likes de la publicación.
    """
    publicacion = crud.unlike_publicacion(db=db, id_publicacion=id_publicacion)
    if not publicacion:
        raise HTTPException(status_code=404, detail="Publicación no encontrada")
    return publicacion

# --- VOTOS ---
@router.post("/publicaciones/{id_publicacion}/voto", summary="Votar Publicación")
def votar_publicacion_endpoint(
    id_publicacion: int,
    voto: schemas.VotoCreate, # Recibe { "es_like": true/false/null }
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    - **es_like: true** -> Like
    - **es_like: false** -> Dislike
    - **es_like: null** -> Borrar voto (Neutro)
    """
    estado = crud.votar_publicacion(db, current_user.id_usuario, id_publicacion, voto.es_like)
    return {"msg": estado}
