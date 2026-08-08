import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/app_back_handler.dart';

class DobVerificationScreen extends StatefulWidget {
  const DobVerificationScreen({super.key});

  @override
  State<DobVerificationScreen> createState() => _DobVerificationScreenState();
}

class _DobVerificationScreenState extends State<DobVerificationScreen> {
  int? _birthMonth;
  int? _birthYear;
  String? _error;

  bool get _isValidAge {
    if (_birthMonth == null || _birthYear == null) return false;
    final now = DateTime.now();
    var age = now.year - _birthYear!;
    if (now.month < _birthMonth!) age--;
    return age >= 18;
  }

  Future<void> _submit() async {
    if (_birthMonth == null || _birthYear == null) {
      setState(() => _error = 'Please select your birth month and year.');
      return;
    }
    if (!_isValidAge) {
      setState(() => _error = 'You must be 18 or older to use this app.');
      return;
    }

    final success = await context.read<AppState>().completeDobVerification(
          birthMonth: _birthMonth!,
          birthYear: _birthYear!,
        );

    if (!success && mounted) {
      setState(() => _error = 'Could not save your date of birth. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final years = List.generate(80, (i) => DateTime.now().year - i - 10);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        handleExitBack(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Verify Your Age')),
        body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Date of birth',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'We need your birth month and year to confirm you are 18 or older, as required by our community guidelines.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Birth month',
                border: OutlineInputBorder(),
              ),
              initialValue: _birthMonth,
              items: List.generate(
                12,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text([
                    'January',
                    'February',
                    'March',
                    'April',
                    'May',
                    'June',
                    'July',
                    'August',
                    'September',
                    'October',
                    'November',
                    'December',
                  ][i]),
                ),
              ),
              onChanged: (v) => setState(() {
                _birthMonth = v;
                _error = null;
              }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(
                labelText: 'Birth year',
                border: OutlineInputBorder(),
              ),
              initialValue: _birthYear,
              items: years
                  .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (v) => setState(() {
                _birthYear = v;
                _error = null;
              }),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
