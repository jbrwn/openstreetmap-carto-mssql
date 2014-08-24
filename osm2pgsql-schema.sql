CREATE TABLE z_order (
	offset	INT,
	highway NVARCHAR(16),
	roads	INT
)
GO

INSERT INTO z_order (offset,highway,roads) VALUES ( 3, 'minor',         0 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 3, 'road',          0 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 3, 'unclassified',  0 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 3, 'residential',   0 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 4, 'tertiary_link', 0 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 4, 'tertiary',      0 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 6, 'secondary_link',1 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 6, 'secondary',     1 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 7, 'primary_link',  1 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 7, 'primary',       1 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 8, 'trunk_link',    1 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 8, 'trunk',         1 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 9, 'motorway_link', 1 )
INSERT INTO z_order (offset,highway,roads) VALUES ( 9, 'motorway',      1 )
GO

CREATE VIEW planet_osm_point
AS 
SELECT *,
		null AS z_order
FROM points
GO

CREATE VIEW planet_osm_line
AS 
SELECT	L.*,
		z_order.offset AS z_order
FROM 
	(
		SELECT * FROM lines
		UNION ALL
		SELECT * FROM multilinestrings
	) L
	 LEFT JOIN 
		z_order ON L.highway = z_order.highway
GO

CREATE VIEW planet_osm_roads
AS 
SELECT	L.*,
		z_order.offset AS z_order
FROM 
	(
		SELECT * FROM lines
		UNION ALL
		SELECT * FROM multilinestrings
	) L
	 LEFT JOIN 
		z_order ON L.highway = z_order.highway
WHERE z_order.roads = 1
GO

CREATE VIEW planet_osm_polygon
AS 
SELECT	multipolygons.*,
		z_order.offset as z_order
FROM multipolygons
	 LEFT JOIN 
		z_order ON multipolygons.highway = z_order.highway
GO


INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
    VALUES (DB_NAME(),SCHEMA_NAME(),'planet_osm_point','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
    VALUES (DB_NAME(),SCHEMA_NAME(),'planet_osm_line','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
    VALUES (DB_NAME(),SCHEMA_NAME(),'planet_osm_polygon','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
    VALUES (DB_NAME(),SCHEMA_NAME(),'planet_osm_roads','ogr_geometry',2,900913,'LINESTRING')