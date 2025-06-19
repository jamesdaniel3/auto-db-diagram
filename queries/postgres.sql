WITH table_info AS (
    SELECT 
        t.table_schema,
        t.table_name,
        json_agg(
            json_build_object(
                'column_name', c.column_name,
                'data_type', c.data_type,
                'character_maximum_length', c.character_maximum_length,
                'numeric_precision', c.numeric_precision,
                'numeric_scale', c.numeric_scale,
                'is_nullable', c.is_nullable,
                'column_default', c.column_default,
                'ordinal_position', c.ordinal_position
            ) ORDER BY c.ordinal_position
        ) as columns
    FROM information_schema.tables t
    JOIN information_schema.columns c 
        ON t.table_name = c.table_name 
        AND t.table_schema = c.table_schema
    WHERE t.table_type = 'BASE TABLE'
        AND t.table_schema NOT IN ('information_schema', 'pg_catalog')
        --EXCLUSION_PLACEHOLDER--
    GROUP BY t.table_schema, t.table_name
),
constraint_info AS (
    SELECT 
        tc.table_schema,
        tc.table_name,
        json_agg(
            json_build_object(
                'constraint_name', tc.constraint_name,
                'constraint_type', tc.constraint_type,
                'column_name', kcu.column_name,
                'foreign_table_schema', ccu.table_schema,
                'foreign_table_name', ccu.table_name,
                'foreign_column_name', ccu.column_name
            )
        ) as constraints
    FROM information_schema.table_constraints tc
    LEFT JOIN information_schema.key_column_usage kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    LEFT JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_schema NOT IN ('information_schema', 'pg_catalog')
    GROUP BY tc.table_schema, tc.table_name
),
index_info AS (
    SELECT 
        schemaname as table_schema,
        tablename as table_name,
        json_agg(
            json_build_object(
                'index_name', indexname,
                'index_definition', indexdef
            )
        ) as indexes
    FROM pg_indexes
    WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
    GROUP BY schemaname, tablename
)
SELECT json_build_object(
    'database_info', json_build_object(
        'database_name', current_database(),
        'database_type', 'postgres',
        'host', inet_server_addr(),
        'port', inet_server_port(),
        'extracted_at', now()
    ),
    'tables', json_agg(
        json_build_object(
            'schema', ti.table_schema,
            'name', ti.table_name,
            'columns', ti.columns,
            'constraints', COALESCE(ci.constraints, '[]'::json),
            'indexes', COALESCE(ii.indexes, '[]'::json)
        )
    )
) as schema_data
FROM table_info ti
LEFT JOIN constraint_info ci 
    ON ti.table_schema = ci.table_schema 
    AND ti.table_name = ci.table_name
LEFT JOIN index_info ii
    ON ti.table_schema = ii.table_schema 
    AND ti.table_name = ii.table_name;
