import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../widgets/common.dart';

/// Screen 12 - Customization (Business Profile)
class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  static const _types = ['Retail Store', 'Restaurant', 'Pharmacy', 'Supermarket', 'Salon', 'Other'];
  static const _colors = [
    0xFF8E24AA, 0xFF1E6FE0, 0xFF2E9E4F, 0xFFFBC02D, 0xFFF57C00,
  ];

  late final TextEditingController _name;
  late String _type;
  late int _color;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>();
    _name = TextEditingController(text: s.businessName);
    _type = _types.contains(s.businessType) ? s.businessType : _types.first;
    _color = s.themeColor;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: simpleAppBar('Business Profile'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Business Name', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 16),
          const Text('Business Type', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _type,
            isDense: true,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _type = v ?? _type),
          ),
          const SizedBox(height: 16),
          const Text('Logo', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.storefront, size: 30, color: Colors.grey),
              ),
              TextButton(
                onPressed: () => toast(context,
                    'Add image_picker to choose a logo from the gallery.'),
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Theme Color', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: _colors
                .map((c) => GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: Container(
                        margin: const EdgeInsets.only(right: 14),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: _color == c ? Colors.black87 : Colors.transparent,
                              width: 2.5),
                        ),
                        child: _color == c
                            ? const Icon(Icons.check, color: Colors.white, size: 18)
                            : null,
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Save',
            onPressed: () {
              if (_name.text.trim().isEmpty) {
                toast(context, 'Business name is required');
                return;
              }
              context.read<AppState>().updateBusiness(
                    name: _name.text.trim(),
                    type: _type,
                    color: _color,
                  );
              toast(context, 'Business profile saved');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
