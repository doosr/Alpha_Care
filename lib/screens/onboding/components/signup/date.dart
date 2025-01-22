import 'package:flutter/material.dart';
class DatePicker extends StatefulWidget {
  const DatePicker(BuildContext context, {super.key});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  final TextEditingController _dataController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0, bottom: 16),
        child: TextFormField(
          validator: (value) {
            if (value!.isEmpty) {
              return "";
            }
            return null;
          },
          onSaved: (Data) {},
          controller: _dataController,
          decoration: const InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Icon(
                Icons.calendar_today,
              ),
            ),
            filled: true,
            enabledBorder: OutlineInputBorder(borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
            labelText: "select date",
          ),
          readOnly: true,
          onTap: () {
            _selectDate();
          },
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2018),
        lastDate: DateTime(2028));
    setState(() {
      _dataController.text = picked.toString().split(" ")[0];
    });
    }
}
