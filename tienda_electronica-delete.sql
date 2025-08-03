USE tienda_electronicos;

-- Insertar reseñas/Insert reviews (10 reviews)
DELETE FROM reseñas;
SELECT COUNT(*) FROM reseñas;

-- Insertar detalles de pedido/Insert details into the order (25 details) (precio unitario = unit price)
DELETE FROM detalles_pedido;
SELECT COUNT(*) FROM detalles_pedido;

-- Insertar pedidos (20 pedidos)
DELETE FROM pedidos;
SELECT COUNT(*) FROM pedidos;

-- Insertar clientes (15 clientes mexicanos)
DELETE FROM clientes;
SELECT COUNT(*) FROM clientes;

-- Insertar productos (30 productos)
DELETE FROM productos;
SELECT COUNT(*) FROM productos;

-- Borrar todos los registros de categorías y comprobar contando los registros en la tabla despues del DELETE
DELETE FROM categorias;
SELECT COUNT(*) FROM categorias;