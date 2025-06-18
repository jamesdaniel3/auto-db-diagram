# Auto DB Diagram: an ERD generation tool

This tool was built to solve the pains of maintaining database diagrams on software projects such as regularly having to make new diagrams and dealing with descrepancies between your diagrams and your actual databases. Just download the tool, pass it your database info, and let it handle the diagrams!

![Example of a generated PNG](ERD.png)

## Installation and Usage

To install on Mac or Linux:

```bash
brew install jamesdaniel3/auto-db-diagram/db-diagram
```

The code can either be run in headless mode, in which case, you must pass the file path to a config file:

```bash
db-diagram  --headless /Users/jamesdaniel/automatic-db-digrammer/config.json
db-diagram  -h /Users/jamesdaniel/automatic-db-digrammer/config.json
```

or it can be run in interactive mode, where it will walk you through the setup:

```
db-diagram
```

Here is the contents of a valid config.json file:

```json
{
  "DATABASE_TYPE": "postgres",
  "CONNECTION_INFO": {
    "HOST": "localhost",
    "PORT": 5432,
    "USERNAME": "postgres",
    "DATABASE_NAME": "mind-map-development"
    "PASSWORD": "",
  }
}
```

The password field is optional (unless it's needed to connect to your DB!) and all fields are case-insensitive.

As of the current inplementation, all of the fields in the file are required.

This tool currently only supports connections to local postgreSQL instances.

## Planned Features

- MySQL connections
- SQL Server Connections
- Hosted DB Connections

## Contributing

- [Spot a Bug?](https://github.com/jamesdaniel3/auto-db-diagram/issues)
- [Want to add something?](https://github.com/jamesdaniel3/auto-db-diagram/pulls)
