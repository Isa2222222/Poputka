import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

class AreaSelector extends StatefulWidget {
  final String hintText;
  final Function(RecordModel?) onAreaSelected;
  final RecordModel? excludeArea; // Area to exclude from selection
  final RecordModel? selectedArea; // Currently selected area

  const AreaSelector({
    super.key,
    required this.hintText,
    required this.onAreaSelected,
    this.excludeArea,
    this.selectedArea,
  });

  @override
  State<AreaSelector> createState() => _AreaSelectorState();
}

class _AreaSelectorState extends State<AreaSelector> {
  final TextEditingController _controller = TextEditingController();
  final PocketBaseService _pbService = PocketBaseService();
  List<RecordModel> _areas = [];
  List<RecordModel> _filteredAreas = [];
  bool _isLoading = false;
  bool _showDropdown = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAreas();

    // Set initial text if we have a selected area
    if (widget.selectedArea != null) {
      _controller.text = widget.selectedArea!.data['name'].toString();
    }
  }

  @override
  void didUpdateWidget(AreaSelector oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update controller text if selected area changes
    if (widget.selectedArea != null &&
        (oldWidget.selectedArea?.id != widget.selectedArea?.id)) {
      _controller.text = widget.selectedArea!.data['name'].toString();
    }

    // Clear text if selected area was removed
    if (widget.selectedArea == null && oldWidget.selectedArea != null) {
      _controller.clear();
    }

    // Refilter areas if the excluded area changed
    if (oldWidget.excludeArea?.id != widget.excludeArea?.id) {
      _updateFilteredAreas();
    }
  }

  Future<void> _loadAreas() async {
    if (_isLoading) return; // Prevent multiple simultaneous loads

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final areas = await _pbService.getAreas();

      if (!mounted) return; // Check if widget is still in the tree

      setState(() {
        _areas = areas;
        _isLoading = false;
      });

      _updateFilteredAreas();

      if (_areas.isEmpty) {
        setState(() {
          _errorMessage = 'Нет доступных мест';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка загрузки данных';
      });
    }
  }

  void _updateFilteredAreas() {
    final query = _controller.text.toLowerCase();

    // Filter areas by search query and exclude the selected area from the other field
    final filtered = _areas.where((area) {
      // Exclude the area if it's selected in the other field
      if (widget.excludeArea != null && area.id == widget.excludeArea!.id) {
        return false;
      }

      // Filter by search query
      if (query.isNotEmpty) {
        final name = area.data['name'].toString().toLowerCase();
        return name.contains(query);
      }

      return true;
    }).toList();

    setState(() {
      _filteredAreas = filtered;
    });
  }

  void _toggleDropdown() {
    setState(() => _showDropdown = !_showDropdown);

    // Make sure filtered areas are updated when dropdown is shown
    if (!_showDropdown) {
      _updateFilteredAreas();
    }
  }

  void _selectArea(RecordModel area) {
    _controller.text = area.data['name'].toString();
    widget.onAreaSelected(area);
    setState(() => _showDropdown = false);
  }

  void _clearSelection() {
    _controller.clear();
    widget.onAreaSelected(null);
    setState(() {
      _showDropdown = true; // Show dropdown after clearing
      _updateFilteredAreas(); // Update filtered areas after clearing
    });
  }

  void _showDropdownWithOptions() {
    // Update filtered areas before showing dropdown
    _updateFilteredAreas();
    setState(() => _showDropdown = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _showDropdownWithOptions,
          borderRadius: BorderRadius.circular(8),
          child: IgnorePointer(
            ignoring: false, // Allow taps on the TextField for cursor focus
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined),
                hintText: widget.hintText,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clear button if area is selected
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: _clearSelection,
                        tooltip: 'Очистить',
                      ),
                    _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              _showDropdown
                                  ? Icons.arrow_drop_up
                                  : Icons.arrow_drop_down,
                            ),
                            onPressed: _toggleDropdown,
                            tooltip: 'Показать варианты',
                          ),
                  ],
                ),
              ),
              onTap: _showDropdownWithOptions,
              readOnly: true, // Make it act like a dropdown
            ),
          ),
        ),
        if (_errorMessage != null && !_isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 8.0),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 12,
              ),
            ),
          ),
        if (_showDropdown) _buildDropdown(),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : _filteredAreas.isEmpty
                ? _buildEmptyState()
                : _buildAreasList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Нет доступных мест',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadAreas,
              icon: const Icon(Icons.refresh),
              label: const Text('Обновить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreasList() {
    // Pre-filtered list for better performance
    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _filteredAreas.length,
      itemBuilder: (context, index) {
        final area = _filteredAreas[index];
        return ListTile(
          title: Text(area.data['name'].toString()),
          onTap: () => _selectArea(area),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
