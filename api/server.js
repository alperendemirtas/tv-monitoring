const express = require('express');
const cors = require('cors');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = 3001;

// .env dosya yolu
const envFilePath = path.join(__dirname, '.env');

// Middleware
app.use(cors());
app.use(express.json());

// .env dosyasını oku
const readEnvFile = async () => {
  try {
    const envContent = await fs.readFile(envFilePath, 'utf-8');
    const envVars = {};
    
    envContent.split('\n').forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const [key, ...valueParts] = trimmed.split('=');
        if (key && valueParts.length > 0) {
          envVars[key.trim()] = valueParts.join('=').trim().replace(/^["']|["']$/g, '');
        }
      }
    });
    
    return envVars;
  } catch (error) {
    console.log('.env dosyası bulunamadı, yeni oluşturulacak');
    return {};
  }
};

// .env dosyasına yaz
const writeEnvFile = async (envVars) => {
  try {
    let envContent = '# TV Monitoring Dashboard Environment Variables\n';
    envContent += `# Generated at: ${new Date().toISOString()}\n\n`;
    
    Object.entries(envVars).forEach(([key, value]) => {
      const quotedValue = value.includes(' ') || value.includes('://') ? `"${value}"` : value;
      envContent += `${key}=${quotedValue}\n`;
    });
    
    await fs.writeFile(envFilePath, envContent);
    console.log('✅ .env dosyası güncellendi');
    return true;
  } catch (error) {
    console.error('❌ .env dosyası yazılamadı:', error);
    return false;
  }
};

// GET /api/config
app.get('/api/config', async (req, res) => {
  try {
    const envVars = await readEnvFile();
    
    const config = {
      opmanagerUrl: envVars.OPMANAGER_URL || '',
      sensiboApiKey: envVars.SENSIBO_API_KEY || ''
    };
    
    console.log(`[${new Date().toISOString()}] Config okundu`);
    
    res.json({
      success: true,
      config: config
    });
  } catch (error) {
    console.error('Config okuma hatası:', error);
    res.status(500).json({
      success: false,
      error: 'Konfigürasyon okunamadı'
    });
  }
});

// POST /api/config
app.post('/api/config', async (req, res) => {
  try {
    const { opmanagerUrl, sensiboApiKey } = req.body;
    
    const currentEnv = await readEnvFile();
    
    const updatedEnv = {
      ...currentEnv,
      OPMANAGER_URL: opmanagerUrl || '',
      SENSIBO_API_KEY: sensiboApiKey || ''
    };
    
    const success = await writeEnvFile(updatedEnv);
    
    if (success) {
      console.log(`[${new Date().toISOString()}] Config kaydedildi`);
      res.json({
        success: true,
        message: 'Konfigürasyon başarıyla kaydedildi'
      });
    } else {
      res.status(500).json({
        success: false,
        error: '.env dosyasına yazılamadı'
      });
    }
  } catch (error) {
    console.error('Config yazma hatası:', error);
    res.status(500).json({
      success: false,
      error: 'Konfigürasyon kaydedilemedi'
    });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    service: 'TV Monitoring Config API'
  });
});

// Sunucuyu başlat
app.listen(PORT, () => {
  console.log(`🚀 TV Monitoring Config API sunucusu port ${PORT} üzerinde çalışıyor`);
  console.log(`📁 .env dosya yolu: ${envFilePath}`);
});
