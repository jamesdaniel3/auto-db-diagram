import subprocess
import pytest
import os

SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'main.sh'))
CONFIGS_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'config_examples', 'invalid_configs'))

def run_script_with_args(args):
    result = subprocess.run(
        ['bash', SCRIPT_PATH] + args,
        capture_output=True,
        text=True
    )
    return result.returncode, result.stdout, result.stderr

@pytest.mark.parametrize("args,expected_msg", [
    ([], "No config file provided"),
    (["/nonexistent/path.json"], "Config file '/nonexistent/path.json' does not exist"),
    ([f"{CONFIGS_DIR}/not_json.txt"], "XXXXXXXXXX"),
    ([f"{CONFIGS_DIR}/missing_fields.json"], "Missing required configuration fields"),
    ([f"{CONFIGS_DIR}/unsupported_db.json"], "Unsupported database type")
])
def test_error_messages(args, expected_msg):
    code, stdout, stderr = run_script_with_args(args)
    combined_output = stdout + stderr
    assert code != 0
    assert expected_msg in combined_output
