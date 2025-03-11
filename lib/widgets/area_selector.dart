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
  bool _isLoading = false;
  bool _showDropdown = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final areas = await _pbService.getAreas();
      setState(() {
        _areas = areas;
        _isLoading = false;
      });

      if (_areas.isEmpty) {
        setState(() {
          _errorMessage = 'Нет доступных мест';
        });
      }
    } catch (e) {
      print('Error loading areas: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка загрузки данных';
      });
    }
  }

  List<RecordModel> _getFilteredAreas() {
    final query = _controller.text.toLowerCase();

    // Filter areas by search query and exclude the selected area from the other field
    return _areas.where((area) {
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
                    onPressed: () {
                      setState(() => _showDropdown = !_showDropdown);
                    },
                  ),
          ),
          onTap: () {
            setState(() => _showDropdown = true);
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
        if (_showDropdown)
          Container(
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
                      ? Padding(
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
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _getFilteredAreas().length,
                          itemBuilder: (context, index) {
                            final area = _getFilteredAreas()[index];
                            return ListTile(
                              title: Text(area.data['name'].toString()),
                              onTap: () {
                                _controller.text = area.data['name'].toString();
                                widget.onAreaSelected(area);
                                setState(() => _showDropdown = false);
                              },
                            );
                          },
                        ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
