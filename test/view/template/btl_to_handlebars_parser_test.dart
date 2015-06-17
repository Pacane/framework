import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import 'package:bridge/view.dart';
import 'package:bridge/http.dart';

class BtlToHandlebarsParserTest implements TestCase {
  BtlToHandlebarsParser parser;
  Router router;

  setUp() {
    router = new Router();
    parser = new BtlToHandlebarsParser(new UrlGenerator(router));
  }

  tearDown() {
  }

  @test
  it_does_nothing_to_plain_html() async {
    expect(await parser.parse('<div></div>'), equals('<div></div>'));
  }

  @test
  it_can_change_a_variable_in_btl_to_handlebars() async {
    expect(await parser.parse(r'<div>$var</div>'),
    equals('<div>{{ var }}</div>'));
  }

  @test
  it_can_inject_variable_nested_in_map() async {
    expect(await parser.parse(r'<div>${map.key}</div>'), equals('<div>{{ map.key }}</div>'));
  }

  @test
  it_can_replace_iterations_with_handlebars() async {
    expect(await parser.parse(r"<for in=$items>$key</for>"),
    equals('{{# items }}{{ key }}{{/ items }}'));
  }

  @test
  it_can_name_the_repeated_list_item() async {
    expect(await parser.parse(r"<for each=$item in=$items>${item.key}</for>"),
    equals('{{# items }}{{ key }}{{/ items }}'));
  }

  @test
  it_can_escape_a_variable_character() async {
    expect(await parser.parse(r'\$var'), equals(r'$var'));
  }

  @test
  it_has_if_statements() async {
    expect(await parser.parse(r'<if $show>shown</if>'), equals('{{# show }}shown{{/ show }}'));
  }

  @test
  it_can_have_nested_if_statements() async {
    expect(await parser.parse(r'<if $show><if $show2>shown</if></if>'),
    equals('{{# show }}{{# show2 }}shown{{/ show2 }}{{/ show }}'));
  }

  @test
  it_can_use_multiple_functions() async {
    var btl = r'''
<div>
<if $showTitle><h1>$title</h1></if>
<for each=$item in=$items>
  \$wag
  <if ${item.show}>
    // Insert content
    <p>${item.content}</p>
  </if>
</for>
</div>
    '''.trim();

    expect((await parser.parse(btl)).replaceAll(new RegExp(r'\s+'), ' '), equals(
        r'<div> {{# showTitle }}<h1>{{ title }}</h1>{{/ showTitle }} {{# items }} $wag {{# show }} <p>{{ content }}</p> {{/ show }} {{/ items }} </div>'));
  }

  @test
  it_can_have_comments() async {
    expect(await parser.parse('Text// Comment'), equals('Text'));
  }

  @test
  it_knows_when_two_slashes_are_not_a_comment() async {
    expect(await parser.parse('<a href="//notacomment"></a>'), equals('<a href="//notacomment"></a>'));
  }

  @test
  it_can_simulate_form_methods() async {
    var before = "<form method='put'></form>";
    var after = "<form method='POST'><input type='hidden' name='_method' value='PUT'></form>";
    expect(await parser.parse(before), equals(after));
  }

  @test
  it_can_use_route_names_for_form_actions() async {
    router.get('/', () => '', name: 'home');
    var before = "<form route='home'>";
    var after = "<form action='/'>";
    expect(await parser.parse(before), equals(after));
  }
}
