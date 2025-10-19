// Exemplo: src/api/SendToConsultor.js

// 1. Importa a instância de messaging
const { messaging } = require('../firebase');

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).send('Method Not Allowed');

  // Renomeado deviceToken para token (convenção do FCM)
  const { token, title, body } = req.body; 

  if (!token || !title || !body) {
    return res.status(400).json({ message: 'Missing parameters' });
  }

  // 2. Cria o objeto da mensagem no formato da API v1
  const message = {
    notification: {
      title: title,
      body: body,
    },
    // Adicione dados bidirecionais aqui, se necessário
    data: {
      acao: 'novo_agendamento', 
      agendamentoId: '12345',
    },
    token: token,
    // Adiciona as configurações de prioridade diretamente na mensagem v1
    android: {
      priority: 'HIGH',
    },
  };

  try {
    // 3. Usa o método send() do SDK
    const response = await messaging.send(message);

    // O retorno é o messageId
    res.status(200).json({ success: true, messageId: response }); 

  } catch (error) {
    // Erros do Admin SDK são mais detalhados
    console.error('Erro ao enviar notificação:', error);
    res.status(500).json({ message: 'Falha no envio da notificação', error: error.code });
  }
}
