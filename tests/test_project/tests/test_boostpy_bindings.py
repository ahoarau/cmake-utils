import test_project_bp

def test_bp_brackets():
    ret = test_project_bp.StringUtils().brackets("HelloWorld!")
    assert ret == "[HelloWorld!]"
