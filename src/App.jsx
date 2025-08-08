import { useState, useEffect } from 'react'
import './App.css'

function App() {
  // State yönetimi
  const [opmanagerUrl, setOpmanagerUrl] = useState('')
  const [sensiboApiKey, setSensiboApiKey] = useState('')
  const [sensiboData, setSensiboData] = useState([]) // Array olarak değiştirdik
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState('')
  const [configLoading, setConfigLoading] = useState(true)
  const [isConfigured, setIsConfigured] = useState(false)
  const [serverIp, setServerIp] = useState('')
  const [isTvMode, setIsTvMode] = useState(false)
  const [showSettingsModal, setShowSettingsModal] = useState(false) // Settings modal kontrolü

  // TV mode tespiti - Büyük ekranlar için
  useEffect(() => {
    const screenWidth = window.screen.width
    const screenHeight = window.screen.height
    const pixelDensity = window.devicePixelRatio || 1
    
    // 50+ inç TV tespiti (genelde 1920x1080+ ve düşük pixel density)
    const isBigScreen = screenWidth >= 1920 && screenHeight >= 1080 && pixelDensity <= 1.5
    const userAgent = navigator.userAgent.toLowerCase()
    const isTvBrowser = userAgent.includes('smart') || 
                        userAgent.includes('tizen') || 
                        userAgent.includes('webos') || 
                        userAgent.includes('opera tv')
    
    if (isBigScreen || isTvBrowser) {
      setIsTvMode(true)
      document.body.classList.add('tv-mode')
      console.log('TV Mode activated - Screen:', screenWidth + 'x' + screenHeight)
    }
  }, [])

  // Server IP'sini tespit et
  useEffect(() => {
    const hostname = window.location.hostname
    setServerIp(hostname === 'localhost' ? '10.10.11.164' : hostname)
  }, [])

  // Sıcaklık kategorisini belirle
  const getTempCategory = (temperature) => {
    if (!temperature) return 'temp-unknown'
    if (temperature < 18) return 'temp-cold'
    if (temperature <= 24) return 'temp-normal'
    return 'temp-warm'
  }

  // Nem seviyesi kategorisi
  const getHumidityCategory = (humidity) => {
    if (!humidity) return 'humidity-unknown'
    if (humidity < 40) return 'humidity-low'
    if (humidity <= 60) return 'humidity-normal'
    return 'humidity-high'
  }

  // API endpoint'ini belirle (local vs production)
  const getApiEndpoint = () => {
    const isDev = window.location.hostname === 'localhost'
    return isDev ? 'http://localhost:3001' : '/api/config.php'
  }

  // Sunucudan ayarları çek - PHP API'den
  const fetchConfigFromServer = async () => {
    try {
      const response = await fetch(getApiEndpoint())
      const data = await response.json()
      
      if (data.success && data.config) {
        const { opmanagerUrl: serverOpmanager, sensiboApiKey: serverSensibo } = data.config
        
        if (serverOpmanager) setOpmanagerUrl(serverOpmanager)
        if (serverSensibo) setSensiboApiKey(serverSensibo)
        return true
      }
      return false
    } catch (err) {
      console.error('Sunucudan config alınamadı:', err)
      // Fallback olarak localStorage'u dene
      const savedOpmanagerUrl = localStorage.getItem('opmanagerUrl') || ''
      const savedSensiboApiKey = localStorage.getItem('sensiboApiKey') || ''
      
      if (savedOpmanagerUrl) setOpmanagerUrl(savedOpmanagerUrl)
      if (savedSensiboApiKey) setSensiboApiKey(savedSensiboApiKey)
      return !!(savedOpmanagerUrl || savedSensiboApiKey)
    }
  }

  // Ayarları sunucuya kaydet - PHP API'ye
  const saveConfigToServer = async (opmanager, sensibo) => {
    try {
            const response = await fetch(getApiEndpoint(), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          opmanagerUrl: opmanager,
          sensiboApiKey: sensibo
        })
      })

      const data = await response.json()
      
      // Başarı durumunda localStorage'a da kaydet (fallback için)
      if (data.success) {
        localStorage.setItem('opmanagerUrl', opmanager)
        localStorage.setItem('sensiboApiKey', sensibo)
      }
      
      return data.success
    } catch (err) {
      console.error('Sunucuya config kaydedilemedi:', err)
      // Fallback olarak localStorage'a kaydet
      try {
        localStorage.setItem('opmanagerUrl', opmanager)
        localStorage.setItem('sensiboApiKey', sensibo)
        return true
      } catch (localErr) {
        console.error('LocalStorage\'a kaydedilemedi:', localErr)
        return false
      }
    }
  }

  // Sayfa yüklendiğinde ayarları kontrol et - .env tabanlı sistem
  useEffect(() => {
    const initializeConfig = async () => {
      // URL parametrelerini kontrol et
      const urlParams = new URLSearchParams(window.location.search)
      const urlOpmanager = urlParams.get('opmanager')
      const urlSensibo = urlParams.get('sensibo')
      
      // URL parametresi varsa direkt kullan ve sunucuya kaydet
      if (urlOpmanager || urlSensibo) {
        const opmanagerValue = urlOpmanager ? decodeURIComponent(urlOpmanager) : ''
        const sensiboValue = urlSensibo || ''
        
        if (opmanagerValue) setOpmanagerUrl(opmanagerValue)
        if (sensiboValue) setSensiboApiKey(sensiboValue)
        
        // .env dosyasına kaydet
        await saveConfigToServer(opmanagerValue, sensiboValue)
        setIsConfigured(true)
        setConfigLoading(false)
        return
      }

      // Önce sunucudan (.env dosyasından) ayarları yükle
      const serverConfigLoaded = await fetchConfigFromServer()
      
      if (serverConfigLoaded) {
        setIsConfigured(true)
      } else {
        // Sunucuda da yoksa localStorage'dan yükle
        const savedOpmanagerUrl = localStorage.getItem('opmanagerUrl') || ''
        const savedSensiboApiKey = localStorage.getItem('sensiboApiKey') || ''
        
        setOpmanagerUrl(savedOpmanagerUrl)
        setSensiboApiKey(savedSensiboApiKey)
        setIsConfigured(!!(savedOpmanagerUrl || savedSensiboApiKey))
      }
      
      setConfigLoading(false)
    }

    initializeConfig()
  }, [serverIp])

  // Polling kaldırıldı - Artık sadece localStorage kullanılıyor

  // Sensibo verilerini çek
  const fetchSensiboData = async () => {
    if (!sensiboApiKey) {
      setError('Sensibo API anahtarı girilmemiş')
      return
    }

    setIsLoading(true)
    setError('')

    try {
      // Vite proxy üzerinden çağrı yap - acState'i de çek
      const response = await fetch(`/api/sensibo/users/me/pods?fields=id,room,acState&apiKey=${sensiboApiKey}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json'
        }
      })

      if (!response.ok) {
        throw new Error(`API Hatası: ${response.status}`)
      }

      const data = await response.json()
      
      if (data.status === 'success' && data.result && data.result.length > 0) {
        // Her cihaz için measurement verilerini çek
        const devicesWithData = await Promise.all(
          data.result.map(async (device) => {
            try {
              const measurementResponse = await fetch(
                `/api/sensibo/pods/${device.id}/measurements?fields=temperature,humidity&apiKey=${sensiboApiKey}`,
                {
                  method: 'GET',
                  headers: {
                    'Content-Type': 'application/json'
                  }
                }
              )
              
              if (measurementResponse.ok) {
                const measurementData = await measurementResponse.json()
                if (measurementData.status === 'success' && measurementData.result.length > 0) {
                  const latest = measurementData.result[0]
                  return {
                    id: device.id,
                    room: device.room,
                    temperature: latest.temperature,
                    humidity: latest.humidity,
                    acState: device.acState || { on: false },
                    isOnline: true
                  }
                }
              }
              
              return {
                id: device.id,
                room: device.room,
                temperature: null,
                humidity: null,
                acState: device.acState || { on: false },
                isOnline: false,
                error: 'Veri alınamadı'
              }
            } catch (err) {
              return {
                id: device.id,
                room: device.room,
                temperature: null,
                humidity: null,
                acState: { on: false },
                isOnline: false,
                error: err.message
              }
            }
          })
        )
        
        setSensiboData(devicesWithData)
        setError('') // Başarılı durumda error'u temizle
      } else {
        setError('Sensibo cihazı bulunamadı')
      }
    } catch (err) {
      setError(`Sensibo verisi alınamadı: ${err.message}`)
      console.error('Sensibo API Hatası:', err)
    } finally {
      setIsLoading(false)
    }
  }

  // API anahtarı değiştiğinde veri çek
  useEffect(() => {
    if (sensiboApiKey) {
      fetchSensiboData()
    }
  }, [sensiboApiKey])

  // 1 dakikada bir otomatik yenile
  useEffect(() => {
    let interval
    if (sensiboApiKey) {
      interval = setInterval(() => {
        fetchSensiboData()
      }, 60 * 1000) // 1 dakika
    }

    return () => {
      if (interval) {
        clearInterval(interval)
      }
    }
  }, [sensiboApiKey])

  // Ayarları kaydet - .env dosyasına kaydet
  const handleSaveSettings = async () => {
    // .env dosyasına kaydet
    const saved = await saveConfigToServer(opmanagerUrl, sensiboApiKey)
    
    if (saved) {
      setIsConfigured(true)
      // Sensibo verilerini yeniden çek
      if (sensiboApiKey) {
        fetchSensiboData()
      }
      // Success feedback
      alert('✅ Ayarlar .env dosyasına kaydedildi ve tüm cihazlarda senkronize olacak!')
    } else {
      alert('❌ Ayarlar kaydedilemedi.')
    }
  }

  // Yapılandırma yükleme ekranı - Sadece hızlı yükleme için
  if (configLoading) {
    return (
      <div className="app">
        <div className="config-loading">
          <div className="loading-spinner"></div>
          <h2>Yükleniyor...</h2>
        </div>
      </div>
    )
  }

  // Yapılandırma bekleme ekranı - TAMAMEN KALDIRILDI
  // Artık her zaman ana dashboard gösterilecek

  return (
    <div className={`app ${isTvMode ? 'tv-mode' : ''}`}>
      {/* TV Mode Indicator */}
      {isTvMode && (
        <div className="tv-mode-indicator">
          📺 TV Mode - {window.screen.width}x{window.screen.height}
        </div>
      )}
      
      {/* Ana Dashboard Konteyneri */}
      <div className="dashboard-container">
        {/* Ana İçerik Alanı - OpManager (Tam Genişlik) */}
        <div className="panel main-panel">
          {opmanagerUrl ? (
            <div className="iframe-container">
              <iframe
                src={opmanagerUrl}
                className="opmanager-iframe"
                title="OpManager Dashboard"
                sandbox="allow-same-origin allow-scripts allow-forms allow-popups"
                referrerPolicy="no-referrer-when-downgrade"
              />
            </div>
          ) : (
            <div className="panel-placeholder">
              <p>OpManager linkini ayarlardan girin</p>
              <p className="hint">Örnek: https://example.com/dashboard</p>
            </div>
          )}
        </div>

        {/* Alt Bar - Sensibo Verileri + Ayarlar */}
        <div className="bottom-bar">
          {/* Sol Kısım - Sensibo Verileri */}
          <div className="sensibo-section">
            <div className="sensibo-content">
              {isLoading && (
                <div className="loading">
                  <p>Yükleniyor...</p>
                </div>
              )}
              
              {error && (
                <div className="error">
                  <p>{error}</p>
                </div>
              )}
              
              {sensiboData && sensiboData.length > 0 && !isLoading && !error && (
                <div className="sensibo-data">
                  {sensiboData.map((device, index) => (
                    <div key={device.id || index} className="device-card modern-card">
                      <div className="device-card-header">
                        <div className="device-title-row">
                          <h4>{device.room?.name || `Cihaz ${index + 1}`}</h4>
                        </div>
                      </div>
                      <div className="device-card-data">
                        <div className="data-row temperature-row">
                          <div className="data-label">
                            <span className="data-icon">🌡️</span>
                            Sıcaklık
                          </div>
                          <div className={`data-value temperature-value ${getTempCategory(device.temperature)}`}>
                            {device.temperature ? 
                              `${device.temperature.toFixed(1)}°C` : 
                              'N/A'}
                            {device.temperature && <div className="unit-label">Derece</div>}
                          </div>
                        </div>
                        <div className="data-row humidity-row">
                          <div className="data-label">
                            <span className="data-icon">💧</span>
                            Nem
                          </div>
                          <div className="data-value humidity-value">
                            {device.humidity ? 
                              `${device.humidity.toFixed(0)}%` : 
                              'N/A'}
                            {device.humidity && <div className="unit-label">Yüzde</div>}
                          </div>
                        </div>
                        {device.humidity && (
                          <div className="humidity-gauge">
                            <div className="gauge-track">
                              <div 
                                className={`gauge-fill ${getHumidityCategory(device.humidity)}`}
                                style={{ width: `${Math.min(device.humidity, 100)}%` }}
                              ></div>
                            </div>
                            <div className="gauge-labels">
                              <span>0%</span>
                              <span>50%</span>
                              <span>100%</span>
                            </div>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                  <div className="last-update">
                    Son Güncelleme: {new Date().toLocaleTimeString('tr-TR')}
                  </div>
                </div>
              )}
              
              {!sensiboApiKey && !isLoading && (
                <div className="no-data-message">
                  <p>Sensibo API anahtarını ayarlardan girin</p>
                </div>
              )}
            </div>
          </div>

          {/* Sağ Kısım - Ayarlar */}
          <div className="settings-section">
            <div className="settings-toggle" onClick={() => setShowSettingsModal(true)}>
              <div className="settings-icon">⚙️</div>
              <span>Ayarlar</span>
            </div>
            <div className="settings-content">
              <div className="settings-inputs">
                <input
                  type="text"
                  placeholder="OpManager Linki"
                  value={opmanagerUrl}
                  onChange={(e) => setOpmanagerUrl(e.target.value)}
                  className="settings-input"
                />
                <input
                  type="password"
                  placeholder="Sensibo API Anahtarı"
                  value={sensiboApiKey}
                  onChange={(e) => setSensiboApiKey(e.target.value)}
                  className="settings-input"
                />
                <button onClick={handleSaveSettings} className="save-button">
                  Kaydet
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Settings Modal */}
      {showSettingsModal && (
        <div className="settings-modal-overlay">
          <div className="settings-modal">
            <div className="modal-header">
              <h2>⚙️ Sistem Ayarları</h2>
              <button 
                className="modal-close-button"
                onClick={() => setShowSettingsModal(false)}
                title="Kapat"
              >
                ✕
              </button>
            </div>
            
            <div className="modal-content">
              <div className="setting-group">
                <label htmlFor="opmanager-input">OpManager Dashboard URL</label>
                <input
                  id="opmanager-input"
                  type="text"
                  placeholder="https://example.com/dashboard"
                  value={opmanagerUrl}
                  onChange={(e) => setOpmanagerUrl(e.target.value)}
                  className="modal-input"
                />
                <small>Üst panelde görüntülenecek OpManager linkini girin</small>
              </div>

              <div className="setting-group">
                <label htmlFor="sensibo-input">Sensibo API Anahtarı</label>
                <input
                  id="sensibo-input"
                  type="password"
                  placeholder="API anahtarınızı girin"
                  value={sensiboApiKey}
                  onChange={(e) => setSensiboApiKey(e.target.value)}
                  className="modal-input"
                />
                <small>Sensibo cihaz verilerini almak için API anahtarı gerekli</small>
              </div>

              <div className="modal-actions">
                <button 
                  onClick={() => setShowSettingsModal(false)}
                  className="modal-button secondary"
                >
                  İptal
                </button>
                <button 
                  onClick={() => {
                    handleSaveSettings();
                    setShowSettingsModal(false);
                  }}
                  className="modal-button primary"
                >
                  Kaydet
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
      </div>
  )
}

export default App
