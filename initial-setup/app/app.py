from flask import Flask, render_template_string
import os
import socket
from datetime import datetime

app = Flask(__name__)

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terraform Workshop - {{ app_name }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        .container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            max-width: 800px;
            width: 100%;
        }
        h1 {
            color: #667eea;
            margin-bottom: 10px;
            font-size: 2.5em;
        }
        .subtitle {
            color: #666;
            margin-bottom: 30px;
            font-size: 1.2em;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 30px 0;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #667eea;
        }
        .info-label {
            font-weight: bold;
            color: #667eea;
            margin-bottom: 5px;
            text-transform: uppercase;
            font-size: 0.85em;
        }
        .info-value {
            color: #333;
            font-size: 1.1em;
        }
        .workshop-days {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .workshop-days h2 {
            color: #667eea;
            margin-bottom: 15px;
        }
        .day-item {
            padding: 10px;
            margin: 5px 0;
            background: white;
            border-radius: 5px;
            border-left: 3px solid #764ba2;
        }
        .status {
            display: inline-block;
            padding: 5px 15px;
            background: #28a745;
            color: white;
            border-radius: 20px;
            font-size: 0.9em;
            margin-top: 20px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 {{ app_name }}</h1>
        <p class="subtitle">Advanced Terraform Workshop - Azure Container Apps</p>
        
        <div class="info-grid">
            <div class="info-card">
                <div class="info-label">Environment</div>
                <div class="info-value">{{ environment }}</div>
            </div>
            <div class="info-card">
                <div class="info-label">Hostname</div>
                <div class="info-value">{{ hostname }}</div>
            </div>
            <div class="info-card">
                <div class="info-label">Current Time</div>
                <div class="info-value">{{ current_time }}</div>
            </div>
            <div class="info-card">
                <div class="info-label">Version</div>
                <div class="info-value">1.0.0</div>
            </div>
        </div>

        <div class="workshop-days">
            <h2>📚 Workshop Curriculum</h2>
            <div class="day-item"><strong>Day 1:</strong> State Management (Local & Remote)</div>
            <div class="day-item"><strong>Day 2:</strong> Multi-Environment Deployment</div>
            <div class="day-item"><strong>Day 3:</strong> Custom Modules and Reusability</div>
            <div class="day-item"><strong>Day 4:</strong> Dynamic Logic and Validation</div>
            <div class="day-item"><strong>Day 5:</strong> TFE Policy as Code (Sentinel)</div>
        </div>

        <div style="text-align: center;">
            <span class="status">✓ Application Running</span>
        </div>

        <div class="footer">
            Deployed with Terraform | Managed by Infrastructure as Code
        </div>
    </div>
</body>
</html>
'''

@app.route('/')
def home():
    return render_template_string(
        HTML_TEMPLATE,
        app_name=os.getenv('APP_NAME', 'Terraform Workshop'),
        environment=os.getenv('ENVIRONMENT', 'development'),
        hostname=socket.gethostname(),
        current_time=datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    )

@app.route('/health')
def health():
    return {
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'environment': os.getenv('ENVIRONMENT', 'development')
    }, 200

if __name__ == '__main__':
    port = int(os.getenv('PORT', 80))
    app.run(host='0.0.0.0', port=port, debug=False)
