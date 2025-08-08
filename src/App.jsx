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

  // Sunucudan ayarları çek - Tüm cihazlar için merkezi sistem
  const fetchConfigFromServer = async () => {
    try {
      const response = await fetch(`http://${serverIp}:3001/api/config`)
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

  // Ayarları sunucuya kaydet - Tüm cihazlar için
  const saveConfigToServer = async (opmanager, sensibo) => {
    try {
      const response = await fetch(`http://${serverIp}:3001/api/config`, {
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

  // Sayfa yüklendiğinde ayarları kontrol et - Sunucu + localStorage hibrit
  useEffect(() => {
    const initializeConfig = async () => {
      // URL parametrelerini kontrol et
      const urlParams = new URLSearchParams(window.location.search)
      const urlOpmanager = urlParams.get('opmanager')
      const urlSensibo = urlParams.get('sensibo')
      
      // URL parametresi varsa direkt kullan ve sunucuya kaydet
      if (urlOpmanager || urlSensibo) {
        if (urlOpmanager) {
          const decodedUrl = decodeURIComponent(urlOpmanager)
          setOpmanagerUrl(decodedUrl)
        }
        if (urlSensibo) {
          setSensiboApiKey(urlSensibo)
        }
        // URL parametrelerini sunucuya ve localStorage'a kaydet
        await saveConfigToServer(
          urlOpmanager ? decodeURIComponent(urlOpmanager) : '',
          urlSensibo || ''
        )
        setIsConfigured(true)
        setConfigLoading(false)
        return
      }

      // Önce sunucudan ayarları yükle
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

  // Ayarları kaydet - Sunucu tabanlı sistem
  const handleSaveSettings = async () => {
    // Sunucuya kaydet
    const saved = await saveConfigToServer(opmanagerUrl, sensiboApiKey)
    
    if (saved) {
      setIsConfigured(true)
      // Sensibo verilerini yeniden çek
      if (sensiboApiKey) {
        fetchSensiboData()
      }
      // Success feedback
      alert('✅ Ayarlar başarıyla kaydedildi ve tüm cihazlara gönderildi!')
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
    <div className="app">
      {/* Ana Dashboard Konteyneri */}
      <div className="dashboard-container">
        {/* Sol Panel - OpManager (%80) */}
        <div className="panel left-panel">
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

        {/* Sağ Panel - Sensibo (%20) */}
        <div className="panel right-panel">
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
                <div className="devices-header">
                  <h3>Toplam {sensiboData.length} Cihaz</h3>
                </div>
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
              <div className="panel-placeholder">
                <p>Sensibo API anahtarını ayarlardan girin</p>
              </div>
            )}
          </div>

          {/* Ayarlar Bölümü - Sağ Panel Alt Kısım */}
          <div className="settings">
            <div className="settings-handle">
              <div className="settings-handle-icon">⚙️</div>
              <div className="settings-handle-text">Ayarlar</div>
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
                
                {/* TV için kullanım talimatı */}
                <div className="tv-instructions">
                  <div className="tv-tip">
                    📺 <strong>TV İçin Kolay Kurulum:</strong>
                  </div>
                  <div className="tv-tip-text">
                    Bilgisayardan şu formatta link hazırla:<br/>
                    <code>
                      http://{serverIp}/?opmanager=OPMANAGER_URL&sensibo=API_KEY
                    </code>
                  </div>
                  <div className="tv-example">
                    <strong>Örnek:</strong><br/>
                    <small>http://{serverIp}/?opmanager=https%3A//example.com&sensibo=abc123</small>
                  </div>
                  <div className="tv-note">
                    💡 <strong>Not:</strong> Ayarlar sunucuda saklanır, tüm cihaz ve sekmelerde görünür
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
