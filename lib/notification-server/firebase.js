// src/config/firebase.js (ou o arquivo onde você inicializa)
const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');

// 1. Pega a string JSON da variável de ambiente
const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

if (!serviceAccountJson) {
    console.error("FIREBASE_SERVICE_ACCOUNT_JSON environment variable is not set!");
    // Em um ambiente local, você pode usar um arquivo JSON:
    // const serviceAccount = require('./caminho/para/seu/arquivo.json');
    // ... mas no Vercel, evite o arquivo.
}

// 2. Converte a string JSON em um objeto JavaScript
// (O método `cert` precisa de um objeto ou de um caminho para um arquivo)
const serviceAccount = JSON.parse(serviceAccountJson);

// 3. Inicializa o Firebase com as credenciais
const app = initializeApp({
    credential: cert(serviceAccount),
    // Se você precisar de outras configurações (como databaseURL):
    // databaseURL: "https://<PROJECT_ID>.firebaseio.com", 
});

const messaging = getMessaging(app);

// 4. Exporta a instância de messaging para uso em outros arquivos
module.exports = { messaging, app };

// Exporta o app ou o messaging para ser usado em `fcmService.js`