/* ================================
   TRABAJO PRÁCTICO FINAL - BD II (Lo hice solo, no tengo grupo)
   ================================ */

/* DDL de Creacion de Tablas */

CREATE TABLE TIPOLIBRO (TIPO char(2) PRIMARY KEY not null,
			         DESCTIPO char(40))
--

CREATE TABLE LIBRO (NRO_LIBRO int PRIMARY KEY not null, 
                     TITULO char(40),
                     AUTOR char(30),
                     TIPO char(2),
                     PRECIO_ORI smallmoney,
                     PRECIO_ACT smallmoney, 
                     EDICION smallint,
					 ESTADO char(1) not null DEFAULT 'D',
                     CONSTRAINT CK_LIBRO_ESTADO CHECK (ESTADO IN ('D', 'N')),
                     FOREIGN KEY (TIPO) REFERENCES TIPOLIBRO (TIPO))
--

CREATE TABLE LECTOR (NRO_LECTOR int PRIMARY KEY NOT NULL,
                     NOMBRE varchar(22),
                     TRABAJO varchar(15) NOT NULL,
                     SALARIO smallmoney,
					 ESTADO char(1) not null DEFAULT 'H',
                     CONSTRAINT CK_LECTOR_ESTADO CHECK (ESTADO IN ('H', 'I')),
                     CONSTRAINT CK_LECTOR_TRABAJO CHECK (TRABAJO IN ('EMPLEADO', 'EJECUTIVO', 'VENDEDOR', 'COMERCIANTE')),
                     CONSTRAINT CK_LECTOR_SALARIO CHECK (SALARIO > 0))
--
CREATE TABLE DOMICILIO (NRO_LECTOR int NOT NULL,
                        CALLE VARCHAR(50) NOT NULL,
                        ALTURA CHAR(5) NOT NULL,
                        PISO CHAR(5) NULL,
                        DTO CHAR(5) NULL,
                        PRIMARY KEY (NRO_LECTOR, CALLE, ALTURA),
                        FOREIGN KEY (NRO_LECTOR) REFERENCES LECTOR (NRO_LECTOR))

CREATE TABLE COPIAS (NRO_LIBRO int not null,
                       NRO_COPIA smallint,
					   ESTADO char(1) not null DEFAULT 'N',
                       PRIMARY KEY (NRO_LIBRO, NRO_COPIA),
                       FOREIGN KEY (NRO_LIBRO) REFERENCES LIBRO (NRO_LIBRO),
                       CONSTRAINT CK_COPIAS_ESTADO CHECK (ESTADO IN ('P', 'D', 'N')))
--
CREATE TABLE PRESTAMO (NRO_LECTOR int,
                       NRO_LIBRO int,
                       NRO_COPIA smallint,
                       F_PREST datetime,
                       F_DEVOL datetime,
                       PRIMARY KEY (NRO_LECTOR, NRO_LIBRO, NRO_COPIA, F_PREST),
                       FOREIGN KEY (NRO_LECTOR) REFERENCES LECTOR (NRO_LECTOR),
                       FOREIGN KEY (NRO_LIBRO, NRO_COPIA) REFERENCES COPIAS(NRO_LIBRO, NRO_COPIA))



