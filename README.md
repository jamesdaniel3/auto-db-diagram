# Auto DB Diagram: an ERD generation tool

This tool was built to solve the pains of maintaining database diagrams on software projects such as regularly having to make new diagrams and dealing with descrepancies between your diagrams and your actual databases.

## Installation and Usage

To install on Mac or Linux:

```bash
brew install jamesdaniel3/auto-db-diagram/db-diagram
```

To run the code, pass the path to a config.json file along with the startup command:

```bash
db-diagram /Users/jamesdaniel/automatic-db-digrammer/config.json
```

Here is the contents of a valid config.json file:

```json
{
  "DATABASE_TYPE": "postgres",
  "HOST": "localhost",
  "PORT": 5432,
  "USERNAME": "postgres",
  "DATABASE_NAME": "mind-map-development"
}
```

As of the current inplementation, all of the fields in the file are required.

This tool currently only supports connections to local postgreSQL instances.

## Planned Features

## Contributing
