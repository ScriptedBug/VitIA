import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
// Asegúrate de que estos imports sean correctos
import '../../core/api_client.dart'; 
import '../../core/services/api_config.dart';
import '../../core/services/user_sesion.dart'; 

class TutorialPage extends StatefulWidget {
    final VoidCallback onFinished; 
    final ApiClient apiClient; 

    const TutorialPage({
        super.key, 
        required this.onFinished,
        required this.apiClient
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

    // Colores basados en las imágenes
    final Color _mainColor = const Color(0xFF6B8E23); // Olivo/Verde
    final Color _activeProgressColor = const Color(0xFF9C27B0); // Magenta/Vino
    final Color _inactiveColor = const Color(0xFFF4C4C4); // Rosa pálido
    final Color _lightYellowBackground = const Color(0xFFFFFBE6); // Fondo de burbujas

    @override
    void dispose() {
        _pageController.dispose();
        super.dispose();
    }

    // 🔑 Llama al Backend (PATCH /users/me) y finaliza el tutorial
    Future<void> _completeTutorial() async {
        if (!mounted) return;
        setState(() => _isCompleting = true);
        
        try {
            await widget.apiClient.markTutorialAsComplete();
            widget.onFinished();
            
        } on DioException catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al guardar el tutorial: ${e.message}')),
            );
        } catch (e) {
             ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error al guardar el tutorial: $e')),
            );
        } finally {
            if (mounted) setState(() => _isCompleting = false);
        }
    }
    
    // --- UTILERIAS DE WIDGETS ---
    
    Widget _buildTipCard(IconData icon, String text) {
        return Container(
            width: 140,
            height: 100,
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: _lightYellowBackground,
                borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Icon(icon, size: 24, color: _mainColor),
                    const SizedBox(height: 5),
                    Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                ],
            ),
        );
    }
    
    Widget _buildFinalCard(String title, String content) {
        return Container(
             width: 140,
             height: 120,
             padding: const EdgeInsets.all(10),
             decoration: BoxDecoration(
                 color: Colors.white,
                 borderRadius: BorderRadius.circular(10),
                 border: Border.all(color: Colors.grey.shade200),
             ),
             child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                     Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                     const SizedBox(height: 5),
                     Text(content, style: const TextStyle(fontSize: 11)),
                 ],
             ),
        );
    }

    // --- Contenido específico de cada pantalla ---
    
    Widget _buildPageContent(int index) {
        final isLastPage = index == _numPages - 1;
        
        switch (index) {
            case 0: // Pantalla 0: Introducción
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const SizedBox(height: 50),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        const Text('Guía de uso 1/5', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 40),
                        Container(
                            width: 250,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: _lightYellowBackground,
                                borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text('¡Empieza aquí!\nAbre la cámara tocando el icono de Cámara en el menú inferior 📷', textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: 150),
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
                            // 🖼️ Placeholder para el gráfico del móvil/mano
                            child: Container(
                                width: 200, 
                                height: 300, 
                                color: const Color(0xFFF0E0E0), // Color magenta pálido
                                child: const Center(child: Text('GRÁFICO MANO/MÓVIL', textAlign: TextAlign.center)),
                            ),
                        ),
                    ],
                );

            case 3: // Pantalla 3: Consejos para la Foto
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const SizedBox(height: 30),
                        const Text('Guía de uso 3/5', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        const Text('Haz una foto clara y centrada', style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 20),
                        Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                                _buildTipCard(Icons.wb_sunny, "Mejor con buena luz natural"),
                                _buildTipCard(Icons.compare_arrows_sharp, "Acércate lo suficiente"),
                                _buildTipCard(Icons.center_focus_strong, "Enfoca una sola hoja o racimo"),
                                _buildTipCard(Icons.crop_square, "Evita fondos confusos"),
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
                        const Text('Detectamos la variedad al instante', style: TextStyle(fontSize: 22)),
                        const SizedBox(height: 10),
                        const Text('Cuando haces una foto, Vitia identifica la variedad y la desbloquea automáticamente en tu biblioteca'),
                        const SizedBox(height: 30),
                        Center(
                            child: Container(
                                width: 150, 
                                height: 200, 
                                color: Colors.grey[100],
                                child: const Center(child: Text('TARJETA TREPADELL', textAlign: TextAlign.center)),
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
                        
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                                _buildFinalCard("Todas las variedades", "Información completa de cualquier variedad"),
                                _buildFinalCard("Tus variedades", "Galería de todas las variedades que hayas detectado"),
                            ],
                        ),
                        const SizedBox(height: 30),
                        
                        // Mensaje Final con el icono
                        Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: _lightYellowBackground, borderRadius: BorderRadius.circular(10)),
                            child: Row(
                                children: [
                                    const Icon(Icons.bookmark_outline, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    const Flexible(child: Text('Consulta tu biblioteca de variedades y su galería de fotos.', style: TextStyle(fontSize: 14))),
                                ],
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
        
        return Scaffold(
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
                                    if (isGuidePage) 
                                        IconButton(
                                            icon: const Icon(Icons.arrow_back, color: Color(0xFF9C27B0)),
                                            onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                                        )
                                    else 
                                        const SizedBox(width: 48), 
                                    
                                    // Puntos de Progreso y Título (Solo en las guías 1/5 a 5/5)
                                    if (isGuidePage)
                                        Row(
                                            children: [
                                                // Puntos de Progreso
                                                Row(
                                                    children: List.generate(_numPages - 1, (i) => Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                                        child: Icon(
                                                            Icons.circle, 
                                                            size: 10, 
                                                            color: i + 1 <= _currentPage ? _activeProgressColor : _inactiveColor,
                                                        ),
                                                    )),
                                                ),
                                            ],
                                        )
                                    else
                                        const SizedBox.shrink(),
                                    
                                    // Botón Cerrar (Funcional en todas las pantallas)
                                    IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: isFirstPage ? widget.onFinished : _completeTutorial, 
                                    ),
                                ],
                            ),
                            
                            // 2. CONTENIDO (Ocupa la mayor parte del espacio)
                            Expanded(child: _buildPageContent(index)),

                            // 3. Controles de Navegación Inferior
                            Column(
                                children: [
                                    if (isFirstPage)
                                        // Pantalla de Introducción
                                        Column(
                                            children: [
                                                ElevatedButton(
                                                    onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                                                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: _mainColor),
                                                    child: const Text('Ver tutorial', style: TextStyle(color: Colors.white)),
                                                ),
                                                TextButton(onPressed: widget.onFinished, child: const Text('Saltar', style: TextStyle(color: Colors.black))),
                                            ],
                                        )
                                    else if (isLastPage)
                                        // Pantalla Final
                                        ElevatedButton(
                                            onPressed: _completeTutorial, // MARCA Y CIERRA
                                            style: ElevatedButton.styleFrom(
                                                minimumSize: const Size(double.infinity, 50), 
                                                backgroundColor: _mainColor,
                                                foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Comenzar', style: TextStyle(fontSize: 18)),
                                        )
                                    else 
                                        // Pantallas Intermedias
                                        ElevatedButton(
                                            onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
                                            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: _mainColor),
                                            child: const Text('Siguiente', style: TextStyle(color: Colors.white)),
                                        ),
                                    const SizedBox(height: 20),
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