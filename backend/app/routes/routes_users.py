# --- Archivo NUEVO: /app/routes/routes_user.py ---

from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from sqlalchemy.orm import Session
import os
import base64
from imagekitio import ImageKit

# Importaciones relativas
from .. import crud, models, schemas
from ..database import get_db
from ..auth import get_current_user  # Importamos nuestra dependencia de autenticación

# Inicializar ImageKit (Reutilizando configuración)
from imagekitio.models.UploadFileRequestOptions import UploadFileRequestOptions

# Inicializar ImageKit (Reutilizando configuración)
imagekit = ImageKit(
    public_key=os.getenv("IMAGEKIT_PUBLIC_KEY"),
    private_key=os.getenv("IMAGEKIT_PRIVATE_KEY"),
    url_endpoint=os.getenv("IMAGEKIT_URL_ENDPOINT")
)

router = APIRouter(
    prefix="/users",
    tags=["Usuarios"]
)

@router.get("/me", 
    response_model=schemas.Usuario,
    summary="Obtener el perfil del usuario actual"
)
def read_users_me(
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Devuelve la información completa del perfil del usuario
    que está actualmente autenticado.
    """
    # El objeto 'current_user' que devuelve la dependencia
    # ya es el modelo de SQLAlchemy, así que podemos devolverlo directamente.
    return current_user


@router.patch("/me", 
    response_model=schemas.Usuario,
    summary="Actualizar el perfil del usuario actual"
)
def update_users_me(
    user_update: schemas.UsuarioUpdate,
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Actualiza los datos (nombre, apellidos, email)
    del usuario actualmente autenticado.
    """
    # Lógica de negocio: Validar si el nuevo email ya existe
    if user_update.email:
        existing_user = crud.get_user_by_email(db, email=user_update.email)
        # Si el email existe Y NO pertenece al usuario actual
        if existing_user and existing_user.id_usuario != current_user.id_usuario:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Este correo electrónico ya está registrado por otro usuario."
            )
    
    # Llama a la función CRUD para actualizar
    updated_user = crud.update_user(db=db, db_user=current_user, user_update=user_update)
    return updated_user


@router.delete("/me",
    response_model=schemas.Usuario,
    summary="Eliminar la cuenta del usuario actual"
)
def delete_users_me(
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Elimina permanentemente la cuenta del usuario
    actualmente autenticado.
    
    NOTA: Gracias a 'ON DELETE CASCADE' en la BBDD,
    esto también eliminará automáticamente:
    - Todos los items de su colección.
    - Todas sus publicaciones en el foro.
    """
    deleted_user = crud.delete_user(db, id_usuario=current_user.id_usuario)
    return deleted_user


@router.post("/me/avatar", response_model=schemas.Usuario, summary="Subir o actualizar foto de perfil")
def upload_avatar_me(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: models.Usuario = Depends(get_current_user)
):
    """
    Sube una nueva foto de perfil a ImageKit y actualiza la URL en el usuario.
    """
    if not file:
        raise HTTPException(status_code=400, detail="No se ha enviado ningún archivo")

    try:
        # 1. Leer y codificar archivo
        file_content = file.file.read()
        file_base64 = base64.b64encode(file_content).decode("utf-8")
        
        # 2. Subir a ImageKit
        upload_info = imagekit.upload_file(
            file=file_base64,
            file_name=f"perfil_{current_user.email}.jpg", # Sobreescribir o versionar
            options=UploadFileRequestOptions(
                folder="/fotos_perfil/",
                is_private_file=False,
                use_unique_file_name=True 
            )
        )
        
        # 3. Obtener URL
        new_url = upload_info.url
        
        # 4. Actualizar usuario en BD
        # Usamos crud.update_user con un esquema parcial
        update_data = schemas.UsuarioUpdate(path_foto_perfil=new_url)
        updated_user = crud.update_user(db=db, db_user=current_user, user_update=update_data)
        
        return updated_user
        
    except Exception as e:
        print(f"Error subiendo avatar: {e}")
        raise HTTPException(status_code=500, detail="Error al subir la imagen")