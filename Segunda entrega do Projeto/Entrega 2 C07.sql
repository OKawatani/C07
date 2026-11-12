
DROP DATABASE IF EXISTS inventario_rpg;
CREATE DATABASE inventario_rpg DEFAULT CHARACTER SET utf8mb4;
USE inventario_rpg;

CREATE TABLE Usuario (
  id_usuario    INT          NOT NULL AUTO_INCREMENT,
  nome_usuario  VARCHAR(50)  NOT NULL,
  email         VARCHAR(100) NOT NULL,
  senha         VARCHAR(255) NOT NULL,
  data_cadastro DATE         NOT NULL,
  PRIMARY KEY (id_usuario),
  UNIQUE (nome_usuario),
  UNIQUE (email)
);

CREATE TABLE Raca (
  id_raca        INT         NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(30) NOT NULL,
  bonus_forca    INT         NOT NULL DEFAULT 0,
  bonus_destreza INT         NOT NULL DEFAULT 0,
  PRIMARY KEY (id_raca)
);

CREATE TABLE Classe (
  id_classe INT          NOT NULL AUTO_INCREMENT,
  nome      VARCHAR(30)  NOT NULL,
  descricao VARCHAR(255) NULL DEFAULT NULL,
  vida_base INT          NOT NULL,
  PRIMARY KEY (id_classe)
);

CREATE TABLE TipoItem (
  id_tipo_item    INT         NOT NULL AUTO_INCREMENT,
  nome            VARCHAR(30) NOT NULL,
 permite_equipar TINYINT     NOT NULL DEFAULT FALSE,
  PRIMARY KEY (id_tipo_item)
);

CREATE TABLE Personagem (
  id_personagem    INT          NOT NULL AUTO_INCREMENT,
  id_usuario       INT          NOT NULL,
  id_classe        INT          NOT NULL,
  id_raca          INT          NOT NULL,
  id_mentor        INT          NULL DEFAULT NULL,
  nome             VARCHAR(50)  NOT NULL,
  nivel            INT          NOT NULL DEFAULT 1,
  experiencia      INT          NOT NULL DEFAULT 0,
  vida_atual       INT          NOT NULL,
  capacidade_carga DECIMAL(6,2) NOT NULL DEFAULT 50.00,
  data_criacao     DATETIME     NOT NULL,
  PRIMARY KEY (id_personagem),
  UNIQUE (id_usuario),                                   -- garante o relacionamento 1:1
  FOREIGN KEY (id_usuario) REFERENCES Usuario (id_usuario),
  FOREIGN KEY (id_classe)  REFERENCES Classe (id_classe),
  FOREIGN KEY (id_raca)    REFERENCES Raca (id_raca),
  FOREIGN KEY (id_mentor)  REFERENCES Personagem (id_personagem)
);

CREATE TABLE Item (
  id_item      INT           NOT NULL AUTO_INCREMENT,
  id_tipo_item INT           NOT NULL,
  nome         VARCHAR(60)   NOT NULL,
  descricao    VARCHAR(255)  NULL DEFAULT NULL,
  peso         DECIMAL(5,2)  NOT NULL DEFAULT 0,
  raridade     ENUM('comum', 'incomum', 'raro', 'epico', 'lendario') NOT NULL DEFAULT 'comum',
  valor_base   DECIMAL(10,2) NOT NULL DEFAULT 0,
  PRIMARY KEY (id_item),
  FOREIGN KEY (id_tipo_item) REFERENCES TipoItem (id_tipo_item)
);

CREATE TABLE Loja (
  id_loja     INT          NOT NULL AUTO_INCREMENT,
  nome        VARCHAR(60)  NOT NULL,
  localizacao VARCHAR(100) NULL DEFAULT NULL,
  PRIMARY KEY (id_loja)
);

-- Tabela do N:M entre Personagem e Item
CREATE TABLE ItemDeInventario (
  id_personagem      INT     NOT NULL,
  id_item            INT     NOT NULL,
  quantidade         INT     NOT NULL DEFAULT 1,
  equipado           TINYINT NOT NULL DEFAULT FALSE,
  durabilidade_atual INT     NOT NULL DEFAULT 100,
  PRIMARY KEY (id_personagem, id_item),
  FOREIGN KEY (id_personagem) REFERENCES Personagem (id_personagem),
  FOREIGN KEY (id_item)       REFERENCES Item (id_item)
);

-- Tabela do N:M entre Loja e Item
CREATE TABLE ItemEmVenda (
  id_loja            INT           NOT NULL,
  id_item            INT           NOT NULL,
  preco              DECIMAL(10,2) NOT NULL,
  quantidade_estoque INT           NOT NULL DEFAULT 0,
  PRIMARY KEY (id_loja, id_item),
  FOREIGN KEY (id_loja) REFERENCES Loja (id_loja),
  FOREIGN KEY (id_item) REFERENCES Item (id_item)
);

-- ============================================================================
-- 2. INSERT: 
-- ============================================================================
INSERT INTO Usuario (nome_usuario, email, senha, data_cadastro) VALUES
  ('lucas',  'lucas@email.com',  'senha123', '2026-02-01'),
  ('marina', 'marina@email.com', 'senha123', '2026-02-14'),
  ('pedro',  'pedro@email.com',  'senha123', '2026-03-09'),
  ('ana',    'ana@email.com',    'senha123', '2026-04-22'),
  ('joao',   'joao@email.com',   'senha123', '2026-05-30');

INSERT INTO Raca (nome, bonus_forca, bonus_destreza) VALUES
  ('Humano', 1, 1),
  ('Elfo', 0, 3),
  ('Anao', 3, -1),
  ('Orc', 4, -2),
  ('Halfling', -1, 4);

INSERT INTO Classe (nome, descricao, vida_base) VALUES
  ('Guerreiro', 'Combatente corpo a corpo', 120),
  ('Mago', 'Conjurador de magias', 70),
  ('Ladino', 'Agil e furtivo', 85),
  ('Clerigo', 'Curandeiro devoto', 95),
  ('Arqueiro', 'Atirador a distancia', 80);

INSERT INTO TipoItem (nome, permite_equipar) VALUES
  ('Arma', TRUE),
  ('Armadura', TRUE),
  ('Pocao', FALSE),
  ('Material', FALSE),
  ('Acessorio', TRUE);

INSERT INTO Loja (nome, localizacao) VALUES
  ('Emporio do Aventureiro', 'Praca Central'),
  ('Forja do Anao', 'Distrito das Forjas'),
  ('Torre Arcana', 'Colina dos Magos'),
  ('Boticario Verde', 'Vila das Ervas'),
  ('Mercado Negro', NULL);

INSERT INTO Personagem (id_usuario, id_classe, id_raca, nome, nivel, experiencia, vida_atual, capacidade_carga, data_criacao) VALUES
  (1, 1, 3, 'Thorin',  12, 5400, 210, 80.00, '2026-02-03'),
  (2, 5, 2, 'Lyra',     8, 3100, 120, 45.00, '2026-02-15'),
  (3, 3, 5, 'Pip',      6, 1800,  90, 35.00, '2026-03-10'),
  (4, 4, 1, 'Helena',  10, 4200, 150, 55.00, '2026-04-23'),
  (5, 2, 1, 'Merlin',   9, 3900, 100, 40.00, '2026-07-19');

INSERT INTO Item (id_tipo_item, nome, descricao, peso, raridade, valor_base) VALUES
  (1, 'Espada Longa',       'Espada de aco',        3.50, 'comum',    150.00),
  (2, 'Armadura de Placas', 'Armadura pesada',     25.00, 'incomum',  600.00),
  (3, 'Pocao de Vida',      'Restaura vida',        0.30, 'comum',     25.00),
  (4, 'Minerio de Ferro',   'Material para forja',  5.00, 'comum',     10.00),
  (5, 'Anel da Forca',      'Bonus de forca',       0.10, 'raro',     950.00);

INSERT INTO ItemDeInventario (id_personagem, id_item, quantidade, equipado, durabilidade_atual) VALUES
  (1, 1, 1, TRUE,   90),
  (1, 3, 5, FALSE, 100),
  (2, 3, 3, FALSE, 100),
  (3, 2, 1, TRUE,   80),
  (4, 5, 1, TRUE,  100),
  (5, 4, 2, FALSE, 100);

INSERT INTO ItemEmVenda (id_loja, id_item, preco, quantidade_estoque) VALUES
  (1, 3,   30.00, 100),
  (1, 4,   12.00, 200),
  (2, 1,  180.00,  10),
  (2, 2,  720.00,   4),
  (3, 5, 1000.00,   2),
  (4, 3,   28.00,   0);


-- >>> SECAO 3
-- ============================================================================
-- 3. UPDATE e DELETE
-- ============================================================================

-- UPDATE: Lyra ganhou experiência e subiu de nivel
UPDATE Personagem
   SET experiencia = experiencia + 500,
       nivel = nivel + 1
 WHERE id_personagem = 2;

-- DELETE: Aqui a oferta sem estoque do Boticario Verde sai da lista de vendas.
DELETE FROM ItemEmVenda
 WHERE id_loja = 4
   AND id_item = 3;


-- >>> SECAO 4
-- ============================================================================
-- 4. Dois usuários relacionados por uma ROLE
-- ============================================================================
DROP USER IF EXISTS 'usuario_a'@'localhost';
DROP USER IF EXISTS 'usuario_b'@'localhost';
DROP ROLE IF EXISTS 'role_leitura';

CREATE ROLE 'role_leitura';
GRANT SELECT ON inventario_rpg.* TO 'role_leitura';

CREATE USER 'usuario_a'@'localhost' IDENTIFIED BY 'Senha@123';
CREATE USER 'usuario_b'@'localhost' IDENTIFIED BY 'Senha@123';

GRANT 'role_leitura' TO 'usuario_a'@'localhost', 'usuario_b'@'localhost';
SET DEFAULT ROLE 'role_leitura' TO 'usuario_a'@'localhost', 'usuario_b'@'localhost';


-- >>> SECAO 5
-- ============================================================================
-- 5. Consultas com JOIN
-- ============================================================================

-- 5.1 Relacionamento 1:1 (Usuario - Personagem)
SELECT u.nome_usuario, p.nome AS personagem, p.nivel
  FROM Usuario u
 INNER JOIN Personagem p ON p.id_usuario = u.id_usuario;

-- 5.2 Relacionamento 1:N (Classe e Raca - Personagem) Uma classe (ou raça) pode ter vários personagens; cada personagem tem uma só.
SELECT p.nome AS personagem, c.nome AS classe, r.nome AS raca
  FROM Personagem p
 INNER JOIN Classe c ON c.id_classe = p.id_classe
 INNER JOIN Raca   r ON r.id_raca   = p.id_raca;

-- 5.3 Relacionamento N:M (Personagem - Item, pela tabela ItemDeInventario)
SELECT p.nome AS personagem, i.nome AS item, ii.quantidade, ii.equipado
  FROM Personagem p
 INNER JOIN ItemDeInventario ii ON ii.id_personagem = p.id_personagem
 INNER JOIN Item i              ON i.id_item        = ii.id_item;

-- 5.4 Relacionamento N:M (Loja - Item, pela tabela ItemEmVenda)
SELECT l.nome AS loja, i.nome AS item, iv.preco, iv.quantidade_estoque
  FROM Loja l
 INNER JOIN ItemEmVenda iv ON iv.id_loja = l.id_loja
 INNER JOIN Item i         ON i.id_item  = iv.id_item;


-- >>> SECAO 6
-- ============================================================================
-- 6. FUNCTION, VIEW, PROCEDURE e TRIGGER
-- ============================================================================

-- FUNCTION: calcula o peso total carregado por um personagem.
DELIMITER $$
CREATE FUNCTION fn_peso_total(p_id_personagem INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_total DECIMAL(10,2);

    SELECT COALESCE(SUM(i.peso * ii.quantidade), 0) INTO v_total
      FROM ItemDeInventario ii
     INNER JOIN Item i ON i.id_item = ii.id_item
     WHERE ii.id_personagem = p_id_personagem;

    RETURN v_total;
END$$
DELIMITER ;

-- VIEW: guarda a consulta do inventário já pronta.
CREATE VIEW vw_inventario AS
SELECT p.nome AS personagem, i.nome AS item, ii.quantidade,
       (i.peso * ii.quantidade) AS peso_total
  FROM ItemDeInventario ii
 INNER JOIN Personagem p ON p.id_personagem = ii.id_personagem
 INNER JOIN Item i       ON i.id_item       = ii.id_item;

-- PROCEDURE: sobe o nível de um personagem em 1.
DELIMITER $$
CREATE PROCEDURE sp_subir_nivel(IN p_id_personagem INT)
BEGIN
    UPDATE Personagem
       SET nivel = nivel + 1
     WHERE id_personagem = p_id_personagem;
END$$
DELIMITER ;

-- TRIGGER: antes de inserir um personagem, garante que o nível seja no mínimo 1.
DELIMITER $$
CREATE TRIGGER trg_personagem_nivel_minimo
BEFORE INSERT ON Personagem
FOR EACH ROW
BEGIN
    IF NEW.nivel < 1 THEN
        SET NEW.nivel = 1;
    END IF;
END$$
DELIMITER ;


-- >>> SECAO 7
-- ============================================================================
-- 7. Testes
-- ============================================================================
SELECT fn_peso_total(1) AS peso_do_thorin;

SELECT * FROM vw_inventario;

CALL sp_subir_nivel(3);
SELECT nome, nivel FROM Personagem WHERE id_personagem = 3;

-- Trigger: inserimos um personagem com nível 0 e ele é gravado com nível 1.
INSERT INTO Usuario (nome_usuario, email, senha, data_cadastro)
VALUES ('teste', 'teste@email.com', 'senha123', '2026-11-10');

INSERT INTO Personagem (id_usuario, id_classe, id_raca, nome, nivel, vida_atual, data_criacao)
VALUES (6, 1, 1, 'Novato', 0, 100, NOW());

SELECT nome, nivel FROM Personagem WHERE nome = 'Novato';