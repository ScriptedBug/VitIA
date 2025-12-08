# tests/test_coleccion_security.py
from app import crud, schemas, models

def test_aislamiento_coleccion_usuarios(db_session):
    """
    Requisito: "En la colección solo se muestran las propias del usuario"
    """
    # 1. Setup: Crear 2 usuarios y 1 variedad
    user1 = crud.create_user(db_session, schemas.UsuarioCreate(email="u1@test.com", nombre="U1", apellidos="A", password="p"), "hash")
    user2 = crud.create_user(db_session, schemas.UsuarioCreate(email="u2@test.com", nombre="U2", apellidos="B", password="p"), "hash")
    variedad = crud.create_variedad(db_session, schemas.VariedadCreate(nombre="Uva Test", descripcion="Desc"))

    # 2. Acción: User 1 añade un item a su colección
    item_create = schemas.ColeccionCreate(
        path_foto_usuario="s3://foto1.jpg", 
        id_variedad=variedad.id_variedad,
        notas="Nota de Usuario 1"
    )
    crud.create_coleccion_item(db_session, item_create, id_usuario=user1.id_usuario)

    # 3. Validación (Asserts)
    
    # La colección del Usuario 1 debe tener 1 elemento
    col_u1 = crud.get_user_coleccion(db_session, id_usuario=user1.id_usuario)
    assert len(col_u1) == 1
    assert col_u1[0].notas == "Nota de Usuario 1"

    # La colección del Usuario 2 debe estar VACÍA (CRÍTICO)
    col_u2 = crud.get_user_coleccion(db_session, id_usuario=user2.id_usuario)
    assert len(col_u2) == 0

    # Intento de acceso cruzado (Hacking simulado)
    # User 2 intenta leer el item específico del User 1
    item_robado = crud.get_coleccion_item(db_session, id_coleccion=col_u1[0].id_coleccion, id_usuario=user2.id_usuario)
    assert item_robado is None  # Debe devolver None, no el objeto