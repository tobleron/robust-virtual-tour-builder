
const { exec } = require('child_process');

function checkBackend() {
  exec('curl -s http://localhost:8080/health', (error, stdout, stderr) => {
    if (error || stdout.trim() !== 'OK') {
        // Try alternate port or just connect
        exec('nc -z localhost 8080', (err) => {
            if (err) {
                console.log('Backend not ready...');
                setTimeout(checkBackend, 5000);
            } else {
                console.log('Backend port 8080 is open!');
            }
        });
    } else {
      console.log('Backend ready!');
    }
  });
}

checkBackend();
