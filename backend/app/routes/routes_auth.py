# --- En tu archivo /app/routes/routes_auth.py ---

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from .. import crud, schemas, auth, security
from ..database import get_db

router = APIRouter(
    prefix="/auth",
    tags=["Autenticación"]
)

@router.post("/register", 
    response_model=schemas.Usuario, 
    status_code=status.HTTP_201_CREATED,
    summary="Registrar un nuevo usuario"
)
def register_user(user: schemas.UsuarioCreate, db: Session = Depends(get_db)):
    """Crea un nuevo usuario en la base de datos."""
    db_user = crud.get_user_by_email(db, email=user.email)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El correo electrónico ya está registrado"
        )
    
    # Hashea la contraseña antes de guardarla
    hashed_password = security.get_password_hash(user.password)
    
    # Llama a una nueva función CRUD (que crearemos en el paso 2)
    return crud.create_user(db=db, user=user, hashed_password=hashed_password)


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
    if not user or not security.verify_password(form_data.password, user.password_hash):
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