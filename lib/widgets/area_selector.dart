import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

class AreaSelector extends StatefulWidget {
  final String hintText;
  final Function(RecordModel) onAreaSelected;

  const AreaSelector({
    super.key,
    required this.hintText,
    required this.onAreaSelected,
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

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() => _isLoading = true);
    final areas = await _pbService.getAreas();
    setState(() {
      _areas = areas;
      _isLoading = false;
    });
  }

  List<RecordModel> _getFilteredAreas() {
    final query = _controller.text.toLowerCase();
    if (query.isEmpty) return _areas;
    return _areas.where((area) {
      final name = area.data['name'].toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                : null,
          ),
          onTap: () {
            setState(() => _showDropdown = true);
          },
          onChanged: (value) {
            setState(() {});
          },
        ),
        if (_showDropdown)
          Container(
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
              child: ListView.builder(
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
