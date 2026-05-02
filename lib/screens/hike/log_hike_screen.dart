import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/badge_service.dart';
import '../../utils/app_theme.dart';

class LogHikeScreen extends StatefulWidget {
  final TrailModel? preselectedTrail;
  const LogHikeScreen({super.key, this.preselectedTrail});

  @override
  State<LogHikeScreen> createState() => _LogHikeScreenState();
}

class _LogHikeScreenState extends State<LogHikeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _distanceController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minsController = TextEditingController();
  final _elevationController = TextEditingController();

  DateTime _hikeDate = DateTime.now();
  bool _isPublic = true;
  bool _loading = false;
  final List<File> _photos = [];
  TrailModel? _selectedTrail;

  @override
  void initState() {
    super.initState();
    _selectedTrail = widget.preselectedTrail;
    if (_selectedTrail != null) {
      _titleController.text = _selectedTrail!.name;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _distanceController.dispose();
    _hoursController.dispose();
    _minsController.dispose();
    _elevationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hikeDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _hikeDate = picked);
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 5 photos per hike')),
      );
      return;
    }
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );
    if (result != null) setState(() => _photos.add(File(result.path)));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();

    try {
      // Upload photos to Firebase Storage
      final photoURLs = <String>[];
      for (final photo in _photos) {
        final url = await StorageService.uploadHikePhoto(
          userId: auth.uid!,
          file: photo,
        );
        photoURLs.add(url);
      }

      final hours = int.tryParse(_hoursController.text) ?? 0;
      final mins = int.tryParse(_minsController.text) ?? 0;
      final durationMins = hours * 60 + mins;

      final distance =
          double.tryParse(_distanceController.text.replaceAll(',', '.')) ?? 0;

      final hike = HikeModel(
        id: '',
        userId: auth.uid!,
        trailId: _selectedTrail?.id ?? '',
        title: _titleController.text.trim(),
        distance: distance,
        durationMinutes: durationMins,
        date: _hikeDate,
        notes: _notesController.text.trim(),
        photoURLs: photoURLs,
        isPublic: _isPublic,
        createdAt: DateTime.now(),
        elevationGain: int.tryParse(_elevationController.text) ?? 0,
      );

      await firestore.addHike(hike);

      // Check and award badges
      final newBadges = await BadgeService.checkAndAwardBadges(
        authService: auth,
        firestoreService: firestore,
        hikeDistanceMiles: distance,
      );

      await auth.incrementHikeStats(
        distanceMiles: distance,
        newBadges: newBadges,
      );

      // Check photographer badge
      final user = auth.userModel;
      if (user != null && _photos.isNotEmpty) {
        final hikesWithPhotos = user.totalHikes + 1; // rough estimate
        await BadgeService.checkPhotographerBadge(
          authService: auth,
          hikesWithPhotos: hikesWithPhotos,
        );
      }

      if (mounted) {
        if (newBadges.isNotEmpty) {
          _showBadgeDialog(newBadges);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hike logged successfully!')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log hike: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showBadgeDialog(List<String> badgeIds) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Badge Earned!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: badgeIds.map((id) {
            final badge = AppBadges.findById(id);
            return ListTile(
              leading: const Icon(Icons.military_tech, color: AppTheme.accent),
              title: Text(badge?.name ?? id),
              subtitle: Text(badge?.description ?? ''),
            );
          }).toList(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a Hike')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trail name / title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Hike Title *',
                  prefixIcon: Icon(Icons.terrain),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Date picker
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      hintText: DateFormat('MMM d, yyyy').format(_hikeDate),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('MMM d, yyyy').format(_hikeDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Distance
              TextFormField(
                controller: _distanceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Distance (miles) *',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter distance';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duration
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hoursController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Hours',
                        prefixIcon: Icon(Icons.timer),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _minsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minutes',
                      ),
                      validator: (v) {
                        final h = int.tryParse(_hoursController.text) ?? 0;
                        final m = int.tryParse(v ?? '') ?? 0;
                        if (h == 0 && m == 0) return 'Enter duration';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Elevation
              TextFormField(
                controller: _elevationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Elevation Gain (ft)',
                  prefixIcon: Icon(Icons.trending_up),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Public toggle
              SwitchListTile(
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
                title: const Text('Share to community feed'),
                subtitle: const Text('Others can see this hike'),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primary,
              ),
              const SizedBox(height: 16),

              // Photos
              const Text(
                'Photos',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_photos.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (_, i) => Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_photos[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos.removeAt(i)),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Photo'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Hike'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
