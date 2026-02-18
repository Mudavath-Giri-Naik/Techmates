
import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../widgets/main_layout.dart';
import 'package:intl/intl.dart';

class CreateOpportunityScreen extends StatefulWidget {
  final String? initialType;
  final Map<String, dynamic>? existingData; // For duplicate/edit
  final String? editId; // If validation passed, this triggers Update mode

  const CreateOpportunityScreen({
    super.key, 
    this.initialType,
    this.existingData, 
    this.editId,
  });

  @override
  State<CreateOpportunityScreen> createState() => _CreateOpportunityScreenState();
}

class _CreateOpportunityScreenState extends State<CreateOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();

  String _selectedType = 'internship';
  bool _isLoading = false;

  // Common Fields
  final _titleController = TextEditingController();
  final _orgController = TextEditingController(); // Company/Organization/Organiser
  final _linkController = TextEditingController(); // Apply Link / Website
  final _locationController = TextEditingController(); // General Location
  final _descriptionController = TextEditingController();
  
  // Date Fields
  DateTime _deadline = DateTime.now().add(const Duration(days: 7)); // Applications Deadline
  DateTime? _startDate; // For Hackathon/Event
  DateTime? _endDate;   // For Hackathon/Event

  // Internship Specific
  final _stipendController = TextEditingController(); 
  final _durationController = TextEditingController();
  String _empType = 'Full-time'; 
  final _eligibilityController = TextEditingController(); // Also used for Hackathon
  final _tagsController = TextEditingController(); // Comma separated
  bool _isEliteInternship = true;

  // Hackathon Specific
  final _prizeController = TextEditingController(); // 'prizes'
  final _teamSizeController = TextEditingController();
  final _roundsController = TextEditingController();

  // Event Specific
  final _venueController = TextEditingController(); 
  final _entryFeeController = TextEditingController(); 
  final _locationLinkController = TextEditingController(); 

  // Source Field
  final _sourceController = TextEditingController();
  static const _sourceSuggestions = [
    'Internshala', 'Unstop', 'LinkedIn',
    'Company Career Page', 'IIT Portal', 'Google Search',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _selectedType = widget.initialType!;
    }

    if (widget.existingData != null) {
      _prefillData();
    }
  }

  void _prefillData() {
    final data = widget.existingData!;
    // Common
    _titleController.text = data['title'] ?? '';
    _orgController.text = data['company'] ?? data['organization'] ?? data['organizer'] ?? '';
    _linkController.text = data['link'] ?? data['apply_link'] ?? '';
    _locationController.text = data['location'] ?? '';
    _descriptionController.text = data['description'] ?? '';

    // Source
    _sourceController.text = data['source'] ?? '';
    
    // Deadline
    if (data['deadline'] != null) {
      _deadline = DateTime.tryParse(data['deadline'].toString())?.toLocal() ?? DateTime.now();
    } else if (data['apply_deadline'] != null) {
       _deadline = DateTime.tryParse(data['apply_deadline'].toString())?.toLocal() ?? DateTime.now();
    }

    // Start/End Dates
    if (data['start_date'] != null) {
      _startDate = DateTime.tryParse(data['start_date'].toString())?.toLocal();
    }
    if (data['end_date'] != null) {
      _endDate = DateTime.tryParse(data['end_date'].toString())?.toLocal();
    }

    // Type specific
    if (_selectedType == 'internship') {
       _stipendController.text = data['stipend']?.toString() ?? '';
       _durationController.text = data['duration'] ?? '';
       _empType = data['emp_type'] ?? data['mode'] ?? 'Full-time';
       const validTypes = ['Full-time', 'Part-time', 'Contract', 'Research Internship'];
       if (!validTypes.contains(_empType)) _empType = 'Full-time';
       _isEliteInternship = _parseEliteToggleValue(data['is_elite']);
       
       _eligibilityController.text = data['eligibility'] ?? '';
       
       // Tags
       if (data['tags'] is List) {
         _tagsController.text = (data['tags'] as List).join(', ');
       } else if (data['tags'] is String) {
         _tagsController.text = data['tags'];
       }

    } else if (_selectedType == 'hackathon') {
       _prizeController.text = data['prizes'] ?? data['prize_pool'] ?? '';
       _teamSizeController.text = data['team_size'] ?? '';
       _roundsController.text = data['rounds']?.toString() ?? '';
       _eligibilityController.text = data['eligibility'] ?? ''; // Reusing controller

    } else if (_selectedType == 'event') {
       _venueController.text = data['venue'] ?? '';
       _entryFeeController.text = data['entry_fee'] ?? '';
       _locationLinkController.text = data['location_link'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _orgController.dispose();
    _linkController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _stipendController.dispose();
    _durationController.dispose();
    _eligibilityController.dispose();
    _tagsController.dispose();
    _prizeController.dispose();
    _teamSizeController.dispose();
    _roundsController.dispose();
    _venueController.dispose();
    _entryFeeController.dispose();
    _locationLinkController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> childData = {};
      
      // Basic Fields
      childData['title'] = _titleController.text.trim();
      childData['description'] = _descriptionController.text.trim();

      // Source (common across all types)
      final sourceTrimmed = _sourceController.text.trim();
      childData['source'] = sourceTrimmed.isEmpty ? null : sourceTrimmed;
      
      // Assuming 'deadline' is always the application deadline
      // For Event this maps to 'apply_deadline' usually, handling below.

      if (_selectedType == 'internship') {
         childData['company'] = _orgController.text.trim();
         childData['location'] = _locationController.text.trim();
         childData['link'] = _linkController.text.trim();
         childData['deadline'] = _deadline.toIso8601String();
         
         childData['emp_type'] = _empType;
         childData['stipend'] = _stipendController.text.trim(); // Service handles parsing if needed or string db
         childData['duration'] = _durationController.text.trim();
         childData['eligibility'] = _eligibilityController.text.trim();
         childData['is_elite'] = _isEliteInternship;
         
         // Fix: tags should be a List<String> for Supabase array column
         if (_tagsController.text.isNotEmpty) {
            childData['tags'] = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
         } else {
            childData['tags'] = [];
         }

      } else if (_selectedType == 'hackathon') {
         childData['company'] = _orgController.text.trim();
         childData['location'] = _locationController.text.trim();
         childData['link'] = _linkController.text.trim();
         childData['deadline'] = _deadline.toIso8601String();

         childData['prizes'] = _prizeController.text.trim();
         childData['team_size'] = _teamSizeController.text.trim();
         childData['rounds'] = int.tryParse(_roundsController.text.trim()) ?? 1;
         childData['eligibility'] = _eligibilityController.text.trim();
         
         childData['start_date'] = _startDate?.toIso8601String();
         childData['end_date'] = _endDate?.toIso8601String();

      } else if (_selectedType == 'event') {
         childData['organizer'] = _orgController.text.trim();
         childData['venue'] = _venueController.text.trim();
         // Events often rely on 'venue' instead of 'location' column in 'opportunities'?
         // But 'opportunities' table has 'location'. 
         // We should probably sync them or just fill 'location' with City/Online.
         // Let's use _locationController for the parent 'location' field.
         childData['location'] = _locationController.text.trim(); 
         
         childData['apply_link'] = _linkController.text.trim();
         childData['apply_deadline'] = _deadline.toIso8601String();
         
         childData['entry_fee'] = _entryFeeController.text.trim();
         childData['location_link'] = _locationLinkController.text.trim();
         
         childData['start_date'] = _startDate?.toIso8601String();
         childData['end_date'] = _endDate?.toIso8601String();
      }

      if (widget.editId != null) {
        await _adminService.updateOpportunity(
          id: widget.editId!,
          type: _selectedType,
          title: _titleController.text.trim(),
          organization: _orgController.text.trim(),
          additionalData: childData,
        );
      } else {
        await _adminService.createOpportunity(
          type: _selectedType,
          title: _titleController.text.trim(),
          organization: _orgController.text.trim(),
          additionalData: childData,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.editId != null ? "Updated successfully" : "Added successfully"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Opportunity"),
        content: const Text("Are you sure you want to delete this opportunity? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true && widget.editId != null) {
      try {
        setState(() => _isLoading = true);
        await _adminService.deleteOpportunity(widget.editId!);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Deleted successfully"), backgroundColor: Colors.green),
           );
           Navigator.pop(context, true); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error deleting: $e"), backgroundColor: Colors.red),
          );
           setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: Text(widget.editId != null ? "Edit Opportunity" : "New Opportunity"),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.editId != null ? [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isLoading ? null : _delete,
            tooltip: 'Delete Opportunity',
          )
        ] : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel("Basic Information"),
                const SizedBox(height: 16),
                
                // Type Selector (Disabled if editing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.editId != null ? Colors.grey.shade100 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      // Disable type change on edit to preserve data integrity
                      onChanged: widget.editId != null ? null : (val) => setState(() => _selectedType = val!),
                      items: const [
                        DropdownMenuItem(value: 'internship', child: Text("Internship")),
                        DropdownMenuItem(value: 'hackathon', child: Text("Hackathon")),
                        DropdownMenuItem(value: 'event', child: Text("Event")),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _titleController,
                  label: "Title",
                  hint: "Ex: Senior Flutter Developer",
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _orgController,
                  label: _selectedType == 'event' ? "Organizer" : "Organization / Company",
                  hint: "Ex: Techmates Inc.",
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _locationController,
                  label: "Location (City/Remote)",
                  hint: "Ex: Remote, Bangalore",
                  validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                ),

                const SizedBox(height: 24),
                _buildSectionLabel("Specific Details"),
                const SizedBox(height: 16),

                // == TYPE SPECIFIC FIELDS ==
                if (_selectedType == 'internship') ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _stipendController,
                          label: "Stipend",
                          hint: "Ex: 10000",
                          validator: (v) {
                             if (v == null || v.isEmpty) return null;
                             final numericRegex = RegExp(r'^[0-9]+k?$'); 
                             if (!numericRegex.hasMatch(v.toLowerCase())) {
                                return "Only numbers (e.g. 10000) allowed";
                             }
                             return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _durationController,
                          label: "Duration",
                          hint: "Ex: 3 Months",
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Row for EmpType
                  Container(
                    width: double.infinity,
                    child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Type", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _empType,
                                  isExpanded: true,
                                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                                  items: const [
                                    DropdownMenuItem(value: 'Full-time', child: Text("Full-time")),
                                    DropdownMenuItem(value: 'Part-time', child: Text("Part-time")),
                                    DropdownMenuItem(value: 'Contract', child: Text("Contract")),
                                    DropdownMenuItem(value: 'Research Internship', child: Text("Research")),
                                  ],
                                  onChanged: (val) => setState(() => _empType = val!),
                                ),
                              ),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _eligibilityController,
                    label: "Eligibility",
                    hint: "Ex: 3rd year students only",
                    maxLines: 2,
                  ),
                   const SizedBox(height: 16),
                  _buildTextField(
                    controller: _tagsController,
                    label: "Tags (Comma separated)",
                    hint: "Ex: Python, Django, Remote",
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            "Mark as Elite Internship",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isEliteInternship,
                          onChanged: (value) {
                            setState(() {
                              _isEliteInternship = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                ] else if (_selectedType == 'hackathon') ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _prizeController,
                          label: "Prizes / Prize Pool",
                          hint: "Ex: 50000",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _teamSizeController,
                          label: "Team Size",
                          hint: "Ex: 1-4",
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 16),
                   _buildTextField(
                    controller: _roundsController,
                    label: "Number of Rounds",
                    hint: "Ex: 2",
                     validator: (v) {
                             if (v != null && v.isNotEmpty) {
                                if (int.tryParse(v) == null) return "Number required";
                             }
                             return null;
                     }
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _eligibilityController,
                    label: "Eligibility",
                    hint: "Ex: Open to all students",
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Start/End Dates
                   Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: "Start Date",
                          selectedDate: _startDate,
                          onDateSelected: (date) => setState(() => _startDate = date),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePicker(
                          label: "End Date",
                          selectedDate: _endDate,
                          onDateSelected: (date) => setState(() => _endDate = date),
                        ),
                      ),
                    ],
                  ),

                ] else if (_selectedType == 'event') ...[
                  _buildTextField(
                    controller: _venueController,
                    label: "Venue / Platform",
                    hint: "Ex: Hall 101, Main Block or 'Zoom'",
                    validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _entryFeeController,
                          label: "Entry Fee",
                          hint: "Ex: Free or ₹100",
                        ),
                      ),
                    ],
                  ),
                   const SizedBox(height: 16),
                   Row(
                    children: [
                      Expanded(
                        child: _buildDatePicker(
                          label: "Start Date & Time",
                          selectedDate: _startDate,
                          onDateSelected: (date) => setState(() => _startDate = date),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDatePicker(
                          label: "End Date & Time",
                          selectedDate: _endDate,
                          onDateSelected: (date) => setState(() => _endDate = date),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                   _buildTextField(
                    controller: _locationLinkController,
                    label: "Google Maps Link (Optional)",
                    hint: "https://maps.google.com/...",
                    prefixIcon: Icons.map,
                  ),
                ],

                const SizedBox(height: 24),
                _buildSectionLabel("Deadline"),
                const SizedBox(height: 8),
                _buildDatePicker(
                  label: _selectedType == 'event' ? "Registration Deadline" : "Application Deadline",
                  selectedDate: _deadline,
                  onDateSelected: (date) => setState(() => _deadline = date),
                ),

                const SizedBox(height: 24),
                _buildSectionLabel("Description"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _descriptionController,
                  label: "", // Hidden label
                  hint: "Enter detailed description here...",
                  maxLines: 6,
                ),

                const SizedBox(height: 24),
                _buildSectionLabel("External Link"),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _linkController,
                  label: _selectedType == 'event' ? "Registration Link" : "Apply / Website Link",
                  hint: "https://...",
                  validator: (v) {
                    if (v!.isEmpty) return "Required";
                    if (!v.startsWith('http')) return "Must start with http/https";
                    return null;
                  },
                  prefixIcon: Icons.link,
                ),

                const SizedBox(height: 24),
                _buildSectionLabel("Source"),
                const SizedBox(height: 8),
                // Autocomplete Source Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _sourceSuggestions;
                        }
                        // Hide dropdown if text exactly matches a suggestion (just selected)
                        if (_sourceSuggestions.contains(textEditingValue.text)) {
                          return const Iterable<String>.empty();
                        }
                        return _sourceSuggestions.where((option) =>
                          option.toLowerCase().contains(textEditingValue.text.toLowerCase()),
                        );
                      },
                      onSelected: (String selection) {
                        _sourceController.text = selection;
                        // Dismiss keyboard & dropdown after selection
                        FocusScope.of(context).unfocus();
                      },
                      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                        // Sync with our own controller
                        if (textEditingController.text.isEmpty && _sourceController.text.isNotEmpty) {
                          textEditingController.text = _sourceController.text;
                        }
                        textEditingController.addListener(() {
                          _sourceController.text = textEditingController.text;
                        });
                        return TextFormField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            hintText: "Ex: Internshala, LinkedIn, Custom...",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                            prefixIcon: const Icon(Icons.source_outlined, color: Colors.grey, size: 20),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.black, width: 1.5),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14, color: Colors.black),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              constraints: const BoxConstraints(maxHeight: 220),
                              width: MediaQuery.of(context).size.width - 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                itemBuilder: (context, index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    dense: true,
                                    title: Text(option, style: const TextStyle(fontSize: 14)),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            widget.editId != null ? "Save Changes" : "Create Opportunity",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    // Determine display string
    String displayDate = selectedDate == null 
        ? "Select Date" 
        : DateFormat('MMM dd, yyyy').format(selectedDate);

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2023),
          lastDate: DateTime(2030),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(
                    displayDate,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: selectedDate == null ? Colors.grey : Colors.black87),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
           Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
           const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey, size: 20) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black),
        ),
      ],
    );
  }

  bool _parseEliteToggleValue(dynamic raw) {
    if (raw == null) return true;
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'no') return false;
    }
    return true;
  }
}
