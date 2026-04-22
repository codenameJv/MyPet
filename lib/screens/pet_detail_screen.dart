import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/pet_models.dart';
import '../models/health_models.dart';
import '../models/weight_models.dart';
import '../models/note_models.dart';
import '../models/appointment_models.dart';
import '../services/database_service.dart';
import 'add_edit_pet_screen.dart';
import 'add_vaccination_screen.dart';
import 'add_medication_screen.dart';
import 'add_vet_visit_screen.dart';
import 'add_weight_entry_screen.dart';
import 'add_note_screen.dart';

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
        content: const Text(
            'Are you sure you want to remove this pet? All related records will be deleted.'),
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
    return FutureBuilder<Pet?>(
      future: _petFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final pet = snapshot.data;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Pet not found')),
          );
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
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
                  flexibleSpace: FlexibleSpaceBar(
                    background: pet.photoPath != null
                        ? Image.file(
                            File(pet.photoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _photoPlaceholder(context),
                          )
                        : _photoPlaceholder(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pet.species} - ${pet.breed}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _TabBarDelegate(
                    TabBar(
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Health'),
                        Tab(text: 'Weight'),
                        Tab(text: 'Notes'),
                      ],
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                children: [
                  _OverviewTab(pet: pet),
                  _HealthTab(petId: widget.petId),
                  _WeightTab(petId: widget.petId),
                  _NotesTab(petId: widget.petId),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _photoPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Center(
        child: Icon(
          Icons.pets,
          size: 80,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}

// ─── Overview Tab ───

class _OverviewTab extends StatelessWidget {
  final Pet pet;
  const _OverviewTab({required this.pet});

  @override
  Widget build(BuildContext context) {
    final birthdate = DateTime.tryParse(pet.birthdate);
    final formattedDate = birthdate != null
        ? DateFormat.yMMMd().format(birthdate)
        : pet.birthdate;

    final dbService = DatabaseService();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _InfoRow(icon: Icons.cake, label: 'Birthdate', value: formattedDate),
        _InfoRow(icon: Icons.wc, label: 'Gender', value: pet.gender),
        _InfoRow(
          icon: Icons.monitor_weight,
          label: 'Weight',
          value: '${pet.weight} kg',
        ),
        const SizedBox(height: 24),
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<dynamic>>(
          future: Future.wait([
            dbService.getAppointmentsForPet(pet.id!),
            dbService.getVaccinationsForPet(pet.id!),
            dbService.getVetVisitsForPet(pet.id!),
          ]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final appointments = snapshot.data![0] as List<Appointment>;
            final vaccinations = snapshot.data![1] as List<Vaccination>;
            final vetVisits = snapshot.data![2] as List<VetVisit>;

            final upcoming = appointments
                .where((a) =>
                    DateTime.tryParse(a.dateTime)?.isAfter(DateTime.now()) ??
                    false)
                .length;

            return Row(
              children: [
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.event,
                    value: '$upcoming',
                    label: 'Upcoming',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.vaccines,
                    value: '${vaccinations.length}',
                    label: 'Vaccines',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickStatCard(
                    icon: Icons.local_hospital,
                    value: '${vetVisits.length}',
                    label: 'Vet Visits',
                  ),
                ),
              ],
            );
          },
        ),
      ],
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

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _QuickStatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Health Tab ───

class _HealthTab extends StatefulWidget {
  final int petId;
  const _HealthTab({required this.petId});

  @override
  State<_HealthTab> createState() => _HealthTabState();
}

class _HealthTabState extends State<_HealthTab> {
  final _dbService = DatabaseService();
  List<Vaccination> _vaccinations = [];
  List<Medication> _medications = [];
  List<VetVisit> _vetVisits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final vaccinations = await _dbService.getVaccinationsForPet(widget.petId);
    final medications = await _dbService.getMedicationsForPet(widget.petId);
    final vetVisits = await _dbService.getVetVisitsForPet(widget.petId);
    if (mounted) {
      setState(() {
        _vaccinations = vaccinations;
        _medications = medications;
        _vetVisits = vetVisits;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          context,
          title: 'Vaccinations',
          icon: Icons.vaccines,
          count: _vaccinations.length,
          onAdd: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddVaccinationScreen(petId: widget.petId),
              ),
            );
            _loadData();
          },
          children: _vaccinations.map((v) {
            final date = DateTime.tryParse(v.date);
            return _HealthCard(
              title: v.name,
              subtitle:
                  date != null ? DateFormat.yMMMd().format(date) : v.date,
              trailing: v.nextDueDate != null
                  ? 'Due: ${_formatDate(v.nextDueDate!)}'
                  : null,
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddVaccinationScreen(
                      petId: widget.petId,
                      vaccination: v,
                    ),
                  ),
                );
                _loadData();
              },
              onDelete: () async {
                await _dbService.deleteVaccination(v.id!);
                _loadData();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          title: 'Medications',
          icon: Icons.medication,
          count: _medications.length,
          onAdd: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddMedicationScreen(petId: widget.petId),
              ),
            );
            _loadData();
          },
          children: _medications.map((m) {
            return _HealthCard(
              title: m.name,
              subtitle: '${m.dosage} - ${m.frequency}',
              trailing: 'Since ${_formatDate(m.startDate)}',
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMedicationScreen(
                      petId: widget.petId,
                      medication: m,
                    ),
                  ),
                );
                _loadData();
              },
              onDelete: () async {
                await _dbService.deleteMedication(m.id!);
                _loadData();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildSection(
          context,
          title: 'Vet Visits',
          icon: Icons.local_hospital,
          count: _vetVisits.length,
          onAdd: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddVetVisitScreen(petId: widget.petId),
              ),
            );
            _loadData();
          },
          children: _vetVisits.map((v) {
            return _HealthCard(
              title: v.reason,
              subtitle: _formatDate(v.date),
              trailing: v.cost != null
                  ? '\$${v.cost!.toStringAsFixed(2)}'
                  : null,
              onEdit: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddVetVisitScreen(
                      petId: widget.petId,
                      vetVisit: v,
                    ),
                  ),
                );
                _loadData();
              },
              onDelete: () async {
                await _dbService.deleteVetVisit(v.id!);
                _loadData();
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  String _formatDate(String isoDate) {
    final dt = DateTime.tryParse(isoDate);
    return dt != null ? DateFormat.yMMMd().format(dt) : isoDate;
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required int count,
    required VoidCallback onAdd,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '$title ($count)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        if (children.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No records yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ...children,
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? trailing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HealthCard({
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (trailing != null)
              Text(
                trailing!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        isThreeLine: trailing != null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

// ─── Weight Tab ───

class _WeightTab extends StatefulWidget {
  final int petId;
  const _WeightTab({required this.petId});

  @override
  State<_WeightTab> createState() => _WeightTabState();
}

class _WeightTabState extends State<_WeightTab> {
  final _dbService = DatabaseService();
  List<WeightEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final entries = await _dbService.getWeightEntriesForPet(widget.petId);
    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _addEntry() async {
    final entry = await showDialog<WeightEntry>(
      context: context,
      builder: (_) => AddWeightEntryScreen(petId: widget.petId),
    );
    if (entry != null) {
      await _dbService.insertWeightEntry(entry);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Icon(Icons.show_chart,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Weight Chart',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addEntry,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_entries.length >= 2)
          _buildChart(context)
        else
          _buildChartPlaceholder(context),
        const SizedBox(height: 24),
        Text(
          'History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (_entries.isEmpty)
          Text(
            'No weight entries yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ..._entries.reversed.map((entry) {
          final date = DateTime.tryParse(entry.date);
          final dateStr =
              date != null ? DateFormat.yMMMd().format(date) : entry.date;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.monitor_weight),
              title: Text('${entry.weight} kg'),
              subtitle: Text(dateStr),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await _dbService.deleteWeightEntry(entry.id!);
                  _loadData();
                },
              ),
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildChartPlaceholder(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Add at least 2 entries to see the chart',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final firstDate = DateTime.parse(_entries.first.date);
    final spots = _entries.map((e) {
      final date = DateTime.parse(e.date);
      final days = date.difference(firstDate).inDays.toDouble();
      return FlSpot(days, e.weight);
    }).toList();

    final minY =
        _entries.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 1;
    final maxY =
        _entries.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 1;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = firstDate.add(Duration(days: value.toInt()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('M/d').format(date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Notes Tab ───

class _NotesTab extends StatefulWidget {
  final int petId;
  const _NotesTab({required this.petId});

  @override
  State<_NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<_NotesTab> {
  final _dbService = DatabaseService();
  List<PetNote> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final notes = await _dbService.getNotesForPet(widget.petId);
    if (mounted) {
      setState(() {
        _notes = notes;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        if (_notes.isEmpty)
          Center(
            child: Text(
              'No notes yet',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _notes.length + 1,
            itemBuilder: (context, index) {
              if (index == _notes.length) return const SizedBox(height: 80);
              final note = _notes[index];
              final date = DateTime.tryParse(note.createdAt);
              final dateStr = date != null
                  ? DateFormat('MMM d, y – h:mm a').format(date)
                  : note.createdAt;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (note.isPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.push_pin,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              dateStr,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'pin') {
                                await _dbService.updateNote(
                                  note.copyWith(isPinned: !note.isPinned),
                                );
                                _loadData();
                              } else if (value == 'edit') {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddNoteScreen(
                                      petId: widget.petId,
                                      note: note,
                                    ),
                                  ),
                                );
                                _loadData();
                              } else if (value == 'delete') {
                                await _dbService.deleteNote(note.id!);
                                _loadData();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'pin',
                                child:
                                    Text(note.isPinned ? 'Unpin' : 'Pin'),
                              ),
                              const PopupMenuItem(
                                  value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(note.content),
                    ],
                  ),
                ),
              );
            },
          ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddNoteScreen(petId: widget.petId),
                ),
              );
              _loadData();
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
