import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    proxy: {
      '/api/sensibo': {
        target: 'https://home.sensibo.com',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/sensibo/, '/api/v2'),
        secure: true
      }
    }
  }
})
