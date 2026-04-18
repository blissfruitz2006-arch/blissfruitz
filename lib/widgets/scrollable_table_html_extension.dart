import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_html_table/flutter_html_table.dart';

class ScrollableTableHtmlExtension extends TableHtmlExtension {
  const ScrollableTableHtmlExtension();

  @override
  InlineSpan build(ExtensionContext context) {
    final InlineSpan span = super.build(context);
    
    if (context.elementName == "table" && span is WidgetSpan) {
      return WidgetSpan(
        alignment: span.alignment,
        baseline: span.baseline,
        child: LayoutBuilder(
          builder: (buildContext, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: span.child,
              ),
            );
          },
        ),
      );
    }
    return span;
  }
}
