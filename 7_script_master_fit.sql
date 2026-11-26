-- ==========================================
-- 0. REMOÇÃO DE TABELAS EXISTENTES (CASO NECESSÁRIO)
-- ==========================================
DROP TABLE IF EXISTS diario_alimentar CASCADE;
DROP TABLE IF EXISTS item_pedido CASCADE;
DROP TABLE IF EXISTS pedido CASCADE;
DROP TABLE IF EXISTS suplemento_favorito CASCADE;
DROP TABLE IF EXISTS notificacao_push CASCADE;
DROP TABLE IF EXISTS endereco CASCADE;
DROP TABLE IF EXISTS cupom_desconto CASCADE;
DROP TABLE IF EXISTS alimento CASCADE;
DROP TABLE IF EXISTS suplemento CASCADE;
DROP TABLE IF EXISTS usuario CASCADE;

-- Remoção dos ENUMs caso já existam
DROP TYPE IF EXISTS categoria_refeicao_enum;
DROP TYPE IF EXISTS status_pedido_enum;
DROP TYPE IF EXISTS tipo_notificacao_enum;
DROP TYPE IF EXISTS tipo_perfil_user;

-- ==========================================
-- CRIAÇÃO DOS TIPOS ENUM
-- ==========================================
CREATE TYPE tipo_perfil_user AS ENUM ('CLIENTE', 'ADMIN');
CREATE TYPE tipo_notificacao_enum AS ENUM ('LEMBRETE_REFEICAO', 'PROMOCAO', 'STATUS_PEDIDO', 'META_ATINGIDA');
CREATE TYPE status_pedido_enum AS ENUM ('PENDENTE', 'PAGO', 'ENVIADO', 'ENTREGUE', 'CANCELADO');
CREATE TYPE categoria_refeicao_enum AS ENUM ('CAFE_DA_MANHA', 'ALMOCO', 'JANTAR', 'LANCHE', 'PRE_TREINO', 'POS_TREINO');

-- ==========================================
-- 1. TABELA: usuario
-- ==========================================
CREATE TABLE usuario (
    id_usuario SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    senha_hash VARCHAR(255) NOT NULL,
    data_nascimento DATE NOT NULL,
    tipo_perfil tipo_perfil_user NOT NULL,
    fcm_token VARCHAR(255),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_usuario_email UNIQUE (email)
);

-- ==========================================
-- 2. TABELA: suplemento
-- ==========================================
CREATE TABLE suplemento (
    id_suplemento SERIAL PRIMARY KEY,
    nome VARCHAR(150) NOT NULL,
    descricao TEXT,
    peso_kg_g VARCHAR(30) NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,
    quantidade_estoque INT NOT NULL,
    url_imagem VARCHAR(255),
    ativo BOOLEAN DEFAULT TRUE
);

-- ==========================================
-- 3. TABELA: alimento
-- ==========================================
CREATE TABLE alimento (
    id_alimento SERIAL PRIMARY KEY,
    nome VARCHAR(120) NOT NULL,
    porcao_padrao_gramas DECIMAL(8,2) NOT NULL,
    calorias_base DECIMAL(8,2) NOT NULL,
    proteinas_g DECIMAL(6,2),
    carboidratos_g DECIMAL(6,2),
    gorduras_g DECIMAL(6,2),
    fk_usuario INT,

    CONSTRAINT uq_alimento_nome UNIQUE (nome),
    CONSTRAINT fk_alimento_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE SET NULL
);

-- ==========================================
-- 4. TABELA: cupom_desconto
-- ==========================================
CREATE TABLE cupom_desconto (
    id_cupom_desconto SERIAL PRIMARY KEY,
    codigo_cupom VARCHAR(30) NOT NULL,
    percentual_desconto DECIMAL(5,2),
    valor_desconto_fixo DECIMAL(10,2),
    data_validade TIMESTAMP NOT NULL,
    ativo BOOLEAN DEFAULT TRUE,

    CONSTRAINT uq_cupom_desconto_codigo UNIQUE (codigo_cupom)
);

-- ==========================================
-- 5. TABELA: endereco
-- ==========================================
CREATE TABLE endereco (
    id_endereco SERIAL PRIMARY KEY,
    fk_usuario INT NOT NULL,
    cep VARCHAR(8) NOT NULL,
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(20) NOT NULL,
    complemento VARCHAR(50),
    bairro VARCHAR(100) NOT NULL,
    cidade VARCHAR(100) NOT NULL,
    estado VARCHAR(2) NOT NULL,
    eh_principal BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_endereco_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

-- ==========================================
-- 6. TABELA: notificacao_push
-- ==========================================
CREATE TABLE notificacao_push (
    id_notificacao_push SERIAL PRIMARY KEY,
    fk_usuario INT NOT NULL,
    titulo VARCHAR(100) NOT NULL,
    mensagem TEXT NOT NULL,
    tipo_notificacao tipo_notificacao_enum NOT NULL,
    data_agendamento TIMESTAMP NOT NULL,
    enviada BOOLEAN DEFAULT FALSE,
    data_envio TIMESTAMP,

    CONSTRAINT fk_notificacao_push_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE
);

-- ==========================================
-- 7. TABELA: suplemento_favorito
-- ==========================================
CREATE TABLE suplemento_favorito (
    id_suplemento_favorito SERIAL PRIMARY KEY,
    fk_usuario INT NOT NULL,
    fk_suplemento INT NOT NULL,
    data_adicao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_suplemento_favorito_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_suplemento_favorito_suplemento FOREIGN KEY (fk_suplemento) REFERENCES suplemento(id_suplemento) ON DELETE CASCADE
);

-- ==========================================
-- 8. TABELA: pedido
-- ==========================================
CREATE TABLE pedido (
    id_pedido SERIAL PRIMARY KEY,
    fk_usuario INT NOT NULL,
    fk_endereco INT NOT NULL,
    fk_cupom_desconto INT,
    status_pedido status_pedido_enum NOT NULL,
    valor_subtotal DECIMAL(10,2) NOT NULL,
    valor_desconto DECIMAL(10,2) DEFAULT 0.00,
    valor_total DECIMAL(10,2) NOT NULL,
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_pedido_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_endereco FOREIGN KEY (fk_endereco) REFERENCES endereco(id_endereco) ON DELETE CASCADE,
    CONSTRAINT fk_pedido_cupom_desconto FOREIGN KEY (fk_cupom_desconto) REFERENCES cupom_desconto(id_cupom_desconto) ON DELETE SET NULL
);

-- ==========================================
-- 9. TABELA: item_pedido
-- ==========================================
CREATE TABLE item_pedido (
    id_item_pedido SERIAL PRIMARY KEY,
    fk_pedido INT NOT NULL,
    fk_suplemento INT NOT NULL,
    quantidade INT NOT NULL,
    preco_unitario DECIMAL(10,2) NOT NULL,

    CONSTRAINT fk_item_pedido_pedido FOREIGN KEY (fk_pedido) REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    CONSTRAINT fk_item_pedido_suplemento FOREIGN KEY (fk_suplemento) REFERENCES suplemento(id_suplemento) ON DELETE CASCADE
);

-- ==========================================
-- 10. TABELA: diario_alimentar
-- ==========================================
CREATE TABLE diario_alimentar (
    id_diario_alimentar SERIAL PRIMARY KEY,
    fk_usuario INT NOT NULL,
    fk_alimento INT NOT NULL,
    categoria_refeicao categoria_refeicao_enum NOT NULL,
    quantidade_gramas DECIMAL(8,2) NOT NULL,
    calorias_calculadas DECIMAL(8,2) NOT NULL,
    data_registro DATE NOT NULL,
    data_sincronizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_diario_alimentar_usuario FOREIGN KEY (fk_usuario) REFERENCES usuario(id_usuario) ON DELETE CASCADE,
    CONSTRAINT fk_diario_alimentar_alimento FOREIGN KEY (fk_alimento) REFERENCES alimento(id_alimento) ON DELETE CASCADE
);


-- ==========================================
-- SCRIPT DE INSERÇÃO DIDÁTICA (DADOS REALISTAS)
-- ==========================================

-- 1. USUARIO
INSERT INTO usuario (nome, email, senha_hash, data_nascimento, tipo_perfil, fcm_token) VALUES
('Ana Souza', 'ana.admin@masterfit.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', '1988-04-12', 'ADMIN', 'fcm_token_ana_001'),
('Carlos Silva', 'carlos.silva@email.com', '$2y$10$8kR5vN2m1L0p9Q3w5e6r7u8i9o0p1a2s3d4f5g6h7j8k9l0z1x2c3v', '1992-09-23', 'CLIENTE', 'fcm_token_carlos_002'),
('Beatriz Lima', 'beatriz.lima@email.com', '$2y$10$3vB2nM1k9L8j7H6g5f4d3s2a1p0o9i8u7y6t5r4e3w2q1z0x9c8v7b', '1995-07-15', 'CLIENTE', 'fcm_token_beatriz_003'),
('Daniel Oliveira', 'daniel.oli@email.com', '$2y$10$5tG7bN4m2V1c0x9z8l7k6j5h4g3f2d1s0a9p8o7i6u5y4t3r2e1w0q', '1990-11-30', 'CLIENTE', 'fcm_token_daniel_004'),
('Elena Rocha', 'elena.admin@masterfit.com', '$2y$10$1qA2z3W4s5X6c7D8f9V0gHjKlPoIuYtReWqAsDfGhJkLzXcVbNm', '1985-02-18', 'ADMIN', 'fcm_token_elena_005'),
('Felipe Santos', 'felipe.santos@email.com', '$2y$10$9p0O9i8U7y6T5r4E3w2Q1a0S9d8F7g6H5j4K3l2Z1x0C9v8B7n6M5', '1998-06-05', 'CLIENTE', 'fcm_token_felipe_006'),
('Gabriela Costa', 'gabriela.costa@email.com', '$2y$10$4bN5m6L7k8J9h0G1f2D3s4A5p6O7i8U9y0T1r2E3w4Q5a6S7d8F9g', '1994-12-09', 'CLIENTE', 'fcm_token_gabriela_007'),
('Hugo Almeida', 'hugo.almeida@email.com', '$2y$10$7z8x9c0v1b2n3m4L5k6J7h8G9f0D1s2A3p4O5i6U7y8T9r0E1w2Q3', '1989-03-27', 'CLIENTE', NULL),
('Isabela Martins', 'isabela.martins@email.com', '$2y$10$2w3e4r5t6y7u8i9o0p1a2s3d4f5g6h7j8k9l0z1x2c3v4b5n6m7k8', '1996-08-14', 'CLIENTE', 'fcm_token_isabela_009'),
('João Pereira', 'joao.pereira@email.com', '$2y$10$6m5n4b3v2c1x0z9l8k7j6h5g4f3d2s1a0p9o8i7u6y5t4r3e2w1q0', '1993-10-02', 'CLIENTE', 'fcm_token_joao_010');

-- 2. SUPLEMENTO
INSERT INTO suplemento (nome, descricao, peso_kg_g, preco_unitario, quantidade_estoque, url_imagem, ativo) VALUES
('Whey Protein Concentrado 80%', 'Proteína concentrada do soro do leite sabor chocolate.', '900g', 129.90, 50, 'https://cdn.masterfit.com/img/whey-conc.png', TRUE),
('Whey Protein Isolado', 'Proteína isolada de rápida absorção sem lactose sabor baunilha.', '900g', 189.90, 35, 'https://cdn.masterfit.com/img/whey-iso.png', TRUE),
('Creatina Monohidratada Pura', 'Creatina 100% pura micronizada para aumento de força e explosão.', '300g', 89.90, 80, 'https://cdn.masterfit.com/img/creatina.png', TRUE),
('Pré-Treino Insane Energy', 'Suplemento termogênico e vasodilatador sabor frutas vermelhas.', '300g', 115.00, 40, 'https://cdn.masterfit.com/img/pre-treino.png', TRUE),
('BCAA 2:1:1 em Pó', 'Aminoácidos de cadeia ramificada para recuperação muscular.', '250g', 69.90, 60, 'https://cdn.masterfit.com/img/bcaa.png', TRUE),
('Glutamina L-Glutamine', 'Suporte imunológico e recuperação pós-treino intenso.', '300g', 74.50, 45, 'https://cdn.masterfit.com/img/glutamina.png', TRUE),
('Hipercalórico Mass Gainer', 'Combinação de carboidratos complexos e proteínas para ganho de massa.', '3kg', 149.90, 25, 'https://cdn.masterfit.com/img/hipercalorico.png', TRUE),
('Multivitamínico Ultra Daily', 'Complexo completo de vitaminas e minerais essenciais (60 cápsulas).', '120g', 49.90, 100, 'https://cdn.masterfit.com/img/multivit.png', TRUE),
('Ômega 3 EPA DHA Concentrado', 'Óleo de peixe purificado de alta concentração (120 cápsulas).', '180g', 64.90, 70, 'https://cdn.masterfit.com/img/omega3.png', TRUE),
('Barra Proteica Crunch Box', 'Caixa com 12 unidades de barra proteica sabor cookies and cream.', '720g', 95.00, 30, 'https://cdn.masterfit.com/img/barra-prot.png', TRUE);

-- 3. ALIMENTO
INSERT INTO alimento (nome, porcao_padrao_gramas, calorias_base, proteinas_g, carboidratos_g, gorduras_g, fk_usuario) VALUES
('Peito de Frango Grelhado', 100.00, 159.00, 32.00, 0.00, 2.50, 1),
('Arroz Branco Cozido', 100.00, 128.00, 2.50, 28.10, 0.20, 1),
('Ovo de Galinha Inteiro Cozido', 50.00, 73.00, 6.30, 0.60, 4.80, 1),
('Batata Doce Cozida', 100.00, 77.00, 0.60, 18.40, 0.10, 5),
('Aveia em Flocos Finos', 30.00, 117.00, 4.30, 17.00, 2.20, 5),
('Banana Prata', 100.00, 98.00, 1.30, 26.00, 0.10, 1),
('Patinho Bovino Moído Refogado', 100.00, 219.00, 35.90, 0.00, 7.30, 5),
('Feijão Carioca Cozido', 100.00, 76.00, 4.80, 13.60, 0.50, 1),
('Pasta de Amendoim Integral', 15.00, 90.00, 4.20, 3.10, 7.50, 5),
('Iogurte Natural Desnatado', 170.00, 75.00, 7.10, 10.50, 0.40, 1);

-- 4. CUPOM_DESCONTO
INSERT INTO cupom_desconto (codigo_cupom, percentual_desconto, valor_desconto_fixo, data_validade, ativo) VALUES
('BEMVINDO10', 10.00, NULL, CURRENT_TIMESTAMP + INTERVAL '30 days', TRUE),
('MASTERFIT20', 20.00, NULL, CURRENT_TIMESTAMP + INTERVAL '15 days', TRUE),
('DESCONTO15FIXO', NULL, 15.00, CURRENT_TIMESTAMP + INTERVAL '20 days', TRUE),
('TREINO25', 25.00, NULL, CURRENT_TIMESTAMP + INTERVAL '10 days', TRUE),
('FRETEGRATIS30', NULL, 30.00, CURRENT_TIMESTAMP + INTERVAL '25 days', TRUE),
('VERAO15', 15.00, NULL, CURRENT_TIMESTAMP + INTERVAL '60 days', TRUE),
('SUPLE50', NULL, 50.00, CURRENT_TIMESTAMP + INTERVAL '7 days', TRUE),
('ATLETA12', 12.00, NULL, CURRENT_TIMESTAMP + INTERVAL '14 days', TRUE),
('EXPIRADO10', 10.00, NULL, CURRENT_TIMESTAMP - INTERVAL '5 days', FALSE),
('VIP30', 30.00, NULL, CURRENT_TIMESTAMP + INTERVAL '45 days', TRUE);

-- 5. ENDERECO
INSERT INTO endereco (fk_usuario, cep, logradouro, numero, complemento, bairro, cidade, estado, eh_principal) VALUES
(2, '80010000', 'Rua XV de Novembro', '1200', 'Apto 402', 'Centro', 'Curitiba', 'PR', TRUE),
(3, '80250210', 'Avenida Sete de Setembro', '3450', 'Bloco B', 'Batel', 'Curitiba', 'PR', TRUE),
(4, '01310100', 'Avenida Paulista', '1578', 'Conj 10', 'Bela Vista', 'São Paulo', 'SP', TRUE),
(6, '22041001', 'Avenida Atlântica', '2100', 'Apto 801', 'Copacabana', 'Rio de Janeiro', 'RJ', TRUE),
(7, '30130001', 'Avenida Afonso Pena', '950', NULL, 'Centro', 'Belo Horizonte', 'MG', TRUE),
(8, '90010150', 'Rua dos Andradas', '1420', 'Sala 3', 'Centro Histórico', 'Porto Alegre', 'RS', TRUE),
(9, '88015200', 'Avenida Beira Mar Norte', '2800', 'Apto 1102', 'Centro', 'Florianópolis', 'SC', TRUE),
(10, '40020000', 'Avenida Sete de Setembro', '510', 'Casa', 'Dois de Julho', 'Salvador', 'BA', TRUE),
(2, '80620010', 'Avenida República Argentina', '1890', NULL, 'Água Verde', 'Curitiba', 'PR', FALSE),
(3, '80420090', 'Rua Comendador Araújo', '450', 'Apto 21', 'Centro', 'Curitiba', 'PR', FALSE);

-- 6. NOTIFICACAO_PUSH
INSERT INTO notificacao_push (fk_usuario, titulo, mensagem, tipo_notificacao, data_agendamento, enviada, data_envio) VALUES
(2, 'Hora do Almoço!', 'Não se esqueça de registrar sua refeição no diário alimentar.', 'LEMBRETE_REFEICAO', CURRENT_TIMESTAMP - INTERVAL '2 hours', TRUE, CURRENT_TIMESTAMP - INTERVAL '2 hours'),
(3, 'Cupom Especial Liberado', 'Use MASTERFIT20 e ganhe 20% OFF em toda linha de Whey Protein.', 'PROMOCAO', CURRENT_TIMESTAMP - INTERVAL '1 day', TRUE, CURRENT_TIMESTAMP - INTERVAL '1 day'),
(4, 'Pedido Enviado!', 'Seu pedido #3 já está com a transportadora.', 'STATUS_PEDIDO', CURRENT_TIMESTAMP - INTERVAL '3 hours', TRUE, CURRENT_TIMESTAMP - INTERVAL '3 hours'),
(6, 'Meta de Proteínas Atingida', 'Parabéns! Você bateu sua meta diária de macronutrientes.', 'META_ATINGIDA', CURRENT_TIMESTAMP - INTERVAL '30 minutes', TRUE, CURRENT_TIMESTAMP - INTERVAL '30 minutes'),
(7, 'Lembrete Pós-Treino', 'Registre seu shake ou refeição pós-treino agora mesmo.', 'LEMBRETE_REFEICAO', CURRENT_TIMESTAMP + INTERVAL '1 hour', FALSE, NULL),
(8, 'Oferta Relâmpago Creatina', 'Estoque renovado! Garanta sua Creatina Pura com desconto.', 'PROMOCAO', CURRENT_TIMESTAMP + INTERVAL '2 hours', FALSE, NULL),
(9, 'Pedido Entregue', 'Seu pedido foi entregue com sucesso no endereço cadastrado.', 'STATUS_PEDIDO', CURRENT_TIMESTAMP - INTERVAL '5 hours', TRUE, CURRENT_TIMESTAMP - INTERVAL '5 hours'),
(10, 'Café da Manhã Saudável', 'Comece o dia registrando suas calorias no MasterFit.', 'LEMBRETE_REFEICAO', CURRENT_TIMESTAMP + INTERVAL '12 hours', FALSE, NULL),
(2, 'Sequência de 7 Dias!', 'Você registrou suas refeições por 7 dias consecutivos.', 'META_ATINGIDA', CURRENT_TIMESTAMP - INTERVAL '1 day', TRUE, CURRENT_TIMESTAMP - INTERVAL '1 day'),
(3, 'Lembrete de Jantar', 'Mantenha o foco na dieta e registre seu jantar.', 'LEMBRETE_REFEICAO', CURRENT_TIMESTAMP + INTERVAL '3 hours', FALSE, NULL);

-- 7. SUPLEMENTO_FAVORITO
INSERT INTO suplemento_favorito (fk_usuario, fk_suplemento) VALUES
(2, 1),
(2, 3),
(3, 2),
(3, 10),
(4, 1),
(6, 4),
(7, 3),
(8, 8),
(9, 2),
(10, 7);

-- 8. PEDIDO
INSERT INTO pedido (fk_usuario, fk_endereco, fk_cupom_desconto, status_pedido, valor_subtotal, valor_desconto, valor_total) VALUES
(2, 1, 1, 'ENTREGUE', 219.80, 21.98, 197.82),
(3, 2, 2, 'ENVIADO', 284.90, 56.98, 227.92),
(4, 3, 3, 'PAGO', 129.90, 15.00, 114.90),
(6, 4, NULL, 'PENDENTE', 115.00, 0.00, 115.00),
(7, 5, 4, 'ENTREGUE', 179.80, 44.95, 134.85),
(8, 6, NULL, 'CANCELADO', 49.90, 0.00, 49.90),
(9, 7, 5, 'ENTREGUE', 189.90, 30.00, 159.90),
(10, 8, 6, 'PAGO', 149.90, 22.49, 127.41),
(2, 9, NULL, 'ENVIADO', 64.90, 0.00, 64.90),
(3, 10, 8, 'PENDENTE', 139.80, 16.78, 123.02);

-- 9. ITEM_PEDIDO
INSERT INTO item_pedido (fk_pedido, fk_suplemento, quantidade, preco_unitario) VALUES
(1, 1, 1, 129.90),
(1, 3, 1, 89.90),
(2, 2, 1, 189.90),
(2, 10, 1, 95.00),
(3, 1, 1, 129.90),
(4, 4, 1, 115.00),
(5, 3, 2, 89.90),
(6, 8, 1, 49.90),
(7, 2, 1, 189.90),
(8, 7, 1, 149.90);

-- 10. DIARIO_ALIMENTAR
INSERT INTO diario_alimentar (fk_usuario, fk_alimento, categoria_refeicao, quantidade_gramas, calorias_calculadas, data_registro) VALUES
(2, 3, 'CAFE_DA_MANHA', 150.00, 219.00, CURRENT_DATE),
(2, 1, 'ALMOCO', 200.00, 318.00, CURRENT_DATE),
(2, 2, 'ALMOCO', 150.00, 192.00, CURRENT_DATE),
(3, 5, 'CAFE_DA_MANHA', 60.00, 234.00, CURRENT_DATE),
(3, 6, 'PRE_TREINO', 100.00, 98.00, CURRENT_DATE),
(4, 4, 'POS_TREINO', 200.00, 154.00, CURRENT_DATE),
(6, 7, 'JANTAR', 180.00, 394.20, CURRENT_DATE),
(7, 8, 'ALMOCO', 120.00, 91.20, CURRENT_DATE),
(9, 9, 'LANCHE', 30.00, 180.00, CURRENT_DATE),
(10, 10, 'CAFE_DA_MANHA', 170.00, 75.00, CURRENT_DATE);


-- ==========================================
-- 11. CONSULTAS DE VALIDAÇÃO (TESTE RÁPIDO)
-- ==========================================

-- 1. Testar tabela usuario
SELECT * FROM usuario;

-- 2. Testar tabela suplemento
SELECT * FROM suplemento;

-- 3. Testar tabela alimento
SELECT * FROM alimento;

-- 4. Testar tabela cupom_desconto
SELECT * FROM cupom_desconto;

-- 5. Testar tabela endereco
SELECT * FROM endereco;

-- 6. Testar tabela notificacao_push
SELECT * FROM notificacao_push;

-- 7. Testar tabela suplemento_favorito
SELECT * FROM suplemento_favorito;

-- 8. Testar tabela pedido
SELECT * FROM pedido;

-- 9. Testar tabela item_pedido
SELECT * FROM item_pedido;

-- 10. Testar tabela diario_alimentar
SELECT * FROM diario_alimentar;