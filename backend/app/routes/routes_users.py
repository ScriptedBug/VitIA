# --- Archivo NUEVO: /app/routes/routes_user.py ---

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

# Importaciones relativas
from .. import crud, models, schemas
from ..database import get_db
from ..auth import get_current_user  # Importamos nuestra dependencia de autenticación

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