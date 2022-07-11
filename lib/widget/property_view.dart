import 'package:flutter/material.dart';

class PropertyView extends StatefulWidget {
  const PropertyView({
    super.key,
    required this.label,
    required this.value,
    this.onSubmit,
    this.editable = true,
  }) : assert(editable ? onSubmit != null : true);

  final String label;
  final String value;
  final ValueChanged<String>? onSubmit;
  final bool editable;

  @override
  State<PropertyView> createState() => _PropertyViewState();
}

class _PropertyViewState extends State<PropertyView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.value;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() {
          _editMode = false;
        });
        widget.onSubmit!(_controller.text);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: _editMode
              ? TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    suffix: GestureDetector(
                      child: Icon(
                        Icons.done,
                        color: Theme.of(context).primaryColor,
                      ),
                      onTap: _focusNode.unfocus,
                    ),
                  ),
                )
              : Text(_controller.text),
          trailing: !widget.editable || _editMode
              ? null
              : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _editMode = true;
                      _focusNode.requestFocus();
                    });
                  },
                ),
        ),
      ],
    );
  }
}
