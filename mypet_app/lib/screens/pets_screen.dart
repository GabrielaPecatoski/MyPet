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
      appBar: const MypetAppBar(showBack: false),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _pets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pets, size: 64, color: AppColors.greyLight),
                  SizedBox(height: 16),
                  Text('Nenhum pet cadastrado',
                      style: TextStyle(color: AppColors.grey, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('Toque no + para adicionar',
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: pet.imageUrl != null
                ? FileImage(File(pet.imageUrl!))
                : null,
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
                            backgroundColor: AppColors.danger),
                        child: const Text('Remover',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit', child: Text('Editar')),
              const PopupMenuItem(
                  value: 'delete', child: Text('Remover')),
            ],
            child: const Icon(Icons.more_vert, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
