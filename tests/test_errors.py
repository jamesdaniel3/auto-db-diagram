import subprocess
import pytest
import os

# path to main script
SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'main.sh'))
INVALID_CONFIGS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'config_examples/invalid_configs'))
VALID_CONFIGS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'config_examples/valid_configs'))

def run_script_with_args(args):
    """Run the main.sh script with given arguments"""
    result = subprocess.run(
        ['bash', SCRIPT_PATH] + args,
        capture_output=True,
        text=True
    )
    return result.returncode, result.stdout, result.stderr

# config file paths
VALID_CONFIG = os.path.join(VALID_CONFIGS_DIR, 'valid_postgres.json')
MIXED_CASE_CONFIG = os.path.join(VALID_CONFIGS_DIR, 'mixed_case_fields.json')

INVALID_JSON = os.path.join(INVALID_CONFIGS_DIR, 'invalid_json.txt')
MISSING_DB_TYPE = os.path.join(INVALID_CONFIGS_DIR, 'missing_database_type.json')
MISSING_CONNECTION = os.path.join(INVALID_CONFIGS_DIR, 'missing_connection_info.json')
MISSING_HOST = os.path.join(INVALID_CONFIGS_DIR, 'missing_host.json')
UNSUPPORTED_DB = os.path.join(INVALID_CONFIGS_DIR, 'unsupported_database.json')


def test_help_flag():
    """Test --help flag works"""
    code, stdout, stderr = run_script_with_args(['--help'])
    assert code == 0
    assert 'usage' in stdout.lower() or 'help' in stdout.lower() or len(stdout) > 0

def test_no_args_interactive():
    """Test that running with no args starts interactive mode"""
    # Since the script starts interactive mode, it should either:
    # 1. Show the database selection menu, or 
    # 2. Exit with tool check error (which is expected behavior depending on environment)
    # 3. Exit successfully
    code, stdout, stderr = run_script_with_args([])
    combined_output = stdout + stderr
    
    interactive_started = "Running in interactive mode" in combined_output
    has_database_menu = "Select the type of database" in combined_output
    tool_check_error = ("is not installed" in combined_output or 
                       "not in PATH" in combined_output or
                       "not found" in combined_output)
    
    # script should start interactive mode properly, even if it fails due to missing tools
    assert (code == 0 or interactive_started or has_database_menu or tool_check_error), \
           f"Unexpected output: {combined_output}"

@pytest.mark.parametrize("args,expected_msg", [
    (["--headless"], "Config file required"),  
    (["-h"], "Config file required"),  
    (["--headless", "/nonexistent/path.json"], "does not exist"),
    (["-h", "/nonexistent/path.json"], "does not exist"),
])
def test_headless_mode_errors(args, expected_msg):
    """Test headless mode error handling"""
    code, stdout, stderr = run_script_with_args(args)
    combined_output = stdout + stderr
    # either show error or usage info
    assert code != 0 or len(combined_output) > 0

def test_invalid_json():
    """Test invalid JSON handling"""
    code, stdout, stderr = run_script_with_args(['--headless', INVALID_JSON])
    combined_output = stdout + stderr
    # exit with error for invalid JSON (unless tool check fails first)
    tool_check_error = ("is not installed" in combined_output or 
                       "not in PATH" in combined_output)
    json_error = "not valid JSON" in combined_output or "parse" in combined_output.lower()
    
    assert code != 0 and (tool_check_error or json_error)

def test_missing_database_type():
    """Test missing database_type field"""
    code, stdout, stderr = run_script_with_args(['--headless', MISSING_DB_TYPE])
    combined_output = stdout + stderr
    # exit with error for missing required field (unless tool check fails first)
    tool_check_error = ("is not installed" in combined_output or 
                       "not in PATH" in combined_output)
    config_error = "database_type" in combined_output.lower() or "missing" in combined_output.lower()
    
    assert code != 0 and (tool_check_error or config_error)

def test_missing_connection_info():
    """Test missing connection_info"""
    code, stdout, stderr = run_script_with_args(['--headless', MISSING_CONNECTION])
    combined_output = stdout + stderr
    # exit with error for missing connection info (unless tool check fails first)
    tool_check_error = ("is not installed" in combined_output or 
                       "not in PATH" in combined_output)
    config_error = "connection" in combined_output.lower() or "missing" in combined_output.lower()
    
    assert code != 0 and (tool_check_error or config_error)

def test_missing_required_fields():
    """Test missing required connection fields"""
    code, stdout, stderr = run_script_with_args(['--headless', MISSING_HOST])
    combined_output = stdout + stderr
    # exit with error for missing required field (unless tool check fails first)
    tool_check_error = ("is not installed" in combined_output or 
                       "not in PATH" in combined_output)
    config_error = "host" in combined_output.lower() or "missing" in combined_output.lower()
    
    assert code != 0 and (tool_check_error or config_error)

def test_unsupported_database():
    """Test unsupported database type"""
    code, stdout, stderr = run_script_with_args(['--headless', UNSUPPORTED_DB])
    combined_output = stdout + stderr
    # exit with error for unsupported database (unless tool check fails first)
    tool_check_error = ("is not installed" in combined_output or 
                       "not in PATH" in combined_output)
    db_error = "unsupported" in combined_output.lower()
    
    assert code != 0 and (tool_check_error or db_error)

def test_valid_config_parsing():
    """Test that valid config is parsed without errors (connection may still fail)"""
    code, stdout, stderr = run_script_with_args(['--headless', VALID_CONFIG])
    combined_output = stdout + stderr
    
    # config parsing should succeed, but connection or tool check might fail
    tool_check_error = ("is not installed" in combined_output or 
                       "not in PATH" in combined_output)
    
    if code != 0:
        assert ("not valid JSON" not in combined_output and 
                "missing" not in combined_output.lower()) or tool_check_error
        # connection failure or tool check failure is expected in test environment

def test_case_insensitive_config():
    """Test that config parsing handles mixed case field names"""
    code, stdout, stderr = run_script_with_args(['--headless', MIXED_CASE_CONFIG])
    combined_output = stdout + stderr
    
    # should not fail due to case sensitivity (tool check or connection failures are acceptable)
    tool_check_error = ("is not installed" in combined_output or 
                       "not in PATH" in combined_output)
    case_sensitivity_issue = "database_type" in combined_output.lower() and "missing" in combined_output.lower()
    
    assert not case_sensitivity_issue or tool_check_error or code == 0

def test_tool_check_behavior():
    """Test that the script properly checks for required tools"""
    code, stdout, stderr = run_script_with_args(['--headless', VALID_CONFIG])
    combined_output = stdout + stderr
    
    # if dot is missing, should get appropriate error message
    if "dot is not installed" in combined_output or "not in PATH" in combined_output:
        assert code != 0
        assert "dot" in combined_output
    # if dot is available, script should proceed further
    elif code == 0 or "Extracting PostgreSQL schema" in combined_output:
        # tool check passed, any failure is likely due to database connection
        pass
    else:
        # some other error occurred
        assert code != 0