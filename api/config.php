<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// OPTIONS request için (CORS preflight)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// .env dosya yolu
$envFile = __DIR__ . '/.env';

// .env dosyasını oku
function readEnvFile($filePath) {
    $envVars = [];
    if (file_exists($filePath)) {
        $lines = file($filePath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        foreach ($lines as $line) {
            $line = trim($line);
            if ($line && !str_starts_with($line, '#')) {
                $parts = explode('=', $line, 2);
                if (count($parts) === 2) {
                    $key = trim($parts[0]);
                    $value = trim($parts[1], '"\'');
                    $envVars[$key] = $value;
                }
            }
        }
    }
    return $envVars;
}

// .env dosyasına yaz
function writeEnvFile($filePath, $envVars) {
    $content = "# TV Monitoring Dashboard Environment Variables\n";
    $content .= "# Generated at: " . date('c') . "\n\n";
    
    foreach ($envVars as $key => $value) {
        // URL veya boşluk içeren değerleri tırnak içine al
        $quotedValue = (strpos($value, ' ') !== false || strpos($value, '://') !== false) 
            ? '"' . $value . '"' 
            : $value;
        $content .= "$key=$quotedValue\n";
    }
    
    return file_put_contents($filePath, $content) !== false;
}

try {
    if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // Config oku
        $envVars = readEnvFile($envFile);
        
        $config = [
            'opmanagerUrl' => $envVars['OPMANAGER_URL'] ?? '',
            'sensiboApiKey' => $envVars['SENSIBO_API_KEY'] ?? ''
        ];
        
        echo json_encode([
            'success' => true,
            'config' => $config
        ]);
        
    } elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Config kaydet
        $input = json_decode(file_get_contents('php://input'), true);
        
        if (!$input) {
            throw new Exception('Geçersiz JSON verisi');
        }
        
        $currentEnv = readEnvFile($envFile);
        
        // Yeni değerleri güncelle
        $currentEnv['OPMANAGER_URL'] = $input['opmanagerUrl'] ?? '';
        $currentEnv['SENSIBO_API_KEY'] = $input['sensiboApiKey'] ?? '';
        
        if (writeEnvFile($envFile, $currentEnv)) {
            echo json_encode([
                'success' => true,
                'message' => 'Konfigürasyon başarıyla kaydedildi'
            ]);
        } else {
            throw new Exception('.env dosyasına yazılamadı');
        }
        
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'error' => 'Desteklenmeyen HTTP metodu'
        ]);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
