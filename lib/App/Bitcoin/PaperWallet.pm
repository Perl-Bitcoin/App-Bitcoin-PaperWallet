package App::Bitcoin::PaperWallet;

use v5.12;
use warnings;

use Bitcoin::Crypto qw(btc_extprv);
use Bitcoin::Crypto::Util qw(generate_mnemonic mnemonic_from_entropy);
use Digest::SHA qw(sha256);
use Encode qw(encode);

sub get_addresses
{
	my ($key, $count) = @_;
	$count //= 4;

	my @addrs;
	my $priv = $key->derive_key_bip44(purpose => 49, index => 0)->get_basic_key;
	my $addr = $priv->get_public_key->get_compat_address;
	push @addrs, $addr;

	for my $ind (1 .. $count - 1) {
		my $priv = $key->derive_key_bip44(purpose => 84, index => $ind)->get_basic_key;
		my $addr = $priv->get_public_key->get_segwit_address;
		push @addrs, $addr;
	}

	return @addrs;
}

sub generate
{
	my ($class, $entropy, $pass, $address_count) = @_;

	my $mnemonic = defined $entropy
		? mnemonic_from_entropy(sha256(encode 'UTF-8', $entropy))
		: generate_mnemonic(256)
	;

	my $key = btc_extprv->from_mnemonic($mnemonic, $pass);

	return {
		mnemonic => $mnemonic,
		addresses => [get_addresses($key, $address_count)],
	};
}

1;

__END__

=head1 NAME

App::Bitcoin::PaperWallet - Generate printable cold storage of bitcoins

=head1 SYNOPSIS

	use App::Bitcoin::PaperWallet;

	my $hash = App::Bitcoin::PaperWallet->generate($entropy, $password, $address_count // 4);

	my $mnemonic = $hash->{mnemonic};
	my $addresses = $hash->{addresses};

=head1 DESCRIPTION

This module allows you to generate a Hierarchical Deterministic BIP49/84
compilant Bitcoin wallet.

This package contains high level cryptographic operations for doing that. See
L<paper-wallet> for the main script of this distribution.

=head1 FUNCTIONS

=head2 generate

	my $hash = App::Bitcoin::PaperWallet->generate($entropy, $password, $address_count // 4);

Not exported, should be used as a class method. Returns a hash containing two
keys: C<mnemonic> (string) and C<addresses> (array reference of strings).

C<$entropy> is meant to be user-defined entropy (string) that will be passed
through sha256 to obtain wallet seed. Can be passed C<undef> explicitly to use
cryptographically secure random number generator instead.

C<$password> is a password that will be used to secure the generated mnemonic.
Passing empty string will disable the password protection. Note that password
does not have to be strong, since it will only secure the mnemonic in case
someone obtained physical access to your mnemonic. Using a hard, long password
increases the possibility you will not be able to claim your bitcoins in the
future.

Optional C<$address_count> is the number of addresses that will be generated
(default 4). The first address is always SegWit compat address, while the rest
are SegWit native addresses.

=head1 CAVEATS

=over

=item

This module should properly handle unicode in command line, but for in-Perl
usage it is required to pass UTF8-decoded strings to it (like with C<use
utf8;>).

Internally, passwords are handled as-is, while seeds are encoded into UTF8
before passing them to SHA256.

=item

An extra care should be taken when using this module on Windows command line.
Some Windows-specific quirks may not be handled properly. Verify before sending
funds to the wallet.

=back

=head2 Compatibility

=over

=item

Versions 1.01 and older generated addresses with invalid derivation paths.
Funds in these wallets won't be visible in most HD wallets, and have to be
swept by revealing their private keys in tools like
L<https://iancoleman.io/bip39/>. Use derivation path C<m/44'/0'/0'/0> and
indexes C<0> throughout C<3> - sweeping these private keys will recover your
funds.

=item

Versions 1.02 and older incorrectly handled unicode. If you generated a wallet
with unicode password in the past, open an issue in the bug tracker.

=back

=head1 SEE ALSO

L<Bitcoin::Crypto>

=head1 AUTHOR

Bartosz Jarzyna, E<lt>bbrtj.pro@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Bartosz Jarzyna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.0 or,
at your option, any later version of Perl 5 you may have available.


=cut

