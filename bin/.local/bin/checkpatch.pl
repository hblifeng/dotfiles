# SPDX-License-Identifier: GPL-2.0
#
# (c) 2010-2018 Joe Perches <joe@perches.com>
use Encode qw(decode encode);
my $allow_c99_comments = 1; # Can be overridden by --ignore C99_COMMENT_TOLERANCE
# git output parsing needs US English output, so first set backtick child process LANGUAGE
my $git_command ='export LANGUAGE=en_US.UTF-8; git';
my $perl_version_ok = 1;
	$perl_version_ok = 0;
	exit(1) if (!$ignore_perl_version);
			__refconst|
			__refdata|
			__ro_after_init|
our $allocFunctions = qr{(?x:
	(?:(?:devm_)?
		(?:kv|k|v)[czm]alloc(?:_node|_array)? |
		kstrdup(?:_const)? |
		kmemdup(?:_nul)?) |
	(?:\w+)?alloc_skb(?:ip_align)? |
				# dev_alloc_skb/netdev_alloc_skb, et al
	dma_alloc_coherent
)};

	Co-developed-by:|
our %deprecated_apis = (
	"synchronize_rcu_bh"			=> "synchronize_rcu",
	"synchronize_rcu_bh_expedited"		=> "synchronize_rcu_expedited",
	"call_rcu_bh"				=> "call_rcu",
	"rcu_barrier_bh"			=> "rcu_barrier",
	"synchronize_sched"			=> "synchronize_rcu",
	"synchronize_sched_expedited"		=> "synchronize_rcu_expedited",
	"call_rcu_sched"			=> "call_rcu",
	"rcu_barrier_sched"			=> "rcu_barrier",
	"get_state_synchronize_sched"		=> "get_state_synchronize_rcu",
	"cond_synchronize_sched"		=> "cond_synchronize_rcu",
);

#Create a search pattern for all these strings to speed up a loop below
our $deprecated_apis_search = "";
foreach my $entry (keys %deprecated_apis) {
	$deprecated_apis_search .= '|' if ($deprecated_apis_search ne "");
	$deprecated_apis_search .= $entry;
}
$deprecated_apis_search = "(?:${deprecated_apis_search})";

our %maintained_status = ();

	if (!exists($maintained_status{$filename})) {
		$maintained_status{$filename} = `perl $root/scripts/get_maintainer.pl --status --nom --nol --nogit --nogit-fallback -f $filename 2>&1`;
	}
	return $maintained_status{$filename} =~ /obsolete/i;
}

sub is_SPDX_License_valid {
	my ($license) = @_;

	return 1 if (!$tree || which("python") eq "" || !(-e "$root/scripts/spdxcheck.py") || !(-e "$root/.git"));

	my $root_path = abs_path($root);
	my $status = `cd "$root_path"; echo "$license" | python scripts/spdxcheck.py -`;
	return 0 if ($status ne "");
	return 1;
		my $git_last_include_commit = `${git_command} log --no-merges --pretty=format:"%h%n" -1 -- include`;
		$files = `${git_command} ls-files "include/*.h"`;
	my $output = `${git_command} log --no-color --format='%H %s' -1 $commit 2>&1`;
	if ($lines[0] =~ /^error: short SHA1 $commit is ambiguous/) {
		my $lines = `${git_command} log --no-color --no-merges --pretty=format:'%H %s' $git_range`;
$allow_c99_comments = !defined $ignore_type{"C99_COMMENT_TOLERANCE"};
	if (!$perl_version_ok) {
      An upgrade to at least perl $minimum_perl_version is suggested.
	my $author = '';
	my $authorsignoff = 0;
	my $is_binding_patch = -1;
	my $commit_log_lines = 0;	#Number of commit log lines
# check if it's a mode change, rename or start of a patch
		if (!$in_commit_log &&
		    ($line =~ /^ mode change [0-7]+ => [0-7]+ \S+\s*$/ ||
		    ($line =~ /^rename (?:from|to) \S+\s*$/ ||
		     $line =~ /^diff --git a\/[\w\/\.\_\-]+ b\/\S+\s*$/))) {
			$is_patch = 1;
		}


			if ($realfile !~ /^MAINTAINERS/) {
				my $last_binding_patch = $is_binding_patch;

				$is_binding_patch = () = $realfile =~ m@^(?:Documentation/devicetree/|include/dt-bindings/)@;

				if (($last_binding_patch != -1) &&
				    ($last_binding_patch ^ $is_binding_patch)) {
					WARN("DT_SPLIT_BINDING_PATCH",
					     "DT binding docs and includes should be a separate patch. See: Documentation/devicetree/bindings/submitting-patches.txt\n");
				}
			}

# Verify the existence of a commit log if appropriate
# 2 is used because a $signature is counted in $commit_log_lines
		if ($in_commit_log) {
			if ($line !~ /^\s*$/) {
				$commit_log_lines++;	#could be a $signature
			}
		} elsif ($has_commit_log && $commit_log_lines < 2) {
			WARN("COMMIT_MESSAGE",
			     "Missing commit description - Add an appropriate one\n");
			$commit_log_lines = 2;	#warn only once
		}

# Check the patch for a From:
		if (decode("MIME-Header", $line) =~ /^From:\s*(.*)/) {
			$author = $1;
			$author = encode("utf8", $author) if ($line =~ /=\?utf-8\?/i);
			$author =~ s/"//g;
		}

			if ($author ne '') {
				my $l = $line;
				$l =~ s/"//g;
				if ($l =~ /^\s*signed-off-by:\s*\Q$author\E/i) {
				    $authorsignoff = 1;
				}
			}

# Check Co-developed-by: immediately followed by Signed-off-by: with same name and email
			if ($sign_off =~ /^co-developed-by:$/i) {
				if ($email eq $author) {
					WARN("BAD_SIGN_OFF",
					      "Co-developed-by: should not be used to attribute nominal patch author '$author'\n" . "$here\n" . $rawline);
				}
				if (!defined $lines[$linenr]) {
					WARN("BAD_SIGN_OFF",
                                             "Co-developed-by: must be immediately followed by Signed-off-by:\n" . "$here\n" . $rawline);
				} elsif ($rawlines[$linenr] !~ /^\s*signed-off-by:\s*(.*)/i) {
					WARN("BAD_SIGN_OFF",
					     "Co-developed-by: must be immediately followed by Signed-off-by:\n" . "$here\n" . $rawline . "\n" .$rawlines[$linenr]);
				} elsif ($1 ne $email) {
					WARN("BAD_SIGN_OFF",
					     "Co-developed-by and Signed-off-by: name/email do not match \n" . "$here\n" . $rawline . "\n" .$rawlines[$linenr]);
				}
			}
		     $line =~ /^\s*\[\<[0-9a-fA-F]{8,}\>\]/) ||
		     $line =~ /^(?:\s+\w+:\s+[0-9a-fA-F]+){3,3}/ ||
		     $line =~ /^\s*\#\d+\s*\[[0-9a-fA-F]+\]\s*\w+ at [0-9a-fA-F]+/) {
					# stack dump address styles
# Check for adding new DT bindings not in schema format
		if (!$in_commit_log &&
		    ($line =~ /^new file mode\s*\d+\s*$/) &&
		    ($realfile =~ m@^Documentation/devicetree/bindings/.*\.txt$@)) {
			WARN("DT_SCHEMA_BINDING_PATCH",
			     "DT bindings should be in DT schema format. See: Documentation/devicetree/writing-schema.rst\n");
		}

# check for invalid commit id
		if ($in_commit_log && $line =~ /(^fixes:|\bcommit)\s+([0-9a-f]{6,40})\b/i) {
			my $id;
			my $description;
			($id, $description) = git_commit_info($2, undef, undef);
			if (!defined($id)) {
				WARN("UNKNOWN_COMMIT_ID",
				     "Unknown commit id '$2', maybe rebased or not pulled?\n" . $herecurr);
			}
		}

			my $vp_file = $dt_path . "vendor-prefixes.yaml";
				`grep -Eq "\\"\\^\Q$vendor\E,\\.\\*\\":" $vp_file`;
# check SPDX comment style for .[chsS] files
				if ($realfile =~ /\.[chsS]$/ &&
				    $rawline =~ /SPDX-License-Identifier:/ &&
				    $rawline !~ m@^\+\s*\Q$comment\E\s*@) {
					WARN("SPDX_LICENSE_TAG",
					     "Improper SPDX comment style for '$realfile', please use '$comment' instead\n" . $herecurr);
				}

				    $rawline !~ m@^\+\Q$comment\E SPDX-License-Identifier: @) {
				} elsif ($rawline =~ /(SPDX-License-Identifier: .*)/) {
					my $spdx_license = $1;
					if (!is_SPDX_License_valid($spdx_license)) {
						WARN("SPDX_LICENSE_TAG",
						     "'$spdx_license' is not supported in LICENSES/...\n" . $herecurr);
					}
# check for using SPDX-License-Identifier on the wrong line number
		if ($realline != $checklicenseline &&
		    $rawline =~ /\bSPDX-License-Identifier:/ &&
		    substr($line, @-, @+ - @-) eq "$;" x (@+ - @-)) {
			WARN("SPDX_LICENSE_TAG",
			     "Misplaced SPDX-License-Identifier tag - use line $checklicenseline instead\n" . $herecurr);
		}

		if ($perl_version_ok &&
		if ($perl_version_ok &&
		      $sline =~ /^\+\s+(?:static\s+)?(?:const\s+)?(?:union|struct|enum|typedef)\b/ ||
# check for unnecessary <signed> int declarations of short/long/long long
		while ($sline =~ m{\b($TypeMisordered(\s*\*)*|$C90_int_types)\b}g) {
			my $type = trim($1);
			next if ($type !~ /\bint\b/);
			next if ($type !~ /\b(?:short|long\s+long|long)\b/);
			my $new_type = $type;
			$new_type =~ s/\b\s*int\s*\b/ /;
			$new_type =~ s/\b\s*(?:un)?signed\b\s*/ /;
			$new_type =~ s/^const\s+//;
			$new_type = "unsigned $new_type" if ($type =~ /\bunsigned\b/);
			$new_type = "const $new_type" if ($type =~ /^const\b/);
			$new_type =~ s/\s+/ /g;
			$new_type = trim($new_type);
			if (WARN("UNNECESSARY_INT",
				 "Prefer '$new_type' over '$type' as the int is unnecessary\n" . $herecurr) &&
			    $fix) {
				$fixed[$fixlinenr] =~ s/\b\Q$type\E\b/$new_type/;
			}
		}

		}

# check for initialized const char arrays that should be static const
		if ($line =~ /^\+\s*const\s+(char|unsigned\s+char|_*u8|(?:[us]_)?int8_t)\s+\w+\s*\[\s*(?:\w+\s*)?\]\s*=\s*"/) {
			if (WARN("STATIC_CONST_CHAR_ARRAY",
				 "const array should probably be static const\n" . $herecurr) &&
			    $fix) {
				$fixed[$fixlinenr] =~ s/(^.\s*)const\b/${1}static const/;
			}
		}
		}
		if ($perl_version_ok &&
		    $line =~ /\b(?:else|do)\{/) {
				$fixed[$fixlinenr] =~ s/^(\+.*(?:do|else|\)))\{/$1 {/;
		if ($line =~ /}(?!(?:,|;|\)|\}))\S/) {
		    $perl_version_ok && defined($stat) &&
			if ($perl_version_ok &&
		if ($perl_version_ok &&
		if ($perl_version_ok &&
#Ignore SI style variants like nS, mV and dB
#(ie: max_uV, regulator_min_uA_show, RANGE_mA_VALUE)
			    $var !~ /^(?:[a-z0-9_]*|[A-Z0-9_]*)?_?[a-z][A-Z](?:_[a-z0-9_]+|_[A-Z0-9_]+)?$/ &&
				$define_args =~ s/\\\+?//g;
				$tmp_stmt =~ s/\b(sizeof|typeof|__typeof__|__builtin\w+|typecheck\s*\(\s*$Type\s*,|\#+)\s*\(*\s*$arg\s*\)*\b//g;
				my $use_cnt = () = $tmp_stmt =~ /\b$arg\b/g;
		if ($perl_version_ok &&
		if ($line =~ /$String[A-Za-z0-9_]/ || $line =~ /[A-Za-z0-9_]$String/) {
			if (CHK("CONCATENATED_STRING",
				"Concatenated strings should use spaces between elements\n" . $herecurr) &&
			    $fix) {
				while ($line =~ /($String)/g) {
					my $extracted_string = substr($rawline, $-[0], $+[0] - $-[0]);
					$fixed[$fixlinenr] =~ s/\Q$extracted_string\E([A-Za-z0-9_])/$extracted_string $1/;
					$fixed[$fixlinenr] =~ s/([A-Za-z0-9_])\Q$extracted_string\E/$1 $extracted_string/;
				}
			}
			if (WARN("STRING_FRAGMENTS",
				 "Consecutive strings are generally better as a single string\n" . $herecurr) &&
			    $fix) {
				while ($line =~ /($String)(?=\s*")/g) {
					my $extracted_string = substr($rawline, $-[0], $+[0] - $-[0]);
					$fixed[$fixlinenr] =~ s/\Q$extracted_string\E\s*"/substr($extracted_string, 0, -1)/e;
				}
			}
			WARN("IF_0",
			     "Consider removing the code enclosed by this #if 0 and its #endif\n" . $herecurr);
		}

# warn about #if 1
		if ($line =~ /^.\s*\#\s*if\s+1\b/) {
			WARN("IF_1",
			     "Consider removing the #if 1 and its #endif\n" . $herecurr);
			if ($s =~ /(?:^|\n)[ \+]\s*(?:$Type\s*)?\Q$testval\E\s*=\s*(?:\([^\)]*\)\s*)?\s*$allocFunctions\s*\(/ &&
			    $s !~ /\b__GFP_NOWARN\b/ ) {
		if ($perl_version_ok &&
		if ($perl_version_ok) {
				    "usleep_range is preferred over udelay; see Documentation/timers/timers-howto.rst\n" . $herecurr);
				     "msleep < 20ms can sleep for up to 20ms; see Documentation/timers/timers-howto.rst\n" . $herecurr);
# Check for __attribute__ section, prefer __section
		if ($realfile !~ m@\binclude/uapi/@ &&
		    $line =~ /\b__attribute__\s*\(\s*\(.*_*section_*\s*\(\s*("[^"]*")/) {
			my $old = substr($rawline, $-[1], $+[1] - $-[1]);
			my $new = substr($old, 1, -1);
			if (WARN("PREFER_SECTION",
				 "__section($new) is preferred over __attribute__((section($old)))\n" . $herecurr) &&
			    $fix) {
				$fixed[$fixlinenr] =~ s/\b__attribute__\s*\(\s*\(\s*_*section_*\s*\(\s*\Q$old\E\s*\)\s*\)\s*\)/__section($new)/;
			}
		}

		if ($perl_version_ok &&
		if ($perl_version_ok &&
				my $specifier;
				my $extension;
				my $qualifier;
				my $bad_specifier = "";
				while ($fmt =~ /(\%[\*\d\.]*p(\w)(\w*))/g) {
					$qualifier = $3;
					if ($extension !~ /[SsBKRraEehMmIiUDdgVCbGNOxtf]/ ||
					    ($extension eq "f" &&
					     defined $qualifier && $qualifier !~ /^w/)) {
		if ($perl_version_ok &&
#		if ($perl_version_ok &&
#		if ($perl_version_ok &&
#		if ($perl_version_ok &&
		if ($perl_version_ok &&
		if ($perl_version_ok &&
				     "usleep_range should not use min == max args; see Documentation/timers/timers-howto.rst\n" . "$here\n$stat\n");
				     "usleep_range args reversed, use min then max; see Documentation/timers/timers-howto.rst\n" . "$here\n$stat\n");
		if ($perl_version_ok &&
		if ($perl_version_ok &&
		if ($perl_version_ok &&
# check for pointless casting of alloc functions
		if ($line =~ /\*\s*\)\s*$allocFunctions\b/) {
		if ($perl_version_ok &&
		    $line =~ /\b($Lval)\s*\=\s*(?:$balanced_parens)?\s*((?:kv|k|v)[mz]alloc(?:_node)?)\s*\(\s*(sizeof\s*\(\s*struct\s+$Lval\s*\))/) {
		if ($perl_version_ok &&
		if ($perl_version_ok &&
		    $line =~ /\b($Lval)\s*\=\s*(?:$balanced_parens)?\s*krealloc\s*\(\s*($Lval)\s*,/ &&
		    $1 eq $3) {
		if ($perl_version_ok &&
# check for spin_is_locked(), suggest lockdep instead
		if ($line =~ /\bspin_is_locked\(/) {
			WARN("USE_LOCKDEP",
			     "Where possible, use lockdep_assert_held instead of assertions based on spin_is_locked\n" . $herecurr);
		}

# check for deprecated apis
		if ($line =~ /\b($deprecated_apis_search)\b\s*\(/) {
			my $deprecated_api = $1;
			my $new_api = $deprecated_apis{$deprecated_api};
			WARN("DEPRECATED_API",
			     "Deprecated use of '$deprecated_api', prefer '$new_api' instead\n" . $herecurr);
		}

		if ($perl_version_ok &&
# nested likely/unlikely calls
		if ($line =~ /\b(?:(?:un)?likely)\s*\(\s*!?\s*(IS_ERR(?:_OR_NULL|_VALUE)?|WARN)/) {
			WARN("LIKELY_MISUSE",
			     "nested (un)?likely() calls, $1 already uses unlikely() internally\n" . $herecurr);
		}

		if ($perl_version_ok &&
		if ($perl_version_ok &&

# check for sysctl duplicate constants
		if ($line =~ /\.extra[12]\s*=\s*&(zero|one|int_max)\b/) {
			WARN("DUPLICATED_SYSCTL_CONST",
				"duplicated sysctl range checking value '$1', consider using the shared one in include/linux/sysctl.h\n" . $herecurr);
		}
	if ($is_patch && $has_commit_log && $chk_signoff) {
		if ($signoff == 0) {
			ERROR("MISSING_SIGN_OFF",
			      "Missing Signed-off-by: line(s)\n");
		} elsif (!$authorsignoff) {
			WARN("NO_AUTHOR_SIGN_OFF",
			     "Missing Signed-off-by: line by nominal patch author '$author'\n");
		}