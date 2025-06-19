import pytest
from conftest import (
    INVALID_JSON, MISSING_DB_TYPE, MISSING_CONNECTION, MISSING_HOST, UNSUPPORTED_DB, VALID_POSTGRES_CONFIG, MISSING_DB_LOCATION
)

class TestConfigurationErrors:
    """Test all configuration-related error conditions"""
    
    def test_invalid_json_format(self, script_runner, mock_tools_env):
        """Should fail with JSON parsing error for malformed JSON"""
        code, stdout, stderr = script_runner(['--headless', INVALID_JSON], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        assert code != 0
        assert any(keyword in combined_output.lower() 
                  for keyword in ['json', 'parse', 'invalid', 'malformed'])
    
    def test_missing_database_type_field(self, script_runner, mock_tools_env):
        """Should fail when database_type field is missing"""
        code, stdout, stderr = script_runner(['--headless', MISSING_DB_TYPE], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        assert code != 0
        assert any(keyword in combined_output.lower() 
                  for keyword in ['database_type', 'missing', 'required'])
    
    def test_missing_connection_info_section(self, script_runner, mock_tools_env):
        """Should fail when connection_info section is missing"""
        code, stdout, stderr = script_runner(['--headless', MISSING_CONNECTION], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        assert code != 0
        assert any(keyword in combined_output.lower() 
                  for keyword in ['connection', 'missing', 'required'])
    
    def test_missing_required_connection_fields_postgres(self, script_runner, mock_tools_env):
        """Should fail when required connection fields like host are missing"""
        code, stdout, stderr = script_runner(['--headless', MISSING_HOST], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        assert code != 0
        assert any(keyword in combined_output.lower() 
                  for keyword in ['host', 'missing', 'required'])
    
    def test_missing_required_connection_fields_sqlite(self, script_runner, mock_tools_env):
        """
            Should fail when required connection fields like database_location are missing
            Used because required fields for sqlite and postgres are different 
        """
        code, stdout, stderr = script_runner(['--headless', MISSING_DB_LOCATION], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        assert code != 0
        assert any(keyword in combined_output.lower() 
                  for keyword in ['host', 'missing', 'required'])
    
    def test_unsupported_database_type(self, script_runner, mock_tools_env):
        """Should fail for unsupported database types"""
        code, stdout, stderr = script_runner(['--headless', UNSUPPORTED_DB], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        assert code != 0
        assert 'unsupported' in combined_output.lower()

class TestCommandLineErrors:
    """Test command-line argument error conditions"""
    
    @pytest.mark.parametrize("args,error_type", [
        (["--headless"], "missing_config"),
        (["-h"], "missing_config"),
        (["--headless", "/nonexistent/path.json"], "file_not_found"),
        (["-h", "/nonexistent/path.json"], "file_not_found"),
        (["--invalid-flag"], "invalid_argument"),
    ])
    def test_command_line_argument_errors(self, script_runner, mock_tools_env, args, error_type):
        """Test various command-line argument error conditions"""
        code, stdout, stderr = script_runner(args, mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        assert code != 0
        
        if error_type == "missing_config":
            assert any(keyword in combined_output.lower() 
                      for keyword in ['config', 'required', 'usage'])
        elif error_type == "file_not_found":
            assert any(keyword in combined_output.lower() 
                      for keyword in ['exist', 'found', 'no such file'])
        elif error_type == "invalid_argument":
            assert any(keyword in combined_output.lower() 
                      for keyword in ['invalid', 'unknown', 'usage'])

class TestDependencyErrors:
    """Test dependency and tool availability error conditions"""
    
    def test_missing_tools_detected(self, script_runner):
        """Should detect and report missing tools when they're not available"""
        # Run without mocked tools to test real dependency checking
        code, stdout, stderr = script_runner(['--headless', VALID_POSTGRES_CONFIG], 
                                           use_mock_env=False)
        combined_output = stdout + stderr
        
        # Should either succeed (if tools are available) or fail with tool error
        if code != 0:
            has_tool_error = any(phrase in combined_output 
                               for phrase in ['is not installed', 'not in PATH', 'not found'])
            has_connection_error = any(keyword in combined_output.lower() 
                                     for keyword in ['connection', 'database', 'connect'])
            
            assert has_tool_error or has_connection_error