import os
import pytest
from PIL import Image, ImageEnhance
from collections import Counter
from app.ia.model_loader import model

# -------------------------------------------------------------------------
# 1. CONFIGURACIÓN DE DATASETS
# -------------------------------------------------------------------------
SAMPLES_DIR = os.path.join(os.path.dirname(__file__), "samples")

# DEFINICIÓN DE TUS GRUPOS DE PRUEBA
# Estructura: "NOMBRE_DEL_SET": [ (archivo, clase, confianza_minima), ... ]
DATASETS = {
    "DATASET_ALTA_CALIDAD": [
    # Ahmer Bounamer
("ahmerbounamer1.jpg", "Ahmer Bounamer", 0.50),
("ahmerbounamer2.jpg", "Ahmer Bounamer", 0.50),
("ahmerbounamer3.jpg", "Ahmer Bounamer", 0.50),

# Aledo
("aledo1.jpg", "Aledo", 0.50),
("aledo2.jpg", "Aledo", 0.50),
("aledo3.jpg", "Aledo", 0.50),

# Fernandella
("fernandella1.jpg", "Fernandella", 0.50),
("fernandella2.jpg", "Fernandella", 0.50),
("fernandella3.jpg", "Fernandella", 0.50),

# Jacquet
("jacquet1.jpg", "Jacquet", 0.50),
("jacquet2.jpg", "Jacquet", 0.50),
("jacquet3.jpg", "Jacquet", 0.50),

# Merseguera
("merseguera1.jpg", "Merseguera", 0.50),
("merseguera2.jpg", "Merseguera", 0.50),
("merseguera3.jpg", "Merseguera", 0.50),

# Moscatell
("moscatells1.jpg", "Moscatell", 0.50),
("moscatells2.jpg", "Moscatell", 0.50),
("moscatells3.jpg", "Moscatell", 0.50),

# Planta fina de pedralba
("plantafinapedralba1.jpg", "Planta fina de pedralba", 0.50),
("plantafinapedralba2.jpg", "Planta fina de pedralba", 0.50),
("plantafinapedralba3.jpg", "Planta fina de pedralba", 0.50),

# Roseti
("roseti1.jpg", "Roseti", 0.50),
("roseti2.jpg", "Roseti", 0.50),
("roseti3.jpg", "Roseti", 0.50),

# Trepadell
("trepadell1.jpg", "Trepadell", 0.50),
("trepadell2.jpg", "Trepadell", 0.50),
("trepadell3.jpg", "Trepadell", 0.50),

# Chardonay
("chardonay1.jpg", "Chardonay", 0.50),
("chardonay2.jpg", "Chardonay", 0.50),
("chardonay3.jpg", "Chardonay", 0.50),

# Tintorera
("tintorera1.jpg", "Tintorera", 0.50),
("tintorera2.jpg", "Tintorera", 0.50),
("tintorera3.jpg", "Tintorera", 0.50),

# Monastrell
("monastrell1.jpg", "Monastrell", 0.50),
("monastrell2.jpg", "Monastrell", 0.50),
("monastrell3.jpg", "Monastrell", 0.50),

# Cabernet-Sauvignon
("cabernetsauvignon1.jpg", "Cabernet-Sauvignon", 0.50),
("cabernetsauvignon2.jpg", "Cabernet-Sauvignon", 0.50),
("cabernetsauvignon3.jpg", "Cabernet-Sauvignon", 0.50),

# De Cuerno
("decuerno1.jpg", "De Cuerno", 0.50),
("decuerno2.jpg", "De Cuerno", 0.50),
("decuerno3.jpg", "De Cuerno", 0.50),

# Garnacha
("garnacha1.jpg", "Garnacha", 0.50),
("garnacha2.jpg", "Garnacha", 0.50),
("garnacha3.jpg", "Garnacha", 0.50),

# Merlot
("merlot1.jpg", "Merlot", 0.50),
("merlot2.jpg", "Merlot", 0.50),
("merlot3.jpg", "Merlot", 0.50),

# Valenci negre
("valencinegre1.jpg", "Valenci negre", 0.50),
("valencinegre2.jpg", "Valenci negre", 0.50),
("valencinegre3.jpg", "Valenci negre", 0.50),

# Valensi blanc
("valenciblanc1.jpg", "Valensi blanc", 0.50),
("valenciblanc2.jpg", "Valensi blanc", 0.50),
("valenciblanc3.jpg", "Valensi blanc", 0.50),

# raim de tots sants
("raimtotssants1.jpg", "Raim de tots sants", 0.50),
("raimtotssants2.jpg", "Raim de tots sants", 0.50),
("raimtotssants3.jpg", "Raim de tots sants", 0.50),

    ],
    "DATASET_BAJA_CALIDAD": [
    ("LQahmer1.JPG", "Ahmer Bounamer", 0.50),
    ("LQmerseguera1.JPG", "Merseguera", 0.50),
    ("LQmerseguera2.JPG", "Merseguera", 0.50),
    ("LQmonastrell1.JPG", "Monastrell", 0.50),
    ("LQmoscatell1.JPG", "Moscatell", 0.50),
    ("LQmoscatell2.JPG", "Moscatell", 0.50),
    ("LQmoscatell3.JPG", "Moscatell", 0.50),
    ("LQmoscatell4.JPG", "Moscatell", 0.50),
    ("LQmoscatell5.JPG", "Moscatell", 0.50),
    ("LQtotsants1.JPG", "Raim de tots sants", 0.50),
    ("LQtrepadell1.JPG", "Trepadell", 0.50),
    ("LQtrepadell2.JPG", "Trepadell", 0.50),
    ("LQvalencinegre1.JPG", "Valenci negre", 0.50),  
    ("LQvalencinegre2.JPG", "Valenci negre", 0.50),  
    ("LQvalensiblanc1.JPG", "Valensi blanc", 0.50),  
    ("LQvalensiblanc2.JPG", "Valensi blanc", 0.50), 
    ]
}

# Aplanamos los datos para que Pytest pueda procesarlos uno a uno
# Formato resultante: [(dataset_name, archivo, clase, conf), ...]
FULL_TEST_SUITE = []
for ds_name, items in DATASETS.items():
    for fname, cls, conf in items:
        FULL_TEST_SUITE.append((ds_name, fname, cls, conf))

# Almacén de Métricas Globales
GLOBAL_METRICS = {
    "results": [],  # Lista de resultados individuales
    "coverage": {}  # Métricas de cobertura por dataset
}

# -------------------------------------------------------------------------
# 2. FIXTURE MAESTRO: REPORTE FINAL MULTI-DATASET
# -------------------------------------------------------------------------
@pytest.fixture(scope="session", autouse=True)
def print_final_scorecard():
    """Genera el reporte final organizado por Dataset y luego por Pruebas."""
    yield # Ejecución de tests

    TABLE_WIDTH = 125
    print("\n" + "="*TABLE_WIDTH)
    print("🤖  VITIA AI — REPORTE COMPARATIVO DE DATASETS  🤖".center(TABLE_WIDTH))
    print("="*TABLE_WIDTH)

    # Tipos de prueba a reportar
    test_types = [
        ("NORMAL", "Validación Estándar"),
        ("BRILLO", "Stress: Baja Luminosidad"),
        ("ROTACION", "Stress: Rotación 45°"),
    ]

    row_fmt = "{:<30} | {:<18} | {:<18} | {:^12} | {:^12} | {:^16}"

    # Iteramos por cada Dataset definido
    for ds_name in DATASETS.keys():
        print(f"\n📦 GRUPO DE DATOS: {ds_name}")
        print("="*TABLE_WIDTH)

        ds_passed = 0
        ds_total = 0

        for code_type, title in test_types:
            print(f"\n  📍 {title}")
            print("  " + "-" * (TABLE_WIDTH - 2))
            print("  " + row_fmt.format("ARCHIVO", "ESPERADO", "DETECTADO", "COINCIDE", "CONF.", "ESTADO"))
            print("  " + "-" * (TABLE_WIDTH - 2))

            # Filtrar resultados por Dataset y Tipo de Test
            section_results = [
                r for r in GLOBAL_METRICS["results"] 
                if r['dataset'] == ds_name and r['type'] == code_type
            ]

            passed_count = 0
            for res in section_results:
                class_match = res['expected'] == res['detected']
                class_icon = "✅ SI" if class_match else "❌ NO"
                
                if res['passed']:
                    status = "✅ PASS"
                    passed_count += 1
                elif class_match and not res['passed']:
                    status = "⚠️ LOW CONF"
                else:
                    status = "❌ FAIL"
                
                # Truncar nombre
                fname = res['img']
                if len(fname) > 27: fname = fname[:24] + "..."
                
                print("  " + row_fmt.format(fname, res['expected'], res['detected'], class_icon, res['conf'], status))

            total = len(section_results)
            if total > 0:
                acc = (passed_count / total) * 100
                print("  " + "-" * (TABLE_WIDTH - 2))
                print(f"     🎯 Precisión: {acc:.1f}% ({passed_count}/{total})")
            else:
                print("     (Sin pruebas)")
            
            ds_passed += passed_count
            ds_total += total
        
        # Resumen del Dataset
        print("."*TABLE_WIDTH)
        acc_ds = (ds_passed/ds_total*100) if ds_total else 0
        print(f"📊 RENDIMIENTO TOTAL '{ds_name}': {acc_ds:.2f}%")
        print("="*TABLE_WIDTH)

    # --- SECCIÓN DE COBERTURA (Por Dataset) ---
    print("\n\n📍 DIAGNÓSTICO DE COBERTURA (DATASET HEALTH)")
    print("-" * TABLE_WIDTH)
    
    for ds_name, cov in GLOBAL_METRICS["coverage"].items():
        print(f"\n📂 {ds_name}:")
        print(f"   📊 Cobertura Variedades: {cov['pct']:.1f}%")
        if cov['missing']:
            print(f"   ⚠️  FALTAN: {', '.join(cov['missing'])}")
        else:
            print(f"   ✨  Completo (Todas las variedades probadas)")
            
        for warn in cov['balance_warnings']:
            print(f"   ⚖️  {warn}")

    print("\n" + "="*TABLE_WIDTH + "\n")


# -------------------------------------------------------------------------
# 3. HELPER: INFERENCIA Y REGISTRO
# -------------------------------------------------------------------------
def run_inference(image):
    results = model.predict(image, save=False, verbose=False)
    top_pred = "Desconocido"
    top_conf = 0.0
    for r in results:
        for box in r.boxes:
            conf = float(box.conf)
            if conf > top_conf:
                top_conf = conf
                cls_id = int(box.cls)
                top_pred = model.names[cls_id]
    return top_pred, top_conf

def record_metric(dataset, filename, expected, detected, conf, passed, test_type):
    GLOBAL_METRICS["results"].append({
        "dataset": dataset,
        "img": filename,
        "expected": expected,
        "detected": detected,
        "conf": f"{conf:.1%}",
        "passed": passed,
        "type": test_type
    })

# -------------------------------------------------------------------------
# 4. TESTS (Parametrizados para correr en todos los Datasets)
# -------------------------------------------------------------------------

# A) NORMAL
@pytest.mark.parametrize("ds_name, filename, expected_class, min_conf", FULL_TEST_SUITE)
def test_performance_normal(ds_name, filename, expected_class, min_conf):
    img_path = os.path.join(SAMPLES_DIR, filename)
    if not os.path.exists(img_path): pytest.fail(f"No existe: {filename}")
    
    image = Image.open(img_path).convert("RGB")
    detected, conf = run_inference(image)
    
    passed = (detected == expected_class) and (conf >= min_conf)
    record_metric(ds_name, filename, expected_class, detected, conf, passed, "NORMAL")
    assert passed

# B) BRILLO
@pytest.mark.parametrize("ds_name, filename, expected_class, _", FULL_TEST_SUITE)
def test_performance_brightness(ds_name, filename, expected_class, _):
    img_path = os.path.join(SAMPLES_DIR, filename)
    image = Image.open(img_path).convert("RGB")
    enhancer = ImageEnhance.Brightness(image)
    dark_image = enhancer.enhance(0.5)
    
    detected, conf = run_inference(dark_image)
    passed = (detected == expected_class) and (conf > 0.40)
    record_metric(ds_name, filename, expected_class, detected, conf, passed, "BRILLO")
    assert passed

# C) ROTACIÓN
@pytest.mark.parametrize("ds_name, filename, expected_class, _", FULL_TEST_SUITE)
def test_performance_rotation(ds_name, filename, expected_class, _):
    img_path = os.path.join(SAMPLES_DIR, filename)
    image = Image.open(img_path).convert("RGB")
    rotated_image = image.rotate(45, expand=True)
    
    detected, conf = run_inference(rotated_image)
    passed = (detected == expected_class) and (conf > 0.40)
    record_metric(ds_name, filename, expected_class, detected, conf, passed, "ROTACION")
    assert passed

# -------------------------------------------------------------------------
# 5. COBERTURA (Itera sobre cada dataset definido)
# -------------------------------------------------------------------------
def test_dataset_coverage_metrics():
    known_classes = set(model.names.values())
    
    # Iteramos dataset por dataset para analizar cada uno independientemente
    for ds_name, items in DATASETS.items():
        tested_classes = set([item[1] for item in items])
        missing = known_classes - tested_classes
        
        pct = (len(tested_classes) / len(known_classes)) * 100 if known_classes else 0
        counts = Counter([item[1] for item in items])
        warnings = [f"Pocas muestras para '{cls}' ({cnt})" for cls, cnt in counts.items() if cnt < 2]

        GLOBAL_METRICS["coverage"][ds_name] = {
            "pct": pct, "missing": missing, "balance_warnings": warnings
        }
    
    # El test falla si ALGÚN dataset está incompleto (opcional, puedes quitar el assert)
    for ds_name, metric in GLOBAL_METRICS["coverage"].items():
        if metric["missing"]:
            pytest.fail(f"El dataset '{ds_name}' está incompleto. Faltan: {metric['missing']}")
>>>>>>> a26c62b (PYtest IA)
