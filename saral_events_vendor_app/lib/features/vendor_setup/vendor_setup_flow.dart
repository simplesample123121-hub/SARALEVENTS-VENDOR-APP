import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../core/state/session.dart';
import '../../core/theme/app_theme.dart';
import 'vendor_service.dart';
import 'vendor_models.dart';

class VendorSetupFlow extends StatefulWidget {
  const VendorSetupFlow({super.key});

  @override
  State<VendorSetupFlow> createState() => _VendorSetupFlowState();
}

class _VendorSetupFlowState extends State<VendorSetupFlow> {
  final PageController _controller = PageController();
  int _step = 0;
  final VendorService _vendorService = VendorService();
  bool _isSaving = false;

  // Business Details
  final _businessName = TextEditingController();
  String _category = 'Venue';
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _workingHours = TextEditingController();
  final _gstNumber = TextEditingController();
  final _panNumber = TextEditingController();
  final _aadhaarNumber = TextEditingController();

  // Document uploads
  final Map<String, dynamic> _documents = {};
  final Map<String, bool> _documentUploaded = {};

  final List<String> _categories = [
    'Venue',
    'Farmhouse',
    'Catering',
    'Photography',
    'Music/DJ',
    'Decoration',
    'Event Essentials',
    'Transportation',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _initializeDocuments();
  }

  void _initializeDocuments() {
    final docTypes = [
      'PAN Card',
      'Aadhaar Card',
      'Address Proof',
      'Business Registration',
      'GST Certificate',
      'FSSAI License',
      'Trade License',
      'Udyam Registration',
      'Bank Details',
      'Cancelled Cheque',
      'Professional Insurance',
      'Work Portfolio',
      'Signed Agreement',
      'Authorization Letter'
    ];
    
    for (String doc in docTypes) {
      _documentUploaded[doc] = false;
      _documents[doc] = null;
    }
  }

  @override
  void dispose() {
    _businessName.dispose();
    _description.dispose();
    _address.dispose();
    _contact.dispose();
    _workingHours.dispose();
    _gstNumber.dispose();
    _panNumber.dispose();
    _aadhaarNumber.dispose();
    super.dispose();
  }

  bool get _canProceed {
    if (_step == 0) {
      return _businessName.text.isNotEmpty && _address.text.isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Vendor Setup', style: Theme.of(context).textTheme.titleLarge),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Step ${_step + 1} of 4', style: Theme.of(context).textTheme.bodyMedium),
                    Text('${((_step + 1) / 4 * 100).round()}%', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_step + 1) / 4,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _BusinessDetailsStep(
                  businessName: _businessName,
                  description: _description,
                  category: _category,
                  address: _address,
                  contact: _contact,
                  workingHours: _workingHours,
                  gstNumber: _gstNumber,
                  panNumber: _panNumber,
                  aadhaarNumber: _aadhaarNumber,
                  categories: _categories,
                  onCategoryChanged: (v) => setState(() => _category = v),
                  onTextChanged: () => setState(() {}),
                ),
                _DocumentsStep(
                  documents: _documents,
                  documentUploaded: _documentUploaded,
                  onDocumentUploaded: (docType, file) {
                    setState(() {
                      _documents[docType] = file;
                      _documentUploaded[docType] = true;
                    });
                  },
                ),
                _BankDetailsStep(),
                _ReviewStep(
                  businessName: _businessName.text,
                  category: _category,
                  address: _address.text,
                  documents: _documentUploaded,
                ),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primary),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    child: Text('Back', style: TextStyle(color: AppColors.primary)),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _canProceed ? () {
                    if (_step < 3) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _completeSetup();
                    }
                  } : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _canProceed ? AppColors.primary : Colors.grey.shade300,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _step < 3 ? 'Next' : 'Complete Setup',
                          style: TextStyle(
                            color: _canProceed ? Colors.white : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _completeSetup() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      // Create vendor profile
      final vendorProfile = VendorProfile(
        userId: context.read<AppSession>().currentUser?.id ?? '',
        businessName: _businessName.text.trim(),
        address: _address.text.trim(),
        category: _category,
        phoneNumber: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
        email: context.read<AppSession>().currentUser?.email,
        website: null, // Not collected in current form
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        services: [], // Will be populated when services are added
        documents: [], // Will be populated when documents are uploaded
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save vendor profile to Supabase
      final savedProfile = await _vendorService.saveVendorProfile(vendorProfile);

      // Upload documents if any
      for (final entry in _documents.entries) {
        if (entry.value != null && entry.value is File) {
          try {
            await _vendorService.uploadDocument(
              entry.value as File,
              entry.key,
              savedProfile.id ?? '',
            );
          } catch (e) {
            print('Failed to upload ${entry.key}: $e');
            // Continue with other documents
          }
        }
      }

      // Mark vendor setup as complete
      context.read<AppSession>().completeVendorSetup();
      
      // Navigate to dashboard
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete setup: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _BusinessDetailsStep extends StatelessWidget {
  final TextEditingController businessName;
  final TextEditingController description;
  final String category;
  final TextEditingController address;
  final TextEditingController contact;
  final TextEditingController workingHours;
  final TextEditingController gstNumber;
  final TextEditingController panNumber;
  final TextEditingController aadhaarNumber;
  final List<String> categories;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onTextChanged;

  const _BusinessDetailsStep({
    required this.businessName,
    required this.description,
    required this.category,
    required this.address,
    required this.contact,
    required this.workingHours,
    required this.gstNumber,
    required this.panNumber,
    required this.aadhaarNumber,
    required this.categories,
    required this.onCategoryChanged,
    required this.onTextChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Information',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your business. Only business name, address, and category are required.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Business Name (Required)
          TextFormField(
            controller: businessName,
            onChanged: (_) => onTextChanged(),
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              hintText: 'Enter your business name',
              prefixIcon: Icon(Icons.business),
            ),
          ),
          const SizedBox(height: 16),
          
          // Category (Required)
          DropdownButtonFormField<String>(
            value: category,
            items: categories.map((cat) => DropdownMenuItem(
              value: cat,
              child: Text(cat),
            )).toList(),
            onChanged: (v) {
              onCategoryChanged(v ?? 'Venue');
              onTextChanged();
            },
            decoration: const InputDecoration(
              labelText: 'Service Category *',
              hintText: 'Select your service category',
              prefixIcon: Icon(Icons.category),
            ),
          ),
          const SizedBox(height: 16),
          
          // Address (Required)
          TextFormField(
            controller: address,
            onChanged: (_) => onTextChanged(),
            decoration: const InputDecoration(
              labelText: 'Business Address *',
              hintText: 'Enter your business address',
              prefixIcon: Icon(Icons.location_on),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          
          // Contact
          TextFormField(
            controller: contact,
            decoration: const InputDecoration(
              labelText: 'Contact Number',
              hintText: 'Enter your contact number',
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          
          // Working Hours
          TextFormField(
            controller: workingHours,
            decoration: const InputDecoration(
              labelText: 'Working Hours',
              hintText: 'e.g., Mon-Sat: 9 AM - 6 PM',
              prefixIcon: Icon(Icons.access_time),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: description,
            decoration: const InputDecoration(
              labelText: 'Business Description',
              hintText: 'Describe your services and expertise',
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          
          // Legal Information Section
          Text(
            'Legal Information (Optional)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // GST Number
          TextFormField(
            controller: gstNumber,
            decoration: const InputDecoration(
              labelText: 'GST Number',
              hintText: 'Enter GST number if applicable',
              prefixIcon: Icon(Icons.receipt),
            ),
          ),
          const SizedBox(height: 16),
          
          // PAN Number
          TextFormField(
            controller: panNumber,
            decoration: const InputDecoration(
              labelText: 'PAN Number',
              hintText: 'Enter PAN number',
              prefixIcon: Icon(Icons.credit_card),
            ),
          ),
          const SizedBox(height: 16),
          
          // Aadhaar Number
          TextFormField(
            controller: aadhaarNumber,
            decoration: const InputDecoration(
              labelText: 'Aadhaar Number',
              hintText: 'Enter Aadhaar number',
              prefixIcon: Icon(Icons.person),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}

class _DocumentsStep extends StatelessWidget {
  final Map<String, dynamic> documents;
  final Map<String, bool> documentUploaded;
  final Function(String, dynamic) onDocumentUploaded;

  const _DocumentsStep({
    required this.documents,
    required this.documentUploaded,
    required this.onDocumentUploaded,
  });

  @override
  Widget build(BuildContext context) {
    final docCategories = {
      'Identity Documents': ['PAN Card', 'Aadhaar Card', 'Address Proof'],
      'Business Documents': ['Business Registration', 'GST Certificate', 'FSSAI License', 'Trade License', 'Udyam Registration'],
      'Financial Documents': ['Bank Details', 'Cancelled Cheque'],
      'Other Documents': ['Professional Insurance', 'Work Portfolio', 'Signed Agreement', 'Authorization Letter'],
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Upload',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload your KYC documents. All documents are optional except business name, address, and category.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          ...docCategories.entries.map((category) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.key,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          const SizedBox(height: 12),
              ...category.value.map((docType) => _DocumentTile(
                title: docType,
                isUploaded: documentUploaded[docType] ?? false,
                file: documents[docType],
                onUpload: () => _showUploadOptions(context, docType),
                onView: () => _viewDocument(context, documents[docType]),
              )),
              const SizedBox(height: 16),
            ],
          )),
        ],
      ),
    );
  }

  void _showUploadOptions(BuildContext context, String docType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, docType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, docType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_copy, color: AppColors.primary),
              title: const Text('Choose PDF'),
              onTap: () {
                Navigator.pop(context);
                _pickPDF(docType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, String docType) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image != null) {
        onDocumentUploaded(docType, File(image.path));
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _pickPDF(String docType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        onDocumentUploaded(docType, result.files.first);
      }
    } catch (e) {
      print('Error picking PDF: $e');
    }
  }

  void _viewDocument(BuildContext context, dynamic file) {
    if (file == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Preview'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: file is File && file.path.endsWith('.pdf')
              ? const Center(child: Text('PDF Preview'))
              : file is File
                  ? Image.file(file, fit: BoxFit.cover)
                  : const Center(child: Text('File Preview')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final String title;
  final bool isUploaded;
  final dynamic file;
  final VoidCallback onUpload;
  final VoidCallback onView;

  const _DocumentTile({
    required this.title,
    required this.isUploaded,
    required this.file,
    required this.onUpload,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isUploaded ? Icons.check_circle : Icons.upload_file,
          color: isUploaded ? AppColors.secondary : AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isUploaded ? FontWeight.w600 : FontWeight.w500,
            color: isUploaded ? Colors.black87 : Colors.grey.shade700,
          ),
        ),
        subtitle: isUploaded ? Text(
          file is File ? 'File uploaded' : 'Document uploaded',
          style: TextStyle(color: AppColors.secondary),
        ) : null,
        trailing: isUploaded
            ? IconButton(
                icon: const Icon(Icons.visibility, color: AppColors.primary),
                onPressed: onView,
              )
            : TextButton(
                onPressed: onUpload,
                child: const Text('Upload'),
              ),
      ),
    );
  }
}

class _BankDetailsStep extends StatelessWidget {
  final _accountHolderName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _ifscCode = TextEditingController();
  final _bankName = TextEditingController();
  final _branchName = TextEditingController();

  _BankDetailsStep();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bank Account Details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Provide your bank details for receiving payments. This information is optional.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          TextFormField(
            controller: _accountHolderName,
            decoration: const InputDecoration(
              labelText: 'Account Holder Name',
              hintText: 'Enter account holder name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _accountNumber,
            decoration: const InputDecoration(
              labelText: 'Account Number',
              hintText: 'Enter account number',
              prefixIcon: Icon(Icons.account_balance),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _ifscCode,
            decoration: const InputDecoration(
              labelText: 'IFSC Code',
              hintText: 'Enter IFSC code',
              prefixIcon: Icon(Icons.code),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _bankName,
            decoration: const InputDecoration(
              labelText: 'Bank Name',
              hintText: 'Enter bank name',
              prefixIcon: Icon(Icons.account_balance_wallet),
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _branchName,
            decoration: const InputDecoration(
              labelText: 'Branch Name',
              hintText: 'Enter branch name',
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final String businessName;
  final String category;
  final String address;
  final Map<String, bool> documents;

  const _ReviewStep({
    required this.businessName,
    required this.category,
    required this.address,
    required this.documents,
  });

  @override
  Widget build(BuildContext context) {
    final uploadedDocs = documents.values.where((uploaded) => uploaded).length;
    final totalDocs = documents.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review & Submit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your information before submitting.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          
          // Business Information
          _ReviewSection(
            title: 'Business Information',
            icon: Icons.business,
            children: [
              _ReviewItem(label: 'Business Name', value: businessName),
              _ReviewItem(label: 'Category', value: category),
              _ReviewItem(label: 'Address', value: address),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Documents
          _ReviewSection(
            title: 'Documents Uploaded',
            icon: Icons.folder,
            children: [
              _ReviewItem(
                label: 'Documents',
                value: '$uploadedDocs out of $totalDocs documents uploaded',
                valueColor: uploadedDocs > 0 ? AppColors.secondary : Colors.grey.shade600,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Note
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Only business name, address, and category are mandatory. All other information and documents are optional.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ReviewSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReviewItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


