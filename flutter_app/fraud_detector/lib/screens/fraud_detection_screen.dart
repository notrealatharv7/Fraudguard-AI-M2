import 'package:flutter/material.dart';
import 'package:fraud_detector/models/fraud_prediction.dart';
import 'package:fraud_detector/models/transaction_input.dart';
import 'package:fraud_detector/services/api_service.dart';

class FraudDetectionScreen extends StatefulWidget {
  const FraudDetectionScreen({super.key});

  @override
  State<FraudDetectionScreen> createState() => _FraudDetectionScreenState();
}

class _FraudDetectionScreenState extends State<FraudDetectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controllers = {
    'amount': TextEditingController(),
    'deviation': TextEditingController(),
    'anomaly': TextEditingController(),
    'distance': TextEditingController(),
    'novelty': TextEditingController(),
    'frequency': TextEditingController(),
  };

  bool _isLoading = false;
  FraudPrediction? _prediction;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _prediction = null;
      _errorMessage = null;
    });

    try {
      final transaction = TransactionInput(
        transactionAmount: double.parse(_controllers['amount']!.text),
        transactionAmountDeviation: double.parse(_controllers['deviation']!.text),
        timeAnomaly: double.parse(_controllers['anomaly']!.text),
        locationDistance: double.parse(_controllers['distance']!.text),
        merchantNovelty: double.parse(_controllers['novelty']!.text),
        transactionFrequency: double.parse(_controllers['frequency']!.text),
      );

      final prediction = await _apiService.predictFraud(transaction);
      setState(() => _prediction = prediction);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    for (var controller in _controllers.values) {
      controller.clear();
    }
    setState(() {
      _prediction = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FraudShield AI'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Real-Time Fraud Analysis',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text('Enter transaction details to analyze for potential fraud.',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 800) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildInputSection()),
                            const SizedBox(width: 24),
                            Expanded(flex: 3, child: _buildResultsSection()),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildInputSection(),
                            const SizedBox(height: 24),
                            _buildResultsSection(),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transaction Details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              _buildTextField(
                  controller: _controllers['amount']!,
                  label: 'Amount (₹)',
                  hint: 'e.g., 150.50',
                  icon: Icons.currency_rupee,
                  validator: _validateRequiredNumber),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _controllers['deviation']!,
                  label: 'Amount Deviation',
                  hint: 'e.g., 0.25',
                  icon: Icons.trending_up,
                  validator: _validateRequiredNumber),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _controllers['anomaly']!,
                  label: 'Time Anomaly (0-1)',
                  hint: 'e.g., 0.3',
                  icon: Icons.timer,
                  validator: _validateRange),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _controllers['distance']!,
                  label: 'Location Distance (km)',
                  hint: 'e.g., 25.0',
                  icon: Icons.location_on,
                  validator: _validateRequiredNumber),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _controllers['novelty']!,
                  label: 'Merchant Novelty (0-1)',
                  hint: 'e.g., 0.2',
                  icon: Icons.store,
                  validator: _validateRange),
              const SizedBox(height: 16),
              _buildTextField(
                  controller: _controllers['frequency']!,
                  label: 'Transaction Frequency',
                  hint: 'e.g., 5',
                  icon: Icons.history,
                  validator: _validateRequiredNumber),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Check for Fraud'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(onPressed: _resetForm, child: const Text('Reset')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
            child: child,
          ),
        );
      },
      child: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorCard(_errorMessage!)
              : _prediction != null
                  ? _buildResultCard(_prediction!)
                  : _buildPlaceholderCard(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 20)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      key: const ValueKey('loading'),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 16),
            Text('Analyzing transaction...', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String errorMessage) {
    return Container(
      key: const ValueKey('error'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(FraudPrediction prediction) {
    final isFraud = prediction.fraud;
    final riskScore = prediction.riskScore;
    final riskPercentage = (riskScore * 100).toStringAsFixed(1);
    final color = isFraud ? Theme.of(context).colorScheme.error : const Color(0xFF059669);
    final containerColor = isFraud ? Theme.of(context).colorScheme.errorContainer : const Color(0xFFD1FAE5);

    return Container(
      key: const ValueKey('result'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isFraud ? Icons.warning_amber_rounded : Icons.check_circle, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(isFraud ? 'Potential Fraud Detected!' : 'Transaction is Safe',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Confidence: $riskPercentage%', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
          if (prediction.explanation != null && prediction.explanation!.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Text('AI Analysis', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(prediction.explanation!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard() {
    return Container(
      key: const ValueKey('placeholder'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Transaction Analysis', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Submit transaction details to check for potential fraud', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  String? _validateRequiredNumber(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    if (double.tryParse(value) == null) return 'Please enter a valid number';
    return null;
  }

  String? _validateRange(String? value) {
    final numberError = _validateRequiredNumber(value);
    if (numberError != null) return numberError;
    final val = double.parse(value!);
    if (val < 0 || val > 1) return 'Must be between 0 and 1';
    return null;
  }
}


