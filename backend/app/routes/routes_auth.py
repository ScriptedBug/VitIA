# --- En tu archivo /app/routes/routes_auth.py ---

import os
from fastapi import APIRouter, Depends, HTTPException, status, Form, File, UploadFile
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import Optional

# Importar ImageKit (Asegúrate de tener esto configurado como en tus otras rutas)
from imagekitio import ImageKit
from ..config import settings # O donde tengas tus claves
import base64

# Inicializar ImageKit
imagekit = ImageKit(
    public_key=os.getenv("IMAGEKIT_PUBLIC_KEY"),
    private_key=os.getenv("IMAGEKIT_PRIVATE_KEY"),
    url_endpoint=os.getenv("IMAGEKIT_URL_ENDPOINT")
)

from .. import crud, models, schemas, auth
from ..database import get_db

router = APIRouter(
    prefix="/auth",
    tags=["Autenticación"]
)

@router.post("/register", response_model=schemas.Usuario)
def register_user(
    # 1. Recibimos los datos como FORM (ya no como JSON body automático)
    email: str = Form(...),
    password: str = Form(...),
    nombre: str = Form(...),
    apellidos: str = Form(...),
    ubicacion: Optional[str] = Form(None),
    
    # 2. Recibimos el archivo (Opcional)
    foto: Optional[UploadFile] = File(None),
    
    db: Session = Depends(get_db)
):
    """
    Registro de usuario con foto de perfil opcional.
    Usa multipart/form-data.
    """
    
    # A. Validar si el email ya existe
    db_user = crud.get_user_by_email(db, email=email)
    if db_user:
        raise HTTPException(status_code=400, detail="El email ya está registrado")

    # B. Subir foto a ImageKit (si el usuario envió una)
    url_foto = None
    if foto:
        try:
            # Leer el archivo
            file_content = foto.file.read()
            # Convertir a base64 para ImageKit
            file_base64 = base64.b64encode(file_content).decode("utf-8")
            
            # Subir
            upload_info = imagekit.upload_file(
                file=file_base64,
                file_name=f"perfil_{email}.jpg", # Nombre único
                options={
                    "folder": "/fotos_perfil/", # Carpeta ordenada
                    "is_private_file": False
                }
            )
            url_foto = upload_info.url
        except Exception as e:
            print(f"Error subiendo foto: {e}")
            # Opcional: ¿Quieres fallar si la foto falla? 
            # Si no, simplemente seguimos sin foto.
            pass

    # C. Crear el objeto UsuarioCreate manualmente para pasarlo al CRUD
    # (Hacemos esto para reutilizar tu función crud existente)
    user_data = schemas.UsuarioCreate(
        email=email,
        password=password,
        nombre=nombre,
        apellidos=apellidos,
        ubicacion=ubicacion
    )

    # D. Guardar en BD
    return crud.create_user(db=db, user=user_data, url_foto=url_foto)


@router.post("/token", 
    response_model=schemas.Token,
    summary="Iniciar sesión y obtener un token"
)
def login_for_access_token(
    db: Session = Depends(get_db),
    form_data: OAuth2PasswordRequestForm = Depends()
):
    """
    Endpoint de login.
    Recibe un 'username' (que será nuestro email) y 'password' 
    en un formulario, y devuelve un token de acceso.
    """
    user = crud.get_user_by_email(db, email=form_data.username)
    
    # Verifica que el usuario exista y la contraseña sea correcta
    if not user or not auth.verify_password(form_data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Crea el token. El "subject" (sub) será el ID del usuario
    access_token = auth.create_access_token(
        data={"sub": str(user.id_usuario)}
    )
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/logout",
    status_code=status.HTTP_200_OK,
    summary="Cerrar sesión (invalidar token en cliente)"
)
def logout_user(current_user: models.Usuario = Depends(auth.get_current_user)):
    """
    Endpoint para que el cliente notifique un cierre de sesión.
    
    El servidor no hace nada (al ser JWT stateless).
    El cliente DEBE eliminar el token localmente después de llamar a esto.
    """
    return {"msg": "Cierre de sesión exitoso. El token debe ser eliminado por el cliente."}