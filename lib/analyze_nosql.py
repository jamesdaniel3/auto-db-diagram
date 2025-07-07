import json
import sys
import os

def main():
    file_name = sys.argv[1]
    collection_name = os.path.basename(file_name).replace(".json", "")

    try:
        with open(file_name, "r") as file_stream:
            data = json.load(file_stream)
    except json.JSONDecodeError as err:
        print(f"Error reading JSON file: {err}", file=sys.stderr)
        return 1
    except Exception:
        print("An error occurred while processing the data from your MongoDB instance", file=sys.stderr)
        return 1

    types = {}
    constraints = {}

    for document in data:
        for field in document:
            current_type = type(document[field]).__name__

            # hardcoded _id type override, need to investigate MongoDB types to see if this is valid
            if field == "_id":
                types[field] = "string"
                constraints[field] = "PRIMARY KEY"
                continue

            if field not in types:
                types[field] = current_type
            elif current_type not in types[field]:
                types[field] += f", {current_type}"

    output = {
        "schema": "public",
        "name": collection_name,
        "columns": [],
        "constraints": []
    }

    for field, dtype in types.items():
        output["columns"].append({
            "column_name": field,
            "data_type": dtype,
            "is_nullable": "YES" if field == "_id" else "NO"
        })
    
    for field, constraint_type in constraints.items():
        output["constraints"].append({
            "constraint_name": f"{collection_name}_pkey",
            "constraint_type": "PRIMARY KEY",
            "column_name": field,
            "foreign_table_schema": "public",
            "foreign_table_name": collection_name,
            "foreign_column_name": field
        })

    json.dump(output, sys.stdout, indent=4)
    print()  # Ensure newline after each block

if __name__ == "__main__":
    main()
