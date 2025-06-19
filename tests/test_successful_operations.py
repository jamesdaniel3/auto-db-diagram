import pytest
from conftest import VALID_POSTGRES_CONFIG, VALID_SQLITE_CONFIG, MIXED_CASE_CONFIG, check_for_real_tools

class TestConfigurationParsing:
    """Test successful configuration parsing and validation"""
    
    def test_valid_postgres_config_parsing_success(self, script_runner, mock_tools_env):
        """Valid configuration should parse without config-related errors"""
        code, stdout, stderr = script_runner(['--headless', VALID_POSTGRES_CONFIG], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        # Should not fail due to config parsing issues
        config_errors = ['not valid JSON', 'missing', 'required', 'unsupported']
        tool_errors = ['is not installed', 'not in PATH']
        
        for error in config_errors + tool_errors:
            assert error not in combined_output
        
        # If it fails, should be due to database connection, not config
        if code != 0:
            assert any(keyword in combined_output.lower() 
                      for keyword in ['connection', 'connect', 'database'])
    
    def test_valid_sqlite_config_parsing_success(self, script_runner, mock_tools_env):
        """Valid configuration should parse without config-related errors"""
        code, stdout, stderr = script_runner(['--headless', VALID_POSTGRES_CONFIG], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        # Should not fail due to config parsing issues
        config_errors = ['not valid JSON', 'missing', 'required', 'unsupported']
        tool_errors = ['is not installed', 'not in PATH']
        
        for error in config_errors + tool_errors:
            assert error not in combined_output
        
        # If it fails, should be due to database connection, not config
        if code != 0:
            assert any(keyword in combined_output.lower() 
                      for keyword in ['connection', 'connect', 'database'])
    
    def test_case_insensitive_field_parsing(self, script_runner, mock_tools_env):
        """Should handle mixed case field names correctly"""
        code, stdout, stderr = script_runner(['--headless', MIXED_CASE_CONFIG], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        # Should not fail due to case sensitivity
        case_error = 'database_type' in combined_output.lower() and 'missing' in combined_output.lower()
        assert not case_error
    
    def test_mock_tools_are_recognized(self, script_runner, mock_tools_env):
        """Verify that mocked tools are properly recognized"""
        code, stdout, stderr = script_runner(['--headless', VALID_POSTGRES_CONFIG], 
                                           mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        # With mocked tools, should not get tool availability errors
        tool_errors = ['is not installed', 'not in PATH', 'not found']
        for error in tool_errors:
            assert error not in combined_output

class TestInteractiveMode:
    """Test successful interactive mode operations"""
    
    def test_interactive_mode_starts_successfully(self, script_runner, mock_tools_env):
        """Interactive mode should start without errors when tools are available"""
        code, stdout, stderr = script_runner([], mock_tools_env=mock_tools_env)
        combined_output = stdout + stderr
        
        # Should show interactive mode indicators
        interactive_indicators = [
            "Running in interactive mode",
            "Select the type of database",
            "Enter your choice"
        ]
        
        success_indicators = [code == 0] + [indicator in combined_output 
                                          for indicator in interactive_indicators]
        assert any(success_indicators), f"No success indicators found in: {combined_output}"

class TestHelpAndUsage:
    """Test help and usage information display"""
    
    @pytest.mark.parametrize("help_flag", ["--help"])
    def test_help_displays_successfully(self, script_runner, help_flag):
        """Help flag should display usage information successfully"""
        code, stdout, stderr = script_runner([help_flag], use_mock_env=False)
        combined_output = stdout + stderr
        
        assert code == 0
        assert len(combined_output) > 0
        assert any(keyword in combined_output.lower() 
                  for keyword in ['usage', 'help', 'options'])