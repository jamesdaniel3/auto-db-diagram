import sys 
from lib import utils, config_tools, interactive_helper, config, database
from config import DatabaseConfig
from database import mongo, mysql, postgres, sqlite

HELP_MESSAGE = """Invalid usage of db-diagram, run db-diagram --help for more info or man db-diagram for a full manpage"""
ERROR_MESSAGE = """db-diagram - Generate ERD diagrams from live database connections

USAGE:
    db-diagram                                   # Interactive mode
    db-diagram --headless <path/to/config.json>  # Headless mode with config

OPTIONS:
    -h, --headless     Use existing JSON config file
    --help             Show this help message

EXAMPLES:
    db-diagram                          # Guided setup
    db-diagram -h my-db-config.json    # Use existing config

CONFIG FILE FORMAT:
    See config information at: https://auto-db-diagram.dev"""

MONGOEXPORT_ERROR_MESSAGE = """This tool relies on `mongoexport`, which is not part of Homebrew core.
To install it, run:
brew tap mongodb/brew
brew install mongodb-database-tools"""

def main():
    num_args = len(sys.argv - 1)

    if num_args == 0:
        run_extraction("interactive")
    elif num_args == 2:
        if sys.argv[1] in ["--headless", "-h"]:
            run_extraction("headless")
        else:
            utils.error(ERROR_MESSAGE)
    elif num_args == 1 and sys.argv[1] == "--help":
        print(HELP_MESSAGE)
        sys.exit()
    else:
        utils.error(ERROR_MESSAGE)


def run_extraction(mode):
    if mode == "headless":
        try:
            file = sys.argv[2]
            stream = open(file, "r")
            strem.close()
        except FileNotFound:
            utils.error("The file passed in the command line cannot be located") 
        
        utils.check_tool("jq")
        config_tools.parse_config(sys.argv[2])
        config_tools.validate_config()
    else:
        interactive_helper.get_database_info()
    
    utils.check_tool("dot")

    match DatabaseConfig.DATABASE_TYPE:
        case "postgres":
            utils.check_tool("psql")
            try:
                postgres.run_postgres_extraction()
            except:
                utils.error("Failed to extraxt PostgreSQL Schema") 
        case "mysql":
            utils.check_tool("mysql")
            try:
                mysql.run_mysql_extraction()
            except:
                utils.error("Failed to extraxt MySQL Schema") 
        case "sqlite":
            try:
                sqlite.run_sqlite_extraction()
            except:
                utils.error("Failed to extraxt SQLite Schema") 
        case "mongodb":
            utils.check_tool("mongoexport", MONGOEXPORT_ERROR_MESSAGE)
            utils.check_tool("mongosh")
            try:
                mongo.run_mongo_extraction()
            except:
                utils.error("Failed to extraxt MongoDB Schema") 
        case _:
            utils.error("Unsupported database type: " + str(DatabaseConfig.DATABASE_TYPE))

if __name__ == "__main__":
    main()