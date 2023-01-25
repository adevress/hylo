import Core
import FrontEnd
import XCTest

final class ASTTests: XCTestCase {

  func testAppendModule() throws {
    var ast = AST()
    var diagnostics = Diagnostics()
    let i = ast.insert(ModuleDecl(name: "Val"), diagnostics: &diagnostics)
    XCTAssert(ast.modules.contains(i))
    XCTAssert(diagnostics.log.isEmpty)
    let j = ast.insert(synthesized: ModuleDecl(name: "Val1"))
    XCTAssert(ast.modules.contains(j))
  }

  func testDeclAccess() throws {
    var ast = AST()

    // Create a module declarations.
    let input = SourceFile(synthesizedText: "")
    let site = input.range(input.text.startIndex ..< input.text.endIndex)
    let module = ast.insert(synthesized: ModuleDecl(name: "Val"))

    // Create a trait declaration.
    let decl = ast.insert(
      synthesized: ImportDecl(
        introducerSite: site,
        identifier: SourceRepresentable(value: "T", range: site),
        site: site))

    // Create a source declaration set.
    let source = ast.insert(synthesized: TopLevelDeclSet(decls: [AnyDeclID(decl)], site: site))
    ast[module].addSourceFile(source)

    // Subscript the AST for reading with a type-erased ID.
    XCTAssert(ast[ast[ast[module].sources.first!].decls.first!] is ImportDecl)
  }

  func testCodableRoundtrip() throws {
    var ast = AST()

    // Create a module.
    let input = SourceFile(synthesizedText: "")
    let site = input.range(input.text.startIndex ..< input.text.endIndex)
    let module = ast.insert(synthesized: ModuleDecl(name: "Val"))

    let source = ast.insert(
      synthesized: TopLevelDeclSet(
        decls: [
          AnyDeclID(
            ast.insert(
              synthesized: FunctionDecl(
                introducerSite: site,
                identifier: SourceRepresentable(value: "foo", range: site),
                site: site)))
        ],
        site: site))
    ast[module].addSourceFile(source)

    // Serialize the AST.
    let encoder = JSONEncoder()
    let serialized = try encoder.encode(ast)

    // Deserialize the AST.
    let decoder = JSONDecoder()
    let deserialized = try decoder.decode(AST.self, from: serialized)

    // Deserialized AST should containt a function `foo`.
    XCTAssertEqual(deserialized[source].decls.first?.kind, NodeKind(FunctionDecl.self))
  }

}
