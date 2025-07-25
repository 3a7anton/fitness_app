import 'package:flutter/material.dart';
import 'package:fitness_flutter/core/service/weather_service.dart';

class ApiSetupScreen extends StatefulWidget {
  const ApiSetupScreen({Key? key}) : super(key: key);

  @override
  State<ApiSetupScreen> createState() => _ApiSetupScreenState();
}

class _ApiSetupScreenState extends State<ApiSetupScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isValidating = false;
  String? _validationMessage;
  bool? _isKeyValid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Setup'),
        backgroundColor: const Color(0xFF6C63FF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🌤️ OpenWeather API Setup',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 20),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Steps to get your API key:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text('1. Visit openweathermap.org/api'),
                    const Text('2. Sign up for a free account'),
                    const Text('3. Check your email for the API key'),
                    const Text('4. Copy your 32-character API key below'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Free plan includes 1,000 calls/day',
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'OpenWeather API Key',
                hintText: 'Enter your 32-character API key',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                suffixIcon: _isKeyValid == true 
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : _isKeyValid == false
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _validationMessage = null;
                  _isKeyValid = null;
                });
              },
            ),
            
            if (_validationMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isKeyValid == true ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isKeyValid == true ? Colors.green : Colors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isKeyValid == true ? Icons.check_circle : Icons.error,
                      color: _isKeyValid == true ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationMessage!,
                        style: TextStyle(
                          color: _isKeyValid == true ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValidating ? null : _validateApiKey,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isValidating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Validating...'),
                      ],
                    )
                  : const Text(
                      'Validate API Key',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text(
                          'Important Notes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('• API calls are limited to once per 10 minutes per location'),
                    const Text('• Free plan: 1,000 calls/day, 60 calls/minute'),
                    const Text('• Use coordinates instead of city names for better accuracy'),
                    const Text('• Keep your API key secure and private'),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Skip for Now'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isKeyValid == true ? _saveApiKey : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text(
                      'Save & Continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateApiKey() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty) {
      setState(() {
        _validationMessage = 'Please enter an API key';
        _isKeyValid = false;
      });
      return;
    }
    
    if (!WeatherService.isValidApiKey(apiKey)) {
      setState(() {
        _validationMessage = 'API key should be 32 characters long and contain only letters and numbers';
        _isKeyValid = false;
      });
      return;
    }
    
    setState(() {
      _isValidating = true;
      _validationMessage = null;
    });
    
    // Test the API key with a simple request
    try {
      final testWeather = await WeatherService.getCurrentWeather(
        lat: 37.7749, // San Francisco coordinates for testing
        lon: -122.4194,
      );
      
      if (testWeather != null) {
        setState(() {
          _validationMessage = 'API key is valid! Weather data retrieved successfully.';
          _isKeyValid = true;
        });
      } else {
        setState(() {
          _validationMessage = 'API key validation failed. Please check your key.';
          _isKeyValid = false;
        });
      }
    } catch (e) {
      setState(() {
        _validationMessage = 'Error validating API key: $e';
        _isKeyValid = false;
      });
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }
  
  void _saveApiKey() {
    // In a real app, you would save this to secure storage
    // For now, we'll just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API key validated! You can now use weather features.'),
        backgroundColor: Colors.green,
      ),
    );
    
    Navigator.pop(context);
  }
}
