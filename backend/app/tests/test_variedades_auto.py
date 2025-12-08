# backend/app/tests/test_variedades_auto.py
from hypothesis import given, strategies as st, settings, HealthCheck
from app import crud, schemas

# AÑADIMOS @settings para suprimir el aviso de "HealthCheck"
@settings(suppress_health_check=[HealthCheck.function_scoped_fixture])
@given(
    nombre=st.text(min_size=1, max_size=150), 
    descripcion=st.text(min_size=1)
)
def test_create_variedad_fuzzing(db_session, nombre, descripcion):
    """
    Validación automática: Intenta crear variedades con todo tipo de texto.
    """
    variedad_in = schemas.VariedadCreate(
        nombre=nombre, 
        descripcion=descripcion,
        links_imagenes=["http://fake.url/img.jpg"]
    )
    
    # Ejecutamos la función a validar
    variedad = crud.create_variedad(db_session, variedad_in)
    
    # Aserciones
    assert variedad.nombre == nombre
    assert variedad.descripcion == descripcion
    assert variedad.id_variedad is not None