// Exemplo: src/api/SendToHig.js

// 1. Importa a instância de messaging
const { messaging } = require('../firebase');

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

  // Renomeado deviceTokens para tokens (convenção do FCM)
  const { tokens, title, body } = req.body; 

  if (!tokens || !title || !body || !Array.isArray(tokens) || tokens.length === 0) {
    return res.status(400).json({ message: 'Missing parameters or invalid tokens array' });
  }
  
  // O formato da mensagem é o mesmo, mas a lista de tokens fica fora
  const multicastMessage = {
    notification: {
      title: title,
      body: body,
    },
    // Adicione dados bidirecionais aqui, se necessário
    data: {
      acao: 'agendamento_concluido', 
      higienizadorId: '9876',
    },
    // O array de tokens vai aqui
    tokens: tokens, 
    android: {
      priority: 'HIGH',
    },
  };

  try {
    // 3. Usa o método sendMulticast() do SDK
    // É recomendado para envio em massa (até 500 tokens por chamada)
    const response = await messaging.sendMulticast(multicastMessage);

    // O retorno mostra o sucesso e a falha de cada token
    res.status(200).json({ 
        success: true, 
        message: `${response.successCount} mensagens enviadas com sucesso.`,
        failedCount: response.failureCount,
        details: response.responses.filter(r => !r.success) // Detalhes dos erros
    });

  } catch (error) {
    console.error('Erro ao enviar notificação em massa:', error);
    res.status(500).json({ message: 'Falha no envio da notificação em massa', error: error.code });
  }
}
