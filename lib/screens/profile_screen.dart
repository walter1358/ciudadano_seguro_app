/*import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/emergency_contact.dart';
import '../widgets/emergency_contact_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Colores y Estilos Personalizados ---
const Color primaryColor = Color(0xFF007AFF);
const Color activeStatusColor = Color(0xFF198754);
const Color redButtonColor = Color(0xFFDC3545);

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Widget _buildDynamicDaysActiveItem() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.metadata.creationTime == null) {
      return _buildStatItem("0", "Días Activo");
    }

    final creationDateUTC = user.metadata.creationTime!;
    final creationDateLocal = creationDateUTC.toLocal();
    final now = DateTime.now();

    final daysActive = _calculateDaysBetween(creationDateLocal, now);
    return _buildStatItem(daysActive.toString(), "Días Activo");
  }

  int _calculateDaysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Perfil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications_none, color: Colors.grey),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            _buildStatsSection(),
            const SizedBox(height: 20),
            //_buildQuickConfigSection(),
            const SizedBox(height: 20),
            _buildAccountConfigSection(),
            const SizedBox(height: 20),
            _buildEmergencyContactSection(),
            const SizedBox(height: 30),
            _buildLogoutButton(),
            const SizedBox(height: 30),
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(widget.userPhotoUrl!),
                  backgroundColor: Colors.grey.shade200,
                )
              : const CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_pin_circle,
                          size: 14, color: activeStatusColor),
                      const SizedBox(width: 4),
                      Text(
                        "Ciudadano Activo",
                        style: TextStyle(
                          fontSize: 12,
                          color: activeStatusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          //const Icon(Icons.edit_note, color: primaryColor), // Se quito el icono para editar
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("0", "Reportes"),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFF1F1F1),
            ),
            _buildDynamicDaysActiveItem(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

/*
  Widget _buildQuickConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            "Configuración Rápida",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF495057),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildConfigSwitchItem(
                Icons.notifications_none,
                "Notificaciones",
                true,
                primaryColor,
              ),
              _buildConfigSwitchItem(
                Icons.location_on_outlined,
                "Ubicación",
                true,
                activeStatusColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
*/
/*
  Widget _buildConfigSwitchItem(
    IconData icon,
    String title,
    bool initialValue,
    Color switchColor,
  ) {
    return _ConfigSwitchItem(
      icon: icon,
      title: title,
      initialValue: initialValue,
      switchColor: switchColor,
    );
  }
*/
  Widget _buildAccountConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            "Configuración de Cuenta",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF495057),
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildConfigNavigationItem(
                Icons.person_outline,
                "Información Personal",
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigNavigationItem(
    IconData icon,
    String title, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          leading: Icon(icon, color: Colors.grey.shade700),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: () {
            debugPrint("Navegar a: $title");
          },
        ),
        if (showDivider)
          const Divider(
            height: 0,
            thickness: 1,
            indent: 16,
            endIndent: 0,
            color: Color(0xFFF1F1F1),
          ),
      ],
    );
  }

  Widget _buildEmergencyContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            "Contacto de Emergencia",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF495057),
            ),
          ),
        ),
        StreamBuilder<EmergencyContact>(
          stream: _firestoreService.emergencyContactStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final contact = snapshot.data ?? EmergencyContact.empty();
            final hasContact = !contact.isEmpty;

            return Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.phone,
                    color: hasContact ? redButtonColor : Colors.grey,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name.isEmpty
                              ? 'Sin configurar'
                              : contact.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasContact ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.phone.isEmpty
                              ? 'Agrega un contacto de emergencia'
                              : contact.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showEmergencyContactDialog(contact),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redButtonColor.withOpacity(0.1),
                      foregroundColor: redButtonColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: redButtonColor.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Text(
                      hasContact ? "Cambiar" : "Agregar",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showEmergencyContactDialog(
      EmergencyContact currentContact) async {
    final method = await showDialog<String>(
      context: context,
      builder: (context) => const EmergencyContactMethodDialog(),
    );

    if (method == null) return;

    EmergencyContact? result;

    if (method == 'contacts') {
      result = await showDialog<EmergencyContact>(
        context: context,
        builder: (context) => const ContactPickerDialog(),
      );
    } else if (method == 'manual') {
      result = await showDialog<EmergencyContact>(
        context: context,
        builder: (context) => EmergencyContactDialog(
          currentContact: currentContact.isEmpty ? null : currentContact,
        ),
      );
    }

    if (result != null) {
      try {
        await _firestoreService.saveEmergencyContact(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacto de emergencia guardado'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildLogoutButton() {
    return Center(
      child: TextButton.icon(
        onPressed: widget.onLogout,
        icon: const Icon(Icons.logout, color: redButtonColor),
        label: const Text(
          "Cerrar Sesión",
          style: TextStyle(
            color: redButtonColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return const Center(
      child: Text(
        "Versión 1.0.0 • Seguridad Ciudadana IA",
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}

class _ConfigSwitchItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool initialValue;
  final Color switchColor;

  const _ConfigSwitchItem({
    required this.icon,
    required this.title,
    required this.initialValue,
    required this.switchColor,
  });

  @override
  State<_ConfigSwitchItem> createState() => __ConfigSwitchItemState();
}

class __ConfigSwitchItemState extends State<_ConfigSwitchItem> {
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
          leading: Icon(widget.icon, color: widget.switchColor),
          title: Text(widget.title, style: const TextStyle(fontSize: 16)),
          trailing: Switch.adaptive(
            value: _isEnabled,
            onChanged: (bool value) {
              setState(() {
                _isEnabled = value;
                debugPrint("${widget.title}: $value");
              });
            },
            activeColor: widget.switchColor,
          ),
        ),
        const Divider(
          height: 0,
          thickness: 1,
          indent: 16,
          endIndent: 0,
          color: Color(0xFFF1F1F1),
        ),
      ],
    );
  }
}
*/

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/emergency_contact.dart';
import '../models/personal_info.dart';
import '../widgets/emergency_contact_dialog.dart';
import '../widgets/personal_info_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Colores y Estilos Personalizados ---
const Color primaryColor = Color(0xFF007AFF);
const Color activeStatusColor = Color(0xFF198754);
const Color redButtonColor = Color(0xFFDC3545);

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;
  final String? userPhotoUrl;

  const ProfileScreen({
    super.key,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
    this.userPhotoUrl,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Widget _buildDynamicDaysActiveItem() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || user.metadata.creationTime == null) {
      return _buildStatItem("0", "Días Activo");
    }

    final creationDateUTC = user.metadata.creationTime!;
    final creationDateLocal = creationDateUTC.toLocal();
    final now = DateTime.now();

    final daysActive = _calculateDaysBetween(creationDateLocal, now);
    return _buildStatItem(daysActive.toString(), "Días Activo");
  }

  int _calculateDaysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Perfil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications_none, color: Colors.grey),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            _buildStatsSection(),
            const SizedBox(height: 20),
            _buildAccountConfigSection(),
            const SizedBox(height: 20),
            _buildEmergencyContactSection(),
            const SizedBox(height: 30),
            _buildLogoutButton(),
            const SizedBox(height: 30),
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.userPhotoUrl != null && widget.userPhotoUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(widget.userPhotoUrl!),
                  backgroundColor: Colors.grey.shade200,
                )
              : const CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_pin_circle,
                          size: 14, color: activeStatusColor),
                      const SizedBox(width: 4),
                      Text(
                        "Ciudadano Activo",
                        style: TextStyle(
                          fontSize: 12,
                          color: activeStatusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
/*
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem("0", "Reportes"),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFF1F1F1),
            ),
            _buildDynamicDaysActiveItem(),
          ],
        ),
      ),
    );
  }
*/

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      margin: const EdgeInsets.only(top: 10),
      color: Colors.white,
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // ⭐ REPORTES DINÁMICOS CON STREAMBUILDER
            StreamBuilder<int>(
              stream: _firestoreService.userIncidentCountStream(),
              initialData: 0, // ⭐ AGREGA ESTA LÍNEA
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildStatItem("...", "Reportes");
                }
                if (snapshot.hasError) {
                  return _buildStatItem("0", "Reportes");
                }
                final count = snapshot.data ?? 0;
                return _buildStatItem(count.toString(), "Reportes");
              },
            ),
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: Color(0xFFF1F1F1),
            ),
            _buildDynamicDaysActiveItem(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAccountConfigSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            "Configuración de Cuenta",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF495057),
            ),
          ),
        ),
        StreamBuilder<PersonalInfo>(
          stream: _firestoreService.personalInfoStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: const Center(
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final personalInfo = snapshot.data ?? PersonalInfo.empty();
            final hasInfo = !personalInfo.isEmpty;

            return Container(
              color: Colors.white,
              child: Column(
                children: [
                  _buildPersonalInfoItem(personalInfo, hasInfo),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInfoItem(PersonalInfo info, bool hasInfo) {
    return InkWell(
      onTap: () => _showPersonalInfoDialog(info),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.person_outline,
              color: hasInfo ? primaryColor : Colors.grey.shade700,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información Personal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (hasInfo) ...[
                    if (info.dni.isNotEmpty)
                      _buildInfoRow(Icons.badge_outlined, 'DNI: ${info.dni}'),
                    if (info.phone.isNotEmpty)
                      _buildInfoRow(Icons.phone_outlined, info.phone),
                    if (info.birthDate.isNotEmpty)
                      _buildInfoRow(Icons.cake_outlined, info.birthDate),
                    if (info.address.isNotEmpty)
                      _buildInfoRow(Icons.home_outlined, info.address),
                  ] else
                    const Text(
                      'Completa tu información personal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              hasInfo ? Icons.edit_outlined : Icons.add_circle_outline,
              color: primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPersonalInfoDialog(PersonalInfo currentInfo) async {
    final result = await showDialog<PersonalInfo>(
      context: context,
      builder: (context) => PersonalInfoDialog(
        currentInfo: currentInfo.isEmpty ? null : currentInfo,
      ),
    );

    if (result != null) {
      try {
        await _firestoreService.savePersonalInfo(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Información personal guardada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildEmergencyContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            "Contacto de Emergencia",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF495057),
            ),
          ),
        ),
        StreamBuilder<EmergencyContact>(
          stream: _firestoreService.emergencyContactStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                color: Colors.white,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final contact = snapshot.data ?? EmergencyContact.empty();
            final hasContact = !contact.isEmpty;

            return Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.phone,
                    color: hasContact ? redButtonColor : Colors.grey,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name.isEmpty
                              ? 'Sin configurar'
                              : contact.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasContact ? Colors.black : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contact.phone.isEmpty
                              ? 'Agrega un contacto de emergencia'
                              : contact.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showEmergencyContactDialog(contact),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: redButtonColor.withOpacity(0.1),
                      foregroundColor: redButtonColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: redButtonColor.withOpacity(0.2),
                        ),
                      ),
                    ),
                    child: Text(
                      hasContact ? "Cambiar" : "Agregar",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _showEmergencyContactDialog(
      EmergencyContact currentContact) async {
    final method = await showDialog<String>(
      context: context,
      builder: (context) => const EmergencyContactMethodDialog(),
    );

    if (method == null) return;

    EmergencyContact? result;

    if (method == 'contacts') {
      result = await showDialog<EmergencyContact>(
        context: context,
        builder: (context) => const ContactPickerDialog(),
      );
    } else if (method == 'manual') {
      result = await showDialog<EmergencyContact>(
        context: context,
        builder: (context) => EmergencyContactDialog(
          currentContact: currentContact.isEmpty ? null : currentContact,
        ),
      );
    }

    if (result != null) {
      try {
        await _firestoreService.saveEmergencyContact(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Contacto de emergencia guardado'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildLogoutButton() {
    return Center(
      child: TextButton.icon(
        onPressed: widget.onLogout,
        icon: const Icon(Icons.logout, color: redButtonColor),
        label: const Text(
          "Cerrar Sesión",
          style: TextStyle(
            color: redButtonColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return const Center(
      child: Text(
        "Versión 1.0.0 • Seguridad Ciudadana IA",
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }
}
