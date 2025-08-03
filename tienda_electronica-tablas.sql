-- Crear base de datos
CREATE DATABASE IF NOT EXISTS tienda_electronicos;
USE tienda_electronicos;

-- Tabla de Clientes
CREATE TABLE clientes (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(100),
    INDEX indice_correo (correo) -- índice para búsquedas por correo
);

-- Tabla de Categorías de Productos
CREATE TABLE categorias (
    id_categoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL,
    descripcion VARCHAR(100),
    INDEX indice_nombre_categoria (nombre) -- índice para búsqueda por nombre de categoría
);

-- Tabla de Productos
CREATE TABLE productos (
    id_producto INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(100),
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0), -- restricción stock no negativo,
    id_categoria INT NOT NULL,
    FOREIGN KEY (id_categoria) REFERENCES categorias(id_categoria),
    INDEX indice_nombre_producto (nombre), -- indice para búsqueda por nombre de producto
    INDEX indice_categoria_producto (id_categoria) -- indice para búsqueda por categoria
);


-- Tabla de Pedidos
CREATE TABLE pedidos (
    id_pedido INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    fecha_pedido DATE DEFAULT (CURRENT_DATE),
    estado ENUM('pendiente', 'procesando', 'enviado', 'entregado', 'cancelado') DEFAULT 'pendiente',
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    INDEX indice_cliente_pedido (id_cliente),  -- índice para búsquedas de pedidos por cliente
    INDEX indice_estado_pedido (estado)  -- índice para búsqueda por estado de pedido
);

-- Tabla de Detalles de Pedidos
CREATE TABLE detalles_pedido (
    id_detalle INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL CHECK (cantidad > 0), -- restricción para cantidad positiva
    precio_unitario DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    INDEX indice_pedido_detalle (id_pedido) -- índice para búsquedas de detalles por pedido
);

-- Tabla de Reseñas
CREATE TABLE reseñas (
    id_reseña INT PRIMARY KEY AUTO_INCREMENT,
    id_producto INT NOT NULL,
    id_cliente INT NOT NULL,
    calificacion INT NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    comentario VARCHAR(300),
    fecha DATE DEFAULT (CURRENT_DATE),
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto),
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    INDEX indice_producto_reseña (id_producto)  -- índice para búsquedas de reseñas por producto
);