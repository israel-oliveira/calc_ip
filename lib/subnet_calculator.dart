/// Cálculo de sub-rede IPv4 a partir de um IP e um prefixo CIDR.
///
/// Aceita `192.168.4.4/24` ou máscara decimal `192.168.4.4/255.255.255.0`.
class SubnetInfo {
  const SubnetInfo({
    required this.address,
    required this.prefix,
    required this.network,
    required this.broadcast,
    required this.firstUsable,
    required this.lastUsable,
    required this.mask,
    required this.wildcard,
    required this.totalAddresses,
    required this.usableHosts,
    required this.ipClass,
    required this.addressType,
    required this.ipBinary,
    required this.maskBinary,
    required this.networkBinary,
    required this.ipInteger,
    required this.ipHex,
  });

  /// IP informado, sem o prefixo.
  final String address;

  /// Prefixo CIDR, de 0 a 32.
  final int prefix;

  /// Primeiro endereço do intervalo (endereço de rede).
  final String network;

  /// Último endereço do intervalo (broadcast).
  final String broadcast;

  final String firstUsable;
  final String lastUsable;
  final String mask;
  final String wildcard;
  final int totalAddresses;
  final int usableHosts;
  final String ipClass;
  final String addressType;
  final String ipBinary;
  final String maskBinary;
  final String networkBinary;
  final int ipInteger;
  final String ipHex;

  int get hostBits => 32 - prefix;

  int get networkBits => prefix;

  String get networkCidr => '$network/$prefix';

  /// Em /31 e /32 não há endereço reservado de rede nem de broadcast.
  bool get pointToPoint => prefix >= 31;

  String get blockFormula => '2^$hostBits = ${formatCount(totalAddresses)}';

  String get note {
    if (prefix == 32) {
      return 'Prefixo /32: o intervalo tem um único endereço, o próprio host.';
    }
    if (prefix == 31) {
      return 'Prefixo /31 (RFC 3021): os dois endereços são utilizáveis. '
          'É o caso típico de um enlace ponto a ponto.';
    }
    return 'O primeiro endereço é a rede e o último é o broadcast. '
        'Os dois ficam de fora da faixa de hosts utilizáveis.';
  }

  String get networkHelp => pointToPoint
      ? 'Começo do intervalo. Em /$prefix as duas pontas também podem ser usadas.'
      : 'Início do bloco. Esse endereço dá nome à rede e não vai para um equipamento.';

  String get broadcastHelp => pointToPoint
      ? 'Fim do intervalo. Em /$prefix esse endereço também pode ser usado.'
      : 'Broadcast. Um pacote enviado para cá chega em todos os equipamentos da rede.';

  String get totalHelp =>
      'Tamanho do bloco, somando rede e broadcast. $blockFormula.';

  String get firstUsableHelp => pointToPoint
      ? 'Neste prefixo o primeiro endereço também pode ir para um equipamento.'
      : 'Primeiro IP que pode ser configurado num computador, impressora ou roteador.';

  String get lastUsableHelp => pointToPoint
      ? 'Neste prefixo o último endereço também pode ir para um equipamento.'
      : 'Último IP que pode ser configurado num equipamento dessa rede.';

  String get usableHelp => pointToPoint
      ? 'Em /$prefix todos os endereços do intervalo podem ser usados.'
      : 'O total menos 2. Saem o endereço de rede e o broadcast.';

  String get maskHelp =>
      'O /$prefix escrito em decimal. 255 trava o número; 0 deixa o número variar.';

  String get wildcardHelp =>
      'A máscara ao contrário: 0 é bit fixo e 255 é bit livre. Aparece em ACL e em alguns filtros.';

  String get cidrHelp =>
      'Nome do bloco. Todo IP de $network até $broadcast pertence a $networkCidr.';

  String get informedHelp =>
      'O IP que você digitou. A rede é calculada a partir dele e do /$prefix.';

  String get classHelp {
    final first = int.parse(address.split('.').first);
    final range = switch (ipClass) {
      'A' => 'de 0 a 127. Era a classe das redes enormes, hoje um /8',
      'B' => 'de 128 a 191. Era a classe das redes médias, hoje um /16',
      'C' => 'de 192 a 223. Era a classe das redes pequenas, hoje um /24',
      'D' => 'de 224 a 239. Essa classe é multicast: um envio para um grupo',
      'E' => 'de 240 a 255. Essa faixa fica reservada',
      _ => '',
    };
    return 'Classe $ipClass porque o primeiro número é $first, e essa classe vai $range.';
  }

  String get typeHelp {
    final parts = address.split('.');
    final first = int.parse(parts[0]);
    final second = int.parse(parts[1]);
    if (first == 10) {
      return 'Privado porque começa com 10. De 10.0.0.0 a 10.255.255.255 '
          'a faixa fica na rede local.';
    }
    if (first == 172 && second >= 16 && second <= 31) {
      return 'Privado porque 172.$second está entre 172.16 e 172.31. '
          'Essa faixa fica na rede local.';
    }
    if (first == 192 && second == 168) {
      return 'Privado porque começa com 192.168. De 192.168.0.0 a '
          '192.168.255.255 a faixa fica na rede local, como a da sua casa.';
    }
    return switch (addressType) {
      'Público' =>
        'Público porque $address está fora das faixas reservadas. '
            'Esse endereço pode aparecer na internet.',
      'Loopback' =>
        'Loopback porque começa com 127. É o próprio computador falando com ele mesmo.',
      'Link-local (APIPA)' =>
        'Link-local porque começa com 169.254. O aparelho escolheu esse IP sozinho, sem DHCP.',
      'CGNAT (RFC 6598)' =>
        'CGNAT porque cai entre 100.64 e 100.127. O provedor compartilha a internet nessa faixa.',
      'Multicast' =>
        'Multicast porque o primeiro número está entre 224 e 239. '
            'O pacote vai para um grupo, não para um único host.',
      'Reservado' =>
        'Reservado porque o primeiro número é $first, entre 240 e 255. '
            'Essa faixa não é usada em hosts.',
      'Broadcast limitado' =>
        '255.255.255.255 é o broadcast da rede local em que o pacote está.',
      'Este host' =>
        '0.0.0.0 significa este host enquanto ele ainda não tem um endereço definido.',
      'Rede atual' =>
        'Começa com 0. Essa faixa aponta para a rede atual.',
      _ => addressType,
    };
  }

  String get integerHelp {
    final parts = address.split('.').map(int.parse).toList();
    return '${parts[0]}×16.777.216 + ${parts[1]}×65.536 + '
        '${parts[2]}×256 + ${parts[3]} = ${formatCount(ipInteger)}. '
        'Os quatro números ocupam 8 bits cada e, juntos, viram um número só.';
  }

  String get hexHelp {
    final parts = address.split('.').map(int.parse).toList();
    final pairs = [
      for (final part in parts)
        part.toRadixString(16).padLeft(2, '0').toUpperCase(),
    ];
    return 'O mesmo inteiro na base 16, a forma comum em código e log. '
        'Cada par é um número do IP: '
        '${pairs[0]} = ${parts[0]}, ${pairs[1]} = ${parts[1]}, '
        '${pairs[2]} = ${parts[2]}, ${pairs[3]} = ${parts[3]}.';
  }

  String get binaryIpHelp =>
      'Os 32 bits do IP. Cada grupo de 8 bits é um dos quatro números.';

  String get binaryMaskHelp =>
      'Bit 1 é a parte da rede, que fica fixa. Bit 0 é a parte que muda entre os hosts.';

  String get binaryNetworkHelp =>
      'O IP com a parte do host zerada. Por isso coincide com o primeiro endereço.';

  String get summary {
    return [
      'IP informado: $address/$prefix',
      'Rede (primeiro IP): $network',
      'Broadcast (último IP): $broadcast',
      'Endereços no intervalo: ${formatCount(totalAddresses)}',
      'Primeiro host: $firstUsable',
      'Último host: $lastUsable',
      'Hosts utilizáveis: ${formatCount(usableHosts)}',
      'Máscara: $mask',
      'Wildcard: $wildcard',
      'CIDR da rede: $networkCidr',
      'Classe: $ipClass',
      'Tipo: $addressType',
      'IP em inteiro: $ipInteger',
      'IP em hexadecimal: $ipHex',
      'Binário do IP: $ipBinary',
      'Binário da máscara: $maskBinary',
      'Binário da rede: $networkBinary',
    ].join('\n');
  }

  static SubnetInfo parse(String input) {
    final raw = input.replaceAll(RegExp(r'\s+'), '');
    if (raw.isEmpty) {
      throw const FormatException(
        'Informe um IP com prefixo, por exemplo 192.168.4.4/24.',
      );
    }

    final cidr = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/(\d{1,2})$',
    ).firstMatch(raw);
    final dotted = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/'
      r'(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
    ).firstMatch(raw);

    if (cidr == null && dotted == null) {
      throw const FormatException(
        'Use o formato 192.168.4.4/24 ou 192.168.4.4/255.255.255.0.',
      );
    }

    final match = (cidr ?? dotted)!;
    final octets = List<int>.generate(4, (i) => int.parse(match.group(i + 1)!));
    if (octets.any((octet) => octet > 255)) {
      throw const FormatException('Cada octeto do IP precisa estar entre 0 e 255.');
    }

    final int prefix;
    if (cidr != null) {
      prefix = int.parse(match.group(5)!);
      if (prefix > 32) {
        throw const FormatException('O prefixo CIDR precisa estar entre 0 e 32.');
      }
    } else {
      final maskOctets = List<int>.generate(
        4,
        (i) => int.parse(match.group(i + 5)!),
      );
      if (maskOctets.any((octet) => octet > 255)) {
        throw const FormatException(
          'Cada octeto da máscara precisa estar entre 0 e 255.',
        );
      }
      final parsed = _prefixFromMask(_pack(maskOctets));
      if (parsed == null) {
        throw const FormatException(
          'Máscara inválida. Os bits 1 precisam ser contíguos, como em 255.255.255.0.',
        );
      }
      prefix = parsed;
    }

    final ip = _pack(octets);
    final mask = _maskFromPrefix(prefix);
    final network = ip & mask;
    final broadcast = network | ((~mask) & 0xFFFFFFFF);
    final total = 1 << (32 - prefix);

    final int firstUsable;
    final int lastUsable;
    final int usable;
    if (prefix >= 31) {
      firstUsable = network;
      lastUsable = broadcast;
      usable = total;
    } else {
      firstUsable = network + 1;
      lastUsable = broadcast - 1;
      usable = total - 2;
    }

    return SubnetInfo(
      address: _formatIp(ip),
      prefix: prefix,
      network: _formatIp(network),
      broadcast: _formatIp(broadcast),
      firstUsable: _formatIp(firstUsable),
      lastUsable: _formatIp(lastUsable),
      mask: _formatIp(mask),
      wildcard: _formatIp((~mask) & 0xFFFFFFFF),
      totalAddresses: total,
      usableHosts: usable,
      ipClass: _ipClass(ip),
      addressType: _addressType(ip),
      ipBinary: _binary(ip),
      maskBinary: _binary(mask),
      networkBinary: _binary(network),
      ipInteger: ip,
      ipHex: '0x${ip.toRadixString(16).padLeft(8, '0').toUpperCase()}',
    );
  }
}

int _pack(List<int> octets) {
  return (octets[0] << 24) | (octets[1] << 16) | (octets[2] << 8) | octets[3];
}

int _maskFromPrefix(int prefix) {
  if (prefix == 0) return 0;
  return (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
}

int? _prefixFromMask(int mask) {
  var bits = 0;
  var seenZero = false;
  for (var shift = 31; shift >= 0; shift--) {
    final bit = (mask >> shift) & 1;
    if (bit == 1) {
      if (seenZero) return null;
      bits++;
    } else {
      seenZero = true;
    }
  }
  return bits;
}

String _formatIp(int ip) {
  return '${(ip >> 24) & 0xFF}.'
      '${(ip >> 16) & 0xFF}.'
      '${(ip >> 8) & 0xFF}.'
      '${ip & 0xFF}';
}

String _binary(int ip) {
  final parts = <String>[];
  for (var shift = 24; shift >= 0; shift -= 8) {
    parts.add(((ip >> shift) & 0xFF).toRadixString(2).padLeft(8, '0'));
  }
  return parts.join('.');
}

String _ipClass(int ip) {
  final first = (ip >> 24) & 0xFF;
  if (first < 128) return 'A';
  if (first < 192) return 'B';
  if (first < 224) return 'C';
  if (first < 240) return 'D';
  return 'E';
}

String _addressType(int ip) {
  final first = (ip >> 24) & 0xFF;
  final second = (ip >> 16) & 0xFF;
  if (ip == 0xFFFFFFFF) return 'Broadcast limitado';
  if (ip == 0) return 'Este host';
  if (first == 127) return 'Loopback';
  if (first == 10) return 'Privado (RFC 1918)';
  if (first == 172 && second >= 16 && second <= 31) return 'Privado (RFC 1918)';
  if (first == 192 && second == 168) return 'Privado (RFC 1918)';
  if (first == 169 && second == 254) return 'Link-local (APIPA)';
  if (first == 100 && second >= 64 && second <= 127) return 'CGNAT (RFC 6598)';
  if (first >= 224 && first <= 239) return 'Multicast';
  if (first >= 240) return 'Reservado';
  if (first == 0) return 'Rede atual';
  return 'Público';
}

String formatCount(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
