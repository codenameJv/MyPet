import 'dart:io';
import 'package:flutter/material.dart';
import '../models/pet_models.dart';
import '../services/database_service.dart';
import 'add_edit_pet_screen.dart';
import 'pet_detail_screen.dart';
import 'settings_screen.dart';
import 'appointments_screen.dart';

String _getGreeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning!';
  if (hour < 17) return 'Good afternoon!';
  return 'Good evening!';
}

String _calculateAge(String birthdate) {
  final birth = DateTime.tryParse(birthdate);
  if (birth == null) return 'Unknown';
  final now = DateTime.now();
  var years = now.year - birth.year;
  var months = now.month - birth.month;
  if (now.day < birth.day) months--;
  if (months < 0) {
    years--;
    months += 12;
  }
  if (years > 0 && months > 0) return '$years yrs, $months mo';
  if (years > 0) return '$years yrs';
  if (months > 0) return '$months mo';
  return 'Newborn';
}

Map<String, int> _getSpeciesBreakdown(List<Pet> pets) {
  final map = <String, int>{};
  for (final pet in pets) {
    map[pet.species] = (map[pet.species] ?? 0) + 1;
  }
  return map;
}

IconData _speciesIcon(String species) {
  switch (species.toLowerCase()) {
    case 'dog':
      return Icons.pets;
    case 'cat':
      return Icons.catching_pokemon;
    case 'bird':
      return Icons.flutter_dash;
    case 'fish':
      return Icons.water;
    case 'rabbit':
      return Icons.cruelty_free;
    default:
      return Icons.pets;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _dbService = DatabaseService();
  late Future<List<Pet>> _petsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _refreshPets();
  }

  void _refreshPets() {
    setState(() {
      _petsFuture = _dbService.getPets();
    });
  }

  Future<void> _navigateToAdd() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditPetScreen()),
    );
    _refreshPets();
  }

  List<Pet> _filterPets(List<Pet> pets) {
    if (_searchQuery.isEmpty) return pets;
    final query = _searchQuery.toLowerCase();
    return pets.where((pet) {
      return pet.name.toLowerCase().contains(query) ||
          pet.species.toLowerCase().contains(query) ||
          pet.breed.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Pet>>(
          future: _petsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final pets = snapshot.data ?? [];

            if (pets.isEmpty) {
              return _buildEmptyState(context);
            }

            return _buildDashboard(context, pets);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAdd,
        icon: const Icon(Icons.add),
        label: const Text('Add Pet'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _GreetingHeader(
            petCount: 0,
            onSettings: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            onAppointments: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            ),
          ),
          const Spacer(),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.pets,
              size: 56,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No pets yet!',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first furry friend',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _navigateToAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Pet'),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, List<Pet> pets) {
    final speciesBreakdown = _getSpeciesBreakdown(pets);
    final filteredPets = _filterPets(pets);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _GreetingHeader(
          petCount: pets.length,
          onSettings: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            _refreshPets();
          },
          onAppointments: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
            );
            _refreshPets();
          },
        ),
        const SizedBox(height: 16),
        SearchBar(
          hintText: 'Search pets...',
          leading: const Icon(Icons.search),
          trailing: _searchQuery.isNotEmpty
              ? [
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                    },
                  )
                ]
              : null,
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        const SizedBox(height: 24),
        _StatsSection(
          totalPets: pets.length,
          speciesCount: speciesBreakdown.length,
          speciesBreakdown: speciesBreakdown,
        ),
        const SizedBox(height: 28),
        Text(
          'My Pets',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (filteredPets.isEmpty && _searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No pets match "$_searchQuery"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ),
        ...filteredPets.map((pet) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PetCard(
                pet: pet,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PetDetailScreen(petId: pet.id!),
                    ),
                  );
                  _refreshPets();
                },
              ),
            )),
        const SizedBox(height: 80),
      ],
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final int petCount;
  final VoidCallback onSettings;
  final VoidCallback onAppointments;

  const _GreetingHeader({
    required this.petCount,
    required this.onSettings,
    required this.onAppointments,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = petCount == 0
        ? 'Start building your pet family'
        : 'You have $petCount ${petCount == 1 ? 'pet' : 'pets'} in your family';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onAppointments,
          icon: const Icon(Icons.calendar_month),
          tooltip: 'Appointments',
        ),
        IconButton(
          onPressed: onSettings,
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
        ),
      ],
    );
  }
}

class _StatsSection extends StatelessWidget {
  final int totalPets;
  final int speciesCount;
  final Map<String, int> speciesBreakdown;

  const _StatsSection({
    required this.totalPets,
    required this.speciesCount,
    required this.speciesBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.pets,
                value: '$totalPets',
                label: 'Total Pets',
                color: Theme.of(context).colorScheme.primaryContainer,
                onColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.category,
                value: '$speciesCount',
                label: 'Species',
                color: Theme.of(context).colorScheme.tertiaryContainer,
                onColor: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: speciesBreakdown.entries.map((entry) {
            return Chip(
              avatar: Icon(_speciesIcon(entry.key), size: 18),
              label: Text(
                  '${entry.value} ${entry.key}${entry.value > 1 ? 's' : ''}'),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color onColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: onColor),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onColor,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: onColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;
  final VoidCallback onTap;

  const _PetCard({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMale = pet.gender.toLowerCase() == 'male';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: pet.photoPath != null
                      ? Image.file(
                          File(pet.photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholderIcon(context),
                        )
                      : _placeholderIcon(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            pet.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          isMale ? Icons.male : Icons.female,
                          size: 20,
                          color: isMale ? Colors.blue : Colors.pink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pet.breed.isNotEmpty
                          ? '${pet.species} \u00B7 ${pet.breed}'
                          : pet.species,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.cake_outlined,
                          label: _calculateAge(pet.birthdate),
                        ),
                        const SizedBox(width: 8),
                        _InfoChip(
                          icon: Icons.monitor_weight_outlined,
                          label: '${pet.weight} kg',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.pets,
        size: 36,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
