import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/api_service.dart';
import '../../widgets/design_system_widgets.dart';
import 'forgot_password_view.dart';

class LoginSignupView extends StatefulWidget {
  /// Receives the account type returned by the API ('student' or 'teacher'),
  /// so the shell can open the right home screen.
  final void Function(String accountType) onAuthenticated;
  const LoginSignupView({super.key, required this.onAuthenticated});

  @override
  State<LoginSignupView> createState() => _LoginSignupViewState();
}

class _LoginSignupViewState extends State<LoginSignupView> {
  bool isSignUp = false;
  bool rememberMe = true;
  bool isLoading = false;

  final emailMobileController = TextEditingController();
  final passwordController = TextEditingController();
  final fullNameController = TextEditingController();

  List<dynamic> states = [];
  List<dynamic> qualifications = [];
  Map<String, List<String>> districtsByState = {};

  int? selectedStateId;
  String? selectedStateName;
  String? selectedDistrict;
  int? selectedQualId;

  // Fallback comprehensive districts dictionary for instant responsiveness
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
    _loadSavedPreferences();
    _loadMetadata();
  }

  void _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIdentity = prefs.getString('remembered_identity');
    final savedRememberMe = prefs.getBool('remember_me') ?? true;
    if (!mounted) return;
    setState(() {
      rememberMe = savedRememberMe;
      if (savedIdentity != null && savedIdentity.isNotEmpty && rememberMe) {
        emailMobileController.text = savedIdentity;
      } else if (kDebugMode) {
        // Convenience pre-fill for on-device QA only. A release build must not
        // ship credentials in the login form, and must never auto-submit them:
        // doing so showed "Invalid email/mobile or password" on every cold
        // start before the user had touched anything.
        emailMobileController.text = 'demo@examverse.com';
        passwordController.text = 'password123';
      }
    });
  }

  Future<void> _savePreferences(String identity) async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('remembered_identity', identity);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('remembered_identity');
      await prefs.setBool('remember_me', false);
    }
  }

  void _loadMetadata() async {
    try {
      final res = await ApiService.get('/v1/auth/meta');
      if (!mounted) return;
      setState(() {
        states = res['states'] ?? [];
        qualifications = res['qualifications'] ?? [];
        if (res['districts_by_state'] is Map) {
          final apiDistricts = res['districts_by_state'] as Map<String, dynamic>;
          districtsByState = apiDistricts.map((k, v) => MapEntry(k, List<String>.from(v ?? [])));
        } else {
          districtsByState = _defaultDistrictsMap;
        }

        if (states.isNotEmpty && selectedStateId == null) {
          // Default to Bihar or first state
          final biharState = states.firstWhere((s) => (s['name'] ?? '').toString().contains('Bihar'), orElse: () => states[0]);
          selectedStateId = biharState['id'] as int?;
          selectedStateName = biharState['name'] as String?;
          _updateDistrictsForState(selectedStateName);
        }
        if (qualifications.isNotEmpty && selectedQualId == null) {
          selectedQualId = qualifications[0]['id'] as int?;
        }
      });
    } catch (_) {
      if (mounted && states.isEmpty) {
        setState(() {
          states = [
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
          qualifications = [
            {'id': 1, 'code': '10TH', 'name': '10th Pass (Matriculation)'},
            {'id': 2, 'code': '12TH', 'name': '12th Pass (Intermediate / 10+2)'},
            {'id': 4, 'code': 'GRAD', 'name': 'Graduation (BA / B.Sc / B.Com / Degree)'},
            {'id': 5, 'code': 'ENGG', 'name': 'B.Tech / B.E. (Engineering)'},
            {'id': 6, 'code': 'POSTGRAD', 'name': 'Post Graduation (MA / M.Sc / MCA)'},
            {'id': 7, 'code': 'BED', 'name': 'B.Ed / D.El.Ed (Teaching Degree)'},
            {'id': 3, 'code': 'DIPLOMA', 'name': 'Diploma / Polytechnic'},
          ];
          districtsByState = _defaultDistrictsMap;
          selectedStateId = 4;
          selectedStateName = 'Bihar';
          _updateDistrictsForState('Bihar');
          selectedQualId = 4;
        });
      }
    }
  }

  void _updateDistrictsForState(String? stateName) {
    if (stateName == null) return;
    final list = districtsByState[stateName] ?? _defaultDistrictsMap[stateName] ?? [];
    setState(() {
      if (list.isNotEmpty) {
        selectedDistrict = list[0];
      } else {
        selectedDistrict = null;
      }
    });
  }

  List<String> _getDistrictsList() {
    if (selectedStateName == null) return [];
    return districtsByState[selectedStateName!] ?? _defaultDistrictsMap[selectedStateName!] ?? [];
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppConstants.accentRose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleLogin() async {
    final identity = emailMobileController.text.trim();
    final password = passwordController.text.trim();

    if (identity.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in Mobile Number / Email and Password');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.post('/v1/auth/login', {
        'identity': identity,
        'password': password,
      });
      final accountType = (res['account_type'] as String?) ?? 'student';
      await ApiService.setSession(res['token'] as String?, remember: rememberMe, type: accountType);
      await _savePreferences(identity);
      if (!mounted) return;
      widget.onAuthenticated(accountType);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _handleSignup() async {
    final fullName = fullNameController.text.trim();
    final identity = emailMobileController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || identity.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    setState(() => isLoading = true);
    try {
      final res = await ApiService.post('/v1/auth/signup', {
        'full_name': fullName,
        'email': identity.contains('@') ? identity : '',
        'mobile': identity.contains('@') ? '' : identity,
        'password': password,
        'state_id': selectedStateId,
        'district': selectedDistrict,
        'qualification_id': selectedQualId,
      });
      await ApiService.setSession(res['token'] as String?, remember: rememberMe, type: 'student');
      await _savePreferences(identity);
      if (!mounted) return;
      widget.onAuthenticated('student');
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDistricts = _getDistrictsList();

    return Scaffold(
      backgroundColor: AppConstants.scaffoldDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24, vertical: AppConstants.space32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BRAND HEADER
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppConstants.accentBlue, AppConstants.accentCyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.accentBlue.withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: AppConstants.space16),
                  const Text(
                    'EXAMVERSE',
                    style: TextStyle(
                      color: AppConstants.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'India\'s Premier AI Exam Preparation Platform',
                    style: TextStyle(color: AppConstants.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: AppConstants.space24),

                  // LOGIN / SIGNUP CARD
                  ExamVerseCard(
                    padding: const EdgeInsets.all(AppConstants.space24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSignUp ? 'Create Candidate Account' : 'Welcome Back',
                          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isSignUp ? 'Select state, district & education for targeted prep' : 'Continue your AI performance preparation',
                          style: const TextStyle(color: AppConstants.textSecondary, fontSize: 12.5),
                        ),
                        const SizedBox(height: AppConstants.space20),

                        if (isSignUp) ...[
                          CustomTextField(
                            controller: fullNameController,
                            label: 'Full Name',
                            hint: 'e.g. Rahul Kumar Sharma',
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: AppConstants.space16),
                        ],

                        CustomTextField(
                          controller: emailMobileController,
                          label: 'Mobile Number / Email',
                          hint: 'e.g. 9876543210 or candidate@examverse.com',
                          prefixIcon: Icons.contact_mail_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppConstants.space16),

                        CustomTextField(
                          controller: passwordController,
                          label: 'Password',
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: AppConstants.space16),

                        // SIGN UP: STATE & DISTRICT & EDUCATION DROPDOWNS
                        if (isSignUp) ...[
                          // 1. STATE SELECTION DROPDOWN
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: AppConstants.accentBlue),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Select State (राज्य) *',
                                      style: TextStyle(
                                        color: AppConstants.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppConstants.cardBorder),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    isExpanded: true,
                                    value: selectedStateId,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.accentCyan),
                                    hint: const Text('Select State', style: TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
                                    items: states.map<DropdownMenuItem<int>>((s) {
                                      return DropdownMenuItem<int>(
                                        value: s['id'] as int?,
                                        child: Text(
                                          (s['name'] ?? '').toString(),
                                          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w600),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val == null) return;
                                      final matched = states.firstWhere((st) => st['id'] == val, orElse: () => null);
                                      setState(() {
                                        selectedStateId = val;
                                        selectedStateName = matched != null ? matched['name'] as String? : null;
                                        _updateDistrictsForState(selectedStateName);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.space16),

                          // 2. DISTRICT SELECTION DROPDOWN (Dynamic based on selected state)
                          if (currentDistricts.isNotEmpty) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.map_outlined, size: 16, color: AppConstants.accentCyan),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Select District (जिला) *',
                                        style: TextStyle(
                                          color: AppConstants.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppConstants.cardBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedDistrict,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.accentCyan),
                                      hint: const Text('Select District', style: TextStyle(color: AppConstants.textSecondary, fontSize: 13)),
                                      items: currentDistricts.map<DropdownMenuItem<String>>((dist) {
                                        return DropdownMenuItem<String>(
                                          value: dist,
                                          child: Text(
                                            dist,
                                            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => selectedDistrict = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.space16),
                          ],

                          // 3. EDUCATION / QUALIFICATION DROPDOWN
                          if (qualifications.isNotEmpty) ...[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.school_outlined, size: 16, color: AppConstants.accentIndigo),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Education / Qualification *',
                                        style: TextStyle(
                                          color: AppConstants.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppConstants.cardBorder),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<int>(
                                      isExpanded: true,
                                      value: selectedQualId,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: AppConstants.accentCyan),
                                      items: qualifications.map<DropdownMenuItem<int>>((q) {
                                        return DropdownMenuItem<int>(
                                          value: q['id'] as int?,
                                          child: Text(
                                            (q['name'] ?? '').toString(),
                                            style: const TextStyle(color: AppConstants.textPrimary, fontSize: 13.5, fontWeight: FontWeight.w500),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) => setState(() => selectedQualId = val),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.space16),
                          ],
                        ],

                        if (!isSignUp) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => rememberMe = !rememberMe),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: rememberMe,
                                        activeColor: AppConstants.accentCyan,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (val) => setState(() => rememberMe = val ?? true),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text('Remember Me', style: TextStyle(color: AppConstants.textSecondary, fontSize: 12.5)),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordView())),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: AppConstants.accentCyan, fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppConstants.space20),
                        ],

                        PrimaryButton(
                          label: isSignUp ? 'Create ExamVerse Account' : 'Log In to ExamVerse',
                          onPressed: isSignUp ? _handleSignup : _handleLogin,
                          isLoading: isLoading,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.space24),

                  // TOGGLE LOGIN / SIGNUP
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        isSignUp ? 'Already have an account?' : 'New candidate on ExamVerse?',
                        style: const TextStyle(color: AppConstants.textSecondary, fontSize: 13.5),
                      ),
                      TextButton(
                        onPressed: () => setState(() => isSignUp = !isSignUp),
                        child: Text(
                          isSignUp ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(color: AppConstants.accentCyan, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space12),

                  // DEMO QUICK FILL HELPER — debug builds only. These are
                  // working credentials, so they must never reach a release.
                  if (!isSignUp && kDebugMode)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.school, size: 16, color: AppConstants.accentCyan),
                          label: const Text('Demo Student', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          backgroundColor: AppConstants.accentCyan.withValues(alpha: 0.1),
                          side: BorderSide(color: AppConstants.accentCyan.withValues(alpha: 0.3)),
                          onPressed: () {
                            emailMobileController.text = 'demo@examverse.com';
                            passwordController.text = 'password123';
                            _handleLogin();
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.psychology, size: 16, color: AppConstants.accentGreen),
                          label: const Text('Demo Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          backgroundColor: AppConstants.accentGreen.withValues(alpha: 0.1),
                          side: BorderSide(color: AppConstants.accentGreen.withValues(alpha: 0.3)),
                          onPressed: () {
                            emailMobileController.text = 'teacher@examverse.com';
                            passwordController.text = 'password123';
                            _handleLogin();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
