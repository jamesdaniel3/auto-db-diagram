class DatabaseConfig:
    DATABASE_TYPE = None
    EXCLUDED_TABLES = None
    EXHAUSTIVE_SEARCH = None

    class ConnectionInfo:
        HOST = None
        PORT = None
        USERNAME = None
        DATABASE_NAME = None
        PASSWOROD = None
        DATABASE_LOCATION = None
        CONNECTION_STRING = None
        SSL_ENABLED = None
        SSL_ALLOW_INVALID_CERTS = None
        SSL_CA_FILE_PATH = None
        SSL_CLIENT_CERT_PATH = None
        CONNECT_WITH_SERVICE_RECORD = None
