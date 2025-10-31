from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app import crud, models, schemas
# Importa la función para obtener la sesión de la DB
from app.supabase_client import get_db # ¡Importante! (Ver Paso 3)

# Creamos un router específico para las variedades
router = APIRouter()

@router.post(
    "/", 
    response_model=schemas.Variedad, 
    status_code=status.HTTP_201_CREATED
)
def crear_nueva_variedad(
    variedad: schemas.VariedadCreate, # 1. Valida el JSON de entrada
    db: Session = Depends(get_db)       # 2. Inyecta la sesión de la DB
):
    """
    Crea una nueva variedad en la biblioteca.
    El nombre debe ser único.
    """
    # 3. Lógica de negocio (del crud.py)
    # Comprobamos si ya existe
    db_variedad = crud.get_variedad_by_name(db, nombre=variedad.nombre)
    if db_variedad:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Ya existe una variedad con este nombre."
        )
    
    # 4. Si no existe, la creamos llamando al crud
    return crud.create_variedad(db=db, variedad=variedad)

@router.get("/", response_model=List[schemas.Variedad])
def leer_variedades(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    """
    Obtiene una lista de todas las variedades.
    """
    variedades = crud.get_variedades(db, skip=skip, limit=limit)
    return variedades

@router.get("/{variedad_id}", response_model=schemas.Variedad)
def leer_variedad(
    variedad_id: int, 
    db: Session = Depends(get_db)
):
    """
    Obtiene una variedad por su ID.
    """
    db_variedad = crud.get_variedad(db, variedad_id=variedad_id)
    if db_variedad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Variedad no encontrada."
        )
    return db_variedad

@router.delete("/{variedad_id}", status_code=status.HTTP_204_NO_CONTENT)
def eliminar_variedad(
    variedad_id: int, 
    db: Session = Depends(get_db)
):
    """
    Elimina una variedad por su ID.
    """
    db_variedad = crud.get_variedad(db, variedad_id=variedad_id)
    if db_variedad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Variedad no encontrada."
        )
    crud.delete_variedad(db, variedad_id=variedad_id)
    return
@router.put("/{variedad_id}", response_model=schemas.Variedad)
def actualizar_variedad(
    variedad_id: int,
    variedad: schemas.VariedadUpdate,
    db: Session = Depends(get_db)
):
    """
    Actualiza una variedad por su ID.
    """
    db_variedad = crud.get_variedad(db, variedad_id=variedad_id)
    if db_variedad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Variedad no encontrada."
        )
    return crud.update_variedad(db, variedad_id=variedad_id, variedad=variedad)