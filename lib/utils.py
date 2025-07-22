def check_tool(tool_name, custom_error_msg=None):
    """Check if a tool exists"""
    import os
    
    if not shutil.which(tool_name):
        if custom_error_msg:
            error(custom_error_msg)
        error(f"{tool_name} is not installed or not in PATH")
    
    return

def error(message):
    """Print error message and exit"""
    print(f"Error: {message}", file=sys.stderr)
    sys.exit(1)