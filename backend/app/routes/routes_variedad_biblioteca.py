from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

# Importaciones relativas (gracias a la estructura de carpetas)
from .. import crud, models, schemas
from ..database import get_db

router = APIRouter(
    prefix="/variedades",  # Prefijo para todas las rutas de este archivo
    tags=["Variedades (Biblioteca)"] # Etiqueta para la documentación de Swagger
)

# -----------------------------------------------------
# ENDPOINTS PARA VARIEDADES (Biblioteca)
# -----------------------------------------------------

@router.post("/", 
    response_model=schemas.Variedad, 
    status_code=status.HTTP_201_CREATED,
    summary="Crear una nueva variedad"
)
def create_variedad_endpoint(
    variedad: schemas.VariedadCreate, 
    db: Session = Depends(get_db)
    # TODO: Añadir dependencia de autenticación (ej. solo para admins)
):
    """
    Crea una nueva variedad en la biblioteca general.
    - **nombre**: Nombre de la variedad (requerido)
    - **descripcion**: Texto descriptivo (requerido)
    """
    # Lógica de negocio: evitar duplicados
    db_variedad = crud.get_variedad_by_nombre(db, nombre=variedad.nombre)
    if db_variedad:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, 
            detail="Ya existe una variedad con este nombre"
        )
    
    # Llama a la función CRUD para crearla
    return crud.create_variedad(db=db, variedad=variedad)


@router.get("/", 
    response_model=List[schemas.Variedad],
    summary="Obtener lista de todas las variedades"
)
def read_variedades_endpoint(
    skip: int = 0, 
    limit: int = 100, 
    db: Session = Depends(get_db)
):
    """
    Devuelve una lista paginada de todas las variedades de la biblioteca.
    - **skip**: Número de registros a saltar.
    - **limit**: Número máximo de registros a devolver.
    """
    variedades = crud.get_variedades(db, skip=skip, limit=limit)
    return variedades


@router.get("/{id_variedad}", 
    response_model=schemas.Variedad,
    summary="Obtener una variedad por ID"
)
def read_variedad_endpoint(id_variedad: int, db: Session = Depends(get_db)):
    """
    Obtiene la información detallada de una única variedad por su ID.
    """
    db_variedad = crud.get_variedad(db, id_variedad=id_variedad)
    if db_variedad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Variedad no encontrada"
        )
    return db_variedad


@router.patch("/{id_variedad}", 
    response_model=schemas.Variedad,
    summary="Actualizar una variedad (Parcial)"
)
def update_variedad_endpoint(
    id_variedad: int, 
    variedad_update: schemas.VariedadUpdate,
    db: Session = Depends(get_db)
    # TODO: Añadir dependencia de autenticación (ej. solo para admins)
):
    """
    Actualiza parcialmente una variedad existente.
    Solo envía los campos que quieres modificar.
    """
    db_variedad = crud.get_variedad(db, id_variedad=id_variedad)
    if db_variedad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Variedad no encontrada"
        )
    
    # Llama a la función CRUD para actualizar
    return crud.update_variedad(db=db, db_variedad=db_variedad, variedad_update=variedad_update)


@router.delete("/{id_variedad}", 
    response_model=schemas.Variedad,
    summary="Eliminar una variedad"
)
def delete_variedad_endpoint(
    id_variedad: int, 
    db: Session = Depends(get_db)
    # TODO: Añadir dependencia de autenticación (ej. solo para admins)
):
    """
    Elimina una variedad de la base de datos usando su ID.
    Devuelve la variedad eliminada.
    """
    db_variedad = crud.delete_variedad(db, id_variedad=id_variedad)
    if db_variedad is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, 
            detail="Variedad no encontrada"
        )
    return db_variedad