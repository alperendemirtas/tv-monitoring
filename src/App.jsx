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

  // Sunucudan ayarları çek (TV için) - Basitleştirilmiş versiyon
  const fetchConfigFromServer = async () => {
    try {
      // Önce localStorage'dan kontrol et
      const savedOpmanagerUrl = localStorage.getItem('opmanagerUrl') || ''
      const savedSensiboApiKey = localStorage.getItem('sensiboApiKey') || ''
      
      if (savedOpmanagerUrl || savedSensiboApiKey) {
        setOpmanagerUrl(savedOpmanagerUrl)
        setSensiboApiKey(savedSensiboApiKey)
        setIsConfigured(true)
        return true
      }
      return false
    } catch (err) {
      console.error('Config yüklenemedi:', err)
      return false
    } finally {
      setConfigLoading(false)
    }
  }

  // Ayarları sunucuya kaydet - Basitleştirilmiş (sadece localStorage)
  const saveConfigToServer = async (opmanager, sensibo) => {
    try {
      // Sadece localStorage'a kaydet
      localStorage.setItem('opmanagerUrl', opmanager)
      localStorage.setItem('sensiboApiKey', sensibo)
      return true
    } catch (err) {
      console.error('LocalStorage\'a kaydedilemedi:', err)
      return false
    }
  }

  // Sayfa yüklendiğinde önce sunucudan, sonra localStorage'dan verileri oku
  useEffect(() => {
    const initializeConfig = async () => {
      // URL parametrelerini kontrol et
      const urlParams = new URLSearchParams(window.location.search)
      const urlOpmanager = urlParams.get('opmanager')
      const urlSensibo = urlParams.get('sensibo')
      
      // URL parametresi varsa direkt kullan
      if (urlOpmanager || urlSensibo) {
        if (urlOpmanager) setOpmanagerUrl(decodeURIComponent(urlOpmanager))
        if (urlSensibo) setSensiboApiKey(urlSensibo)
        setIsConfigured(true)
        setConfigLoading(false)
        return
      }

      // Sunucudan ayarları çekmeye çalış (sadece localStorage)
      const serverConfigLoaded = await fetchConfigFromServer()
      
      if (!serverConfigLoaded) {
        // Sunucuda ayar yoksa localStorage'dan oku
        const savedOpmanagerUrl = localStorage.getItem('opmanagerUrl') || ''
        const savedSensiboApiKey = localStorage.getItem('sensiboApiKey') || ''
        
        setOpmanagerUrl(savedOpmanagerUrl)
        setSensiboApiKey(savedSensiboApiKey)
        setIsConfigured(!!(savedOpmanagerUrl || savedSensiboApiKey))
      }
    }

    initializeConfig()
  }, [serverIp])

  // Ayarları kontrol etmek için polling - Basitleştirilmiş
  useEffect(() => {
    let configInterval
    
    if (!isConfigured) {
      configInterval = setInterval(async () => {
        // Sadece localStorage'u kontrol et
        const savedOpmanagerUrl = localStorage.getItem('opmanagerUrl') || ''
        const savedSensiboApiKey = localStorage.getItem('sensiboApiKey') || ''
        
        if (savedOpmanagerUrl || savedSensiboApiKey) {
          setOpmanagerUrl(savedOpmanagerUrl)
          setSensiboApiKey(savedSensiboApiKey)
          setIsConfigured(true)
          clearInterval(configInterval)
        }
      }, 5000) // 5 saniyede bir kontrol et
    }

    return () => {
      if (configInterval) {
        clearInterval(configInterval)
      }
    }
  }, [isConfigured, serverIp])

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

  // Ayarları kaydet - Basitleştirilmiş versiyon
  const handleSaveSettings = async () => {
    // localStorage'a kaydet
    const saved = await saveConfigToServer(opmanagerUrl, sensiboApiKey)
    
    if (saved) {
      setIsConfigured(true)
      // Sensibo verilerini yeniden çek
      if (sensiboApiKey) {
        fetchSensiboData()
      }
      // Success feedback
      alert('✅ Ayarlar başarıyla kaydedildi!')
    } else {
      alert('❌ Ayarlar kaydedilemedi.')
    }
  }

  // Yapılandırma bekleme ekranı
  if (configLoading) {
    return (
      <div className="app">
        <div className="config-loading">
          <div className="loading-spinner"></div>
          <h2>Ayarlar yükleniyor...</h2>
          <p>Lütfen bekleyin</p>
        </div>
      </div>
    )
  }

  // Yapılandırma bekleme ekranı (TV için)
  if (!isConfigured && !configLoading) {
    return (
      <div className="app">
        <div className="config-waiting">
          <div className="waiting-content">
            <div className="tv-icon">📺</div>
            <h1>TV Dashboard Yapılandırma Bekleniyor</h1>
            
            <div className="instructions">
              <h3>Bu ekranı yapılandırmak için:</h3>
              <ol>
                <li>Aynı ağdaki bir bilgisayardan tarayıcınızı açın</li>
                <li>Aşağıdaki adrese gidin:</li>
                <div className="config-url">
                  http://{serverIp}
                </div>
                <li>Ayarları doldurup "Kaydet" butonuna tıklayın</li>
                <li>Bu TV'de aynı tarayıcıyı kullanmalısınız (localStorage)</li>
              </ol>
            </div>
            
            <div className="polling-indicator">
              <div className="pulse"></div>
              <span>LocalStorage kontrol ediliyor... (5 saniyede bir)</span>
            </div>
            
            <div className="manual-config">
              <details>
                <summary>Manuel Ayar</summary>
                <div className="manual-form">
                  <input
                    type="text"
                    placeholder="OpManager URL"
                    value={opmanagerUrl}
                    onChange={(e) => setOpmanagerUrl(e.target.value)}
                    className="manual-input"
                  />
                  <input
                    type="password"
                    placeholder="Sensibo API Key"
                    value={sensiboApiKey}
                    onChange={(e) => setSensiboApiKey(e.target.value)}
                    className="manual-input"
                  />
                  <button onClick={handleSaveSettings} className="manual-save-btn">
                    Manuel Kaydet
                  </button>
                </div>
              </details>
            </div>
          </div>
        </div>
      </div>
    )
  }

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
                      http://SERVER_IP/?opmanager=OPMANAGER_URL&sensibo=API_KEY
                    </code>
                  </div>
                  <div className="tv-example">
                    <strong>Örnek:</strong><br/>
                    <small>http://10.10.11.164/?opmanager=https%3A//example.com&sensibo=abc123</small>
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
