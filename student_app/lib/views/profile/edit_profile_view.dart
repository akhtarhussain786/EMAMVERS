import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditProfileView({super.key, this.userData});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _examController = TextEditingController();
  final _bioController = TextEditingController();

  String? _avatarUrl;
  Uint8List? _localImageBytes;
  bool _isUploadingAvatar = false;
  bool _isLoading = false;

  List<dynamic> _states = [];
  List<dynamic> _qualifications = [];
  Map<String, List<String>> _districtsByState = {};

  int? _selectedStateId;
  String? _selectedStateName;
  String? _selectedDistrict;
  int? _selectedQualId;

  static const Map<String, List<String>> _defaultDistrictsMap = {
    'Bihar': [
      'Patna', 'Gaya', 'Muzaffarpur', 'Bhagalpur', 'Darbhanga', 'Purnia', 'Rohtas (Sasaram)',
      'Begusarai', 'Saran (Chhapra)', 'Vaishali', 'Samastipur', 'Nalanda (Bihar Sharif)',
      'Munger', 'Siwan', 'East Champaran (Motihari)', 'West Champaran (Bettiah)', 'Katihar',
      'Bhojpur (Ara)', 'Madhubani', 'Saharsa', 'Nawada', 'Buxar', 'Kishanganj', 'Sitamarhi',
      'Gopalganj', 'Jehanabad', 'Aurangabad', 'Banka', 'Khagaria', 'Jamui', 'Arwal',
      'Lakhisarai', 'Sheikhpura', 'Kaimur (Bhabua)', 'Madhepura', 'Supaul', 'Sheohar', 'Araria'
    ],
    'Madhya Pradesh': [
      'Bhopal', 'Indore', 'Gwalior', 'Jabalpur', 'Ujjain', 'Sagar', 'Rewa', 'Satna',
      'Ratlam', 'Chhindwara', 'Dewas', 'Khandwa', 'Khargone', 'Shivpuri', 'Vidisha',
      'Morena', 'Bhind', 'Sehore', 'Hoshangabad (Narmadapuram)', 'Katni', 'Singrauli',
      'Damoh', 'Mandsaur', 'Neemuch', 'Shahdol', 'Betul', 'Guna', 'Dhar', 'Raisen',
      'Balaghat', 'Seoni', 'Datia', 'Narsinghpur', 'Tikamgarh', 'Mandla', 'Barwani',
      'Ashoknagar', 'Harda', 'Anuppur', 'Panna', 'Alirajpur', 'Burhanpur', 'Sidhi',
      'Sheopur', 'Dindori', 'Umaria', 'Niwari'
    ],
    'Uttar Pradesh': [
      'Lucknow', 'Kanpur Nagar', 'Varanasi', 'Prayagraj (Allahabad)', 'Agra', 'Meerut',
      'Noida (Gautam Buddha Nagar)', 'Ghaziabad', 'Bareilly', 'Aligarh', 'Moradabad',
      'Saharanpur', 'Gorakhpur', 'Ayodhya (Faizabad)', 'Jhansi', 'Muzaffarnagar', 'Mathura',
      'Budaun', 'Rampur', 'Shahjahanpur', 'Firozabad', 'Mainpuri', 'Etawah', 'Unnao',
      'Rae Bareli', 'Sitapur', 'Hardoi', 'Lakhimpur Kheri', 'Sultanpur', 'Barabanki',
      'Bahraich', 'Basti', 'Azamgarh', 'Ballia', 'Jaunpur', 'Mirzapur', 'Sonbhadra', 'Deoria'
    ],
    'Rajasthan': [
      'Jaipur', 'Jodhpur', 'Kota', 'Bikaner', 'Ajmer', 'Udaipur', 'Bhilwara', 'Alwar',
      'Bharatpur', 'Sikar', 'Pali', 'Sri Ganganagar', 'Chittorgarh', 'Jhunjhunu', 'Nagaur',
      'Tonk', 'Hanumangarh', 'Beawar', 'Dausa', 'Sawai Madhopur', 'Churu', 'Barmer',
      'Jaisalmer', 'Jalore', 'Banswara', 'Dungarpur', 'Pratapgarh', 'Rajsamand', 'Sirohi'
    ],
    'Delhi NCR': [
      'New Delhi', 'Central Delhi', 'South Delhi', 'North Delhi', 'East Delhi', 'West Delhi',
      'North East Delhi', 'South West Delhi', 'North West Delhi', 'South East Delhi', 'Shahdara'
    ],
    'Maharashtra': [
      'Mumbai City', 'Mumbai Suburban', 'Pune', 'Nagpur', 'Thane', 'Nashik', 'Chhatrapati Sambhajinagar',
      'Solapur', 'Amravati', 'Kolhapur', 'Navi Mumbai', 'Nanded', 'Sangli', 'Jalgaon', 'Akola'
    ],
    'Jharkhand': [
      'Ranchi', 'Jamshedpur (East Singhbhum)', 'Dhanbad', 'Bokaro', 'Deoghar', 'Hazaribagh',
      'Giridih', 'Ramgarh', 'Dumka', 'Palamu (Medininagar)', 'Chaibasa', 'Godda', 'Sahebganj'
    ],
    'Chhattisgarh': [
      'Raipur', 'Bhilai / Durg', 'Bilaspur', 'Korba', 'Rajnandgaon', 'Jagdalpur (Bastar)',
      'Ambikapur (Surguja)', 'Raigarh', 'Dhamtari', 'Mahasamund', 'Kanker'
    ],
    'Haryana': [
      'Gurugram (Gurgaon)', 'Faridabad', 'Panipat', 'Ambala', 'Yamunanagar', 'Rohtak',
      'Hisar', 'Karnal', 'Sonipat', 'Panchkula', 'Bhiwani', 'Sirsa', 'Kurukshetra', 'Rewari'
    ],
    'Uttarakhand': [
      'Dehradun', 'Haridwar', 'Nainital', 'Udham Singh Nagar (Rudrapur)', 'Roorkee',
      'Rishikesh', 'Haldwani', 'Pauri Garhwal', 'Almora', 'Pithoragarh', 'Chamoli'
    ],
  };

  @override
  void initState() {
    super.initState();
    _populateInitialData();
    _loadMetadataAndProfile();
  }

  void _populateInitialData() {
    final data = widget.userData;
    if (data != null) {
      _nameController.text = (data['full_name'] ?? data['passport_holder'] ?? '').toString();
      _emailController.text = (data['email'] ?? '').toString();
      final mobile = (data['mobile'] ?? '').toString();
      _mobileController.text = mobile.startsWith('NA-') ? '' : mobile;
      _examController.text = (data['target_exam'] ?? '').toString();
      _bioController.text = (data['bio'] ?? '').toString();
      _avatarUrl = data['avatar_url'] as String?;
      _selectedDistrict = data['district'] as String?;
      if (data['state_id'] != null) {
        _selectedStateId = int.tryParse(data['state_id'].toString());
      }
      if (data['qualification_id'] != null) {
        _selectedQualId = int.tryParse(data['qualification_id'].toString());
      }
    }
  }

  void _loadMetadataAndProfile() async {
    try {
      // 1. Load meta (states, qualifications, districts)
      final meta = await ApiService.get('/v1/auth/meta');
      if (meta != null && mounted) {
        setState(() {
          _states = meta['states'] ?? [];
          _qualifications = meta['qualifications'] ?? [];
          if (meta['districts_by_state'] is Map) {
            final apiDistricts = meta['districts_by_state'] as Map<String, dynamic>;
            _districtsByState = apiDistricts.map((k, v) => MapEntry(k, List<String>.from(v ?? [])));
          } else {
            _districtsByState = _defaultDistrictsMap;
          }
        });
      }

      // 2. Fetch fresh user profile from backend to ensure latest DB record
      final profile = await ApiService.get('/v1/user/profile');
      if (profile != null && mounted) {
        setState(() {
          if (_nameController.text.isEmpty) {
            _nameController.text = profile['full_name']?.toString() ?? '';
          }
          if (_emailController.text.isEmpty) {
            _emailController.text = profile['email']?.toString() ?? '';
          }
          if (_mobileController.text.isEmpty) {
            final m = profile['mobile']?.toString() ?? '';
            _mobileController.text = m.startsWith('NA-') ? '' : m;
          }
          if (_examController.text.isEmpty) {
            _examController.text = profile['target_exam']?.toString() ?? '';
          }
          if (_bioController.text.isEmpty) {
            _bioController.text = profile['bio']?.toString() ?? '';
          }
          _avatarUrl = profile['avatar_url'] as String? ?? _avatarUrl;
          _selectedDistrict = profile['district'] as String? ?? _selectedDistrict;
          if (profile['state_id'] != null) {
            _selectedStateId = int.tryParse(profile['state_id'].toString()) ?? _selectedStateId;
          }
          if (profile['qualification_id'] != null) {
            _selectedQualId = int.tryParse(profile['qualification_id'].toString()) ?? _selectedQualId;
          }
        });
      }

      // Match selected state name
      if (_selectedStateId != null && _states.isNotEmpty) {
        final matched = _states.firstWhere((s) => s['id'] == _selectedStateId, orElse: () => null);
        if (matched != null) {
          _selectedStateName = matched['name'] as String?;
        }
      }
    } catch (_) {
      if (_states.isEmpty && mounted) {
        setState(() {
          _states = [
            {'id': 4, 'code': 'BR', 'name': 'Bihar'},
            {'id': 6, 'code': 'MP', 'name': 'Madhya Pradesh'},
            {'id': 3, 'code': 'UP', 'name': 'Uttar Pradesh'},
            {'id': 5, 'code': 'RJ', 'name': 'Rajasthan'},
            {'id': 1, 'code': 'DL', 'name': 'Delhi NCR'},
            {'id': 2, 'code': 'MH', 'name': 'Maharashtra'},
            {'id': 13, 'code': 'JH', 'name': 'Jharkhand'},
            {'id': 14, 'code': 'CG', 'name': 'Chhattisgarh'},
            {'id': 11, 'code': 'HR', 'name': 'Haryana'},
            {'id': 20, 'code': 'UK', 'name': 'Uttarakhand'},
            {'id': 33, 'code': 'ALL', 'name': 'All India / Other'},
          ];
          _qualifications = [
            {'id': 1, 'code': '10TH', 'name': '10th Pass (Matriculation)'},
            {'id': 2, 'code': '12TH', 'name': '12th Pass (Intermediate / 10+2)'},
            {'id': 4, 'code': 'GRAD', 'name': 'Graduation (BA / B.Sc / B.Com / Degree)'},
            {'id': 5, 'code': 'ENGG', 'name': 'B.Tech / B.E. (Engineering)'},
            {'id': 6, 'code': 'POSTGRAD', 'name': 'Post Graduation (MA / M.Sc / MCA)'},
            {'id': 7, 'code': 'BED', 'name': 'B.Ed / D.El.Ed (Teaching Degree)'},
            {'id': 3, 'code': 'DIPLOMA', 'name': 'Diploma / Polytechnic'},
          ];
          _districtsByState = _defaultDistrictsMap;
        });
      }
    }
  }

  List<String> _getDistrictsList() {
    if (_selectedStateName == null) return [];
    return _districtsByState[_selectedStateName!] ?? _defaultDistrictsMap[_selectedStateName!] ?? [];
  }

  void _onStateChanged(int? newId) {
    setState(() {
      _selectedStateId = newId;
      if (newId != null && _states.isNotEmpty) {
        final matched = _states.firstWhere((s) => s['id'] == newId, orElse: () => null);
        _selectedStateName = matched?['name'] as String?;
      } else {
        _selectedStateName = null;
      }
      final districts = _getDistrictsList();
      _selectedDistrict = districts.isNotEmpty ? districts[0] : null;
    });
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final pickedFile = result.files.first;
      Uint8List? bytes = pickedFile.bytes;

      if (bytes == null && pickedFile.path != null && !kIsWeb) {
        bytes = await File(pickedFile.path!).readAsBytes();
      }

      if (bytes == null || bytes.isEmpty) {
        _showSnackBar('Could not read selected image file.', isError: true);
        return;
      }

      // Check file size (max 5MB)
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        _showSnackBar('Image is too large. Please select an image under 5MB.', isError: true);
        return;
      }

      setState(() {
        _localImageBytes = bytes;
        _isUploadingAvatar = true;
      });

      final ext = pickedFile.extension ?? 'jpg';
      final base64String = base64Encode(bytes);

      final res = await ApiService.post('/v1/user/avatar', {
        'avatar_base64': base64String,
        'extension': ext,
      });

      final serverAvatarUrl = res['avatar_url'] as String?;
      if (mounted) {
        setState(() {
          if (serverAvatarUrl != null) {
            _avatarUrl = serverAvatarUrl;
          }
          _isUploadingAvatar = false;
        });
        _showSnackBar('Profile image uploaded to server!', isError: false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
        _showSnackBar('Avatar upload failed: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
      }
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: isError ? AppConstants.accentRose : AppConstants.accentEmerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _saveProfile() async {
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      _showSnackBar('Full name cannot be empty', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ApiService.put('/v1/user/profile', {
        'full_name': fullName,
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'state_id': _selectedStateId,
        'district': _selectedDistrict,
        'qualification_id': _selectedQualId,
        'target_exam': _examController.text.trim(),
        'avatar_url': _avatarUrl,
        'bio': _bioController.text.trim(),
      });

      if (mounted) {
        _showSnackBar('Profile updated successfully!', isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _examController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedAvatarUrl = AppConstants.formatImageUrl(_avatarUrl);
    final currentDistricts = _getDistrictsList();

    String initials = 'ST';
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: AppConstants.primaryDark,
      appBar: AppBar(
        backgroundColor: AppConstants.scaffoldDark,
        elevation: 0,
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: AppConstants.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. AVATAR PICKER SECTION
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppConstants.accentBlue, AppConstants.accentCyan],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(color: AppConstants.accentCyan, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: AppConstants.accentCyan.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _localImageBytes != null
                                  ? Image.memory(_localImageBytes!, width: 100, height: 100, fit: BoxFit.cover)
                                  : (formattedAvatarUrl != null && formattedAvatarUrl.isNotEmpty)
                                      ? Image.network(
                                          formattedAvatarUrl,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Center(
                                            child: Text(
                                              initials,
                                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            initials,
                                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                            ),
                          ),
                          if (_isUploadingAvatar)
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              ),
                            ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: AppConstants.accentCyan,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isUploadingAvatar ? 'Uploading avatar to server...' : 'Tap to change profile photo',
                      style: const TextStyle(color: AppConstants.accentCyan, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'Photo is stored securely on the server',
                      style: TextStyle(color: AppConstants.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space24),

              // 2. FORM FIELDS
              const Text(
                'Personal & Contact Information',
                style: TextStyle(color: AppConstants.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.space12),

              CustomTextField(
                controller: _nameController,
                label: 'Full Name *',
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: AppConstants.space16),

              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: AppConstants.space16),

              CustomTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppConstants.space24),

              // 3. TARGET EXAM & ACADEMICS
              const Text(
                'Target Exam & Location',
                style: TextStyle(color: AppConstants.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.space12),

              CustomTextField(
                controller: _examController,
                label: 'Target Exam (e.g. SSC CGL, BPSC, UPSC, RRB)',
                prefixIcon: Icons.school_outlined,
              ),
              const SizedBox(height: AppConstants.space16),

              // STATE DROPDOWN
              if (_states.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _states.any((s) => s['id'] == _selectedStateId) ? _selectedStateId : null,
                      hint: const Text('Select Home State', style: TextStyle(color: AppConstants.textMuted, fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.accentCyan),
                      items: _states.map<DropdownMenuItem<int>>((s) {
                        return DropdownMenuItem<int>(
                          value: s['id'] as int?,
                          child: Text(
                            s['name']?.toString() ?? '',
                            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: _onStateChanged,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.space16),
              ],

              // DISTRICT DROPDOWN
              if (currentDistricts.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: currentDistricts.contains(_selectedDistrict) ? _selectedDistrict : null,
                      hint: const Text('Select Home District', style: TextStyle(color: AppConstants.textMuted, fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.accentCyan),
                      items: currentDistricts.map((d) {
                        return DropdownMenuItem<String>(
                          value: d,
                          child: Text(d, style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedDistrict = val),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.space16),
              ],

              // QUALIFICATION DROPDOWN
              if (_qualifications.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConstants.cardBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      isExpanded: true,
                      value: _qualifications.any((q) => q['id'] == _selectedQualId) ? _selectedQualId : null,
                      hint: const Text('Select Educational Qualification', style: TextStyle(color: AppConstants.textMuted, fontSize: 14)),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.accentCyan),
                      items: _qualifications.map<DropdownMenuItem<int>>((q) {
                        return DropdownMenuItem<int>(
                          value: q['id'] as int?,
                          child: Text(
                            q['name']?.toString() ?? '',
                            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedQualId = val),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.space16),
              ],

              CustomTextField(
                controller: _bioController,
                label: 'Aspirant Bio / Short Note',
                prefixIcon: Icons.notes_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: AppConstants.space32),

              PrimaryButton(
                label: 'Save Profile Changes',
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
