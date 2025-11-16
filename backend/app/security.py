# --- En tu archivo /app/security.py (NUEVA VERSIÓN) ---

import bcrypt

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verifica si la contraseña plana coincide con el hash."""
    
    # Codificamos ambas a bytes, que es lo que bcrypt espera
    password_bytes = plain_password.encode('utf-8')
    hashed_password_bytes = hashed_password.encode('utf-8')
    
    # bcrypt.checkpw hace la magia
    return bcrypt.checkpw(password_bytes, hashed_password_bytes)

def get_password_hash(password: str) -> str:
    """Genera un hash de la contraseña."""
    
    # Codificamos la contraseña a bytes
    password_bytes = password.encode('utf-8')
    
    # Generamos un 'salt' (aleatoriedad)
    salt = bcrypt.gensalt()
    
    # Creamos el hash
    hashed_bytes = bcrypt.hashpw(password_bytes, salt)
    
    # Lo devolvemos como un string para guardarlo en la BBDD
    return hashed_bytes.decode('utf-8')