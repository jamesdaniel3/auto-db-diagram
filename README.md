# Auto DB Diagram: an ERD generation tool

This tool was built to solve the pains of maintaining database diagrams on software projects such as regularly having to make new diagrams and dealing with descrepancies between your diagrams and your actual databases. Just download the tool, pass it your database info, and let it handle the diagrams!

![Example of a generated PNG](ERD.png)

## Installation and Usage

To install on Mac or Linux:

```bash
brew install db-diagram
```

The code can either be run in headless mode, in which case, you must pass the file path to a config file:

```bash
db-diagram  --headless /Users/jamesdaniel/automatic-db-digrammer/config.json
db-diagram  -h /Users/jamesdaniel/automatic-db-digrammer/config.json
```

The structure of valid config files varies based on the type of database you want to connect to, but examples can be found under `/configs_examples/valid_configs`.

Alternatively, the program can be run in interactive mode, where it will walk you through the setup:

```
db-diagram
```

This tool currently supports connections to local postgreSQL instances and SQLite instances.

## Planned Features

- MySQL connections
- SQL Server Connections
- Hosted DB Connections

## Contributing

- [Spot a Bug?](https://github.com/jamesdaniel3/auto-db-diagram/issues)
- [Want to add something?](https://github.com/jamesdaniel3/auto-db-diagram/pulls)
