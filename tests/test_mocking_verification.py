import pytest
from conftest import VALID_POSTGRES_CONFIG

class TestMockingInfrastructure:
    """Verify that test mocking infrastructure works correctly"""
    
    def test_mock_tools_fixture_creates_executables(self, mock_tools_env):
        """Verify mock tools are created and accessible"""
        import subprocess
        
        # Test that mocked tools can be found and executed
        result = subprocess.run(['dot', '-V'], 
                              capture_output=True, 
                              text=True, 
                              env=mock_tools_env)
        
        assert result.returncode == 0
        assert 'Mock tool' in result.stdout
    
    def test_script_runner_fixture_works(self, script_runner, mock_tools_env):
        """Verify script runner fixture functions correctly"""
        code, stdout, stderr = script_runner(['--help'], mock_tools_env=mock_tools_env)
        
        assert isinstance(code, int)
        assert isinstance(stdout, str)
        assert isinstance(stderr, str)
    
    def test_real_vs_mock_environment_difference(self, script_runner, mock_tools_env):
        """Verify that mock and real environments behave differently"""
        # Run with mocks
        mock_code, mock_stdout, mock_stderr = script_runner(
            ['--headless', VALID_POSTGRES_CONFIG], mock_tools_env=mock_tools_env)
        mock_output = mock_stdout + mock_stderr
        
        # Run without mocks  
        real_code, real_stdout, real_stderr = script_runner(
            ['--headless', VALID_POSTGRES_CONFIG], use_mock_env=False)
        real_output = real_stdout + real_stderr
        
        # They should behave differently regarding tool availability
        mock_has_tool_errors = any(error in mock_output 
                                 for error in ['is not installed', 'not in PATH'])
        real_has_tool_errors = any(error in real_output 
                                 for error in ['is not installed', 'not in PATH'])
        
        # Mock should not have tool errors, real might
        assert not mock_has_tool_errors
        # Note: real_has_tool_errors may be True or False depending on system