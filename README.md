# Orça+

Aplicativo profissional para eletricistas criarem orçamentos de forma rápida e eficiente.
- ## ✨ Funcionalidades
- ### Plano Gratuito
- Até 5 orçamentos por mês
- Geração de PDF com marca d'água
- Gerenciamento de clientes
- Tabela fixa de serviços elétricos
- ### Plano Pro (R$ 19,90/mês)
- ✅ Orçamentos ilimitados
- ✅ PDF sem marca d'água
- ✅ Upload de logo personalizada
- ✅ Histórico completo
- ✅ Suporte prioritário
- ## 🏗️ Arquitetura
	- ## Gerenciamento de Estado
	- Atualmente: setState
	- Problemas encontrados:
	- Melhorias planejadas:
	- ## Comunicação com API
	- Onde está localizada
	- Padrão usado
	- Problemas recorrentes
	- ## Organização de pastas
	- Estrutura atual
	- Pontos fracos
	-
- **Clean Architecture + MVVM**
- **State Management:** Riverpod
- **Backend:** Firebase (Auth, Firestore, Storage)
- **PDF Generation:** flutter_pdf
- **Billing:** Google Play In-App Purchase
- ## 📁 Estrutura do Projeto
  
  ```
  lib/
  ├── core/
  │   ├── theme/          # Design system
  │   ├── constants/      # Constantes
  │   └── utils/          # Utilitários
  ├── models/             # Modelos de dados
  ├── services/           # Serviços (Firebase, PDF, etc)
  ├── viewmodels/         # Gerenciamento de estado
  ├── screens/            # Telas do app
  ├── widgets/            # Componentes reutilizáveis
  └── routes/             # Navegação
  ```
- ## 🚀 Como Começar
- ### Pré-requisitos
- Flutter SDK 3.10.7+
- Firebase CLI
- Conta no Firebase
- Conta no Google Play Console (para produção)
- ### Instalação
  
  1. Clone o repositório:
  ```bash
  git clone <repository-url>
  cd orcafacil
  ```
  
  2. Instale as dependências:
  ```bash
  flutter pub get
  ```
  
  3. Configure o Firebase:
  ```bash
  flutterfire configure
  ```
  
  4. Siga o guia completo em `firebase_setup_guide.md`
  
  5. Execute o app:
  ```bash
  flutter run
  ```
- ## 🔧 Configuração do Firebase
  
  Consulte o arquivo `firebase_setup_guide.md` para instruções detalhadas sobre:
- Criação do projeto Firebase
- Configuração de Authentication
- Setup do Firestore
- Configuração do Storage
- Google Play Billing
- ## 📱 Telas Implementadas
- ✅ Splash Screen
- ✅ Login / Cadastro
- ✅ Dashboard
- ✅ Configurações
- 🚧 Novo Orçamento (wizard em 3 etapas)
- 🚧 Histórico de Orçamentos
- 🚧 Gerenciamento de Serviços
- 🚧 Tela de Assinatura
- ## 🎨 Design System
- **Cor Primária:** #2563EB (Azul)
- **Cor Secundária:** #22C55E (Verde)
- **Fonte:** Google Fonts Inter
- **Tema:** Suporte a modo claro/escuro
- **Logo:** Raio + símbolo de adição
- ## 📄 Geração de PDF
  
  O sistema gera PDFs profissionais com:
- Cabeçalho com logo
- Dados do profissional
- Dados do cliente
- Lista de serviços com preços
- Total do orçamento
- Marca d'água para usuários gratuitos
- ## 🔒 Segurança
- Isolamento de dados por usuário (UID)
- Regras de segurança Firestore implementadas
- Proteção contra bypass de assinatura
- Storage com restrições de tamanho e tipo
- ## 🧪 Testes
  
  ```bash
  # Testes unitários
  flutter test
  
  # Análise de código
  flutter analyze
  ```
- ## 📦 Build
- ### Android
  ```bash
  flutter build apk --release
  flutter build appbundle --release
  ```
- ### iOS
  ```bash
  flutter build ios --release
  ```
- ## 🛠️ Tecnologias
- Flutter 3.10.7+
- Firebase (Auth, Firestore, Storage)
- Riverpod (State Management)
- go_router (Navigation)
- Google Fonts
- PDF Generation
- In-App Purchase
- ## 📝 Próximos Passos
  
  1. Implementar wizard completo de criação de orçamento
  2. Adicionar histórico com busca e filtros
  3. Implementar CRUD completo de serviços
  4. Criar tela de upgrade para Pro
  5. Adicionar Analytics
  6. Implementar Cloud Functions para notificações
  7. Adicionar testes automatizados
- ## 💰 Monetização
- **Produto ID:** `orcamais_pro_monthly`
- **Preço:** R$ 19,90/mês
- **Plataforma:** Google Play Store
- ## 📄 Licença
  
  Este projeto é privado e proprietário.
- ## 👨‍💻 Autor
  
  Desenvolvido para eletricistas profissionais.
  
  ---
  
  **Status:** Em desenvolvimento 🚧
  
  Para suporte ou dúvidas, consulte a documentação do Firebase e Flutter.