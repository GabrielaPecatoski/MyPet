import 'dart:io';
import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../models/pet.dart';
import '../widgets/mypet_app_bar.dart';
import 'add_pet_screen.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});
  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  final List<PetModel> _pets = [
    PetModel(id: '1', name: 'Rex', type: 'Cachorro', breed: 'Golden Retriever', age: 3),
    PetModel(id: '2', name: 'Luna', type: 'Gato', breed: 'Siamês', age: 2),
  ];

  Future<void> _addPet() async {
    final pet = await Navigator.push<PetModel>(
      context,
      MaterialPageRoute(builder: (_) => const AddPetScreen()),
    );
    if (pet != null) setState(() => _pets.add(pet));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: MypetAppBar(
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _addPet,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
      body: _pets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(Icons.pets,
                        size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nenhum pet cadastrado',
                      style: TextStyle(
                          color: AppColors.dark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('Toque no + para adicionar um pet',
                      style: TextStyle(color: AppColors.grey, fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: _pets.length,
              itemBuilder: (ctx, i) => _PetCard(
                pet: _pets[i],
                onDelete: () => setState(() => _pets.removeAt(i)),
              ),
            ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetModel pet;
  final VoidCallback onDelete;
  const _PetCard({required this.pet, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage:
                pet.imageUrl != null ? FileImage(File(pet.imageUrl!)) : null,
            child: pet.imageUrl == null
                ? Text(pet.typeIcon, style: const TextStyle(fontSize: 24))
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.dark)),
                const SizedBox(height: 2),
                Text('${pet.breed} • ${pet.age} anos',
                    style: const TextStyle(fontSize: 13, color: AppColors.grey)),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'delete') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('Remover pet'),
                    content: Text('Deseja remover ${pet.name}?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar')),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          onDelete();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.danger, elevation: 0),
                        child: const Text('Remover',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Editar')),
              const PopupMenuItem(value: 'delete', child: Text('Remover')),
            ],
            child: const Icon(Icons.more_vert, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
