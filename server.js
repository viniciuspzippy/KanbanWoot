const express = require('express');
const path = require('path');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();
const PORT = process.env.PORT || 80;
const CHATWOOT_URL = process.env.REACT_APP_CHATWOOT_URL || 'https://chatwoot.zippydigital.com.br';

// Proxy /api/* para o Chatwoot (mantém path completo, resolve CORS)
app.use(createProxyMiddleware({
  target: CHATWOOT_URL,
  changeOrigin: true,
  secure: true,
  pathFilter: '/api',
}));

// Serve arquivos estáticos do build
app.use(express.static(path.join(__dirname, 'build')));

// SPA fallback: qualquer rota não encontrada serve index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`KanbanWoot rodando na porta ${PORT}`);
  console.log(`Proxy API → ${CHATWOOT_URL}`);
});
