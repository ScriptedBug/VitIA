import 'package:flutter/material.dart';

class InicioScreen extends StatelessWidget {
  final String userName;
  final String location;
  final String? profileImage; // Opcional, por si hay foto perfil real

  const InicioScreen({
    super.key,
    required this.userName,
    required this.location,
    this.profileImage,
    required this.onAvatarTap,
  });

  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBF6),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // 2. SALUDO + AVATAR
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¡Hola, $userName!',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight:
                            FontWeight.w400, // Fuente tipo serif elegante
                        fontFamily: 'Serif',
                        color: Color(0xFF142018),
                      ),
                    ),
                    GestureDetector(
                      onTap: onAvatarTap,
                      child: const CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage(
                            'assets/home/avatar_placeholder.png'), // Placeholder
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3. ILUSTRACIÓN VIÑEDO
              // El usuario dijo "he descargado la foto... assets/home/"
              // Asumimos 'assets/home/ilustracion_vinedo.png' (Yo la copié antes)
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Image.asset(
                    'assets/home/ilustracion_home.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // 4. UBICACIÓN
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.black87),
                    const SizedBox(width: 8),
                    Text(
                      location.isNotEmpty
                          ? "$location."
                          : "Sin ubicación definida.",
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_outlined,
                        size: 20, color: Colors.black54),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 5. DATOS ESTÁTICOS (MOCKUP) - Cepas / Hectáreas
              // El usuario dijo "obvia todo lo de estado del viñedo", pero quizás
              // quiera ver los datos inferiores. Los pondré como placeholder estático.
              // 5. DATOS ESTÁTICOS (Cepas / Hectáreas) ELIMINADO
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 24.0),
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: _buildInfoCard("300 Cepas", "4 Variedades"),
              //       ),
              //       const SizedBox(width: 15),
              //       Expanded(
              //         child: _buildInfoCard("1,6 hectáreas", "Desde 1982"),
              //       ),
              //     ],
              //   ),
              // ),

              const SizedBox(height: 100), // Espacio para el navbar
            ],
          ),
        ),
      ),
    );
  }
}
