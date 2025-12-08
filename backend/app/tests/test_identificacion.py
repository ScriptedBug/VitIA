import os
import pytest
import time
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
    """Genera el reporte final incluyendo el NOMBRE DEL GRUPO en las estadísticas de tiempo."""
    yield # Ejecución de tests

    # --- INICIO DEL REPORTE ---
    output = []
    TABLE_WIDTH = 130
    
    output.append("\n" + "="*TABLE_WIDTH)
    output.append("🤖  VITIA AI — REPORTE COMPARATIVO DE DATASETS  🤖".center(TABLE_WIDTH))
    output.append("="*TABLE_WIDTH)

    test_types = [
        ("NORMAL", "Validación Estándar"),
        ("BRILLO", "Stress: Baja Luminosidad"),
        ("ROTACION", "Stress: Rotación 45°"),
    ]

    # Archivo | Esperado | Detectado | Coincide | Conf | Tiempo | Estado
    row_fmt = "{:<28} | {:<18} | {:<18} | {:^10} | {:^8} | {:^10} | {:^12}"

    for ds_name in DATASETS.keys():
        output.append(f"\n📦 GRUPO DE DATOS: {ds_name}")
        output.append("="*TABLE_WIDTH)

        ds_passed_strict = 0
        ds_passed_soft = 0
        ds_total = 0
        
        # Recopilamos resultados de ESTE dataset
        all_ds_results = [r for r in GLOBAL_METRICS["results"] if r['dataset'] == ds_name]

        for code_type, title in test_types:
            output.append(f"\n  📍 {title}")
            output.append("  " + "-" * (TABLE_WIDTH - 2))
            output.append("  " + row_fmt.format("ARCHIVO", "ESPERADO", "DETECTADO", "COINCIDE", "CONF.", "TIEMPO", "ESTADO"))
            output.append("  " + "-" * (TABLE_WIDTH - 2))

            section_results = [r for r in all_ds_results if r['type'] == code_type]

            sect_passed_strict = 0
            sect_passed_soft = 0

            for res in section_results:
                class_match = res['expected'] == res['detected']
                class_icon = "✅ SI" if class_match else "❌ NO"
                
                if res['passed']:
                    status = "✅ PASS"
                    sect_passed_strict += 1
                elif class_match and not res['passed']:
                    status = "⚠️ LOW CONF"
                else:
                    status = "❌ FAIL"
                
                if class_match: sect_passed_soft += 1
                
                fname = res['img']
                if len(fname) > 25: fname = fname[:22] + "..."
                
                # Tiempo formateado
                raw_time = res.get('time_ms', 0)
                time_str = f"{raw_time:.0f} ms" if isinstance(raw_time, (int, float)) else "N/A"
                
                output.append("  " + row_fmt.format(fname, res['expected'], res['detected'], class_icon, res['conf'], time_str, status))

            total = len(section_results)
            ds_total += total
            ds_passed_strict += sect_passed_strict
            ds_passed_soft += sect_passed_soft

            if total > 0:
                acc_strict = (sect_passed_strict / total) * 100
                acc_soft = (sect_passed_soft / total) * 100
                output.append("  " + "-" * (TABLE_WIDTH - 2))
                output.append(f"     🎯 Precisión (Calidad):  {acc_strict:.1f}% ({sect_passed_strict}/{total})")
                output.append(f"     🔍 Identif.  (Flexible): {acc_soft:.1f}% ({sect_passed_soft}/{total})")
            else:
                output.append("     (Sin pruebas)")

        # --- ESTADÍSTICAS DE TIEMPO ---
        output.append("\n" + "  " + "." * (TABLE_WIDTH - 2))
        output.append("  ⏱️  ANÁLISIS DE TIEMPOS DE RESPUESTA:")

        if all_ds_results:
            means_str = []
            for code_type, _ in test_types:
                times = [r['time_ms'] for r in all_ds_results if r['type'] == code_type and isinstance(r.get('time_ms'), (int, float))]
                if times:
                    avg = sum(times) / len(times)
                    means_str.append(f"{code_type}: {avg:.0f}ms")
            
            output.append(f"     🔹 Promedios:  {' | '.join(means_str) if means_str else 'N/A'}")

            # Récords (Min/Max)
            valid_results = [r for r in all_ds_results if isinstance(r.get('time_ms'), (int, float))]
            if valid_results:
                sorted_res = sorted(valid_results, key=lambda x: x['time_ms'])
                fastest = sorted_res[0]
                slowest = sorted_res[-1]
                
                # --- AQUÍ ESTÁ EL CAMBIO: AÑADIDO 'dataset' ---
                output.append(f"     🚀 Más rápido: {fastest['time_ms']:.0f}ms ({fastest['dataset']} | {fastest['img']} | {fastest['type']})")
                output.append(f"     🐌 Más lento:  {slowest['time_ms']:.0f}ms ({slowest['dataset']} | {slowest['img']} | {slowest['type']})")
        else:
            output.append("     (Faltan datos de tiempo)")
        
        output.append("  " + "." * (TABLE_WIDTH - 2))
        
        # Resumen Final Dataset
        acc_total_strict = (ds_passed_strict/ds_total*100) if ds_total else 0
        acc_total_soft = (ds_passed_soft/ds_total*100) if ds_total else 0
        
        output.append(f"📊 RENDIMIENTO '{ds_name}':")
        output.append(f"   ✅ Estricto (Pasa Umbral): {acc_total_strict:.2f}%")
        output.append(f"   ⚠️ Flexible (Sabe qué es): {acc_total_soft:.2f}%")
        output.append("="*TABLE_WIDTH)

    # --- SECCIÓN COBERTURA ---
    output.append("\n\n📍 DIAGNÓSTICO DE COBERTURA (DATASET HEALTH)")
    output.append("-" * TABLE_WIDTH)

    for ds_name in sorted(DATASETS.keys()):
        if ds_name in GLOBAL_METRICS["coverage"]:
            cov = GLOBAL_METRICS["coverage"][ds_name]
            output.append(f"\n📂 {ds_name}:")
            output.append(f"   📊 Cobertura Variedades: {cov['pct']:.1f}%")
            if cov['missing']:
                missing_str = ", ".join(sorted(list(cov['missing'])))
                output.append(f"   ⚠️  FALTAN: {missing_str}")
            else:
                output.append(f"   ✨  Completo")
            for warn in cov['balance_warnings']:
                output.append(f"   ⚖️  {warn}")

    output.append("\n" + "="*TABLE_WIDTH + "\n")

    with open("reporte_rendimiento.txt", "w", encoding="utf-8") as f:
        f.write("\n".join(output))
    
    print("\n".join(output))
    print(f"\n\n📄 REPORTE GENERADO: Busca el archivo 'reporte_rendimiento.txt'.\n")


# -------------------------------------------------------------------------
# 3. HELPER: INFERENCIA Y REGISTRO
# -------------------------------------------------------------------------
def run_inference(image):
    start = time.perf_counter()

    results = model.predict(image, save=False, verbose=False)

    end = time.perf_counter()
    inference_time_ms = (end - start) * 1000

    top_pred = "Desconocido"
    top_conf = 0.0
    for r in results:
        for box in r.boxes:
            conf = float(box.conf)
            if conf > top_conf:
                top_conf = conf
                cls_id = int(box.cls)
                top_pred = model.names[cls_id]
    return top_pred, top_conf, inference_time_ms

def record_metric(dataset, filename, expected, detected, conf, time_ms, passed, test_type):
    GLOBAL_METRICS["results"].append({
        "dataset": dataset,
        "img": filename,
        "expected": expected,
        "detected": detected,
        "conf": f"{conf:.1%}",
        "time_ms": time_ms,
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
    detected, conf, time_ms = run_inference(image)

    MAX_LATENCY_MS = 1000

    accuracy_pass = (detected == expected_class) and (conf >= min_conf)
    latency_pass = time_ms <= MAX_LATENCY_MS

    passed = accuracy_pass and latency_pass
    
    record_metric(ds_name, filename, expected_class, detected, conf, time_ms, passed, "NORMAL")
    
    if not latency_pass:
        print(f"\n LENTITUD DETECTADA: {filename} tardó {time_ms:.2f}ms")
    
    assert passed

# B) BRILLO
@pytest.mark.parametrize("ds_name, filename, expected_class, _", FULL_TEST_SUITE)
def test_performance_brightness(ds_name, filename, expected_class, _):
    img_path = os.path.join(SAMPLES_DIR, filename)
    image = Image.open(img_path).convert("RGB")
    enhancer = ImageEnhance.Brightness(image)
    dark_image = enhancer.enhance(0.5)
    
    # ✅ CORREGIDO: Ahora recibimos 3 valores (incluyendo time_ms)
    detected, conf, time_ms = run_inference(dark_image)
    
    passed = (detected == expected_class) and (conf > 0.40)
    
    # ✅ CORREGIDO: Pasamos time_ms a record_metric
    record_metric(ds_name, filename, expected_class, detected, conf, time_ms, passed, "BRILLO")
    assert passed

# C) ROTACIÓN
@pytest.mark.parametrize("ds_name, filename, expected_class, _", FULL_TEST_SUITE)
def test_performance_rotation(ds_name, filename, expected_class, _):
    img_path = os.path.join(SAMPLES_DIR, filename)
    image = Image.open(img_path).convert("RGB")
    rotated_image = image.rotate(45, expand=True)
    
    # ✅ CORREGIDO: Recibimos time_ms
    detected, conf, time_ms = run_inference(rotated_image)
    
    passed = (detected == expected_class) and (conf > 0.40)
    
    # ✅ CORREGIDO: Pasamos time_ms
    record_metric(ds_name, filename, expected_class, detected, conf, time_ms, passed, "ROTACION")
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
#>>>>>>> a26c62b (PYtest IA)
