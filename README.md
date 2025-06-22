# Auto DB Diagram: an ERD generation tool

This tool was built to solve the pains of maintaining database diagrams on software projects such as regularly having to make new diagrams and dealing with descrepancies between your diagrams and your actual databases. Just download the tool, pass it your database info, and let it handle the diagrams!

![Example of a generated PNG](ERD.png)

## Installation

To install on Mac:

```bash
brew tap jamesdaniel3/auto-db-diagram
brew install db-diagram
```

## Headless Usage

The code can be run in headless mode, in which case, you must pass the file path to a config file:

```bash
db-diagram  --headless /Users/jamesdaniel/automatic-db-digrammer/config.json
db-diagram  -h /Users/jamesdaniel/automatic-db-digrammer/config.json
```

The structure of valid config files varies based on the type of database you want to connect to, but examples can be found under `/configs_examples/valid_configs`. In addition to examples, here is a slightly more formal explanation of the permitted fields in the config file, depending on the database you are trying to connect to.

```TypeScript
postgreSQLConfig {
  database_type: "postgres"
  connection_info: {
    host: string;
    port: number;
    username: string;
    database_name: string;
    password?: string;
  };
  excluded_tables?: string[];
}
```

```TypeScript
mySQLConfig {
  database_type: "mysql"
  connection_info: {
    host: string;
    port: number;
    username: string;
    database_name: string;
    password?: string;
  };
  excluded_tables?: string[];
}
```

```TypeScript
SQLiteConfig {
  database_type: "sqlite"
  connection_info: {
    database_location: string;
  };
  excluded_tables?: string[];
}
```

```TypeScript
MongoDBConfig {
  database_type: "mongodb"
  connection_info: {
    connection_string?: string,
    host?: string;
    port?: number;
    database_name: string;
    username?: string;
    password?: string;
    ssl_enabled?: boolean,
    ssl_allow_invalid_certs?: boolean,  
    ssl_ca_file_path?: string,  // path to ca pem file
    ssl_client_cert_path?: string,  // path to client pem file
    connect_with_service_record?: boolean
  };
  excluded_tables?: string[];
  exhaustive_search?: boolean; // check all documents in each collection rather than a maximum of the most recent 100
}
```

Note: a question mark denotes an optional field, any fields included but not listed will be ignored.

## Interactive Mode Usage

Alternatively, the program can be run in interactive mode, where it will walk you through the setup:

```
db-diagram
```

This tool currently supports connections to the following:

- postgreSQL instances
- SQLite instances
- MySQL instances

## Planned Features

- SQL Server Connections
- Hosted DB Connections

## Contributing

- [Spot a Bug?](https://github.com/jamesdaniel3/auto-db-diagram/issues)
- [Want to add something?](https://github.com/jamesdaniel3/auto-db-diagram/pulls)
