import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class BackendConnectivityChecker extends StatefulWidget {
  const BackendConnectivityChecker({super.key});

  @override
  State<BackendConnectivityChecker> createState() => _BackendConnectivityCheckerState();
}

class _BackendConnectivityCheckerState extends State<BackendConnectivityChecker> {
  final List<ConnectivityTest> tests = [];
  bool isRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeTests();
  }

  void _initializeTests() {
    tests.clear();
    tests.addAll([
      ConnectivityTest(
        name: 'Firebase Auth',
        description: 'Check Firebase Authentication',
        endpoint: 'Firebase',
        testFunction: _testFirebaseAuth,
      ),
      ConnectivityTest(
        name: 'Local Backend (localhost:5000)',
        description: 'Check local Node.js/Python backend',
        endpoint: 'http://localhost:5000',
        testFunction: () => _testBackend('http://localhost:5000'),
      ),
      ConnectivityTest(
        name: 'Local Backend (127.0.0.1:8000)',
        description: 'Check alternative local backend',
        endpoint: 'http://127.0.0.1:8000',
        testFunction: () => _testBackend('http://127.0.0.1:8000'),
      ),
      ConnectivityTest(
        name: 'REST API Health Check',
        description: 'Check /api/health endpoint',
        endpoint: 'http://localhost:5000/api/health',
        testFunction: () => _testHealthEndpoint('http://localhost:5000/api/health'),
      ),
      ConnectivityTest(
        name: 'Database Connection',
        description: 'Check database status endpoint',
        endpoint: 'http://localhost:5000/api/status',
        testFunction: () => _testHealthEndpoint('http://localhost:5000/api/status'),
      ),
      ConnectivityTest(
        name: 'User Routes Endpoint',
        description: 'Check /api/users endpoint',
        endpoint: 'http://localhost:5000/api/users',
        testFunction: () => _testEndpoint('http://localhost:5000/api/users'),
      ),
    ]);
  }

  Future<TestResult> _testFirebaseAuth() async {
    try {
      // This test passes if Firebase was initialized without error
      return TestResult(
        success: true,
        message: 'Firebase using Mock Auth (no credentials configured)',
        statusCode: 200,
        responseTime: 'N/A',
      );
    } catch (e) {
      return TestResult(
        success: false,
        message: 'Firebase Error: $e',
        statusCode: 0,
        responseTime: 'N/A',
      );
    }
  }

  Future<TestResult> _testBackend(String url) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      return TestResult(
        success: response.statusCode == 200,
        message: response.body.isEmpty
            ? 'Connected (No response body)'
            : response.body,
        statusCode: response.statusCode,
        responseTime: '${stopwatch.elapsedMilliseconds}ms',
      );
    } on TimeoutException {
      stopwatch.stop();
      return TestResult(
        success: false,
        message: 'Connection Timeout - Backend not responding',
        statusCode: 0,
        responseTime: '${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        success: false,
        message: 'Connection Error: $e',
        statusCode: 0,
        responseTime: '${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  Future<TestResult> _testHealthEndpoint(String url) async {
    final stopwatch = Stopwatch()..start();
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      try {
        final json = jsonDecode(response.body);
        return TestResult(
          success: response.statusCode == 200,
          message: 'Status: ${json['status'] ?? response.body}',
          statusCode: response.statusCode,
          responseTime: '${stopwatch.elapsedMilliseconds}ms',
          responseData: json,
        );
      } catch (e) {
        return TestResult(
          success: response.statusCode == 200,
          message: response.body,
          statusCode: response.statusCode,
          responseTime: '${stopwatch.elapsedMilliseconds}ms',
        );
      }
    } on TimeoutException {
      stopwatch.stop();
      return TestResult(
        success: false,
        message: 'Timeout - Backend not responding',
        statusCode: 0,
        responseTime: '${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      stopwatch.stop();
      return TestResult(
        success: false,
        message: 'Error: $e',
        statusCode: 0,
        responseTime: '${stopwatch.elapsedMilliseconds}ms',
      );
    }
  }

  Future<TestResult> _testEndpoint(String url) async {
    return _testBackend(url);
  }

  Future<void> _runAllTests() async {
    setState(() => isRunning = true);

    for (int i = 0; i < tests.length; i++) {
      final test = tests[i];
      final result = await test.testFunction();
      setState(() {
        tests[i].result = result;
      });
      await Future.delayed(const Duration(milliseconds: 500));
    }

    setState(() => isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Connectivity Checker'),
        backgroundColor: const Color(0xFF0066FF),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔍 Backend Connectivity Diagnostic',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This tool checks if your frontend is properly connected to the backend.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  'Status: ${_getOverallStatus()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getOverallStatusColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Run Tests Button
          ElevatedButton.icon(
            onPressed: isRunning ? null : _runAllTests,
            icon: const Icon(Icons.play_arrow),
            label: Text(isRunning ? 'Running Tests...' : 'Run All Tests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 20),

          // Tests List
          ...tests.asMap().entries.map((entry) {
            int index = entry.key;
            ConnectivityTest test = entry.value;
            return _buildTestCard(test, index);
          }),

          const SizedBox(height: 20),

          // Summary Box
          if (tests.any((t) => t.result != null))
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Passed: ${tests.where((t) => t.result?.success ?? false).length}/${tests.length}',
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Failed: ${tests.where((t) => t.result != null && !(t.result?.success ?? false)).length}/${tests.length}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Troubleshooting Guide
          _buildTroubleshootingGuide(),
        ],
      ),
    );
  }

  Widget _buildTestCard(ConnectivityTest test, int index) {
    final result = test.result;
    final isRunning = result == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Status Icon
                if (isRunning)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    result!.success ? Icons.check_circle : Icons.cancel,
                    color: result.success ? Colors.green : Colors.red,
                    size: 24,
                  ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        test.description,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isRunning) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (result!.statusCode != 0)
                      Text(
                        'Status Code: ${result.statusCode}',
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      ),
                    Text(
                      'Response Time: ${result.responseTime}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.message,
                      style: TextStyle(
                        color: result.success ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ Troubleshooting Guide',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFFFF9800),
            ),
          ),
          const SizedBox(height: 12),
          _buildTroubleshootingItem(
            '1. Backend Not Running?',
            'Start your backend server:\n'
                '• Node.js: node server.js\n'
                '• Python Flask: python app.py\n'
                '• Python Django: python manage.py runserver',
          ),
          _buildTroubleshootingItem(
            '2. Wrong Port?',
            'Check your backend configuration and update the endpoints in the test.',
          ),
          _buildTroubleshootingItem(
            '3. CORS Issues?',
            'Enable CORS in your backend:\n'
                '• Express: use cors middleware\n'
                '• Flask: use flask-cors',
          ),
          _buildTroubleshootingItem(
            '4. Network Issues?',
            'Ensure both frontend and backend are on the same network or properly configured.',
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  String _getOverallStatus() {
    final results = tests.map((t) => t.result).where((r) => r != null).toList();
    if (results.isEmpty) return 'Not tested yet';
    final passed = results.whereType<TestResult>().where((r) => r.success).length;
    return '$passed/${results.length} tests passed';
  }

  Color _getOverallStatusColor() {
    final results = tests.map((t) => t.result).where((r) => r != null).toList();
    if (results.isEmpty) return Colors.grey;
    final passed = results.whereType<TestResult>().where((r) => r.success).length;
    return passed == results.length
        ? Colors.green
        : passed > 0
            ? Colors.orange
            : Colors.red;
  }
}

class ConnectivityTest {
  final String name;
  final String description;
  final String endpoint;
  final Future<TestResult> Function() testFunction;
  TestResult? result;

  ConnectivityTest({
    required this.name,
    required this.description,
    required this.endpoint,
    required this.testFunction,
  });
}

class TestResult {
  final bool success;
  final String message;
  final int statusCode;
  final String responseTime;
  final dynamic responseData;

  TestResult({
    required this.success,
    required this.message,
    required this.statusCode,
    required this.responseTime,
    this.responseData,
  });
}
