require 'test_helper'
require 'tempfile'

class AcceptanceControllerTest < ActionController::TestCase
  def test_parse_html
    # Create a test html file
    html=<<END_HTML
<html>
<head>
  <title>Test HTML File</title>
</head>
<body>
  <h1>Test HTML File Header</h1>
  <table>
    <tr><th>one</th><th>two</th><th>three</th></tr>
    <tr><td>one-r1</td><td>two-r1</td><td>three-r1</td></tr>
    <tr><td>one-r2</td>
    <td>two-r2</td><td>three-r2</td></tr>
<!-- this is a comment -->
    <tr><td>one-r3</td>
    <td></td><td>three-r3</td></tr>

  </table>
</body>
END_HTML
    file = Tempfile.new('test_parse_html')
    file.puts(html)
    file.close
    
    commands = AcceptanceController.parse_html(file.path)
    assert_equal(4, commands.size)
    command_1 = commands[0]
    assert_equal(4, command_1.size)
    assert_equal(' ', command_1[0])
    assert_equal('one-r1', command_1[1])
    assert_equal('two-r1', command_1[2])
    assert_equal('three-r1', command_1[3])
    command_2 = commands[1]
    assert_equal(4, command_2.size)
    assert_equal(' ', command_2[0])
    assert_equal('one-r2', command_2[1])
    assert_equal('two-r2', command_2[2])
    assert_equal('three-r2', command_2[3])
    command_3 = commands[2]
    assert_equal(3, command_3.size)
    assert_equal('comment', command_3[0])
    assert_equal(' ', command_3[1])
    assert_equal('this is a comment', command_3[2])
    command_4 = commands[3]
    assert_equal(3, command_4.size)
    assert_equal(' ', command_4[0])
    assert_equal('one-r3', command_4[1])
    assert_equal('three-r3', command_4[2])
    assert true
  end # test_parse_html

  def test_parse_selenese
    # Create a test html file
    sel=<<END_SEL
| one-r1 | two-r1 | three-r1 |
| one-r2 | two-r2 | three-r2 |
#this is a comment
| one-r3 | | three-r3 |
#this is a comment at the end
END_SEL
    sel_file = Tempfile.new('test_parse_selenese')
    sel_file.puts(sel)
    sel_file.close

    commands = AcceptanceController.parse_selenese(sel_file.path)
    assert_equal(5, commands.size)
    command_1 = commands[0]
    assert_equal(4, command_1.size)
    assert_equal(1, command_1[0])
    assert_equal('one-r1', command_1[1])
    assert_equal('two-r1', command_1[2])
    assert_equal('three-r1', command_1[3])
    command_2 = commands[1]
    assert_equal(4, command_2.size)
    assert_equal(2, command_2[0])
    assert_equal('one-r2', command_2[1])
    assert_equal('two-r2', command_2[2])
    assert_equal('three-r2', command_2[3])
    command_3 = commands[2]
    assert_equal(3, command_3.size)
    assert_equal('comment', command_3[0])
    assert_equal(3, command_3[1])
    assert_equal("this is a comment\n", command_3[2])
    command_4 = commands[3]
    assert_equal(3, command_4.size)
    assert_equal(4, command_4[0])
    assert_equal('one-r3', command_4[1])
    assert_equal('three-r3', command_4[2])
    command_5 = commands[4]
    assert_equal(3, command_5.size)
    assert_equal('comment', command_5[0])
    assert_equal(5, command_5[1])
    assert_equal("this is a comment at the end\n", command_5[2])
    assert true
  end # test parse_selenese
end
