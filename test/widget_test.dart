import 'package:calc_ip/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('mostra o intervalo de 192.168.4.4/24', (tester) async {
    await tester.pumpWidget(const CalculadoraApp());
    expect(tester.takeException(), isNull);
    expect(find.text('Calcular'), findsOneWidget);

    expect(find.text('192.168.4.0'), findsWidgets);
    expect(find.text('192.168.4.255'), findsWidgets);
    expect(find.text('256'), findsWidgets);
    expect(find.text('254 hosts utilizáveis'), findsOneWidget);
    expect(find.text('192.168.4.0/24'), findsWidgets);
  });

  testWidgets('só calcula no botão e o scroll não apaga o campo', (tester) async {
    await tester.pumpWidget(const CalculadoraApp());

    await tester.enterText(find.byType(TextField), '10.1.2.3/8');
    await tester.pump();

    expect(find.text('192.168.4.0'), findsWidgets);
    expect(find.text('10.0.0.0'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    expect(find.text('10.1.2.3/8'), findsOneWidget);

    await tester.tap(find.text('Calcular'));
    await tester.pump();

    expect(find.text('10.0.0.0', skipOffstage: false), findsWidgets);
    expect(find.text('10.255.255.255', skipOffstage: false), findsWidgets);
    expect(find.text('16.777.216', skipOffstage: false), findsWidgets);
  });

  testWidgets('cabe no celular e explica os campos', (tester) async {
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const CalculadoraApp());

    expect(tester.takeException(), isNull);
    expect(find.textContaining('Classe C porque o primeiro número é 192'), findsOneWidget);
    expect(find.textContaining('Privado porque começa com 192.168'), findsOneWidget);
    expect(find.textContaining('3.232.236.548'), findsOneWidget);
    expect(find.textContaining('C0 = 192'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avisa prefixo inválido', (tester) async {
    await tester.pumpWidget(const CalculadoraApp());

    await tester.enterText(find.byType(TextField), '192.168.4.4/33');
    await tester.tap(find.text('Calcular'));
    await tester.pump();

    expect(
      find.text('O prefixo CIDR precisa estar entre 0 e 32.'),
      findsOneWidget,
    );
    expect(find.text('192.168.4.0'), findsNothing);
  });
}
