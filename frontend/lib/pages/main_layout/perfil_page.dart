// lib/pages/main_layout/perfil_page.dart

import 'package:flutter/material.dart';
import 'package:vinas_mobile/core/services/user_sesion.dart';
import '../auth/login_page.dart'; 
import '../../core/api_client.dart'; // <<< Importar ApiClient

class PerfilPage extends StatelessWidget {
  final ApiClient apiClient; // <<< REQUIERE ApiClient
  
  const PerfilPage({super.key, required this.apiClient}); // <<< MODIFICADO

  void logout(BuildContext context) async { // Hacemos el método async
    // 1. Notificar al backend y limpiar cabeceras de Dio
    await apiClient.logout(); 
    
    // 2. Limpiar el token localmente (la acción crítica)
    UserSession.clearToken(); 
    
    // 3. Navegar a Login y limpiar el historial
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()), 
      (route) => false, 
    );
  }

  // Widget para construir los botones/tarjetas de perfil (Estilo del mockup)
  Widget _buildProfileCard({required String title, required Function() onTap, required IconData icon}) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
              child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(icon, color: Colors.black54), // Icono
                  title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward, color: Colors.black54),
                  onTap: onTap,
              ),
          ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final Color _vinoColor = const Color(0xFFA01B4C); 
    final Color _grisClaro = const Color(0xFFECECEC); 

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back), 
              onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text("Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: const [
              Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Icon(Icons.more_vert), 
              ),
          ],
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // --- Sección de Encabezado ---
                  Center(
                      child: Column(
                          children: [
                              // Avatar
                              CircleAvatar(
                                  radius: 40,
                                  backgroundColor: _grisClaro,
                                  child: Icon(Icons.person, size: 40, color: _vinoColor),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      const Text("Pepe García", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Icon(Icons.edit, size: 18, color: Colors.grey[700]),
                                  ],
                              ),
                              const SizedBox(height: 20),
                          ],
                      ),
                  ),

                  // --- Pestañas General/Suscripción ---
                  Row(
                      children: [
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey.shade400)
                              ),
                              child: const Text("General", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: const Text("Suscripción"),
                          ),
                      ],
                  ),
                  const SizedBox(height: 30),


                  // --- Botón de CERRAR SESIÓN (Funcional) ---
                  _buildProfileCard(
                      title: "Cerrar sesión",
                      onTap: () => logout(context), 
                      icon: Icons.logout,
                  ),
              ],
          ),
      ),
    );
  }
}