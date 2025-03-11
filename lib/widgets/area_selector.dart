import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../constants/app_colors.dart';

class AreaSelector extends StatefulWidget {
  final String hintText;
  final Function(RecordModel) onAreaSelected;
  final RecordModel? excludeArea; // Area to exclude from selection

  const AreaSelector({
    super.key,
    required this.hintText,
    required this.onAreaSelected,
    this.excludeArea,
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
  }

  @override
  void didUpdateWidget(AreaSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  }

  void _selectArea(RecordModel area) {
    _controller.text = area.data['name'].toString();
    widget.onAreaSelected(area);
    setState(() => _showDropdown = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
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
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: _toggleDropdown,
                  ),
          ),
          onTap: () {
            if (!_showDropdown) {
              _toggleDropdown();
            }
          },
          readOnly: true, // Make it act like a dropdown
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
            : _areas.isEmpty
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
