-- Criação do banco de dados
CREATE DATABASE SistemaPedidosOnline;
USE SistemaPedidosOnline;

-- Tabela para armazenar informações de produtos
CREATE TABLE Produtos (
    produto_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    preco DECIMAL(10, 2) NOT NULL CHECK (preco >= 0),
    estoque INT NOT NULL CHECK (estoque >= 0),
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabela para armazenar informações de clientes
CREATE TABLE Clientes (
    cliente_id INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    data_cadastro DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tabela para armazenar o carrinho de compras
CREATE TABLE Carrinho (
    carrinho_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    produto_id INT NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES Produtos(produto_id) ON DELETE CASCADE
);

-- Tabela para armazenar pedidos
CREATE TABLE Pedidos (
    pedido_id INT AUTO_INCREMENT PRIMARY KEY,
    cliente_id INT NOT NULL,
    data_pedido DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'Pendente',
    total DECIMAL(10, 2) NOT NULL CHECK (total >= 0),
    FOREIGN KEY (cliente_id) REFERENCES Clientes(cliente_id) ON DELETE CASCADE
);

-- Tabela para armazenar detalhes dos itens do pedido
CREATE TABLE ItensPedido (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    pedido_id INT NOT NULL,
    produto_id INT NOT NULL,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco DECIMAL(10, 2) NOT NULL CHECK (preco >= 0),
    FOREIGN KEY (pedido_id) REFERENCES Pedidos(pedido_id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES Produtos(produto_id) ON DELETE CASCADE
);

-- Índices para melhorar a performance
CREATE INDEX idx_produto_nome ON Produtos(nome);
CREATE INDEX idx_cliente_email ON Clientes(email);
CREATE INDEX idx_pedido_data ON Pedidos(data_pedido);
CREATE INDEX idx_itens_pedido ON ItensPedido(pedido_id);
CREATE INDEX idx_carrinho_cliente ON Carrinho(cliente_id);

-- View para visualizar o histórico de pedidos de um cliente
CREATE VIEW ViewHistoricoPedidos AS
SELECT p.pedido_id, c.nome AS cliente, p.data_pedido, p.status, p.total
FROM Pedidos p
JOIN Clientes c ON p.cliente_id = c.cliente_id
ORDER BY p.data_pedido DESC;

-- View para visualizar itens de pedidos
CREATE VIEW ViewItensPedidos AS
SELECT ip.item_id, p.nome AS produto, ip.quantidade, ip.preco, pe.pedido_id, pe.data_pedido
FROM ItensPedido ip
JOIN Produtos p ON ip.produto_id = p.produto_id
JOIN Pedidos pe ON ip.pedido_id = pe.pedido_id;

-- Função para calcular o total do pedido
DELIMITER //
CREATE FUNCTION CalcularTotalPedido(pedido_id INT) RETURNS DECIMAL(10, 2)
BEGIN
    DECLARE total DECIMAL(10, 2);
    SELECT SUM(ip.quantidade * ip.preco) INTO total
    FROM ItensPedido ip
    WHERE ip.pedido_id = pedido_id;
    RETURN IFNULL(total, 0);
END //
DELIMITER ;

-- Trigger para atualizar o total do pedido após a inserção de itens
DELIMITER //
CREATE TRIGGER Trigger_AntesInserirItemPedido
BEFORE INSERT ON ItensPedido
FOR EACH ROW
BEGIN
    DECLARE novo_total DECIMAL(10, 2);
    SET novo_total = NEW.quantidade * NEW.preco;
    INSERT INTO Pedidos (cliente_id, total) VALUES (NEW.pedido_id, novo_total);
END //
DELIMITER ;

-- Inserção de exemplo de produtos
INSERT INTO Produtos (nome, descricao, preco, estoque) VALUES 
('Produto A', 'Descrição do Produto A', 50.00, 100),
('Produto B', 'Descrição do Produto B', 75.00, 50),
('Produto C', 'Descrição do Produto C', 25.00, 200);

-- Inserção de exemplo de clientes
INSERT INTO Clientes (nome, email, telefone) VALUES 
('João Silva', 'joao.silva@example.com', '123456789'),
('Maria Oliveira', 'maria.oliveira@example.com', '987654321');

-- Adicionar itens ao carrinho
INSERT INTO Carrinho (cliente_id, produto_id, quantidade) VALUES 
(1, 1, 2),
(1, 2, 1),
(2, 3, 3);

-- Criar um pedido a partir do carrinho
INSERT INTO Pedidos (cliente_id, total) VALUES (1, CalcularTotalPedido(1));

-- Inserir detalhes dos itens do pedido
INSERT INTO ItensPedido (pedido_id, produto_id, quantidade, preco) VALUES 
(1, 1, 2, 50.00),
(1, 2, 1, 75.00);

-- Selecionar histórico de pedidos
SELECT * FROM ViewHistoricoPedidos;

-- Selecionar itens dos pedidos
SELECT * FROM ViewItensPedidos;

-- Excluir um item do carrinho
DELETE FROM Carrinho WHERE carrinho_id = 1;

-- Excluir um produto (isso falhará se houver itens no pedido)
DELETE FROM Produtos WHERE produto_id = 1;

-- Excluir um cliente (isso falhará se o cliente tiver pedidos)
DELETE FROM Clientes WHERE cliente_id = 1;
