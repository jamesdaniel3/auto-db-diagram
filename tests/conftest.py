import subprocess
import pytest
import os
import tempfile
import shutil

# Shared constants
SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'main.sh'))
INVALID_CONFIGS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'config_examples/invalid_configs'))
VALID_CONFIGS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'config_examples/valid_configs'))

# Config file paths
VALID_POSTGRES_CONFIG = os.path.join(VALID_CONFIGS_DIR, 'valid_postgres.json')
VALID_SQLITE_CONFIG = os.path.join(VALID_CONFIGS_DIR, 'valid_sqlite.json')
VALID_MYSQL_CONFIG = os.path.join(VALID_CONFIGS_DIR, 'valid_mysql.json')
MIXED_CASE_CONFIG = os.path.join(VALID_CONFIGS_DIR, 'mixed_case_fields.json')

INVALID_JSON = os.path.join(INVALID_CONFIGS_DIR, 'invalid_json.txt')
MISSING_DB_TYPE = os.path.join(INVALID_CONFIGS_DIR, 'missing_database_type.json')
MISSING_CONNECTION = os.path.join(INVALID_CONFIGS_DIR, 'missing_connection_info.json')
MISSING_HOST = os.path.join(INVALID_CONFIGS_DIR, 'missing_host.json')
MISSING_DB_LOCATION = os.path.join(INVALID_CONFIGS_DIR, 'missing_location_info.json')
UNSUPPORTED_DB = os.path.join(INVALID_CONFIGS_DIR, 'unsupported_database.json')

@pytest.fixture
def mock_tools_env():
    """Create a temporary environment with mock tools"""
    temp_dir = tempfile.mkdtemp()
    
    # Create mock executables
    mock_tools = ['dot', 'pg_dump', 'mysqldump', 'sqlite3', 'psql', 'mysql']
    for tool in mock_tools:
        mock_path = os.path.join(temp_dir, tool)
        with open(mock_path, 'w') as f:
            f.write('#!/bin/bash\n')
            f.write('echo "Mock tool: $0"\n')
            f.write('exit 0\n')
        os.chmod(mock_path, 0o755)
    
    # Create environment with mocked PATH
    env = os.environ.copy()
    env['PATH'] = temp_dir + ':' + env['PATH']
    
    yield env
    
    # Cleanup
    shutil.rmtree(temp_dir)

@pytest.fixture 
def script_runner():
    """Factory for running the script with different configurations"""
    def _run_script(args, use_mock_env=True, mock_tools_env=None):
        env = mock_tools_env if use_mock_env and mock_tools_env else os.environ.copy()
        
        result = subprocess.run(
            ['bash', SCRIPT_PATH] + args,
            capture_output=True,
            text=True,
            env=env
        )
        return result.returncode, result.stdout, result.stderr
    
    return _run_script

def check_for_real_tools():
    """Check if real tools are available in the environment"""
    tools_to_check = ['dot', 'pg_dump']
    available_tools = []
    
    for tool in tools_to_check:
        try:
            subprocess.run([tool, '--version'], capture_output=True, check=True, timeout=5)
            available_tools.append(tool)
        except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
            pass
    
    return available_tools

# Pytest marks for organizing tests
pytest_plugins = []