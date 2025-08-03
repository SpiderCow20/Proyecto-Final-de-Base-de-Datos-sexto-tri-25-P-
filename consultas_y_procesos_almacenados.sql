USE tienda_electronicos;

-- -----------------------------------------------------
-- CONSULTAS
-- -----------------------------------------------------

-- 1. Listar productos disponibles por categoría, ordenados por precio
SELECT 
    c.nombre AS categoria,
    p.nombre AS producto,
    p.descripcion,
    p.precio,
    p.stock
FROM 
    productos p
JOIN 
    categorias c ON p.id_categoria = c.id_categoria
WHERE 
    p.stock > 0
ORDER BY 
    c.nombre, p.precio;

-- 2. Mostrar clientes con pedidos pendientes y total de compras
SELECT 
    cl.id_cliente,
    cl.nombre,
    cl.correo,
    COUNT(p.id_pedido) AS pedidos_pendientes,
    SUM(dp.cantidad * dp.precio_unitario) AS total_compras
FROM 
    clientes cl
JOIN 
    pedidos p ON cl.id_cliente = p.id_cliente
JOIN 
    detalles_pedido dp ON p.id_pedido = dp.id_pedido
WHERE 
    p.estado = 'pendiente'
GROUP BY 
    cl.id_cliente, cl.nombre, cl.correo;

-- 3. Reporte de los 5 productos con mejor calificación promedio en reseñas
SELECT 
    p.id_producto,
    p.nombre,
    AVG(r.calificacion) AS calificacion_promedio,
    COUNT(r.id_reseña) AS total_reseñas
FROM 
    productos p
JOIN 
    reseñas r ON p.id_producto = r.id_producto
GROUP BY 
    p.id_producto, p.nombre
ORDER BY 
    calificacion_promedio DESC
LIMIT 5;

-- -----------------------------------------------------
-- PROCEDIMIENTOS ALMACENADOS
-- -----------------------------------------------------

-- 1. Registrar un nuevo pedido, verificando el límite de 5 pedidos pendientes y stock suficiente
DELIMITER //
CREATE PROCEDURE registrar_pedido(
    IN p_id_cliente INT,
    IN p_id_producto INT,
    IN p_cantidad INT,
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE pedidos_pendientes INT;
    DECLARE stock_actual INT;
    DECLARE precio_producto DECIMAL(10,2);
    
    -- Verificar pedidos pendientes del cliente
    SELECT COUNT(*) INTO pedidos_pendientes
    FROM pedidos
    WHERE id_cliente = p_id_cliente AND estado = 'pendiente';
    
    -- Verificar stock disponible
    SELECT stock, precio INTO stock_actual, precio_producto
    FROM productos
    WHERE id_producto = p_id_producto;
    
    IF pedidos_pendientes >= 5 THEN
        SET p_resultado = 'Error: El cliente ya tiene 5 pedidos pendientes';
    ELSEIF stock_actual < p_cantidad THEN
        SET p_resultado = CONCAT('Error: Stock insuficiente. Disponible: ', stock_actual);
    ELSE
        -- Registrar el pedido
        INSERT INTO pedidos (id_cliente, estado) VALUES (p_id_cliente, 'pendiente');
        
        -- Registrar detalle del pedido
        INSERT INTO detalles_pedido (id_pedido, id_producto, cantidad, precio_unitario)
        VALUES (LAST_INSERT_ID(), p_id_producto, p_cantidad, precio_producto);
        
        -- Actualizar stock
        UPDATE productos SET stock = stock - p_cantidad WHERE id_producto = p_id_producto;
        
        SET p_resultado = 'Pedido registrado exitosamente';
    END IF;
END //
DELIMITER ;

-- 2. Registrar una reseña, verificando que el cliente haya comprado el producto
DELIMITER //
CREATE PROCEDURE registrar_reseña(
    IN p_id_cliente INT,
    IN p_id_producto INT,
    IN p_calificacion INT,
    IN p_comentario VARCHAR(100),
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE cliente_compro_producto INT;
    
    -- Verificar si el cliente compró el producto
    SELECT COUNT(*) INTO cliente_compro_producto
    FROM pedidos p
    JOIN detalles_pedido dp ON p.id_pedido = dp.id_pedido
    WHERE p.id_cliente = p_id_cliente AND dp.id_producto = p_id_producto;
    
    IF cliente_compro_producto = 0 THEN
        SET p_resultado = 'Error: El cliente no ha comprado este producto';
    ELSEIF p_calificacion < 1 OR p_calificacion > 5 THEN
        SET p_resultado = 'Error: La calificación debe estar entre 1 y 5';
    ELSE
        -- Registrar la reseña
        INSERT INTO reseñas (id_producto, id_cliente, calificacion, comentario)
        VALUES (p_id_producto, p_id_cliente, p_calificacion, p_comentario);
        
        SET p_resultado = 'Reseña registrada exitosamente';
    END IF;
END //
DELIMITER ;

-- 3. Actualizar el stock de un producto después de un pedido (siempre disminuye)
DELIMITER //
CREATE PROCEDURE actualizar_stock_pedido(
    IN p_id_producto INT,
    IN p_cantidad INT,
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE stock_actual INT;
    
    SELECT stock INTO stock_actual FROM productos WHERE id_producto = p_id_producto;
    
    IF stock_actual < p_cantidad THEN
        SET p_resultado = CONCAT('Error: Stock insuficiente. Disponible: ', stock_actual);
    ELSE
        -- Siempre disminuir el stock
        UPDATE productos SET stock = stock - p_cantidad WHERE id_producto = p_id_producto;
        
        SET p_resultado = CONCAT('Stock actualizado. Nuevo stock: ', 
                                (SELECT stock FROM productos WHERE id_producto = p_id_producto));
    END IF;
END //
DELIMITER ;

-- 4. Cambiar el estado de un pedido
DELIMITER //
CREATE PROCEDURE cambiar_estado_pedido(
    IN p_id_pedido INT,
    IN p_nuevo_estado VARCHAR(20),
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE estado_actual VARCHAR(20);
    
    SELECT estado INTO estado_actual FROM pedidos WHERE id_pedido = p_id_pedido;
    
    IF estado_actual IS NULL THEN
        SET p_resultado = 'Error: Pedido no encontrado';
    ELSEIF estado_actual = 'cancelado' THEN
        SET p_resultado = 'Error: No se puede modificar un pedido cancelado';
    ELSEIF p_nuevo_estado NOT IN ('pendiente', 'procesando', 'enviado', 'entregado', 'cancelado') THEN
        SET p_resultado = 'Error: Estado no válido';
    ELSE
        UPDATE pedidos SET estado = p_nuevo_estado WHERE id_pedido = p_id_pedido;
        SET p_resultado = CONCAT('Estado del pedido ', p_id_pedido, ' cambiado a ', p_nuevo_estado);
    END IF;
END //
DELIMITER ;

-- 5. Eliminar reseñas de un producto (puede ser una o todas) con promedio actualizado
DELIMITER //
CREATE PROCEDURE eliminar_reseñas_producto(
    IN p_id_producto INT,
    IN p_id_reseña INT, -- NULL para eliminar todas
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE total_reseñas INT;
    DECLARE reseñas_restantes INT;
    DECLARE promedio_actual DECIMAL(3,2);
    
    -- Verificar si el producto existe
    SELECT COUNT(*) INTO total_reseñas FROM reseñas WHERE id_producto = p_id_producto;
    
    IF total_reseñas = 0 THEN
        SET p_resultado = 'Error: El producto no tiene reseñas';
    ELSE
        IF p_id_reseña IS NULL THEN
            -- Eliminar todas las reseñas del producto
            DELETE FROM reseñas WHERE id_producto = p_id_producto;
            SET p_resultado = 'Todas las reseñas del producto eliminadas. No quedan reseñas.';
        ELSE
            -- Eliminar solo la reseña específica
            DELETE FROM reseñas WHERE id_reseña = p_id_reseña AND id_producto = p_id_producto;
            
            -- Verificar si se eliminó alguna reseña
            IF ROW_COUNT() = 0 THEN
                SET p_resultado = 'Error: No se encontró la reseña especificada para este producto';
            ELSE
                -- Calcular reseñas restantes y promedio
                SELECT 
                    COUNT(*) AS count, 
                    IFNULL(AVG(calificacion), 0) AS avg 
                INTO 
                    reseñas_restantes, 
                    promedio_actual
                FROM reseñas 
                WHERE id_producto = p_id_producto;
                
                SET p_resultado = CONCAT(
                    'Reseña eliminada. ',
                    'Reseñas restantes: ', reseñas_restantes, '. ',
                    'Promedio actual: ', ROUND(promedio_actual, 2)
                );
            END IF;
        END IF;
    END IF;
END //
DELIMITER ;

-- 6. Agregar un nuevo producto, verificando que no exista un duplicado
DELIMITER //
CREATE PROCEDURE agregar_producto(
    IN p_nombre VARCHAR(100),
    IN p_descripcion VARCHAR(100),
    IN p_precio DECIMAL(10,2),
    IN p_stock INT,
    IN p_id_categoria INT,
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE producto_existente INT;
    
    -- Verificar si ya existe un producto con el mismo nombre y categoría
    SELECT COUNT(*) INTO producto_existente
    FROM productos
    WHERE nombre = p_nombre AND id_categoria = p_id_categoria;
    
    IF producto_existente > 0 THEN
        SET p_resultado = 'Error: Ya existe un producto con ese nombre en esta categoría';
    ELSEIF p_precio <= 0 THEN
        SET p_resultado = 'Error: El precio debe ser mayor que cero';
    ELSEIF p_stock < 0 THEN
        SET p_resultado = 'Error: El stock no puede ser negativo';
    ELSE
        -- Insertar el nuevo producto
        INSERT INTO productos (nombre, descripcion, precio, stock, id_categoria)
        VALUES (p_nombre, p_descripcion, p_precio, p_stock, p_id_categoria);
        
        SET p_resultado = CONCAT('Producto "', p_nombre, '" agregado exitosamente con ID: ', LAST_INSERT_ID());
    END IF;
END //
DELIMITER ;

-- 7. Actualizar la información de un cliente
DELIMITER //
CREATE PROCEDURE actualizar_cliente(
    IN p_id_cliente INT,
    IN p_nuevo_telefono VARCHAR(20),
    IN p_nueva_direccion VARCHAR(100),
    OUT p_resultado VARCHAR(200)
)
BEGIN
    DECLARE cliente_existente INT;
    
    SELECT COUNT(*) INTO cliente_existente FROM clientes WHERE id_cliente = p_id_cliente;
    
    IF cliente_existente = 0 THEN
        SET p_resultado = 'Error: Cliente no encontrado';
    ELSE
        UPDATE clientes 
        SET telefono = p_nuevo_telefono, direccion = p_nueva_direccion
        WHERE id_cliente = p_id_cliente;
        
        SET p_resultado = CONCAT('Información del cliente ', p_id_cliente, ' actualizada exitosamente');
    END IF;
END //
DELIMITER ;

-- 8. Generar un reporte de productos con stock bajo
DELIMITER //
CREATE PROCEDURE reporte_stock_bajo()
BEGIN
    SELECT 
        p.id_producto,
        p.nombre AS producto,
        c.nombre AS categoria,
        p.stock,
        p.precio
    FROM 
        productos p
    JOIN 
        categorias c ON p.id_categoria = c.id_categoria
    WHERE 
        p.stock < 5
    ORDER BY 
        p.stock ASC;
END //
DELIMITER ;
