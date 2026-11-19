import 'package:calc_ip/subnet_calculator.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const CalculadoraApp());
}

bool _isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < 600;

class CalculadoraApp extends StatelessWidget {
  const CalculadoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de sub-rede',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5B8CFF),
          brightness: Brightness.dark,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const CalculadoraPage(),
    );
  }
}

class CalculadoraPage extends StatefulWidget {
  const CalculadoraPage({super.key});

  @override
  State<CalculadoraPage> createState() => _CalculadoraPageState();
}

class _CalculadoraPageState extends State<CalculadoraPage> {
  static const _prefixes = [8, 16, 24, 25, 26, 27, 28, 30, 31, 32];
  static const _examples = [
    '192.168.4.4/24',
    '10.0.0.5/8',
    '172.16.8.1/12',
    '8.8.8.8/32',
  ];

  late final TextEditingController _controller;
  SubnetInfo? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '192.168.4.4/24');
    _result = SubnetInfo.parse(_controller.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calcular() {
    FocusScope.of(context).unfocus();
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _result = null;
        _error = 'Informe um IP com prefixo, por exemplo 192.168.4.4/24.';
      });
      return;
    }

    try {
      final info = SubnetInfo.parse(text);
      setState(() {
        _result = info;
        _error = null;
      });
    } on FormatException catch (error) {
      setState(() {
        _result = null;
        _error = error.message;
      });
    }
  }

  void _apply(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  void _applyPrefix(int prefix) {
    final current = _controller.text.trim();
    final ip = current.split('/').first.trim();
    final base = ip.isEmpty ? '192.168.0.1' : ip;
    _apply('$base/$prefix');
  }

  Future<void> _copy(SubnetInfo info) async {
    await Clipboard.setData(ClipboardData(text: info.summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resultado copiado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final compact = _isCompact(context);

    final horizontal = compact ? 16.0 : 20.0;
    final draft = _controller.text.trim();
    final draftPrefix = int.tryParse(
      draft.contains('/') ? draft.split('/').last : '',
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: ColoredBox(
        color: const Color(0xFF10182C),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 12),
            child: FilledButton.icon(
              onPressed: _calcular,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3D7EFF),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.calculate_outlined, size: 20),
              label: const Text('Calcular'),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontal,
                    compact ? 12 : 20,
                    horizontal,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculadora de sub-rede',
                        style: TextStyle(
                          fontSize: compact ? 22 : 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.15,
                          color: const Color(0xFFF4F7FB),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _IpField(
                        controller: _controller,
                        compact: compact,
                        onSubmit: _calcular,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFFF8D7A),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 32),
                    children: [
                      Text(
                        'O /24 é o prefixo CIDR. Ele reserva 24 bits para a rede '
                        'e deixa 8 para o intervalo. Também aceita máscara decimal, '
                        'como 192.168.4.4/255.255.255.0.',
                        style: TextStyle(
                          fontSize: compact ? 13.5 : 14.5,
                          height: 1.45,
                          color: const Color(0xFF93A0B8),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Prefixo',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF7E8BA3),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final prefix in _prefixes)
                            _Choice(
                              label: '/$prefix',
                              selected: draftPrefix == prefix,
                              onTap: () => _applyPrefix(prefix),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final example in _examples)
                            _Choice(
                              label: example,
                              selected: draft == example,
                              onTap: () => _apply(example),
                            ),
                        ],
                      ),
                      if (result != null) ...[
                  const SizedBox(height: 16),
                  _Summary(info: result),
                  const SizedBox(height: 16),
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BitBar(prefix: result.prefix),
                        const SizedBox(height: 8),
                        Text(
                          '${result.networkBits} bits de rede  ·  '
                          '${result.hostBits} bits de host',
                          style: const TextStyle(
                            color: Color(0xFF93A0B8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          result.note,
                          style: const TextStyle(
                            color: Color(0xFFC5D0E2),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Details(info: result),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: compact ? double.infinity : null,
                    child: FilledButton.icon(
                      onPressed: () => _copy(result),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar resultado'),
                    ),
                  ),
                ] else if (_error == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 28),
                          child: Text(
                            'Toque em Calcular para ver o intervalo.',
                            style: TextStyle(color: Color(0xFF93A0B8)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IpField extends StatelessWidget {
  const _IpField({
    required this.controller,
    required this.compact,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool compact;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('ip-field'),
      controller: controller,
      style: TextStyle(
        fontSize: compact ? 18 : 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Consolas',
        fontFamilyFallback: const ['Cascadia Mono', 'Courier New'],
      ),
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) => onSubmit(),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9./]')),
      ],
      decoration: InputDecoration(
        hintText: '192.168.4.4/24',
        prefixIcon: const Icon(Icons.lan_outlined),
        filled: true,
        fillColor: const Color(0xFF0E1528),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 14 : 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A3654)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2A3654)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF5B8CFF), width: 1.6),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.info});

  final SubnetInfo info;

  @override
  Widget build(BuildContext context) {
    final compact = _isCompact(context);
    final cards = [
      _Stat(
        label: 'Primeiro IP',
        value: info.network,
        caption: 'Endereço de rede',
        color: const Color(0xFF7DFFC3),
      ),
      _Stat(
        label: 'Último IP',
        value: info.broadcast,
        caption: info.pointToPoint ? 'Fim do intervalo' : 'Broadcast',
        color: const Color(0xFFFFB089),
      ),
      _Stat(
        label: 'No intervalo',
        value: formatCount(info.totalAddresses),
        caption: info.pointToPoint
            ? '${formatCount(info.usableHosts)} utilizáveis'
            : '${formatCount(info.usableHosts)} hosts utilizáveis',
        color: const Color(0xFF9EBEFF),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          info.networkCidr,
          style: TextStyle(
            fontSize: compact ? 22 : 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            fontFamily: 'Consolas',
            fontFamilyFallback: const ['Cascadia Mono', 'Courier New'],
            color: const Color(0xFFF4F7FB),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bloco de ${info.blockFormula}',
          style: const TextStyle(color: Color(0xFF93A0B8), fontSize: 14),
        ),
        const SizedBox(height: 14),
        if (compact)
          _Panel(
            child: Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const _Hairline(),
                  cards[i],
                ],
              ],
            ),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _Panel(child: cards[i])),
              ],
            ],
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.caption,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final compact = _isCompact(context);
    final valueStyle = TextStyle(
      fontSize: compact ? 18 : 20,
      fontWeight: FontWeight.w700,
      color: const Color(0xFFF4F7FB),
      fontFamily: 'Consolas',
      fontFamilyFallback: const ['Cascadia Mono', 'Courier New'],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption,
                    style: const TextStyle(
                      color: Color(0xFF93A0B8),
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: SelectableText(
                value,
                textAlign: TextAlign.right,
                style: valueStyle,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        SelectableText(value, style: valueStyle),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(color: Color(0xFF93A0B8), fontSize: 13),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.info});

  final SubnetInfo info;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final hosts = _Panel(
          child: _Lines(
            title: 'Hosts',
            rows: [
              _Row(
                'Primeiro utilizável',
                info.firstUsable,
                help: info.firstUsableHelp,
              ),
              _Row(
                'Último utilizável',
                info.lastUsable,
                help: info.lastUsableHelp,
              ),
              _Row(
                'Hosts utilizáveis',
                formatCount(info.usableHosts),
                help: info.usableHelp,
              ),
              _Row(
                'Endereços totais',
                formatCount(info.totalAddresses),
                help: info.totalHelp,
              ),
            ],
          ),
        );
        final masks = _Panel(
          child: _Lines(
            title: 'Máscaras',
            rows: [
              _Row('Máscara de sub-rede', info.mask, help: info.maskHelp),
              _Row('Máscara wildcard', info.wildcard, help: info.wildcardHelp),
              _Row('CIDR da rede', info.networkCidr, help: info.cidrHelp),
              _Row(
                'IP informado',
                '${info.address}/${info.prefix}',
                help: info.informedHelp,
              ),
            ],
          ),
        );
        final identity = _Panel(
          child: _Lines(
            title: 'Endereço',
            rows: [
              _Row('Classe', info.ipClass, mono: false, help: info.classHelp),
              _Row('Tipo', info.addressType, mono: false, help: info.typeHelp),
              _Row('Inteiro', '${info.ipInteger}', help: info.integerHelp),
              _Row('Hexadecimal', info.ipHex, help: info.hexHelp),
            ],
          ),
        );
        final binary = _Panel(
          child: _BinaryBlock(
            rows: [
              (label: 'IP', value: info.ipBinary, help: info.binaryIpHelp),
              (
                label: 'Máscara',
                value: info.maskBinary,
                help: info.binaryMaskHelp,
              ),
              (
                label: 'Rede',
                value: info.networkBinary,
                help: info.binaryNetworkHelp,
              ),
            ],
          ),
        );

        if (constraints.maxWidth < 840) {
          return Column(
            children: [
              hosts,
              const SizedBox(height: 12),
              masks,
              const SizedBox(height: 12),
              identity,
              const SizedBox(height: 12),
              binary,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: hosts),
                const SizedBox(width: 12),
                Expanded(child: masks),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identity),
                const SizedBox(width: 12),
                Expanded(child: binary),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines({required this.title, required this.rows});

  final String title;
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB7C3D7),
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const _Hairline(),
          rows[i],
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.mono = true, required this.help});

  final String label;
  final String value;
  final String help;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final compact = _isCompact(context);
    final valueStyle = TextStyle(
      color: const Color(0xFFF4F7FB),
      fontSize: compact ? 16 : 15,
      fontWeight: FontWeight.w600,
      height: 1.35,
      fontFamily: mono ? 'Consolas' : null,
      fontFamilyFallback: mono ? const ['Cascadia Mono', 'Courier New'] : null,
    );

    final valueText = SelectableText(
      value,
      textAlign: compact ? TextAlign.left : TextAlign.right,
      style: valueStyle,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (compact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF93A0B8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                valueText,
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF93A0B8),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(child: valueText),
              ],
            ),
          const SizedBox(height: 4),
          Text(
            help,
            style: const TextStyle(
              color: Color(0xFF8B97AB),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BinaryBlock extends StatelessWidget {
  const _BinaryBlock({required this.rows});

  final List<({String label, String value, String help})> rows;

  @override
  Widget build(BuildContext context) {
    final mono = TextStyle(
      color: const Color(0xFFF4F7FB),
      fontSize: _isCompact(context) ? 13 : 14,
      fontWeight: FontWeight.w600,
      fontFamily: 'Consolas',
      fontFamilyFallback: const ['Cascadia Mono', 'Courier New'],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Binário',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB7C3D7),
          ),
        ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const _Hairline(),
          if (i == 0) const SizedBox(height: 12),
          Text(
            rows[i].label,
            style: const TextStyle(color: Color(0xFF93A0B8), fontSize: 13),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: [
              for (final octet in rows[i].value.split('.'))
                SelectableText(octet, style: mono),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            rows[i].help,
            style: const TextStyle(
              color: Color(0xFF8B97AB),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _BitBar extends StatelessWidget {
  const _BitBar({required this.prefix});

  final int prefix;

  @override
  Widget build(BuildContext context) {
    final gap = _isCompact(context) ? 2.0 : 3.0;
    return Row(
      children: [
        for (var i = 0; i < 32; i++)
          Expanded(
            child: Container(
              height: 10,
              margin: EdgeInsets.only(right: i == 31 ? 0 : gap),
              decoration: BoxDecoration(
                color: i < prefix
                    ? const Color(0xFF5B8CFF)
                    : const Color(0xFF2C3548),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 12),
      child: Divider(height: 1, thickness: 1, color: Color(0xFF243049)),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF243864) : const Color(0xFF12192B),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF5B8CFF)
                  : const Color(0xFF2A3654),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? const Color(0xFFE7EEFF)
                  : const Color(0xFFC5D0E2),
              fontFamily: label.contains('.') ? 'Consolas' : null,
              fontFamilyFallback: label.contains('.')
                  ? const ['Cascadia Mono', 'Courier New']
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF141A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF243049)),
      ),
      child: Padding(
        padding: EdgeInsets.all(_isCompact(context) ? 14 : 16),
        child: child,
      ),
    );
  }
}
