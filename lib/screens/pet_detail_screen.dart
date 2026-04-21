import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/pet_models.dart';
import '../services/database_service.dart';
import 'add_edit_pet_screen.dart';

class PetDetailScreen extends StatefulWidget {
  final int petId;

  const PetDetailScreen({super.key, required this.petId});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen> {
  final _dbService = DatabaseService();
  late Future<Pet?> _petFuture;

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  void _loadPet() {
    setState(() {
      _petFuture = _dbService.getPetById(widget.petId);
    });
  }

  Future<void> _deletePet() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pet'),
        content: const Text('Are you sure you want to remove this pet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbService.deletePet(widget.petId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pet Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final pet = await _dbService.getPetById(widget.petId);
              if (pet == null || !context.mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditPetScreen(pet: pet),
                ),
              );
              _loadPet();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deletePet,
          ),
        ],
      ),
      body: FutureBuilder<Pet?>(
        future: _petFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pet = snapshot.data;
          if (pet == null) {
            return const Center(child: Text('Pet not found'));
          }

          final birthdate = DateTime.tryParse(pet.birthdate);
          final formattedDate = birthdate != null
              ? DateFormat.yMMMd().format(birthdate)
              : pet.birthdate;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 250,
                  child: pet.photoPath != null
                      ? Image.file(
                          File(pet.photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _photoPlaceholder(context),
                        )
                      : _photoPlaceholder(context),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet.name,
                        style:
                            Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pet.species} - ${pet.breed}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(height: 24),
                      _InfoRow(
                        icon: Icons.cake,
                        label: 'Birthdate',
                        value: formattedDate,
                      ),
                      _InfoRow(
                        icon: Icons.wc,
                        label: 'Gender',
                        value: pet.gender,
                      ),
                      _InfoRow(
                        icon: Icons.monitor_weight,
                        label: 'Weight',
                        value: '${pet.weight} kg',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _photoPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.pets,
        size: 80,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ],
      ),
    );
  }
}
