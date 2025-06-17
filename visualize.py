"""
JSON Database Schema to Graphviz DOT Generator

Converts database schema JSON files to DOT format for ERD visualization.
Usage: python visualize.py <schema.json> [output.dot]
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Any, Optional


def generate_dot_from_database_schema(schema_data: Dict[str, Any]) -> str:
    """
    Generate DOT file content from database schema JSON.
    
    Args:
        schema_data: Parsed JSON database schema
        
    Returns:
        DOT file content as string
    """
    database_name = schema_data['database_info']['database_name'].replace('-', '_')  
    
    dot_content = f"""digraph {database_name}ERD {{
    rankdir=TB;
    concentrate=true;
    nodesep=.25;
    ranksep=.25;
    compound=true;
    node [shape=none, fontname="Arial", fontsize=10];
    edge [fontname="Arial", fontsize=8, arrowhead=none, arrowtail=none];
    
"""
    
    # Filter out migration tables
    tables = [table for table in schema_data['tables'] 
              if not table['name'].startswith('knex_')]
    
    # Generate table definitions
    for table in tables:
        dot_content += generate_table_definition(table)
        dot_content += '\n'
    
    # Generate relationships with specific column connections
    dot_content += '    // Relationships\n'
    relationships = extract_relationships(tables)
    for rel in relationships:
        # Connect from specific column to specific column using ports
        from_port = f"{rel['from']}:{rel['column']}"
        to_port = f"{rel['to']}:{rel['foreign_column']}"
        dot_content += f"    {from_port} -> {to_port};\n"
    
    dot_content += '}'
    
    return dot_content


def generate_table_definition(table: Dict[str, Any]) -> str:
    """
    Generate DOT table definition with proper left-right column alignment.
    
    Args:
        table: Table schema dictionary
        
    Returns:
        DOT table definition string
    """
    table_name = table['name']
    
    table_html = f"""    {table_name} [label=<
        <TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0">
            <TR><TD COLSPAN="2" BGCOLOR="steelblue" ALIGN="CENTER"><FONT COLOR="white"><B>{table_name}</B></FONT></TD></TR>"""
    
    # Get primary key columns
    primary_keys = get_primary_key_columns(table)
    
    for column in table['columns']:
        column_name = column['column_name']
        is_primary_key = column_name in primary_keys
        
        display_name = f"{column_name} (PK)" if is_primary_key else column_name
        data_type = format_data_type(column)
        nullable = ' NN' if column['is_nullable'] == 'NO' else ''
        
        # Use two columns: left for name, right for type/constraints
        type_info = f"{data_type}{nullable}"
        
        table_html += f'\n            <TR><TD PORT="{column_name}" ALIGN="LEFT">{display_name}</TD><TD ALIGN="RIGHT">{type_info}</TD></TR>'
    
    table_html += """
        </TABLE>
    >];"""
    
    return table_html


def get_primary_key_columns(table: Dict[str, Any]) -> List[str]:
    """
    Extract primary key column names from table constraints.
    
    Args:
        table: Table schema dictionary
        
    Returns:
        List of primary key column names
    """
    primary_keys = []
    for constraint in table['constraints']:
        if (constraint['constraint_type'] == 'PRIMARY KEY' and 
            constraint['column_name']):
            primary_keys.append(constraint['column_name'])
    return primary_keys


def format_data_type(column: Dict[str, Any]) -> str:
    """
    Format database data types to cleaner display names.
    
    Args:
        column: Column schema dictionary
        
    Returns:
        Formatted data type string
    """
    data_type = column['data_type']
    
    # Map verbose types to cleaner names
    type_map = {
        'character varying': 'string',
        'varchar': 'string',
        'text': 'string',
        'integer': 'integer',
        'boolean': 'boolean',
        'timestamp with time zone': 'timestamptz',
        'timestamptz': 'timestamptz'
    }
    
    return type_map.get(data_type, data_type)


def extract_relationships(tables: List[Dict[str, Any]]) -> List[Dict[str, str]]:
    """
    Extract foreign key relationships between tables.
    
    Args:
        tables: List of table schema dictionaries
        
    Returns:
        List of relationship dictionaries
    """
    relationships = []
    table_names = {table['name'] for table in tables}
    
    for table in tables:
        for constraint in table['constraints']:
            if constraint['constraint_type'] == 'FOREIGN KEY':
                from_table = table['name']
                to_table = constraint['foreign_table_name']
                
                # Only add if both tables exist in our filtered list
                if to_table in table_names:
                    relationships.append({
                        'from': from_table,
                        'to': to_table,
                        'column': constraint['column_name'],
                        'foreign_column': constraint['foreign_column_name']
                    })
    
    return relationships


def load_schema_file(file_path: str) -> Dict[str, Any]:
    """
    Load and parse JSON schema file.
    
    Args:
        file_path: Path to JSON schema file
        
    Returns:
        Parsed schema dictionary
        
    Raises:
        FileNotFoundError: If file doesn't exist
        json.JSONDecodeError: If file contains invalid JSON
    """
    path = Path(file_path)
    if not path.exists():
        raise FileNotFoundError(f"Schema file not found: {file_path}")
    
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_dot_file(content: str, output_path: str) -> None:
    """
    Save DOT content to file.
    
    Args:
        content: DOT file content
        output_path: Output file path
    """
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(content)


def main():
    """Command line interface for the generator."""
    parser = argparse.ArgumentParser(
        description='Generate Graphviz DOT files from JSON database schemas',
        epilog='Example: python json_to_dot.py schema.json diagram.dot'
    )
    parser.add_argument('input_file', help='Input JSON schema file')
    parser.add_argument('output_file', nargs='?', default='database_erd.dot',
                       help='Output DOT file (default: database_erd.dot)')
    parser.add_argument('--png', action='store_true',
                       help='Also generate PNG using dot command')
    
    args = parser.parse_args()
    
    try:
        # Load and process schema
        print(f"Loading schema from: {args.input_file}")
        schema_data = load_schema_file(args.input_file)
        
        # Generate DOT content
        print("Generating DOT content...")
        dot_content = generate_dot_from_database_schema(schema_data)
        
        # Save DOT file
        save_dot_file(dot_content, args.output_file)
        print(f"Generated DOT file: {args.output_file}")
        
        # Optionally generate PNG
        if args.png:
            import subprocess
            png_file = args.output_file.replace('.dot', '.png')
            try:
                subprocess.run(['dot', '-Tpng', args.output_file, '-o', png_file], 
                             check=True)
                print(f"Generated PNG file: {png_file}")
            except subprocess.CalledProcessError:
                print("⚠️  Failed to generate PNG. Make sure Graphviz is installed.")
            except FileNotFoundError:
                print("Graphviz 'dot' command not found. Install Graphviz to generate images.")
        
        print(f"To generate image manually: dot -Tpng {args.output_file} -o diagram.png")
        
    except FileNotFoundError as e:
        print(f"Error: {e}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"JSON Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()


def generate_erd_from_json_string(json_string: str, output_file: str = 'erd.dot') -> str:
    """
    Generate ERD from JSON string.
    
    Args:
        json_string: JSON schema as string
        output_file: Output DOT file path
        
    Returns:
        Generated DOT content
    """
    schema_data = json.loads(json_string)
    dot_content = generate_dot_from_database_schema(schema_data)
    save_dot_file(dot_content, output_file)
    return dot_content