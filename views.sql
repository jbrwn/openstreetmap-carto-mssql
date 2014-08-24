CREATE VIEW landcover
AS
select ogr_geometry, name, religion,coalesce (aeroway, amenity, landuse, leisure, military, natural, power, tourism, highway) as feature from (select top 2147483647 ogr_geometry, COALESCE(name,'') AS name, ('aeroway_' + (case when aeroway in ('apron', 'aerodrome') then aeroway else null end)) as aeroway,('amenity_' + (case when amenity in ('parking', 'university', 'college', 'school', 'hospital', 'kindergarten', 'grave_yard') then amenity else null end)) as amenity,('landuse_' + (case when landuse in ('quarry', 'vineyard', 'orchard', 'cemetery', 'residential', 'garages', 'field', 'meadow', 'grass', 'allotments', 'forest', 'farmyard', 'farm', 'farmland', 'recreation_ground', 'conservation', 'village_green', 'retail', 'industrial', 'railway', 'commercial', 'brownfield', 'landfill', 'construction') then landuse else null end)) as landuse,('leisure_' + (case when leisure in ('swimming_pool', 'playground', 'park', 'recreation_ground', 'common', 'garden', 'golf_course', 'picnic_table','sports_centre','stadium','pitch','track') then leisure else null end)) as leisure,('military_' + (case when military in ('barracks', 'danger_area') then military else null end)) as military,('natural_' + (case when natural in ('beach','desert','heath','mud','grassland','wood','sand','scrub') then natural else null end)) as natural,('power_' + (case when power in ('station','sub_station','substation','generator') then power else null end)) as power,('tourism_' + (case when  tourism in ('attraction', 'camp_site', 'caravan_site', 'picnic_site', 'zoo') then tourism else null end)) as tourism,('highway_' + (case when highway in ('services', 'rest_area') then highway else null end)) as highway,case when religion in ('christian','jewish') then religion else 'INT-generic' end as religion       from planet_osm_polygon       where landuse is not null          or leisure is not null          or aeroway in ('apron','aerodrome')          or amenity in ('parking','university','college','school','hospital','kindergarten','grave_yard')          or military in ('barracks','danger_area')          or natural in ('beach','desert','heath','mud','grassland','wood','sand','scrub')          or power in ('station','sub_station','substation','generator')          or tourism in ('attraction','camp_site','caravan_site','picnic_site','zoo')          or highway in ('services','rest_area')       order by z_order,ogr_geometry_area desc  ) as t
GO

CREATE VIEW landcover_line
AS
select ogr_geometry from planet_osm_line where man_made='cutline'
GO

CREATE VIEW water_lines_casing
AS
select ogr_geometry,waterway,case when tunnel in ('yes','culvert') then 'yes' else 'no' end as int_tunnel       from planet_osm_line      where waterway in ('stream','drain','ditch')        and (tunnel is null or tunnel != 'yes')      
GO

CREATE VIEW water_lines_low_zoom
AS
select ogr_geometry,waterway      from planet_osm_line      where waterway='river'      
GO
     
CREATE VIEW water_areas
AS
select top 2147483647 ogr_geometry,natural,waterway,landuse,name,ogr_geometry_area      from planet_osm_polygon      where (waterway in ('dock','mill_pond','riverbank','canal')         or landuse in ('reservoir','water','basin')         or natural in ('lake','water','land','glacier','mud'))         and building is null      order by z_order,ogr_geometry_area desc      
GO

CREATE VIEW water_areas_overlay
AS
select top 2147483647 ogr_geometry,natural      from planet_osm_polygon      where natural in ('marsh','wetland') and building is null      order by z_order,ogr_geometry_area desc
GO

CREATE VIEW water_lines
AS
select top 2147483647 ogr_geometry,waterway,lock,name,case when tunnel in ('yes','culvert') then 'yes' else 'no' end as int_tunnel      from planet_osm_line      where waterway in ('weir','river','canal','derelict_canal','stream','drain','ditch','wadi')        and (bridge is null or bridge not in ('yes','aqueduct'))      order by z_order
GO

CREATE VIEW dam
AS
select ogr_geometry,name from planet_osm_line where waterway='dam'
GO
     
CREATE VIEW marinas_area
AS
select ogr_geometry from planet_osm_polygon where leisure ='marina'
GO

CREATE VIEW piers_area
AS
select ogr_geometry,man_made from planet_osm_polygon where man_made in ('pier','breakwater','groyne')
GO

CREATE VIEW piers
AS
select ogr_geometry,man_made from planet_osm_line where man_made in ('pier','breakwater','groyne')
GO

CREATE VIEW locks
AS
select ogr_geometry,waterway from planet_osm_point where waterway='lock_gate'
GO
     

CREATE VIEW buildings_lz
AS
select top 2147483647 ogr_geometry,building,railway,amenity from planet_osm_polygon       where railway='station'          or building in ('station','supermarket')          or amenity='place_of_worship'       order by z_order,ogr_geometry_area desc
GO

CREATE VIEW buildings
AS
select top 2147483647 ogr_geometry,aeroway,        case         when building in ('garage','roof','garages','service','shed','shelter','cabin','storage_tank','tank','support','glasshouse','greenhouse','mobile_home','kiosk','silo','canopy','tent') then 'INT-light'         else building        end as building       from planet_osm_polygon       where (building is not null         and building not in ('no','station','supermarket','planned')         and (railway is null or railway != 'station')         and (amenity is null or amenity != 'place_of_worship'))          or aeroway = 'terminal'       order by z_order,ogr_geometry_area desc
GO

CREATE VIEW tunnels
AS
select top 2147483647 ogr_geometry,coalesce(('highway_' + (case when substring(highway, len(highway)-3, 4) = 'link' then substring(highway,0,len(highway)-4) else highway end)), ('railway_' +(case when railway='preserved' and service in ('spur','siding','yard') then 'INT-preserved-ssy' when (railway='rail' and service in ('spur','siding','yard'))  then 'INT-spur-siding-yard' else railway end)), ('aeroway_' + aeroway)) as feature, horse, foot, bicycle, tracktype, case when access in ('destination') then 'destination' when access in ('no', 'private') then 'no' else null end as access, construction, case when service in ('parking_aisle','drive-through','driveway') then 'INT-minor' else 'INT-normal' end as service, case when oneway in ('yes', '-1') and highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link','tertiary','tertiary_link','residential','unclassified','road','service','pedestrian','raceway','living_street','construction') then oneway else null end as oneway, case when substring(highway, len(highway)-3, 4) = 'link' then 'yes' else 'no' end as link, case when layer is null then '0' else layer end as layernotnull from planet_osm_line join (values ('railway_rail',430), ('railway_spur',430), ('railway_siding',430), ('railway_subway',420), ('railway_narrow_gauge',420), ('railway_light_rail',420), ('railway_preserved',420), ('railway_funicular',420), ('railway_monorail',420), ('railway_miniature',420), ('railway_turntable',420), ('railway_tram',410), ('railway_disused',400), ('railway_construction',400), ('highway_motorway',370), ('highway_trunk',360), ('highway_primary',350), ('highway_secondary',340), ('highway_tertiary',340), ('highway_residential',330), ('highway_unclassified',330), ('highway_road',330), ('highway_living_street',320), ('highway_pedestrian',310),  ('highway_raceway',300), ('highway_motorway_link',240), ('highway_trunk_link',230), ('highway_primary_link',220), ('highway_secondary_link',210), ('highway_tertiary_link',200), ('highway_service',150), ('highway_track',110), ('highway_path',100), ('highway_footway',100), ('highway_bridleway',100), ('highway_cycleway',100),  ('highway_steps',100), ('railway_platform',100), ('aeroway_runway',60), ('aeroway_taxiway',50), ('highway_proposed',20), ('highway_construction',10)) as ordertable (feature, prio) on coalesce(('highway_' + planet_osm_line.highway), ('railway_' + planet_osm_line.railway), ('aeroway_' + planet_osm_line.aeroway)) = ordertable.feature where (tunnel='yes' or tunnel='building_passage' or covered='yes') order by layernotnull, ordertable.prio
GO

CREATE VIEW citywalls
AS
select ogr_geometry from planet_osm_line where historic='citywalls'
GO

CREATE VIEW castlewalls
AS
select ogr_geometry from planet_osm_line where historic='castle_walls'
GO

CREATE VIEW castlewalls_poly
AS
select ogr_geometry from planet_osm_polygon where historic='castle_walls'
GO

CREATE VIEW landuse_overlay
AS
select ogr_geometry,landuse,leisure       from planet_osm_polygon       where (landuse = 'military') and building is null
GO

CREATE VIEW line_barriers
AS
select ogr_geometry, barrier from planet_osm_line where barrier is not null
GO

CREATE VIEW cliffs
AS
select ogr_geometry,natural,man_made from planet_osm_line where natural = 'cliff' or man_made = 'embankment'
GO

CREATE VIEW area_barriers
AS
select ogr_geometry,barrier from planet_osm_polygon where barrier is not null
GO

CREATE VIEW tree_row
AS
select ogr_geometry,natural from planet_osm_line where natural = 'tree_row'
GO

CREATE VIEW ferry_routes
AS
select ogr_geometry from planet_osm_line where route='ferry'
GO

CREATE VIEW highogr_geometry_area_casing
AS
select top 2147483647 ogr_geometry,coalesce(('highway_' + (case when highway in ('residential','unclassified','pedestrian','service','footway','cycleway','track','path','platform') then highway else null end)), ('railway_' + (case when railway in ('platform') then railway else null end))) as feature from planet_osm_polygon       where highway in ('residential','unclassified','pedestrian','service','footway','track','path','platform')          or railway in ('platform')       order by z_order,ogr_geometry_area desc
GO

CREATE VIEW roads_casing
AS
select top 2147483647 ogr_geometry,coalesce(('highway_' + (case when substring(highway, len(highway)-3, 4) = 'link' then substring(highway,0,len(highway)-4) else highway end)), ('railway_' +(case when railway='preserved' and service in ('spur','siding','yard') then 'INT-preserved-ssy' when (railway='rail' and service in ('spur','siding','yard'))  then 'INT-spur-siding-yard' else railway end)), ('aeroway_' + aeroway)) as feature, horse, foot, bicycle, tracktype, case when access in ('destination') then 'destination' when access in ('no', 'private') then 'no' else null end as access, construction, case when service in ('parking_aisle','drive-through','driveway') then 'INT-minor' else 'INT-normal' end as service, case when oneway in ('yes', '-1') and highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link','tertiary','tertiary_link','residential','unclassified','road','service','pedestrian','raceway','living_street','construction') then oneway else null end as oneway, case when substring(highway, len(highway)-3, 4) = 'link' then 'yes' else 'no' end as link, case when layer is null then '0' else layer end as layernotnull from planet_osm_line join ( values ('railway_rail',430), ('railway_spur',430), ('railway_siding',430), ('railway_subway',420), ('railway_narrow_gauge',420), ('railway_light_rail',420), ('railway_preserved',420), ('railway_funicular',420), ('railway_monorail',420), ('railway_miniature',420), ('railway_turntable',420), ('railway_tram',410), ('railway_disused',400), ('railway_construction',400), ('highway_motorway',370), ('highway_trunk',360), ('highway_primary',350), ('highway_secondary',340), ('highway_tertiary',340), ('highway_residential',330), ('highway_unclassified',330), ('highway_road',330), ('highway_living_street',320), ('highway_pedestrian',310),  ('highway_raceway',300), ('highway_motorway_link',240), ('highway_trunk_link',230), ('highway_primary_link',220), ('highway_secondary_link',210), ('highway_tertiary_link',200), ('highway_service',150), ('highway_track',110), ('highway_path',100), ('highway_footway',100), ('highway_bridleway',100), ('highway_cycleway',100),  ('highway_steps',100), ('railway_platform',100), ('aeroway_runway',60), ('aeroway_taxiway',50), ('highway_proposed',20), ('highway_construction',10)) as ordertable (feature, prio) on coalesce(('highway_' + planet_osm_line.highway), ('railway_' + planet_osm_line.railway), ('aeroway_' + planet_osm_line.aeroway)) = ordertable.feature where (tunnel is null or not tunnel in ('yes','building_passage')) and (covered is null or not covered='yes') and (bridge is null or not bridge in ('yes','viaduct')) order by ordertable.prio
GO

CREATE VIEW highogr_geometry_area_fill
AS
select top 2147483647 ogr_geometry,coalesce(('highway_' + (case when highway in ('residential','unclassified','pedestrian','service','footway','cycleway','living_street','track','path','platform','services') then highway else null end)), ('railway_' + (case when railway in ('platform') then railway else null end)), (('aeroway_' + case when aeroway in ('runway','taxiway','helipad') then aeroway else null end))) as feature from planet_osm_polygon       where highway in ('residential','unclassified','pedestrian','service','footway','living_street','track','path','platform','services')          or railway in ('platform')          or aeroway in ('runway','taxiway','helipad')       order by z_order,ogr_geometry_area desc
GO

CREATE VIEW roads_fill
AS
select top 2147483647 ogr_geometry,coalesce(('highway_' + (case when substring(highway, len(highway)-3, 4) = 'link' then substring(highway,0,len(highway)-4) else highway end)), ('railway_' +(case when railway='preserved' and service in ('spur','siding','yard') then 'INT-preserved-ssy' when (railway='rail' and service in ('spur','siding','yard'))  then 'INT-spur-siding-yard' else railway end)), ('aeroway_' + aeroway)) as feature, horse, foot, bicycle, tracktype, case when access in ('destination') then 'destination' when access in ('no', 'private') then 'no' else null end as access, construction, case when service in ('parking_aisle','drive-through','driveway') then 'INT-minor' else 'INT-normal' end as service, case when oneway in ('yes', '-1') and highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link','tertiary','tertiary_link','residential','unclassified','road','service','pedestrian','raceway','living_street','construction') then oneway else null end as oneway, case when substring(highway, len(highway)-3, 4) = 'link' then 'yes' else 'no' end as link, case when layer is null then '0' else layer end as layernotnull from planet_osm_line join ( values ('railway_rail',430), ('railway_spur',430), ('railway_siding',430), ('railway_subway',420), ('railway_narrow_gauge',420), ('railway_light_rail',420), ('railway_preserved',420), ('railway_funicular',420), ('railway_monorail',420), ('railway_miniature',420), ('railway_turntable',420), ('railway_tram',410), ('railway_disused',400), ('railway_construction',400), ('highway_motorway',370), ('highway_trunk',360), ('highway_primary',350), ('highway_secondary',340), ('highway_tertiary',340), ('highway_residential',330), ('highway_unclassified',330), ('highway_road',330), ('highway_living_street',320), ('highway_pedestrian',310),  ('highway_raceway',300), ('highway_motorway_link',240), ('highway_trunk_link',230), ('highway_primary_link',220), ('highway_secondary_link',210), ('highway_tertiary_link',200), ('highway_service',150), ('highway_track',110), ('highway_path',100), ('highway_footway',100), ('highway_bridleway',100), ('highway_cycleway',100),  ('highway_steps',100), ('railway_platform',100), ('aeroway_runway',60), ('aeroway_taxiway',50), ('highway_proposed',20), ('highway_construction',10)) as ordertable (feature, prio) on coalesce(('highway_' + planet_osm_line.highway), ('railway_' + planet_osm_line.railway), ('aeroway_' + planet_osm_line.aeroway)) = ordertable.feature where (tunnel is null or not tunnel in ('yes','building_passage')) and (covered is null or not covered='yes') and (bridge is null or not bridge in ('yes','viaduct')) order by ordertable.prio
GO

CREATE VIEW aerialways
AS
select ogr_geometry,aerialway from planet_osm_line where aerialway is not null
GO

CREATE VIEW roads_low_zoom
AS
select top 2147483647 ogr_geometry,coalesce(('highway_' + (case when substring(highway, len(highway)-3, 4) = 'link' then substring(highway,0,len(highway)-4) else highway end)), ('railway_' + (case when (railway='rail' and service in ('spur','siding','yard'))  then 'INT-spur-siding-yard' when railway in ('rail','tram','light_rail','funicular','narrow_gauge') then railway else null end))) as feature,tunnel       from planet_osm_roads       where highway is not null          or (railway is not null and railway!='preserved' and (service is null or service not in ('spur','siding','yard')))       order by z_order
GO

CREATE VIEW waterway_bridges
AS
select top 2147483647 ogr_geometry,name from planet_osm_line where waterway='canal' and bridge in ('yes','aqueduct') order by z_order
GO

CREATE VIEW bridges
AS
select top 2147483647 ogr_geometry,coalesce(('highway_' + (case when substring(highway, len(highway)-3, 4) = 'link' then substring(highway,0,len(highway)-4) else highway end)), ('railway_' +(case when railway='preserved' and service in ('spur','siding','yard') then 'INT-preserved-ssy' when (railway='rail' and service in ('spur','siding','yard'))  then 'INT-spur-siding-yard' else railway end)), ('aeroway_' + aeroway)) as feature, horse, foot, bicycle, tracktype, case when access in ('destination') then 'destination' when access in ('no', 'private') then 'no' else null end as access, construction, case when service in ('parking_aisle','drive-through','driveway') then 'INT-minor' else 'INT-normal' end as service, case when oneway in ('yes', '-1') and highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link','tertiary','tertiary_link','residential','unclassified','road','service','pedestrian','raceway','living_street','construction') then oneway else null end as oneway, case when substring(highway, len(highway)-3, 4) = 'link' then 'yes' else 'no' end as link, case when layer is null then '0' else layer end as layernotnull from planet_osm_line join ( values ('railway_rail',430), ('railway_spur',430), ('railway_siding',430), ('railway_subway',420), ('railway_narrow_gauge',420), ('railway_light_rail',420), ('railway_preserved',420), ('railway_funicular',420), ('railway_monorail',420), ('railway_miniature',420), ('railway_turntable',420), ('railway_tram',410), ('railway_disused',400), ('railway_construction',400), ('highway_motorway',370), ('highway_trunk',360), ('highway_primary',350), ('highway_secondary',340), ('highway_tertiary',340), ('highway_residential',330), ('highway_unclassified',330), ('highway_road',330), ('highway_living_street',320), ('highway_pedestrian',310),  ('highway_raceway',300), ('highway_motorway_link',240), ('highway_trunk_link',230), ('highway_primary_link',220), ('highway_secondary_link',210), ('highway_tertiary_link',200), ('highway_service',150), ('highway_track',110), ('highway_path',100), ('highway_footway',100), ('highway_bridleway',100), ('highway_cycleway',100),  ('highway_steps',100), ('railway_platform',100), ('aeroway_runway',60), ('aeroway_taxiway',50), ('highway_proposed',20), ('highway_construction',10)) as ordertable (feature, prio) on coalesce(('highway_' + planet_osm_line.highway), ('railway_' + planet_osm_line.railway), ('aeroway_' + planet_osm_line.aeroway)) = ordertable.feature where bridge in ('yes','viaduct') and (layer is null or (layer in ('0','1','2','3','4','5'))) order by layernotnull, ordertable.prio
GO

CREATE VIEW guideways
AS
select ogr_geometry from planet_osm_line where highway='bus_guideway' and (tunnel is null or tunnel != 'yes')
GO

CREATE VIEW admin_01234
AS
select ogr_geometry,admin_level       from planet_osm_roads       where boundary='administrative'         and admin_level in ('0','1','2','3','4')

GO

CREATE VIEW admin_5678
AS
select ogr_geometry,admin_level       from planet_osm_roads       where boundary='administrative'         and admin_level in ('5','6','7','8')
GO

CREATE VIEW admin_other
AS
select ogr_geometry,admin_level       from planet_osm_roads       where boundary='administrative'         and admin_level in ('9', '10')
GO

CREATE VIEW power_minorline
AS
select ogr_geometry from planet_osm_line where power='minor_line'
GO

CREATE VIEW power_line
AS
select ogr_geometry from planet_osm_line where power='line'
GO

CREATE VIEW placenames_large
AS
select ogr_geometry,place,name,ref       from planet_osm_point       where place in ('country','state')
GO

CREATE VIEW placenames_capital
AS
select ogr_geometry,place,name,ref       from planet_osm_point       where place in ('city','town') and capital='yes'
GO

CREATE VIEW placenames_medium
AS
select ogr_geometry,place,name      from planet_osm_point      where place in ('city','town')        and (capital is null or capital != 'yes')
GO

CREATE VIEW placenames_small
AS
select ogr_geometry,place,name      from planet_osm_point      where place in ('suburb','village','hamlet','neighbourhood','locality','isolated_dwelling','farm')
GO

CREATE VIEW stations
AS
select ogr_geometry,name,railway,aerialway,disused      from planet_osm_point      where railway in ('station','halt','tram_stop','subway_entrance')         or aerialway='station'
GO

CREATE VIEW stations_poly
AS
select ogr_geometry,name,railway,aerialway,disused      from planet_osm_polygon      where railway in ('station','halt','tram_stop')         or aerialway='station'
GO

CREATE VIEW glaciers_text
AS
select top 2147483647 ogr_geometry,name,ogr_geometry_area      from planet_osm_polygon      where natural='glacier' and building is null      order by ogr_geometry_area desc
GO

CREATE VIEW amenity_symbols
AS
select *      from planet_osm_point      where aeroway in ('aerodrome','helipad')         or barrier in ('bollard','gate','lift_gate','block')         or highway in ('mini_roundabout','gate')         or man_made in ('lighthouse','power_wind','windmill','mast')         or (power='generator' and (generator_source='wind' or power_source='wind'))         or natural in ('peak','volcano','spring','tree','cave_entrance')         or railway='level_crossing'
GO

CREATE VIEW amenity_symbols_poly
AS
select *      from planet_osm_polygon      where aeroway in ('aerodrome','helipad')         or barrier in ('bollard','gate','lift_gate','block')         or highway in ('mini_roundabout','gate')         or man_made in ('lighthouse','power_wind','windmill','mast')         or (power='generator' and (generator_source='wind' or power_source='wind'))         or natural in ('peak','volcano','spring','tree')         or railway='level_crossing'
GO

CREATE VIEW amenity_points
AS
select ogr_geometry,amenity,shop,tourism,highway,man_made,access,religion,waterway,lock,historic,leisure      from planet_osm_point      where shop in ('accessories', 'alcohol', 'antique', 'antiques', 'appliance', 'art', 'baby_goods', 'bag', 'bags', 'bakery', 'bathroom_furnishing', 'beauty', 'bed', 'betting', 'beverages', 'bicycle', 'boat', 'bookmaker', 'books', 'boutique', 'builder', 'building_materials', 'butcher', 'camera', 'car', 'car_parts', 'car_repair', 'car_service', 'carpet', 'charity', 'cheese', 'chemist', 'chocolate', 'clothes', 'coffee', 'communication', 'computer', 'confectionery', 'convenience', 'copyshop', 'cosmetics', 'craft', 'curtain', 'dairy', 'deli', 'delicatessen', 'department_store', 'discount', 'dive', 'doityourself', 'dry_cleaning', 'e-cigarette', 'electrical', 'electronics', 'energy', 'erotic', 'estate_agent', 'fabric', 'farm', 'fashion', 'fish', 'fishing', 'fishmonger', 'flooring', 'florist', 'food', 'frame', 'frozen_food', 'funeral_directors', 'furnace', 'furniture', 'gallery', 'gambling', 'games', 'garden_centre', 'gas', 'general', 'gift', 'glaziery', 'greengrocer', 'grocery', 'hairdresser', 'hardware', 'health', 'health_food', 'hearing_aids', 'herbalist', 'hifi', 'hobby', 'household', 'houseware', 'hunting', 'ice_cream', 'insurance', 'interior_decoration', 'jewellery', 'jewelry', 'kiosk', 'kitchen', 'laundry', 'leather', 'lighting', 'locksmith', 'lottery', 'mall', 'market', 'massage', 'medical', 'medical_supply', 'mobile_phone', 'money_lender', 'motorcycle', 'motorcycle_repair', 'music', 'musical_instrument', 'newsagent', 'office_supplies', 'optician', 'organic', 'outdoor', 'paint', 'pastry', 'pawnbroker', 'perfumery', 'pet', 'pets', 'pharmacy', 'phone', 'photo', 'photo_studio', 'photography', 'pottery', 'printing', 'radiotechnics', 'real_estate', 'religion', 'rental', 'salon', 'scuba_diving', 'seafood', 'second_hand', 'sewing', 'shoe_repair', 'shoes', 'shopping_centre', 'solarium', 'souvenir', 'sports', 'stationery', 'supermarket', 'tailor', 'tanning', 'tattoo', 'tea', 'ticket', 'tiles', 'tobacco', 'toys', 'trade', 'travel_agency', 'tyres', 'vacuum_cleaner', 'variety_store', 'video', 'video_games', 'watches', 'wholesale', 'wine', 'winery', 'yes')         or amenity is not null         or tourism in ('alpine_hut','picnic_site','camp_site','caravan_site','guest_house','hostel','hotel','motel','museum','viewpoint','bed_and_breakfast','information','chalet')         or highway in ('bus_stop','traffic_signals','ford')         or man_made in ('mast','water_tower')         or historic in ('memorial','archaeological_site')         or waterway='lock'         or lock='yes'         or leisure in ('playground','slipway','picnic_table')
GO

CREATE VIEW amenity_points_poly
AS
select ogr_geometry,amenity,shop,tourism,highway,man_made,access,religion,waterway,lock,historic,leisure      from planet_osm_polygon      where amenity is not null         or shop in ('accessories', 'alcohol', 'antique', 'antiques', 'appliance', 'art', 'baby_goods', 'bag', 'bags', 'bakery', 'bathroom_furnishing', 'beauty', 'bed', 'betting', 'beverages', 'bicycle', 'boat', 'bookmaker', 'books', 'boutique', 'builder', 'building_materials', 'butcher', 'camera', 'car', 'car_parts', 'car_repair', 'car_service', 'carpet', 'charity', 'cheese', 'chemist', 'chocolate', 'clothes', 'coffee', 'communication', 'computer', 'confectionery', 'convenience', 'copyshop', 'cosmetics', 'craft', 'curtain', 'dairy', 'deli', 'delicatessen', 'department_store', 'discount', 'dive', 'doityourself', 'dry_cleaning', 'e-cigarette', 'electrical', 'electronics', 'energy', 'erotic', 'estate_agent', 'fabric', 'farm', 'fashion', 'fish', 'fishing', 'fishmonger', 'flooring', 'florist', 'food', 'frame', 'frozen_food', 'funeral_directors', 'furnace', 'furniture', 'gallery', 'gambling', 'games', 'garden_centre', 'gas', 'general', 'gift', 'glaziery', 'greengrocer', 'grocery', 'hairdresser', 'hardware', 'health', 'health_food', 'hearing_aids', 'herbalist', 'hifi', 'hobby', 'household', 'houseware', 'hunting', 'ice_cream', 'insurance', 'interior_decoration', 'jewellery', 'jewelry', 'kiosk', 'kitchen', 'laundry', 'leather', 'lighting', 'locksmith', 'lottery', 'mall', 'market', 'massage', 'medical', 'medical_supply', 'mobile_phone', 'money_lender', 'motorcycle', 'motorcycle_repair', 'music', 'musical_instrument', 'newsagent', 'office_supplies', 'optician', 'organic', 'outdoor', 'paint', 'pastry', 'pawnbroker', 'perfumery', 'pet', 'pets', 'pharmacy', 'phone', 'photo', 'photo_studio', 'photography', 'pottery', 'printing', 'radiotechnics', 'real_estate', 'religion', 'rental', 'salon', 'scuba_diving', 'seafood', 'second_hand', 'sewing', 'shoe_repair', 'shoes', 'shopping_centre', 'solarium', 'souvenir', 'sports', 'stationery', 'supermarket', 'tailor', 'tanning', 'tattoo', 'tea', 'ticket', 'tiles', 'tobacco', 'toys', 'trade', 'travel_agency', 'tyres', 'vacuum_cleaner', 'variety_store', 'video', 'video_games', 'watches', 'wholesale', 'wine', 'winery', 'yes')         or tourism in ('alpine_hut','camp_site','picnic_site','caravan_site','guest_house','hostel','hotel','motel','museum','viewpoint','bed_and_breakfast','information','chalet')         or highway in ('bus_stop','traffic_signals')         or man_made in ('mast','water_tower')         or historic in ('memorial','archaeological_site')         or leisure in ('playground', 'picnic_table')
GO

CREATE VIEW power_towers
AS
select ogr_geometry from planet_osm_point where power='tower'
GO

CREATE VIEW power_poles
AS
select ogr_geometry from planet_osm_point where power='pole'
GO

CREATE VIEW roads_text_ref_low_zoom
AS
select ogr_geometry,highway,ref,len(ref) as length       from planet_osm_roads       where highway in ('motorway','trunk','primary','secondary')         and ref is not null         and len(ref) between 1 and 11
GO

CREATE VIEW highway_junctions
AS
select ogr_geometry,ref,name      from planet_osm_point      where highway='motorway_junction'
GO

CREATE VIEW roads_text_ref
AS
select ogr_geometry,coalesce(highway,aeroway) as highway,ref,len(ref) as length,       case when bridge in ('yes','aqueduct') then 'yes' else 'no' end as bridge       from planet_osm_line       where (highway is not null or aeroway is not null)         and ref is not null         and len(ref) between 1 and 11
GO

CREATE VIEW roads_area_text_name
AS
select ogr_geometry, highway, name       from planet_osm_polygon       where highway='pedestrian'         and name is not null
GO

CREATE VIEW roads_text_name
AS
select ogr_geometry, case when substring(highway, len(highway)-3, 4) = 'link' then substring(highway,0,len(highway)-4) else highway end highway, name       from planet_osm_line       where highway in ('motorway','motorway_link','trunk','trunk_link','primary','primary_link','secondary','secondary_link','tertiary','tertiary_link','residential','unclassified','road','service','pedestrian','raceway','living_street', 'construction','proposed')          and name is not null
GO

CREATE VIEW paths_text_name
AS
select ogr_geometry, highway, name       from planet_osm_line       where highway in ('bridleway', 'footway', 'cycleway', 'path', 'track', 'steps')          and name is not null
GO

CREATE VIEW text
AS
select ogr_geometry,amenity,shop,access,leisure,landuse,man_made,natural,place,tourism,ele,name,ref,military,aeroway,waterway,historic,NULL as ogr_geometry_area       from planet_osm_point       where amenity is not null          or shop in ('accessories', 'alcohol', 'antique', 'antiques', 'appliance', 'art', 'baby_goods', 'bag', 'bags', 'bakery', 'bathroom_furnishing', 'beauty', 'bed', 'betting', 'beverages', 'bicycle', 'boat', 'bookmaker', 'books', 'boutique', 'builder', 'building_materials', 'butcher', 'camera', 'car', 'car_parts', 'car_repair', 'car_service', 'carpet', 'charity', 'cheese', 'chemist', 'chocolate', 'clothes', 'coffee', 'communication', 'computer', 'confectionery', 'convenience', 'copyshop', 'cosmetics', 'craft', 'curtain', 'dairy', 'deli', 'delicatessen', 'department_store', 'discount', 'dive', 'doityourself', 'dry_cleaning', 'e-cigarette', 'electrical', 'electronics', 'energy', 'erotic', 'estate_agent', 'fabric', 'farm', 'fashion', 'fish', 'fishing', 'fishmonger', 'flooring', 'florist', 'food', 'frame', 'frozen_food', 'funeral_directors', 'furnace', 'furniture', 'gallery', 'gambling', 'games', 'garden_centre', 'gas', 'general', 'gift', 'glaziery', 'greengrocer', 'grocery', 'hairdresser', 'hardware', 'health', 'health_food', 'hearing_aids', 'herbalist', 'hifi', 'hobby', 'household', 'houseware', 'hunting', 'ice_cream', 'insurance', 'interior_decoration', 'jewellery', 'jewelry', 'kiosk', 'kitchen', 'laundry', 'leather', 'lighting', 'locksmith', 'lottery', 'mall', 'market', 'massage', 'medical', 'medical_supply', 'mobile_phone', 'money_lender', 'motorcycle', 'motorcycle_repair', 'music', 'musical_instrument', 'newsagent', 'office_supplies', 'optician', 'organic', 'outdoor', 'paint', 'pastry', 'pawnbroker', 'perfumery', 'pet', 'pets', 'pharmacy', 'phone', 'photo', 'photo_studio', 'photography', 'pottery', 'printing', 'radiotechnics', 'real_estate', 'religion', 'rental', 'salon', 'scuba_diving', 'seafood', 'second_hand', 'sewing', 'shoe_repair', 'shoes', 'shopping_centre', 'solarium', 'souvenir', 'sports', 'stationery', 'supermarket', 'tailor', 'tanning', 'tattoo', 'tea', 'ticket', 'tiles', 'tobacco', 'toys', 'trade', 'travel_agency', 'tyres', 'vacuum_cleaner', 'variety_store', 'video', 'video_games', 'watches', 'wholesale', 'wine', 'winery', 'yes')          or leisure is not null          or landuse is not null          or tourism is not null          or natural is not null          or man_made in ('lighthouse','windmill')          or place='island'          or military='danger_area'          or aeroway='gate'          or waterway='lock'          or historic in ('memorial','archaeological_site')
GO
     
CREATE VIEW text_poly
AS
select ogr_geometry,aeroway,shop,access,amenity,leisure,landuse,man_made,natural,place,tourism,NULL as ele,name,ref,military,waterway,historic,ogr_geometry_area       from planet_osm_polygon       where amenity is not null          or shop in ('accessories', 'alcohol', 'antique', 'antiques', 'appliance', 'art', 'baby_goods', 'bag', 'bags', 'bakery', 'bathroom_furnishing', 'beauty', 'bed', 'betting', 'beverages', 'bicycle', 'boat', 'bookmaker', 'books', 'boutique', 'builder', 'building_materials', 'butcher', 'camera', 'car', 'car_parts', 'car_repair', 'car_service', 'carpet', 'charity', 'cheese', 'chemist', 'chocolate', 'clothes', 'coffee', 'communication', 'computer', 'confectionery', 'convenience', 'copyshop', 'cosmetics', 'craft', 'curtain', 'dairy', 'deli', 'delicatessen', 'department_store', 'discount', 'dive', 'doityourself', 'dry_cleaning', 'e-cigarette', 'electrical', 'electronics', 'energy', 'erotic', 'estate_agent', 'fabric', 'farm', 'fashion', 'fish', 'fishing', 'fishmonger', 'flooring', 'florist', 'food', 'frame', 'frozen_food', 'funeral_directors', 'furnace', 'furniture', 'gallery', 'gambling', 'games', 'garden_centre', 'gas', 'general', 'gift', 'glaziery', 'greengrocer', 'grocery', 'hairdresser', 'hardware', 'health', 'health_food', 'hearing_aids', 'herbalist', 'hifi', 'hobby', 'household', 'houseware', 'hunting', 'ice_cream', 'insurance', 'interior_decoration', 'jewellery', 'jewelry', 'kiosk', 'kitchen', 'laundry', 'leather', 'lighting', 'locksmith', 'lottery', 'mall', 'market', 'massage', 'medical', 'medical_supply', 'mobile_phone', 'money_lender', 'motorcycle', 'motorcycle_repair', 'music', 'musical_instrument', 'newsagent', 'office_supplies', 'optician', 'organic', 'outdoor', 'paint', 'pastry', 'pawnbroker', 'perfumery', 'pet', 'pets', 'pharmacy', 'phone', 'photo', 'photo_studio', 'photography', 'pottery', 'printing', 'radiotechnics', 'real_estate', 'religion', 'rental', 'salon', 'scuba_diving', 'seafood', 'second_hand', 'sewing', 'shoe_repair', 'shoes', 'shopping_centre', 'solarium', 'souvenir', 'sports', 'stationery', 'supermarket', 'tailor', 'tanning', 'tattoo', 'tea', 'ticket', 'tiles', 'tobacco', 'toys', 'trade', 'travel_agency', 'tyres', 'vacuum_cleaner', 'variety_store', 'video', 'video_games', 'watches', 'wholesale', 'wine', 'winery', 'yes')          or leisure is not null          or landuse is not null          or tourism is not null          or natural is not null          or man_made in ('lighthouse','windmill')          or place='island'          or military='danger_area'          or historic in ('memorial','archaeological_site')
GO

CREATE VIEW building_text
AS
select name, ogr_geometry, ogr_geometry_area from planet_osm_polygon where building is not null  and building not in ('no','station','supermarket')
GO

CREATE VIEW interpolation
AS
select ogr_geometry from planet_osm_line where addr_interpolation is not null
GO

CREATE VIEW housenumbers
AS
select ogr_geometry,addr_housenumber from planet_osm_polygon where addr_housenumber is not null and building is not null       union all      select ogr_geometry,addr_housenumber from planet_osm_point where addr_housenumber is not null
GO

CREATE VIEW housenames
AS
select ogr_geometry,addr_housename from planet_osm_polygon where addr_housename is not null and building is not null union all select ogr_geometry,addr_housename from planet_osm_point where addr_housename is not null
GO

CREATE VIEW water_lines_text
AS
select top 2147483647 ogr_geometry,waterway,lock,name,case when tunnel in ('yes','culvert') then 'yes' else 'no' end as int_tunnel      from planet_osm_line      where waterway in ('weir','river','canal','derelict_canal','stream','drain','ditch','wadi')       order by z_order
GO

CREATE VIEW admin_text
AS
select ogr_geometry, name, admin_level from planet_osm_polygon where boundary = 'administrative' and admin_level in ('0','1','2','3','4','5','6','7','8','9','10')
GO

CREATE VIEW nature_reserve_boundaries
AS
select ogr_geometry,ogr_geometry_area,name,boundary from planet_osm_polygon where (boundary='national_park' or leisure='nature_reserve') and building is null
GO

CREATE VIEW theme_park
AS
select ogr_geometry,name,tourism from planet_osm_polygon where tourism='theme_park'
GO

INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'landcover','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'landcover_line','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'water_lines_casing','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'water_lines_low_zoom','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])     
     VALUES (DB_NAME(),SCHEMA_NAME(),'water_areas','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'water_areas_overlay','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'water_lines','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'dam','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])     
     VALUES (DB_NAME(),SCHEMA_NAME(),'marinas_area','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'piers_area','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'piers','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'locks','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'buildings_lz','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'buildings','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'tunnels','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'citywalls','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'castlewalls','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'castlewalls_poly','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'landuse_overlay','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'line_barriers','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'cliffs','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'area_barriers','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'tree_row','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'ferry_routes','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'highway_area_casing','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'roads_casing','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'highway_area_fill','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'roads_fill','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'aerialways','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'roads_low_zoom','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'waterway_bridges','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'bridges','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'guideways','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'admin_01234','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'admin_5678','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'admin_other','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'power_minorline','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'power_line','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'placenames_large','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'placenames_capital','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'placenames_medium','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'placenames_small','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'stations','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'stations_poly','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'glaciers_text','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'amenity_symbols','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'amenity_symbols_poly','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'amenity_POINTs','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'amenity_POINTs_poly','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'power_towers','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'power_poles','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'roads_text_ref_low_zoom','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'highway_junctions','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'roads_text_ref','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'roads_area_text_name','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'roads_text_name','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'paths_text_name','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'text','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])     
     VALUES (DB_NAME(),SCHEMA_NAME(),'text_poly','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'building_text','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'interpolation','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'housenumbers','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'housenames','ogr_geometry',2,900913,'POINT')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'water_lines_text','ogr_geometry',2,900913,'LINESTRING')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'admin_text','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'nature_reserve_boundaries','ogr_geometry',2,900913,'POLYGON')
INSERT INTO [dbo].[geometry_columns] ([f_table_catalog],[f_table_schema],[f_table_name],[f_geometry_column],[coord_dimension],[srid],[geometry_type])
     VALUES (DB_NAME(),SCHEMA_NAME(),'theme_park','ogr_geometry',2,900913,'POLYGON')
GO