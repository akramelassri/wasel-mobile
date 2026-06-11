import 'package:flutter/material.dart';
import 'package:wasel/main.dart';
import 'package:wasel/api/driver_service.dart';
import 'package:wasel/model/driver_profile_model.dart';
import 'package:wasel/themes/colors.dart';
import 'package:wasel/themes/text_styles.dart';

// ─────────────────────────────────────────────────────────────────
// ÉCRAN PROFIL DRIVER
// Accessible depuis Settings ET depuis le header du Home Screen.
// Affiche les infos du driver avec ses stats, et permet de modifier
// nom, téléphone et photo via PATCH /api/users/me
// ─────────────────────────────────────────────────────────────────
class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  // _profile : données affichées. Null pendant le chargement initial.
  DriverProfile? _profile;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.fetchDriverProfile(authService);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _profile = result.data;
      } else {
        _profile = null;
        _errorMessage = result.message ?? 'Unable to load profile.';
      }
    });
  }

  // ── Ouvre le bottom sheet d'édition ──
  // On passe le profil courant pour pré-remplir les champs
  void _openEditSheet() {
    if (_profile == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditProfileSheet(
        profile: _profile!,
        onSaved: (updated) {
          setState(() => _profile = updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: secondaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('My Profile', style: subHeadingText),
        centerTitle: true,
        // Bouton edit dans l'AppBar — visible seulement quand le profil est chargé
        actions: [
          if (_profile != null)
            TextButton(
              onPressed: _openEditSheet,
              child: Text(
                'Edit',
                style: bolderLabelText.copyWith(color: primaryColor),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _profile == null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  // ── Contenu principal ──
  Widget _buildContent() {
    final profile = _profile!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // ── Avatar + nom + email ──
          // Centré en haut, même style que le Settings screen des maquettes
          Center(
            child: Column(
              children: [
                // Avatar — initiales si pas de photo, image sinon
                _Avatar(
                  imageUrl: profile.profileImageUrl,
                  initials: '${profile.firstName[0]}${profile.lastName[0]}',
                  radius: 48,
                  onTap:
                      _openEditSheet, // tap sur la photo ouvre aussi l'édition
                ),
                const SizedBox(height: 16),
                Text(profile.fullName, style: headingText),
                const SizedBox(height: 4),
                // Email en gris car non modifiable
                Text(
                  profile.email,
                  style: captionText.copyWith(
                    color: secondaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Stats : note moyenne + nb missions ──
          // Deux cards côte à côte comme dans les maquettes Uber/Glovo
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.star_rounded,
                  iconColor: primaryColor,
                  value: profile.averageRating.toStringAsFixed(1),
                  label: 'Rating',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.moped_rounded,
                  iconColor: secondaryColor,
                  value: profile.totalMissions.toString(),
                  label: 'Missions',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Section infos personnelles ──
          Text('Personal Info', style: subHeadingText),
          const SizedBox(height: 12),

          // Téléphone — modifiable
          _InfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: profile.phone,
          ),

          const Divider(color: surfaceVariant, height: 1),

          // Email — non modifiable, on l'indique clairement à l'utilisateur
          _InfoRow(
            icon: Icons.email_rounded,
            label: 'Email',
            value: profile.email,
            isLocked:
                true, // affiche un cadenas pour signaler que c'est verrouillé
          ),

          const SizedBox(height: 24),

          // ── Section véhicule ──
          // Lecture seule — les infos véhicule viennent du dossier validé par l'admin
          // Le driver ne peut pas les modifier lui-même (géré dans le dossier)
          Text('Vehicle', style: subHeadingText),
          const SizedBox(height: 12),

          _InfoRow(
            icon: Icons.directions_bike_rounded,
            label: 'Type',
            value: profile.vehicleType,
            isLocked: true,
          ),

          const Divider(color: surfaceVariant, height: 1),

          _InfoRow(
            icon: Icons.badge_rounded,
            label: 'Plate',
            value: profile.vehicleMatricule,
            isLocked: true,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── État erreur ──
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: surfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Could not load profile',
            style: subHeadingText.copyWith(color: secondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() => _loading = true);
              _loadProfile();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: secondaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text('Retry', style: bolderLabelText),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// AVATAR — affiche photo ou initiales
// Réutilisable partout dans l'app (home header, profile, chat...)
// ─────────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double radius;
  final VoidCallback? onTap;

  const _Avatar({
    required this.imageUrl,
    required this.initials,
    required this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: primaryColor.withValues(alpha: 0.15),
            // Si imageUrl est disponible, on affiche la photo, sinon les initiales
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
            child: imageUrl == null
                ? Text(
                    initials.toUpperCase(),
                    style: headingText.copyWith(
                      color: primaryColor,
                      fontSize: radius * 0.5,
                    ),
                  )
                : null,
          ),
          // Icône caméra en bas à droite si onTap est fourni (indique que c'est éditable)
          if (onTap != null)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt_rounded,
                  size: radius * 0.3,
                  color: secondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STAT CARD — une carte chiffre + label (rating, missions)
// ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(value, style: headingText.copyWith(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            label,
            style: captionText.copyWith(
              color: secondaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// INFO ROW — ligne d'information avec icône, label et valeur
// isLocked = true affiche un cadenas et grise la ligne
// ─────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLocked;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // Icône de la ligne
          Icon(
            icon,
            size: 20,
            color: isLocked
                ? secondaryColor.withValues(alpha: 0.3)
                : secondaryColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 14),
          // Label (Phone, Email...) en petit gris au-dessus de la valeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: captionText.copyWith(
                    color: secondaryColor.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: bodyText.copyWith(
                    color: isLocked
                        ? secondaryColor.withValues(alpha: 0.4)
                        : onBackground,
                  ),
                ),
              ],
            ),
          ),
          // Cadenas si le champ n'est pas modifiable
          if (isLocked)
            Icon(
              Icons.lock_outline_rounded,
              size: 16,
              color: secondaryColor.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEET D'ÉDITION
// S'ouvre par-dessus l'écran profil. Contient les champs modifiables :
// prénom, nom, téléphone. Photo via un tap sur l'avatar.
// Dans le vrai projet : appelle PATCH /api/users/me à la sauvegarde.
// ─────────────────────────────────────────────────────────────────
class _EditProfileSheet extends StatefulWidget {
  final DriverProfile profile;
  final ValueChanged<DriverProfile> onSaved;

  const _EditProfileSheet({required this.profile, required this.onSaved});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  // Controllers pour récupérer les valeurs des champs texte
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;

  // _saving : true pendant l'appel API pour désactiver le bouton
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplit les champs avec les valeurs actuelles du profil
    _firstNameCtrl = TextEditingController(text: widget.profile.firstName);
    _lastNameCtrl = TextEditingController(text: widget.profile.lastName);
    _phoneCtrl = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    // Toujours dispose les controllers pour éviter les memory leaks
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ── Sauvegarde ──
  // Dans le vrai projet : PATCH /api/users/me avec { firstName, lastName, phone }
  Future<void> _save() async {
    // Validation basique — champs vides non autorisés
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() => _saving = true);

    final authService = InheritedAuth.of(context).authService;
    final result = await DriverService.updateDriverProfile(
      authService,
      _firstNameCtrl.text.trim(),
      _lastNameCtrl.text.trim(),
      _phoneCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Unable to update profile'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    widget.onSaved(result.data!);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // viewInsets.bottom = hauteur du clavier — permet au sheet de monter avec le clavier
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + keyboardHeight),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // le sheet prend la hauteur de son contenu
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle visuel du bottom sheet ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text('Edit Profile', style: subHeadingText),

          const SizedBox(height: 24),

          // ── Avatar éditable ──
          Center(
            child: _Avatar(
              imageUrl: widget.profile.profileImageUrl,
              initials:
                  '${widget.profile.firstName[0]}${widget.profile.lastName[0]}',
              radius: 40,
              // Dans le vrai projet : ouvre le picker d'image → upload MinIO
              // → PATCH /api/users/me avec { profileObjectKey }
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image upload — coming soon')),
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ── Champs de formulaire ──
          Row(
            children: [
              Expanded(
                child: _FormField(
                  controller: _firstNameCtrl,
                  label: 'First Name',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FormField(
                  controller: _lastNameCtrl,
                  label: 'Last Name',
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _FormField(
            controller: _phoneCtrl,
            label: 'Phone',
            keyboardType: TextInputType.phone,
          ),

          const SizedBox(height: 24),

          // ── Bouton Save ──
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: secondaryColor,
                    ),
                  )
                : Text(
                    'Save changes',
                    style: bolderLabelText.copyWith(color: secondaryColor),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CHAMP DE FORMULAIRE — TextField stylisé avec le design system
// Réutilisé pour tous les champs du bottom sheet
// ─────────────────────────────────────────────────────────────────
class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType keyboardType;

  const _FormField({
    required this.controller,
    required this.label,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: bodyText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: captionText.copyWith(
          color: secondaryColor.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor: surfaceColor,
        // Bordure par défaut : grise légère
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: surfaceVariant),
        ),
        // Bordure focus : jaune primary
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
