# --- En tu archivo /app/auth.py ---

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from datetime import datetime, timedelta, timezone
from typing import Optional

from . import schemas, crud, models
from .database import get_db
from .config import settings
from sqlalchemy.orm import Session

# Esta es la "URL" que FastAPI usará para saber dónde está el endpoint de login
# "token" es la URL que crearemos en routes_auth.py
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/token")

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Crea un nuevo token de acceso JWT."""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        # Usa el tiempo de expiración del archivo de configuración
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def get_current_user(
    token: str = Depends(oauth2_scheme), 
    db: Session = Depends(get_db)
) -> models.Usuario:
    """
    Dependencia para obtener el usuario actual.
    Valida el token, decodifica el ID y devuelve el usuario de la BBDD.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="No se pudieron validar las credenciales",
        headers={"WWW-Authenticate": "Bearer"},
    )
    
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        
        # El "sub" (subject) de nuestro token será el ID del usuario
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
        
        # Usamos el schema TokenData para validar el tipo de ID
        token_data = schemas.TokenData(id_usuario=int(user_id))
    
    except (JWTError, ValueError):
        raise credentials_exception
    
    # Obtenemos el usuario de la BBDD
    user = crud.get_user(db, id_usuario=token_data.id_usuario)
    if user is None:
        raise credentials_exception
    
    return user