const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');
const app = express();
const port = 3001;

app.use(cors());
app.use(express.json());

// Sensibo API proxy endpoint
app.get('/api/sensibo/pods', async (req, res) => {
  try {
    const apiKey = req.query.apiKey || req.headers['x-api-key'];
    
    if (!apiKey) {
      return res.status(401).json({ error: 'API key gerekli (query parameter veya x-api-key header ile)' });
    }

    console.log('Sensibo API isteği gönderiliyor...', { apiKey: apiKey.substring(0, 8) + '...' });

    const apiUrl = `https://home.sensibo.com/api/v2/users/me/pods?fields=id,room,measurements&apiKey=${apiKey}`;
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'User-Agent': 'TV-Dashboard/1.0',
        'Accept': 'application/json'
      }
    });

    console.log('Sensibo API yanıt durumu:', response.status, response.statusText);

    // Yanıtın içeriğini önce text olarak al
    const responseText = await response.text();
    console.log('Yanıt içeriği (ilk 200 karakter):', responseText.substring(0, 200));

    // JSON parse etmeyi dene
    let data;
    try {
      data = JSON.parse(responseText);
    } catch (parseError) {
      console.error('JSON Parse Hatası:', parseError.message);
      
      // HTML yanıt ise muhtemelen auth hatası
      if (responseText.includes('login_required') || responseText.includes('<html>')) {
        return res.status(401).json({ 
          error: 'API anahtarı geçersiz veya yanlış. Sensibo hesabınızdan doğru API anahtarını alın.' 
        });
      }
      
      return res.status(500).json({ 
        error: 'Sensibo API geçersiz yanıt döndürdü',
        details: responseText.substring(0, 100)
      });
    }
    
    if (!response.ok) {
      return res.status(response.status).json(data);
    }

    console.log('Başarılı yanıt alındı, cihaz sayısı:', data.result?.length || 0);
    res.json(data);
    
  } catch (error) {
    console.error('Proxy Hatası:', error.message);
    res.status(500).json({ 
      error: 'Proxy server hatası', 
      details: error.message 
    });
  }
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Sensibo Proxy Server ${port} portunda çalışıyor`);
  console.log('Kullanım için: http://localhost:3001/api/sensibo/pods');
  console.log('Network erişimi: Tüm IP adreslerinden 3001 portu');
});
