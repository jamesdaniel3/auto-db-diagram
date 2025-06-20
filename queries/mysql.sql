SELECT JSON_OBJECT(
    'database_info', JSON_OBJECT(
        'database_name', DATABASE(),
        'database_type', 'mysql',
        'host', @@hostname,
        'port', @@port,
        'extracted_at', NOW()
    ),
    'tables', JSON_ARRAYAGG(
        JSON_OBJECT(
            'schema', table_data.table_schema,
            'name', table_data.table_name,
            'columns', table_data.columns,
            'constraints', COALESCE(constraint_data.constraints, JSON_ARRAY()),
            'indexes', COALESCE(index_data.indexes, JSON_ARRAY())
        )
    )
) as schema_data
FROM (
    SELECT 
        t.table_schema,
        t.table_name,
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'column_name', c.column_name,
                'data_type', c.data_type,
                'character_maximum_length', c.character_maximum_length,
                'numeric_precision', c.numeric_precision,
                'numeric_scale', c.numeric_scale,
                'is_nullable', c.is_nullable,
                'column_default', c.column_default,
                'ordinal_position', c.ordinal_position,
                'extra', c.extra
            )
        ) as columns
    FROM information_schema.tables t
    JOIN information_schema.columns c 
        ON t.table_name = c.table_name 
        AND t.table_schema = c.table_schema
    WHERE t.table_type = 'BASE TABLE'
        AND t.table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
        --EXCLUSION_PLACEHOLDER--
    GROUP BY t.table_schema, t.table_name
) table_data
LEFT JOIN (
    SELECT 
        tc.table_schema,
        tc.table_name,
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'constraint_name', tc.constraint_name,
                'constraint_type', tc.constraint_type,
                'column_name', kcu.column_name,
                'foreign_table_schema', kcu.referenced_table_schema,
                'foreign_table_name', kcu.referenced_table_name,
                'foreign_column_name', kcu.referenced_column_name
            )
        ) as constraints
    FROM information_schema.table_constraints tc
    LEFT JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
        AND tc.table_name = kcu.table_name
    WHERE tc.table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
    GROUP BY tc.table_schema, tc.table_name
) constraint_data
    ON table_data.table_schema = constraint_data.table_schema 
    AND table_data.table_name = constraint_data.table_name
LEFT JOIN (
    SELECT 
        table_schema,
        table_name,
        JSON_ARRAYAGG(
            JSON_OBJECT(
                'index_name', index_name,
                'column_name', column_name,
                'non_unique', CASE WHEN non_unique = 0 THEN false ELSE true END,
                'index_type', index_type,
                'seq_in_index', seq_in_index
            )
        ) as indexes
    FROM information_schema.statistics
    WHERE table_schema NOT IN ('information_schema', 'performance_schema', 'mysql', 'sys')
    GROUP BY table_schema, table_name
) index_data
    ON table_data.table_schema = index_data.table_schema 
    AND table_data.table_name = index_data.table_name;