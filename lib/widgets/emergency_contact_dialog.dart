import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/emergency_contact.dart';

// Diálogo para elegir método de entrada
class EmergencyContactMethodDialog extends StatelessWidget {
  const EmergencyContactMethodDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contacto de Emergencia'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '¿Cómo deseas agregar el contacto?',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.contacts, color: Color(0xFF007AFF)),
            title: const Text('Desde Contactos'),
            subtitle: const Text('Selecciona de tu agenda'),
            onTap: () => Navigator.of(context).pop('contacts'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit, color: Color(0xFF007AFF)),
            title: const Text('Ingresar Manualmente'),
            subtitle: const Text('Escribe los datos'),
            onTap: () => Navigator.of(context).pop('manual'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

// Diálogo de entrada manual
class EmergencyContactDialog extends StatefulWidget {
  final EmergencyContact? currentContact;

  const EmergencyContactDialog({
    super.key,
    this.currentContact,
  });

  @override
  State<EmergencyContactDialog> createState() => _EmergencyContactDialogState();
}

class _EmergencyContactDialogState extends State<EmergencyContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.currentContact?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.currentContact?.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final contact = EmergencyContact(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      Navigator.of(context).pop(contact);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Contacto de Emergencia'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un nombre';
                }
                if (value.trim().length < 3) {
                  return 'El nombre debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Número de teléfono',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                hintText: '+51 999 999 999',
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor ingresa un teléfono';
                }
                final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (digitsOnly.length < 9) {
                  return 'Ingresa un número válido (mín. 9 dígitos)';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveContact,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC3545),
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

// Diálogo para seleccionar de contactos
class ContactPickerDialog extends StatefulWidget {
  const ContactPickerDialog({super.key});

  @override
  State<ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<ContactPickerDialog> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      // Pedir permiso
      if (!await FlutterContacts.requestPermission(readonly: true)) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de contactos denegado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Obtener contactos con teléfonos
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      // Filtrar solo contactos con teléfono
      final contactsWithPhone = contacts
          .where((c) => c.displayName.isNotEmpty && c.phones.isNotEmpty)
          .toList();

      // Ordenar alfabéticamente
      contactsWithPhone.sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      setState(() {
        _contacts = contactsWithPhone;
        _filteredContacts = contactsWithPhone;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando contactos: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar contactos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts
            .where((contact) =>
                contact.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  String _formatPhoneNumber(String phone) {
    // Limpiar el número (quitar espacios, guiones, etc.)
    return phone.replaceAll(RegExp(r'[^\d+]'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF007AFF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.contacts, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Selecciona un Contacto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar contacto...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filterContacts,
            ),
          ),

          // Contacts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No hay contactos disponibles'
                              : 'No se encontraron contactos',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          final phone = contact.phones.first.number;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  const Color(0xFF007AFF).withOpacity(0.1),
                              child: Text(
                                contact.displayName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF007AFF),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(contact.displayName),
                            subtitle: Text(phone),
                            onTap: () {
                              final emergencyContact = EmergencyContact(
                                name: contact.displayName,
                                phone: _formatPhoneNumber(phone),
                              );
                              Navigator.of(context).pop(emergencyContact);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
