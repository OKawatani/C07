# Inventário RPG – Banco de Dados (Entrega 2 – C07)

Este repositório contém a implementação do modelo de dados criado na entrega anterior: um sistema de **inventário de RPG**, onde usuários têm personagens que carregam itens e lojas vendem esses itens.

Integrantes: Eduardo Kawatani Rios - 668 - GES // Dalmo Ney Vieira Neto - 670 - GES


---

## Sumário

1. [Criação do banco e das tabelas (DDL)](#1-criação-do-banco-e-das-tabelas-ddl)
2. [Inserção de dados](#2-inserção-de-dados)
3. [Manipulação de dados (DML) e justificativas](#3-manipulação-de-dados-dml-e-justificativas)
4. [Usuários e ROLE](#4-usuários-e-role)
5. [Consultas com JOIN (1:1, 1:N e N:M)](#5-consultas-com-join-11-1n-e-nm)
6. [Function, View, Procedure e Trigger](#6-function-view-procedure-e-trigger)
7. [Testes](#7-testes)

---

## 1. Criação do banco e das tabelas (DDL)

O banco `inventario_rpg` é criado com `utf8mb4`, para aceitar acentos e caracteres especiais corretamente.

Principais decisões no dicionário de dados:

| Tabela | Campo | Tipo / Restrição | Motivo |
|---|---|---|---|
| Usuario | `nome_usuario`, `email` | `UNIQUE` | Não pode haver dois usuários com o mesmo login ou e-mail. |
| Usuario | `senha` | `VARCHAR(255)` | Tamanho suficiente para guardar um hash de senha. |
| Raca | `bonus_forca`, `bonus_destreza` | `INT DEFAULT 0` | Aceita valores negativos (ex.: Orc tem destreza −2). |
| Classe | `descricao` | `NULL` permitido | Campo opcional. |
| TipoItem | `permite_equipar` | `TINYINT DEFAULT FALSE` | Valor booleano (0/1). |
| Personagem | `id_usuario` | `UNIQUE` + FK | Garante o relacionamento 1:1 com Usuario. |
| Personagem | `id_mentor` | FK para Personagem, `NULL` | Auto-relacionamento opcional. |
| Personagem | `nivel`, `experiencia` | `DEFAULT 1` / `DEFAULT 0` | Todo personagem novo começa no nível 1 sem experiência. |
| Personagem | `capacidade_carga` | `DECIMAL(6,2) DEFAULT 50.00` | Peso máximo que o personagem consegue carregar. |
| Item | `raridade` | `ENUM('comum','incomum','raro','epico','lendario')` | Restringe a raridade a valores válidos. |
| Item | `peso`, `valor_base` | `DECIMAL` | Valores com casas decimais exatas (sem erro de arredondamento de `FLOAT`). |
| ItemDeInventario | `quantidade`, `equipado`, `durabilidade_atual` | atributos da relação | Informações que pertencem à associação personagem–item, não a um dos dois isoladamente. |
| ItemEmVenda | `preco`, `quantidade_estoque` | atributos da relação | O mesmo item pode ter preços e estoques diferentes em cada loja. |

---

## 2. Inserção de dados

Todas as tabelas recebem **no mínimo 5 registros**:

| Tabela | Registros inseridos | Exemplos |
|---|---|---|
| Usuario | 5 (+1 no teste do trigger) | lucas, marina, pedro, ana, joao |
| Raca | 5 | Humano, Elfo, Anão, Orc, Halfling |
| Classe | 5 | Guerreiro, Mago, Ladino, Clérigo, Arqueiro |
| TipoItem | 5 | Arma, Armadura, Poção, Material, Acessório |
| Loja | 5 | Empório do Aventureiro, Forja do Anão, Torre Arcana, Boticário Verde, Mercado Negro |
| Personagem | 5 (+1 no teste do trigger) | Thorin, Lyra, Pip, Helena, Merlin |
| Item | 5 | Espada Longa, Armadura de Placas, Poção de Vida, Minério de Ferro, Anel da Força |
| ItemDeInventario | 6 | Thorin com Espada Longa e 5 Poções de Vida, etc. |
| ItemEmVenda | 6 (5 após o `DELETE`) | Forja do Anão vende Espada Longa por 180,00, etc. |

A ordem dos `INSERT` respeita as chaves estrangeiras: primeiro as tabelas independentes (Usuario, Raca, Classe, TipoItem, Loja), depois as que dependem delas (Personagem, Item) e por último as tabelas associativas (ItemDeInventario, ItemEmVenda).

---

## 3. Manipulação de dados (DML) e justificativas

Os comandos DML usados no projeto são `INSERT`, `UPDATE`, `DELETE` e `SELECT`.

### `INSERT`
Usado para popular o banco com os dados iniciais do jogo e para testar o trigger. Sem ele o banco teria só a estrutura, sem nada para consultar.

### `UPDATE`
```sql
UPDATE Personagem
   SET experiencia = experiencia + 500,
       nivel = nivel + 1
 WHERE id_personagem = 2;
```
**Motivo:** simula uma situação real do jogo: a personagem **Lyra** ganhou 500 pontos de experiência e subiu de nível. O `UPDATE` altera o registro existente em vez de apagar e inserir de novo, mantendo o mesmo `id` e todos os vínculos (inventário, usuário). O `WHERE` garante que só a Lyra seja alterada.

Resultado: Lyra passa do nível 8 para o **9**, e de 3100 para **3600** de experiência.

### `DELETE`
```sql
DELETE FROM ItemEmVenda
 WHERE id_loja = 4
   AND id_item = 3;
```
**Motivo:** o **Boticário Verde** estava anunciando Poção de Vida com estoque **0**. Uma oferta sem estoque não deveria aparecer para o jogador, então ela é removida da lista de vendas. Só a linha da tabela associativa é apagada: a loja e o item continuam existindo, apenas deixam de estar relacionados. O `WHERE` usa a chave primária composta para apagar exatamente essa oferta.

### `SELECT`
Usado em todas as consultas com `JOIN` (seção 5) e nos testes (seção 7), para conferir os dados e o funcionamento dos objetos criados.

---

## 4. Usuários e ROLE

```sql
CREATE ROLE 'role_leitura';
GRANT SELECT ON inventario_rpg.* TO 'role_leitura';

CREATE USER 'usuario_a'@'localhost' IDENTIFIED BY 'Senha@123';
CREATE USER 'usuario_b'@'localhost' IDENTIFIED BY 'Senha@123';

GRANT 'role_leitura' TO 'usuario_a'@'localhost', 'usuario_b'@'localhost';
SET DEFAULT ROLE 'role_leitura' TO 'usuario_a'@'localhost', 'usuario_b'@'localhost';
```

- **`role_leitura`**: role com permissão apenas de **leitura** (`SELECT`) em todas as tabelas do banco `inventario_rpg`.
- **`usuario_a`** e **`usuario_b`**: dois usuários que recebem essa role, ficando relacionados por ela.
- **`SET DEFAULT ROLE`**: faz a role ser ativada automaticamente quando o usuário faz login. Sem isso, o usuário teria que rodar `SET ROLE` manualmente a cada conexão.

**Por que usar uma ROLE:** em vez de dar as permissões a cada usuário individualmente, as permissões ficam centralizadas na role. Se for preciso mudar o que esses usuários podem fazer, basta alterar a role uma única vez. Também segue o princípio do menor privilégio: esses usuários conseguem consultar os dados, mas não conseguem alterá-los nem apagá-los.

O script começa com `DROP USER IF EXISTS` / `DROP ROLE IF EXISTS` para poder ser executado mais de uma vez sem erro.

Para conferir:
```sql
SHOW GRANTS FOR 'usuario_a'@'localhost' USING 'role_leitura';
```

---

## 5. Consultas com JOIN (1:1, 1:N e N:M)

### 5.1 Relacionamento 1:1 – Usuario e Personagem
```sql
SELECT u.nome_usuario, p.nome AS personagem, p.nivel
  FROM Usuario u
 INNER JOIN Personagem p ON p.id_usuario = u.id_usuario;
```
Mostra cada usuário com seu único personagem.

| nome_usuario | personagem | nivel |
|---|---|---|
| lucas | Thorin | 12 |
| marina | Lyra | 9 |
| pedro | Pip | 6 |
| ana | Helena | 10 |
| joao | Merlin | 9 |

### 5.2 Relacionamento 1:N – Classe/Raca e Personagem
```sql
SELECT p.nome AS personagem, c.nome AS classe, r.nome AS raca
  FROM Personagem p
 INNER JOIN Classe c ON c.id_classe = p.id_classe
 INNER JOIN Raca   r ON r.id_raca   = p.id_raca;
```
Uma classe (ou raça) pode ter vários personagens, mas cada personagem tem só uma. Repare que Helena e Merlin são ambos **Humanos**.

| personagem | classe | raca |
|---|---|---|
| Thorin | Guerreiro | Anao |
| Lyra | Arqueiro | Elfo |
| Pip | Ladino | Halfling |
| Helena | Clerigo | Humano |
| Merlin | Mago | Humano |

### 5.3 Relacionamento N:M – Personagem e Item (via ItemDeInventario)
```sql
SELECT p.nome AS personagem, i.nome AS item, ii.quantidade, ii.equipado
  FROM Personagem p
 INNER JOIN ItemDeInventario ii ON ii.id_personagem = p.id_personagem
 INNER JOIN Item i              ON i.id_item        = ii.id_item;
```
Um personagem pode ter vários itens e um item pode estar com vários personagens (a Poção de Vida está com Thorin e com Lyra).

| personagem | item | quantidade | equipado |
|---|---|---|---|
| Thorin | Espada Longa | 1 | 1 |
| Thorin | Pocao de Vida | 5 | 0 |
| Lyra | Pocao de Vida | 3 | 0 |
| Pip | Armadura de Placas | 1 | 1 |
| Helena | Anel da Forca | 1 | 1 |
| Merlin | Minerio de Ferro | 2 | 0 |

### 5.4 Relacionamento N:M – Loja e Item (via ItemEmVenda)
```sql
SELECT l.nome AS loja, i.nome AS item, iv.preco, iv.quantidade_estoque
  FROM Loja l
 INNER JOIN ItemEmVenda iv ON iv.id_loja = l.id_loja
 INNER JOIN Item i         ON i.id_item  = iv.id_item;
```
Uma loja vende vários itens e um item pode ser vendido em várias lojas. A oferta do Boticário Verde não aparece porque foi removida pelo `DELETE`.

| loja | item | preco | quantidade_estoque |
|---|---|---|---|
| Emporio do Aventureiro | Pocao de Vida | 30.00 | 100 |
| Emporio do Aventureiro | Minerio de Ferro | 12.00 | 200 |
| Forja do Anao | Espada Longa | 180.00 | 10 |
| Forja do Anao | Armadura de Placas | 720.00 | 4 |
| Torre Arcana | Anel da Forca | 1000.00 | 2 |

---

## 6. Function, View, Procedure e Trigger

### 6.1 FUNCTION – `fn_peso_total`
```sql
CREATE FUNCTION fn_peso_total(p_id_personagem INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
...
SELECT COALESCE(SUM(i.peso * ii.quantidade), 0) ...
```
**O que faz:** recebe o id de um personagem e retorna o **peso total** que ele está carregando (peso de cada item × quantidade, somados).

**Por que foi criada:** cada personagem tem uma `capacidade_carga`, então saber o peso carregado é uma informação usada com frequência no jogo (por exemplo, para impedir que ele pegue mais itens do que aguenta). Uma function devolve um valor e pode ser usada dentro de qualquer `SELECT`, evitando repetir o cálculo em vários lugares.

- `COALESCE(..., 0)`: se o personagem não tiver nenhum item, a soma seria `NULL`; o `COALESCE` faz a função retornar `0`.
- `READS SQL DATA`: informa ao MySQL que a função só lê dados, sem alterá-los (exigido quando o log binário está ativo).

Exemplo de uso combinado com a capacidade:
```sql
SELECT nome, capacidade_carga, fn_peso_total(id_personagem) AS peso_atual
  FROM Personagem;
```

### 6.2 VIEW – `vw_inventario`
```sql
CREATE VIEW vw_inventario AS
SELECT p.nome AS personagem, i.nome AS item, ii.quantidade,
       (i.peso * ii.quantidade) AS peso_total
  FROM ItemDeInventario ii
 INNER JOIN Personagem p ON p.id_personagem = ii.id_personagem
 INNER JOIN Item i       ON i.id_item       = ii.id_item;
```
**O que faz:** guarda pronta a consulta que mostra o inventário de todos os personagens, com o nome do personagem, o nome do item, a quantidade e o peso daquela linha.

**Por que foi criada:** a consulta do inventário exige dois `JOIN`s e é uma das mais usadas do sistema. Com a view, basta um `SELECT * FROM vw_inventario`, sem reescrever os joins. Ela também esconde os ids internos e mostra só o que interessa para quem vai ler, o que combina com usuários de somente leitura como os da `role_leitura`.

### 6.3 PROCEDURE – `sp_subir_nivel`
```sql
CREATE PROCEDURE sp_subir_nivel(IN p_id_personagem INT)
BEGIN
    UPDATE Personagem
       SET nivel = nivel + 1
     WHERE id_personagem = p_id_personagem;
END
```
**O que faz:** aumenta em 1 o nível do personagem informado.

**Por que foi criada:** subir de nível é uma ação que acontece o tempo todo no jogo. Com a procedure, essa operação fica encapsulada no banco e é executada com um simples `CALL sp_subir_nivel(id)`, sem precisar escrever o `UPDATE` toda vez e sem risco de esquecer o `WHERE` e alterar todos os personagens. Diferente da function, a procedure pode **alterar** dados e não precisa retornar valor.

### 6.4 TRIGGER – `trg_personagem_nivel_minimo`
```sql
CREATE TRIGGER trg_personagem_nivel_minimo
BEFORE INSERT ON Personagem
FOR EACH ROW
BEGIN
    IF NEW.nivel < 1 THEN
        SET NEW.nivel = 1;
    END IF;
END
```
**O que faz:** antes de cada novo personagem ser inserido, verifica o nível; se for menor que 1, corrige para 1.

**Por que foi criado:** no jogo não existe nível 0 ou negativo. Colocando essa regra em um trigger, ela fica **dentro do banco** e vale para qualquer `INSERT`, venha ele do sistema, do Workbench ou de outro programa, sem depender de quem está inserindo lembrar de validar. Por ser `BEFORE INSERT`, o valor é corrigido antes de ser gravado, usando `NEW.nivel`.

---

## 7. Testes

A seção final do script executa os testes dos objetos criados:

| Teste | Comando | Resultado esperado |
|---|---|---|
| Function | `SELECT fn_peso_total(1);` | **5.00** (Espada Longa 3,50 + 5 Poções × 0,30) |
| View | `SELECT * FROM vw_inventario;` | 6 linhas, uma para cada item de inventário |
| Procedure | `CALL sp_subir_nivel(3);` | Pip passa do nível 6 para o **7** |
| Trigger | `INSERT` do personagem "Novato" com `nivel = 0` | "Novato" é gravado com nível **1** |

Para o teste do trigger, primeiro é criado o usuário `teste` (id 6), já que cada personagem precisa de um usuário próprio por causa do relacionamento 1:1.
