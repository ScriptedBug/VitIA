import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

// Asegúrate de que estos imports sean correctos
import '../../core/api_client.dart'; 
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart'; 

class TutorialPage extends StatefulWidget {
    final VoidCallback onFinished; 
    final ApiClient apiClient; 
    final bool isCompulsory;

    const TutorialPage({
        super.key, 
        required this.onFinished,
        required this.apiClient,
        required this.isCompulsory
    });

    @override
    State<TutorialPage> createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
    final PageController _pageController = PageController();
    int _currentPage = 0;
    final int _numPages = 6; // Pantalla 0 (Intro) + 5 Guías (1 a 5)
    
    // Estados de carga
    bool _isCompleting = false;

    // --- COLORES AJUSTADOS A FIGMA ---
    final Color _mainColor = const Color(0xFF8B9E3A); // Verde Musgo
    final Color _activeProgressColor = const Color(0xFF9C27B0); // Magenta/Vino
    final Color _inactiveColor = const Color(0xFFF4C4C4); // Rosa pálido
    final Color _lightYellowBackground = const Color(0xFFFFF2D3); // Fondo de burbujas (Ajustado)
    final Color _darkBackgroundColor = const Color(0xFF1B2414); // Color de la barra inferior (aproximado)

    @override
    void dispose() {
        _pageController.dispose();
        super.dispose();
    }

    Future<void> _completeTutorial() async {
        if (_isCompleting) return;
        
        if (widget.isCompulsory) { 
            setState(() => _isCompleting = true);
            try {
                // Llama al endpoint de la API para marcar como completo
                await widget.apiClient.markTutorialAsComplete(); 
            } on DioException catch (e) {
                debugPrint("Error al completar el tutorial en el servidor: ${e.message}");
            } finally {
                if (mounted) setState(() => _isCompleting = false);
            }
        }
        
        widget.onFinished(); 
    }
    
    // --- UTILERIAS DE WIDGETS ---
    
    // 1. Tarjeta de Consejos (P3)
    Widget _buildImageTipCard(String assetName) {
        // La imagen ya contiene el icono, el texto y el fondo amarillo
        return Container(
            width: 140,
            height: 140, 
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            child: Image.asset(
                'assets/tutorial/$assetName', // Ruta correcta
                fit: BoxFit.contain, 
            ),
        );
    }
    
    // 2. Tarjeta de Biblioteca (P5)
    Widget _buildFinalCard(String title, String content) {
        // Las tarjetas de biblioteca son blancas y rectangulares
        return Container(
             width: 140,
             height: 120,
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(10),
                 boxShadow: [
                     BoxShadow(
                         color: Colors.grey.withOpacity(0.1),
                         spreadRadius: 1,
                         blurRadius: 5,
                         offset: const Offset(0, 3), 
                     ),
                 ]
             ),
             child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                     Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                     const SizedBox(height: 5),
                     Text(content, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                 ],
             ),
        );
    }
    
    // --- Contenido específico de cada pantalla ---
    
    Widget _buildPageContent(int index) {
        switch (index) {
            case 0: // Pantalla 0: Introducción
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const SizedBox(height: 50),
                        // Tipografía serif simulada con fontWeight:bold
                        const Text('Es tu primera vez\npor aquí?', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, height: 1.1)), 
                        const SizedBox(height: 15),
                        const Text('Vitia te ayuda a identificar variedades de viñas usando la cámara.'),
                        const SizedBox(height: 100),
                        const Text('¿Quieres aprender cómo funciona?', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 15),
                    ],
                );

            case 1: // Pantalla 1: Abre la cámara
                return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                        const SizedBox(height: 30),
                        const Text('Guía de uso 1/5', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 100), // Empuja la burbuja hacia la zona del icono de cámara
                        // 🖼️ Burbuja P1: La imagen ya tiene la punta hacia abajo
                        Center(
                            child: Image.asset(
                                'assets/tutorial/tarjeta informativa tutorial.png', 
                                width: 250,
                            ),
                        ),
                        const Expanded(child: SizedBox.shrink()), 
                    ],
                );
                
            case 2: // Pantalla 2: Preparación
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const SizedBox(height: 30),
                        const Text('Guía de uso 2/5', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        const Text('Coloca la hoja o racimo delante del móvil. Cuanta más claridad tenga la imagen, mejor será la detección'),
                        const SizedBox(height: 30),
                        Center(
                            // 🖼️ Ilustración del móvil/mano
                            child: Image.asset(
                                'assets/tutorial/ilustración movil.png', 
                                width: 250, 
                                height: 350, 
                                fit: BoxFit.contain,
                            ),
                        ),
                        const SizedBox(height: 20),
                    ],
                );

            case 3: // Pantalla 3: Consejos para la Foto
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const SizedBox(height: 30),
                        const Text('Guía de uso 3/5', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        const Text('Haz una foto clara y centrada', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 20),
                        Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            // 🖼️ Usamos las imágenes de las tarjetas completas
                            children: [
                                _buildImageTipCard('tarjeta consejo guía 1.png'), 
                                _buildImageTipCard('tarjeta consejo guía 2.png'), 
                                _buildImageTipCard('tarjeta consejo guía 3.png'), 
                                _buildImageTipCard('tarjeta consejo guía 4.png'), 
                            ],
                        ),
                    ],
                );
                
            case 4: // Pantalla 4: Detección Instantánea
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const SizedBox(height: 30),
                        const Text('Guía de uso 4/5', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        const Text('Detectamos la variedad al instante', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 10),
                        const Text('Cuando haces una foto, Vitia identifica la variedad y la desbloquea automáticamente en tu biblioteca'),
                        const SizedBox(height: 30),
                        Center(
                            // 🖼️ Tarjeta de Trepadell + Línea punteada (todo en una imagen)
                            child: Image.asset(
                                'assets/tutorial/Tutorial Pantalla 4.jpg', 
                                width: 200, 
                                height: 350, 
                                fit: BoxFit.contain,
                            ),
                        ),
                    ],
                );

            case 5: // Pantalla 5: Final / Biblioteca
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const SizedBox(height: 30),
                        const Text('Guía de uso 5/5', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        
                        // Tarjetas de Biblioteca 
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                _buildFinalCard("Todas las variedades", "Información completa de cualquier variedad"),
                                _buildFinalCard("Tus variedades", "Galería de todas las variedades que hayas detectado"),
                            ],
                        ),
                        const SizedBox(height: 30),
                        
                        // 🖼️ Burbuja Final con el botón "Comenzar" DENTRO
                        Center(
                            child: Image.asset(
                                'assets/tutorial/tarjeta informativa tutorial 5.png', // Imagen con botón incluido
                                width: 320, 
                                fit: BoxFit.contain,
                            ),
                        ),
                        const SizedBox(height: 50),
                    ],
                );

            default:
                return const Center(child: Text('Error de página'));
        }
    }
    
    Widget _buildTutorialScreen(int index) {
        final isLastPage = index == _numPages - 1;
        final isFirstPage = index == 0;
        final isGuidePage = index > 0;
        
        // Define la ruta del indicador de progreso (Puntos/Uvas)
        String indicatorAsset = '';
        if (isGuidePage) {
             // El índice de la guía va de 1 a 5
             // Mapeamos el índice de la página (1-5) a tu nombre de archivo
             // Nota: Si usas las imágenes 'indicadores pasos uvas tutorial X.png', tendrás que asegurarte que solo
             // el archivo de la página actual esté activo, o que la imagen ya tenga el progreso dibujado.
             // Asumiendo que la imagen ya tiene el estado dibujado:
             indicatorAsset = 'assets/tutorial/indicadores pasos uvas tutorial $index.png'; 
        }

        return Scaffold(
            backgroundColor: const Color(0xFFFCFBF6), // Fondo blanco pálido
            body: SafeArea(
                child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                            // 1. Control Superior (Cerrar / Progreso)
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                    // Flecha de retroceso (usamos el color Magenta/Vino del diseño)
                                    if (isGuidePage) 
                                        IconButton(
                                            icon: Icon(Icons.arrow_back, color: _activeProgressColor), 
                                            onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                                        )
                                    else 
                                        const SizedBox(width: 48), // Placeholder para alineación
                                    
                                    // Puntos de Progreso (Uvas)
                                    if (isGuidePage)
                                        Image.asset(
                                            indicatorAsset, // Ruta del indicador según la página actual
                                            height: 20, // Ajustar altura para que se vea bien
                                            fit: BoxFit.contain,
                                        ),

                                    // Flecha Adelante y Botón Cerrar (Solo en las guías)
                                    if (isGuidePage)
                                        Row(
                                            children: [
                                                // Flecha Adelante
                                                if (!isLastPage)
                                                    IconButton(
                                                        icon: Icon(Icons.arrow_forward, color: _activeProgressColor), 
                                                        onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                                                    )
                                                else // Placeholder para alineación
                                                    const SizedBox(width: 48), 
                                                // Botón Cerrar (X)
                                                IconButton(
                                                    icon: const Icon(Icons.close),
                                                    onPressed: _completeTutorial, 
                                                ),
                                            ],
                                        )
                                    else // En Pantalla 0, el botón cerrar es independiente (solo la X a la derecha)
                                        const SizedBox.shrink(),
                                ],
                            ),

                            // --- Manejo especial para Pantalla 0 (Cerrar a la derecha)
                            if (isFirstPage) 
                                Align(
                                    alignment: Alignment.topRight, // Coloca el botón arriba a la derecha
                                    child: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: widget.onFinished, 
                                    ),
                                ),
                            
                            // 2. CONTENIDO 
                            Expanded(child: _buildPageContent(index)),

                            // 3. Controles de Navegación Inferior (Botones y Barra Negra)
                            Column(
                                children: [
                                    if (isFirstPage)
                                        // Pantalla de Introducción: Botones "Ver tutorial" y "Saltar"
                                        Column(
                                            children: [
                                                // Botón Relleno "Ver tutorial"
                                                ElevatedButton(
                                                    onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                                                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: _mainColor),
                                                    child: const Text('Ver tutorial', style: TextStyle(color: Colors.white)),
                                                ),
                                                const SizedBox(height: 10),
                                                // Botón Contorno "Saltar" 
                                                OutlinedButton(
                                                    onPressed: widget.onFinished, 
                                                    style: OutlinedButton.styleFrom(
                                                        minimumSize: const Size(double.infinity, 50), 
                                                        side: BorderSide(color: _mainColor, width: 1.5), 
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                                    ),
                                                    child: Text('Saltar', style: TextStyle(color: _mainColor)),
                                                ),
                                            ],
                                        )
                                    else if (isLastPage)
                                        // Pantalla Final: El botón "Comenzar" está en la imagen, así que no hay botón aquí.
                                        const SizedBox.shrink()
                                    else 
                                        // Pantallas Intermedias: Botón "Siguiente"
                                        ElevatedButton(
                                            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: _mainColor),
                                            child: const Text('Siguiente', style: TextStyle(color: Colors.white)),
                                        ),
                                    
                                    // Barra de navegación inferior (simulada)
                                    const SizedBox(height: 20),
                                    Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                            color: _darkBackgroundColor,
                                            borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                                Icon(Icons.home, color: Colors.white.withOpacity(0.8)),
                                                Icon(Icons.camera_alt, color: _activeProgressColor), 
                                                Icon(Icons.bookmark, color: Colors.white.withOpacity(0.8)),
                                                Icon(Icons.chat_bubble, color: Colors.white.withOpacity(0.8)),
                                            ],
                                        ),
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ),
        );
    }

    @override
    Widget build(BuildContext context) {
        return PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), 
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: List.generate(_numPages, (index) => _buildTutorialScreen(index)),
        );
    }
}