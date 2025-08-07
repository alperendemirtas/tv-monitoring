<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# TV Monitoring Dashboard Project

This is a React + Vite project for a TV monitoring dashboard that displays:
- OpManager interface in left panel via iframe
- Sensibo climate data in right panel via API
- Settings for OpManager URL and Sensibo API key stored in localStorage
- Full-screen layout optimized for TV displays with dark theme
- Auto-refresh every 5 minutes for Sensibo data

## Key Components
- Split-screen layout with equal panels
- localStorage for persistent settings
- Real-time data fetching from Sensibo API
- Error handling and loading states
- TV-optimized styling
