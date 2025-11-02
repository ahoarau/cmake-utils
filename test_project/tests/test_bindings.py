import test_project

def test_brackets():
    ret = test_project.StringUtils().brackets("HelloWorld!")
    assert ret == "[HelloWorld!]"
