import 'package:calc_ip/subnet_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('192.168.4.4/24', () {
    final info = SubnetInfo.parse('192.168.4.4/24');

    expect(info.network, '192.168.4.0');
    expect(info.broadcast, '192.168.4.255');
    expect(info.firstUsable, '192.168.4.1');
    expect(info.lastUsable, '192.168.4.254');
    expect(info.totalAddresses, 256);
    expect(info.usableHosts, 254);
    expect(info.mask, '255.255.255.0');
    expect(info.wildcard, '0.0.0.255');
    expect(info.networkCidr, '192.168.4.0/24');
    expect(info.ipClass, 'C');
    expect(info.addressType, 'Privado (RFC 1918)');
    expect(info.hostBits, 8);
    expect(info.ipHex, '0xC0A80404');
  });

  test('aceita espaços e máscara decimal', () {
    final info = SubnetInfo.parse(' 192.168.4.4 / 255.255.255.0 ');

    expect(info.prefix, 24);
    expect(info.network, '192.168.4.0');
    expect(info.broadcast, '192.168.4.255');
  });

  test('10.0.0.1/8', () {
    final info = SubnetInfo.parse('10.0.0.1/8');

    expect(info.network, '10.0.0.0');
    expect(info.broadcast, '10.255.255.255');
    expect(info.totalAddresses, 16777216);
    expect(info.usableHosts, 16777214);
    expect(info.mask, '255.0.0.0');
    expect(formatCount(info.totalAddresses), '16.777.216');
  });

  test('172.16.5.10/12', () {
    final info = SubnetInfo.parse('172.16.5.10/12');

    expect(info.network, '172.16.0.0');
    expect(info.broadcast, '172.31.255.255');
    expect(info.mask, '255.240.0.0');
    expect(info.addressType, 'Privado (RFC 1918)');
  });

  test('/25 a partir de máscara', () {
    final info = SubnetInfo.parse('192.168.0.200/255.255.255.128');

    expect(info.prefix, 25);
    expect(info.network, '192.168.0.128');
    expect(info.broadcast, '192.168.0.255');
    expect(info.totalAddresses, 128);
    expect(info.usableHosts, 126);
  });

  test('/32 é um único host', () {
    final info = SubnetInfo.parse('8.8.8.8/32');

    expect(info.network, '8.8.8.8');
    expect(info.broadcast, '8.8.8.8');
    expect(info.totalAddresses, 1);
    expect(info.usableHosts, 1);
    expect(info.addressType, 'Público');
    expect(info.ipClass, 'A');
  });

  test('/31 usa os dois endereços', () {
    final info = SubnetInfo.parse('10.0.0.0/31');

    expect(info.network, '10.0.0.0');
    expect(info.broadcast, '10.0.0.1');
    expect(info.firstUsable, '10.0.0.0');
    expect(info.lastUsable, '10.0.0.1');
    expect(info.usableHosts, 2);
  });

  test('/0 cobre todo o IPv4', () {
    final info = SubnetInfo.parse('1.2.3.4/0');

    expect(info.network, '0.0.0.0');
    expect(info.broadcast, '255.255.255.255');
    expect(info.totalAddresses, 4294967296);
    expect(info.mask, '0.0.0.0');
    expect(info.wildcard, '255.255.255.255');
  });

  test('explica classe, tipo, inteiro e hexadecimal', () {
    final info = SubnetInfo.parse('192.168.4.4/24');

    expect(info.classHelp, contains('primeiro número é 192'));
    expect(info.classHelp, contains('192 a 223'));
    expect(info.typeHelp, contains('192.168'));
    expect(info.integerHelp, contains('3.232.236.548'));
    expect(info.hexHelp, contains('C0 = 192'));
    expect(info.hexHelp, contains('A8 = 168'));
  });

  test('rejeita prefixo, octeto e máscara furada', () {
    expect(() => SubnetInfo.parse('192.168.4.4/33'), throwsFormatException);
    expect(() => SubnetInfo.parse('192.168.4.256/24'), throwsFormatException);
    expect(
      () => SubnetInfo.parse('192.168.4.4/255.0.255.0'),
      throwsFormatException,
    );
    expect(() => SubnetInfo.parse('192.168.4.4'), throwsFormatException);
  });
}
