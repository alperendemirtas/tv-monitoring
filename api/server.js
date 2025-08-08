const express = require('express');
const cors = require('cors');
const fs = require('fs-extra');
const path = require('path');

const app = express();
const PORT = 3001;
const CONFIG_FILE = path.join(__dirname, 'config.json');

// Middleware
app.use(cors());
app.use(express.json());

// Konfigürasyon dosyasını oku
const readConfig = async () => {
  try {
    if (await fs.pathExists(CONFIG_FILE)) {
      const config = await fs.readJson(CONFIG_FILE);
      return config;
    }
    return {};
  } catch (error) {
    console.error('Config dosyası okuma hatası:', error);
    return {};
  }
};

// Konfigürasyon dosyasına yaz
const writeConfig = async (config) => {
  try {
    await fs.writeJson(CONFIG_FILE, config, { spaces: 2 });
    return true;
  } catch (error) {
    console.error('Config dosyası yazma hatası:', error);
    return false;
  }
};

// GET /api/config - Ayarları oku
app.get('/api/config', async (req, res) => {
  try {
    const config = await readConfig();
    
    // Log for debugging
    console.log(`[${new Date().toISOString()}] Config okundu:`, config);
    
    res.json({
      success: true,
      config: config
    });
  } catch (error) {
    console.error('Config okuma API hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Konfigürasyon okunamadı',
      error: error.message
    });
  }
});

// POST /api/config - Ayarları kaydet
app.post('/api/config', async (req, res) => {
  try {
    const { opmanagerUrl, sensiboApiKey } = req.body;
    
    if (!opmanagerUrl && !sensiboApiKey) {
      return res.status(400).json({
        success: false,
        message: 'En az bir ayar gönderilmelidir'
      });
    }
    
    // Mevcut config'i oku
    const currentConfig = await readConfig();
    
    // Yeni config'i oluştur
    const newConfig = {
      ...currentConfig,
      ...(opmanagerUrl && { opmanagerUrl }),
      ...(sensiboApiKey && { sensiboApiKey }),
      lastUpdated: new Date().toISOString(),
      updatedBy: req.ip || 'unknown'
    };
    
    // Config'i kaydet
    const success = await writeConfig(newConfig);
    
    if (success) {
      console.log(`[${new Date().toISOString()}] Config güncellendi:`, newConfig);
      res.json({
        success: true,
        message: 'Ayarlar başarıyla kaydedildi',
        config: newConfig
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Ayarlar kaydedilemedi'
      });
    }
  } catch (error) {
    console.error('Config kaydetme API hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Ayarlar kaydedilemedi',
      error: error.message
    });
  }
});

// DELETE /api/config - Ayarları sıfırla
app.delete('/api/config', async (req, res) => {
  try {
    const success = await writeConfig({});
    
    if (success) {
      console.log(`[${new Date().toISOString()}] Config sıfırlandı`);
      res.json({
        success: true,
        message: 'Ayarlar sıfırlandı'
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Ayarlar sıfırlanamadı'
      });
    }
  } catch (error) {
    console.error('Config sıfırlama API hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Ayarlar sıfırlanamadı',
      error: error.message
    });
  }
});

// GET /api/status - API durumu
app.get('/api/status', (req, res) => {
  res.json({
    success: true,
    message: 'TV Monitoring API çalışıyor',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString()
  });
});

// Sunucuyu başlat
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 TV Monitoring API sunucusu çalışıyor:`);
  console.log(`   - Port: ${PORT}`);
  console.log(`   - Config dosyası: ${CONFIG_FILE}`);
  console.log(`   - CORS aktif: Tüm originlere izin verildi`);
  console.log(`   - Endpoints:`);
  console.log(`     GET    /api/config    - Ayarları oku`);
  console.log(`     POST   /api/config    - Ayarları kaydet`);
  console.log(`     DELETE /api/config    - Ayarları sıfırla`);
  console.log(`     GET    /api/status    - API durumu`);
  console.log(`     GET    /health        - Sağlık kontrolü`);
  
  // IP adreslerini göster
  const os = require('os');
  const networkInterfaces = os.networkInterfaces();
  console.log(`\n📡 Erişilebilir IP adresleri:`);
  
  Object.keys(networkInterfaces).forEach((ifname) => {
    networkInterfaces[ifname].forEach((iface) => {
      if (iface.family === 'IPv4' && !iface.internal) {
        console.log(`   - http://${iface.address}:${PORT}`);
      }
    });
  });
  
  console.log(`\n💡 TV'den erişim için: http://[SERVER_IP]:${PORT}/api/config`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('\n🛑 TV Monitoring API durduruluyor...');
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('\n🛑 TV Monitoring API durduruluyor...');
  process.exit(0);
});
