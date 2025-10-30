class variedad:
    def __init__(self, id: int, nombre: str, descripcion: str, region_origen: str, color_uva: str, imagen_url: str):
        self.id = id
        self.nombre = nombre
        self.descripcion = descripcion
        self.region_origen = region_origen
        self.color_uva = color_uva
        self.imagen_url = imagen_url

    def to_dict(self):
        return {
            "nombre": self.nombre,
            "descripcion": self.descripcion,
            "region_origen": self.region_origen,
            "color_uva": self.color_uva,
            "imagen_url": self.imagen_url
        }