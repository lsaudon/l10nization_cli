import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// L10nVisitor
class BuildContextVisitor extends RecursiveAstVisitor<void> {
  /// L10nVisitor
  BuildContextVisitor({required final String localizationClass})
      : _localizationClass = localizationClass;

  final String _localizationClass;

  /// methodName
  String methodName = '';

  @override
  void visitExtensionDeclaration(final ExtensionDeclaration node) {
    super.visitExtensionDeclaration(node);
    if ((node.extendedType as NamedType).name.name == 'BuildContext') {
      final methodDeclarationList = node.members
          .whereType<MethodDeclaration>()
          .where(
            (final e) =>
                (e.returnType as NamedType?)?.name.name == _localizationClass,
          );
      if (methodDeclarationList.isEmpty) {
        return;
      }
      methodName = methodDeclarationList.first.name.lexeme;
    }
  }
}
