import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PasscodeInputView extends StatefulWidget {
  final String title;
  final String? confirmPasscode;
  final Function(String) onCompleted;

  const PasscodeInputView({
    super.key,
    required this.title,
    this.confirmPasscode,
    required this.onCompleted,
  });

  @override
  State<PasscodeInputView> createState() => _PasscodeInputViewState();
}

class _PasscodeInputViewState extends State<PasscodeInputView> {
  String _passcode = '';
  String _errorMessage = '';

  void _onKeyPressed(String value) {
    if (value == 'delete') {
      if (_passcode.isNotEmpty) {
        setState(() {
          _passcode = _passcode.substring(0, _passcode.length - 1);
          _errorMessage = '';
        });
      }
    } else if (value == 'clear') {
      setState(() {
        _passcode = '';
        _errorMessage = '';
      });
    } else {
      if (_passcode.length < 6) {
        setState(() {
          _passcode += value;
          _errorMessage = '';
        });

        // Auto-check when reaching 6 digits
        if (_passcode.length == 6) {
          if (widget.confirmPasscode != null) {
            // Confirmation mode
            if (_passcode == widget.confirmPasscode) {
              widget.onCompleted(_passcode);
            } else {
              setState(() {
                _errorMessage = 'Passcodes do not match. Try again.';
                _passcode = '';
              });
            }
          } else {
            // First entry mode
            widget.onCompleted(_passcode);
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            widget.confirmPasscode != null ? 'Confirm your passcode' : 'Create a passcode',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 30),

          // Passcode dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 1.5),
                  color: index < _passcode.length ? Theme.of(context).primaryColor : Colors.transparent,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          // Error message
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          const SizedBox(height: 40),

          // Keypad
          _buildKeypad(),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildKey('clear', text: 'Clear', isAction: true),
            _buildKey('0'),
            _buildKey('delete', text: '⌫', isAction: true),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String value, {String? text, bool isAction = false}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () => _onKeyPressed(value),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          child: Center(
            child: text != null
                ? Text(text, style: TextStyle(fontSize: isAction ? 16 : 22, color: isAction ? Colors.grey.shade600 : Colors.black))
                : Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}
