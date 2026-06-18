import 'dart:io';

/// Frees a port by killing the process currently using it.
Future<void> freePort(int port) async {
  if (Platform.isMacOS || Platform.isLinux) {
    try {
      // Find the PID of the process using the port
      final result = await Process.run('sh', ['-c', 'lsof -ti :$port']);
      final output = result.stdout.toString().trim();

      if (output.isNotEmpty) {
        final pids = output.split('\n');
        for (final pid in pids) {
          if (pid.isNotEmpty) {
            print('Port $port is in use by PID $pid. Forcing termination...');
            await Process.run('kill', ['-9', pid]);
            print('Process $pid terminated.');
            // Give the OS a short time to actually free the port
            await Future.delayed(Duration(milliseconds: 500));
          }
        }
      }
    } catch (e) {
      print('Warning: Error while trying to free port $port: $e');
    }
  } else if (Platform.isWindows) {
    try {
      // Find the netstat line containing the port and get the PID from the last column
      final result =
          await Process.run('cmd', ['/c', 'netstat -ano | findstr :$port']);
      final output = result.stdout.toString().trim();

      if (output.isNotEmpty) {
        final lines = output.split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 5) {
            final pid = parts.last;
            // Ensure we do not accidentally kill process '0' (e.g., LISTENING 0)
            if (pid != '0' && pid.isNotEmpty) {
              print(
                  'Port $port is in use by PID $pid. Forcing termination on Windows...');
              await Process.run('taskkill', ['/F', '/PID', pid]);
              print('Process $pid terminated.');
              await Future.delayed(Duration(milliseconds: 500));
            }
          }
        }
      }
    } catch (e) {
      print('Warning: Error while trying to free port $port on Windows: $e');
    }
  }
}
