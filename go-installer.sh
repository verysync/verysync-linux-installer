#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2307263769"
MD5="e4c95756d5019aeabadefcac69637554"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="verysync installer"
script="./go-inst.sh"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="src"
filesizes="65475"
keep="n"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt" | more
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.4.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 587 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." > /dev/tty; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=none
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 188 KB
	echo Compression: gzip
	echo Date of packaging: Sun Aug 26 22:13:50 CST 2018
	echo Built with Makeself version 2.4.0 on linux-gnu
	echo Build command was: "./makeself-2.4.0/makeself.sh \\
    \"src\" \\
    \"go-installer.sh\" \\
    \"verysync installer\" \\
    \"./go-inst.sh\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"n" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"src\"
	echo KEEP=n
	echo NOOVERWRITE=n
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=188
	echo OLDSKIP=588
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 587 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 587 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 587 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
	
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = xy; then
	    echo
	fi
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf "$tmpdir"; eval $finish; exit 15' 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd "$TMPROOT"
    /bin/rm -rf "$tmpdir"
fi
eval $finish; exit $res
� ���[�ZpTU�>� ��G�@@��^Iy� �"��,����@L��;�2%-��Nf�+��5��ugI;���G�Ո�,;n� �ú�3v�׌nm1�4��~��s�?gt��)��j.ur���s��?����ͬ��K�
q�͝��q�w��hΜ�¹s�J���������+�:���!�>_������O�Y��������cfS�������Ii�ܲRQ������u�����������2c�������	G���K��,�c��d�&�ŏI+������6NQ.R�w�� R �`���9�C�6�#e=��ď����d=�nb��z�v߽I�-�/�*BU
~X�+�)��+�	�Z�(|�j�|��1.J����!��G�/W�?c��R��1^
���x)�S���%c�|�H���X��qT�����)��e�t�G�!�T���g��_�q*x�1�
�h�����z:���/��1�
^.�w+�k�x)x�/���\�7��?g���?e��}8���/�W�q(���uǸ^1��?f�o
��1�)�w�<R�G�<R��F�|��!�Pp��`䋂/2�E��7c��j�_�o2��UR��[��+��_��F���࿂��~�|��s��;��+x��?!��)�2��
~��c�_�����p�#�t�2�%?m�?
�5�o1��-��W�e���࿂�1���Vc�P�?��o�W𰱾+x��*��W�[������X�1�ǡ�����K
1����Ŝ����s翹t3����ᥜ�/��gx9�?�+8�ο�gx%�?��q�3|>�?�p�3|!�?Ç��'�*���8�^����E��_����%������K9�~;�?×q�3|9�?����g����_����8�����ws�3����8�^����{8�ο�`�}��_���p�����p�3�~�����p�3�A���q�3�����$����p��C:�ݜ�ob���o�\���I쾺���}��������1�*��8Rs��'��ύ���Ļ��w��
�|&���b�XȍL΄���ِ�19�&O����|����o$�L. �L�E��\L��\J��|+�g���d��L�K�>���}&� �L�!�L���3y
��v��T��D�/�d;�#��o��34����J-��_���b����h�,b����$>Nt��a��[�*�6�*�p%4��F"����~��Drdw�����s�E�=�
_�c2XF�r�N�C^u�~i�\m���ϑq�<8:���{���^3$��1E��q�m��5�E^�h�G�k�Y�!{��:���տ��$���/>������"�]Vps�F���u�[0W9���C?��pb~yC���/�	1=H9x�R�� ��
�y�Yx8��D�9
Gak���yX�ouVDோ��>~V�1�	�������C���{�S����Qh~�c`�V������u�o�͢�|�[�[��<ő�I}L���z<#�V-2I�"v�j���{J(3�\'2#w�Cę� �.t"�1q�;�Q�No�3[D��6��	�?��"���o�?554��M��g��柝�wsB�)0n%��W?�N��P��{��B�8"&�����L�?S�翣�؃?�5E�ct@_g~����;4�E
�מ�����nD�%����˯��D�3���X30�F,��e�cXS_���-�|zM�����������:��g{��g�m���M��q�{�ǥ��)�:�ͤ�c~9�3��tNJ���X���uc]"{��o�5�"jC�N�9���B�UxN��y82լQ|���R�v�'�En�>�<1-Od��d{/|ܺŹ��8��U�P�.�y�u���(�a��'�J�̨ۀ~�Gu�B?�]����|�u�#�r�lx~�w�r�]��NМ{
x=����F��~�w̡׏"~�oNW �
�F�ݨ��-Z܍��Qp7
�F�]�q���?��eBY�b�!>Y���K<�<�a�������?����Ņr����K��
���5�@mŞ��7�(Y�X�]���W���2��:���"� �LZ�5q�s"��X;�;q��'2~��+8U�����j����Ku��4�f̗}b��o�uC,��6�s7�Ú�cԣy�־F�p��h�x/Nk��0��ϫw�s��\��rb^�z�/z���5G�C��Es�P��r��~Kv��w[A7�g��"��7���yha�XA��CY�÷�'�S�v���JC�������'�8��D��C�	¯����G
����C�d�&W�����b�P�k���󲾧8�+��4΋��
z���~�3��zX��w}m�^�a��X#;�6"�ic�"!W{�#�:���C�U��\����?�S�ůh-CI�GJC5��j��m��0���vEC�?�j�[��:���xN|��EE�Y�v=#�˼�_�]�ُ���ک-�{�d�-�s�y��r���l�1r�)�EޝBޝFޝAޝEޝ+��������o�3���D>R��zأОn�Y��zF���K����fm{o�7����>�}ɬe�<���/cRY=�w�R�o�^�-~��C��F�Nd!�F�\�sɦ�. ?���~����xvxץd�P��<!������.��μ[~����(yDv
�*� ���x)^��	��&���<k�쌤����9����ͺ�uy�Z�zok�y�c��{����a�V���c�o����r:e�����-�2v<t���Z��>�SoNq�,߯5s�����OE����:<H;��>S�D�&S��R�h%�~���8�F��2���g0n���+�HzB�n���#H׷Cv!M�qtĭ�x��=&�}��7K �c�+����d�k�����V�~�7�˽����g��y�?��
�ߜ=�J��8��{�	eXV��x�^��(��P�X���þ�댲��~�s<�z�9�?W{�^<`�+��/�w���صP�C
�!Wt4R?�S�������Lb�>��R��օ�Q��96v�t��j�^�]ܑ���,���� �1�tL\D���� �>� N�і2Q�;�hbgV�d��y�s���>��Q=��=�O����|�����<@_y��IC4}
�fy�j��#栜�_���H�$,�i1��!�2��9��<υ쌸��4���Ċ�����۷���&����cĮ{�#�W��� M������D^�υ�·�6���\���N��2't�����
=c/�|�㈥��6r{WO:M}��{�{(��?�T�[{����6>�ԣ�f�f�6֚�Yv�w`��C�W���[�k������k�Ë��$W?ų�sbWЎ,���k���`�އl!��G��d�ۦ.e�/��T�a=ύ��q���
��~�'�T?�z���:(^�\=e(����_���6�AZ��V���r.e�~['��|�wH�̾՛�m�:���A����ݞ�,h~�Q^���eP_��5�	/��o�=?,7bȩ.�F��}�=�]�?h�q�g0_���J���B)[��z⬴{m�[�"�[W�(�?�Ц��4�"���N*�X����.�u���\Sg|���%%�_n@Y�H�cl?�?h�V.��A��e۴�L�\\�>mO�yt�r�sV��O���G����/�|_m��(��<�c����e,��6)ޫ�$�z���(=48�g��I�l�ݛ����1WXN:|�l�{=�N�6J�%��Q�{&�syѮ���9��v����L89��^K�C��(�C�)�o����>>�w�`�f��XKu������/sH ��'�+���U:�\%w�����.�¨��?�u���3��|>g��u�ѿ:J겦j+d�Z�'�w��U��=�S�Ƚ�7=�ϵBs
���v�mWn����E�9p�q�?���q���Oȫ��>^�j���9�Z�P����gL��S�5����A�
�����kx����W���L�Z���֛�|X{>0�:��R���<@�P����@�����+ �<q��qG��;A_�:"�t�������.�;��'��؆$x�j{a�Q�v<�~�w �'̦�����yB���<��
>���Qm(��g���Y�v�3�$n$����.5�|��a��??���rۖ���;(��H�81�:ʟ4�ʄ���%r����B����?�\���A�2��&�K��Wc(<�!��^���ە��8N\���JV�?"��F�6'T����-j|��/
�I�5�Z���eP�C�'����{97a^��(����&�j����J�%�#]���Myo�mPN�B7��qMa=�ݵK=ڤX�r�m�VF�^���h��:F�K�Vh�W����d�O�қZ���W.�$~����樭W 7^���[Km���Yj�`<U)���Q��m��)�A������)���Dz����d�_>F��Y��(�1�f�)��
��(�'{�cW�&��E|���2��B��2�q��ܽB����@`t�����}jĮh�����><C'x�c�B���}	�m�����{b���4������L��+��MLi�;�+�+J����B�X�����u�-�+�7�
�if�2��6��r�W��]C,�7��w���&v�;D�A�G��V�9r>E��b�xv^@=]�"�<���:��)����֓�$�2���qeIM�up���9ƸM؟�{N��P6/5q,�r��,.�Ȇ�a~�/Z�n�N�nW�I�x�)aE��s� �P!��9|v�ĩ��I�hWXq\�H{$}O}�
�>
4)��A[9�%q��U�A{d�H�3��.�^���]�Umj���D��Q��7�)}��^}+eY����m�>Mع�����W|�p^}��u�m}�/�t%~�����s؋���ځ�1���Vs�~vFY����f�u�7�nﻤ�ww5����y߅0��7
�xڑ	i��_+��[9�b�kثo�Z�F�)�Q�[���*��He���
<J�/ǔ0a������M��M��M���!z�?��z�/�naO^�8��tI�v�Wz��H1�_����7�#t����%�z-�4A�7�Rޑ���?ӈ�j�wȹp_[����;���7lj�[s�w��[|��{��>"��̹vp6�`�]���F;�|��o�Θ�#x>�;cӞ����m`u�AS�����3D���6qG4B�
�{*�zｍ�)�\��t���S?s<t/i�u�^��x�� '�#~�C���C9)k�WJ���8x�����G�-)I}�0��/e�Ac�"�s|��ԛ�痠�/�Ý�N�o��R'ݩ��Z��=|l��V.�M���te����4��6ICW�%���w�y&K��*Y�������g;hc���\�}A�qx�{����f�E��z���WM}�c�O��'�����M����Y
�ƹ�����+Ye e(ޗ����{L�l����Jo�f��U`���w�t����_�o=U{�g#�������E,g�����w����L=\;Q��i*̼�k8o�
��B�
�oX�,Z�j���إ��6�����xJ
�E~A��@Df�Z���������HNv�E��u�V����B����y��vt�W�nT����SW��/+�/^]��x�R�� ߾h�}eުu�<�۵��ľ��}gA�*{�I�Ǥ��3��*AYϪ��b��Ιkƌ�g�KV{��󗕸��-����KV���y�
�cB=�W�v���Q11�K���u`��xV-�5��/��,X�.�}ԨQ������ŝ������%����\�
��O.��>?cFV�L7��D�$fw��ܘ��H��iB
3n��j�ژh�p�{�-[�^�&J��ZZX`��{�y�
F��7�.qۋ
V�ŝ�����<w�=/&�?�nG�� 8uy�]��]�P���b�{ު|�uL�l.o��^�l�k�@���;�Ӛ�+�jy��i�b��}�:��'?�GIZ�#��H�PS,B�)�Zrg����y�JVz |Q��%�KD�=����� 1b�Z��B�&uԘ��؇�&$��&���JK��6n�}vδᢨ�x岒�8H���׭����`�p�,w�tf�)�+η����<n���z�}%6B�:1��x���%�KFc��UW�u�#�����z;�e�0�ڐ��WѲ�`�����e��)��/(Y\��Ƚ�X�`a��O�����3 ��)DaIA��aC=�U�k?E؆���g��Eo'�K��1 �=)�_oǕ�j)7eq�b��.4�%��A�R��-�c �XD�D	� `U�{�^�?ίJf_7����%��"��r@���V/vڇ^�68���kF{����W�n$fكn8Z��Lz=�33�\�)}�KW
I�e7��D���(�+)���9�/"9K�2��*����2#%���x`yU�j�=��;s�ښ%n� W�>`��ˊ�E��V��I؆���
�P1g�"�pY�}�g�"���M#�\b(6��sð�����6ԣ��J��(�̔��)qcZvڍ���i���7���R�v㔵E�Ui�S��ݑ�Fܘ���ʼ�U�bO�ⴵiEi��ܜ��4-+�8-?m�3mf}��/[1_n�*;!�@z��2Þ,	�J$�)�y%$���r|z�����v̅b��
������@�]�>Pu�p $�)$*��{V�f�POv�YY.�}�В�,�\?�!_0��~FdL��ѣ��*��䀃��̆�8�C�UR'�L�EJ�\ �Ŋ2k�]a-�Uy ��$o�����=�:#p�(`#�^�L���N��*��m�£:�t�(�j'�	B^T\�y\C�"?�!���ZfK��D�@]�Y��L�!f���a�ꥫ���8��`�n�5��ʁ�i)Џ�k��²�bY�c�-Z]�L�X
+F9A|�1�BC��;$�d��m��)t�v7��E
=�F�_{1�nw��e�|���D�m��~����ǿ�~������q����u�����A�]Gt�gA_`	���#�ﷇ|dy���������,��>1�}�W�դ��H���A�h�"T:�ˬ��|-��,�ë_ظ�>ڬA�Z�����������'�utɯ����ڮ̈́�?��ӡ��������z;�[�=���/�K���������a�*G�jbT���H��Q҈R$FA�)�>uF�;��+��%F�[%Y��b1j�*Ϩ5R��X�w��y,�Ǌ
�l{�u�ſ�Ŗ����<w�U�Z���nOe��y��y�T�`|��b�q��e���j��G���XT�@���I�n��9�Pt����$��W����G��G������'����Uϰ���HX;W�c0��a:�Y��vk=��S_��Օu7�	:���tg�o��k
3t�L���O���?����m
�c5}������v���0��з+���^�Wd���ؕ�v�����w�[}��]���a���:�P�7��Z?|�J���#+�������O�^�]��h�?�4��Ƶ=�p�i���e���r��^������Lh���b��t���mz}ۿX�}��a�L�^�^]�Fk���)����t=���Y�����H�:<�\OX}���^!���ݍ�U=/X?�9Y�_d����}�����'��ǿ�;�F������y�+������	���aᄫƏ+R��jl��qc&��\�ؔ1c�=�c<��.x���������纙�5�sw��0�ן�~����4b,$
+�
M>V��X�ty�|4��³�����Ñ�����"�^`	��F�����O��'��1��a�Fy�&ybl�|�5�patj|4��uy)�nV�;�Bs��х��.�O.�qz2v�kɨ�գ�
�Y���7��l�z��Z`h��S7�O{nX��w͏�'�r�@����ޠ_�1�!RЏ�%��u��~�
����ܠءY?h�!�A�ɺF?����������K�ְqѿ�<�e�\�<_��!����\�.�����g4m=7�2~t/���nֿ�7.��v������������)��`g3�]��I���G��A�㣌:R��E�<��M�}��;,�h9
�̦���_�K
K/
��ڰtix���ua�����~Z'~���*���a��a��>:��Ma�	+�V�4� ��a�o
Ko@ѧ
�p��V���u\yŝ�V������1*�����['gD��_Z,g��0,L� cĚ�U�4����%:,����:ƌ!��!�՞B�R
y՚K�M�J3�Y)�Q�|.$V.���y�V�����bIqA
���M.\�#kW�XD�_[p�
G�)(^Gd�~�K���},�Ϝ1u��1��Jy����~4]���˖�d�V]p� ��o����)� >I���[]�� j��$��X� �Ɛ�1�J`A;�!�;C(I!TcEc$C()AX�2� ?�! ��B��!�� >�!��A��!��0��3�!�����2�b����!��B���B�p3����!�����yB8(gkC�0��!N2�R��!��B�aF�4C(T�0���C(�B9��
�N�P_de��!�>�`�1���&C��A�PJ�g��0C(��2�g��C(�~�P�d���!������3���C
�X��Pb,��ZB��e��Ɛ?��tC(ˉ���B�Ib�zC(�#B�IaA{,C(�Bџ����!��P�3Bi��ʵ�!{ùX�P�0����s>C(�.�P�B�(b���J�Z�P��3���e%��a>��Hn��V��%��>��R���W�/�m/7�l���l�������9���g��h�o7ğ3ğ6�7�7����zC�m�����C<��i�g�
��tI`�� 8{�& yKB�ͦ�&�p4�Sr�#E6�T��$RMB�����
��Q��)�:fl�l ��������j�9���41��;Ͷ��q�Y�}�H��	;�fs����&Q��>�]���R��-j���j�{�0__!�KX��0�lW8j�ܜw!ʚ�e�}kL���_'��i�%�ᣄ]s��9�6sr�4�q�o�,�i��f���e|lb���6�3ޭ:hwD�����Q.c�`�ԇ�r.�8Ьa6+��r<?��\ �#} '`в�gЎEljf��@���I5M���M[�hk'�knG8ᶩ����m�4|�:�"o�ȭi�%ei�Y�n�,�.G�Q�T;&��&οy�hc���Bz(�lG˽��Rģ������#Xۙx1�~���~�w1A�oE��4+V�%݋0�C	c!aL����LC���]�ߎj�_S\��t٘��fm3��F3��$ΊF�ӭ�-��.ZʇGX�;��0Y�������l��6�nG�ߠ�p:#�k('R>h������&�)�̡�=��r�u�����EفǦF�
��}�u"��(�:�v�E\�?Ԝ�F�w�������P�[�Jބ�װ���fG�v�ܗ��,EU�E5@��S��Q�'�}߃'�R��*@�i[��g5��aN?�m�j�^E��z`���j��ޔ�j�n��̱�>r���,�7�Þ����>U����8�a����k����j+�7O[���l��<�zf�{�)�^�<��D�R��j~�H�X_�j �:�i�'��9 �Vw�y���5���
7��R*��n����m�۞�g��2 B��Ds᭏�VYOx���V���&�I�u�D�&���V+`D[��5M�%��zb���7��C���h��K��:��~{��O(��۪���^�l�������H�%f)�H<��Ti��W�{�כ��B;pI�d5r�&^��/�o����|�R�i�~|�K���3��R%���=ɟ��3k
�y`�k
���JH+�MG�j�����D�=[��<�L^�l���4ǝ
�,"��������"o�Z��(�5
�;���� ��$�g���<Bs�&�G�)Ќh��\�ǅ1�=4�1�:�c^.ioU���R66ӆ�j�"�|�3d|ql,��
�G��:
�D,�ƣ�*S���ybDk`�~�>��X����}�Mʹ�Ś\��9��IW��-�^�\�D~�b3.C��[�3i_��Nc&�
ct`n�cN��-�2����o� /4�agO4�i@:	m&!>�kG�t8��M�o����y����"b�$�4�V;�žoR���Xڐ�v�geG���0���U��W�Lo���`�6G<u��O�~8�����%ԫ��Z7�&(]���Q�Ә�c^�|��Ey��1���.Pt�:���^,(P���e�� ���n|o��%Ux~�g+�mx��C��)}�*P�:�k��K����x����qd4�߲���x�u6��X0�C0&d$���G̈_��@�Ԭ�G"R��sN�(�Nb��k��V��&K���M�i�x,JH�:V�9��d[�Cy�
�$��5خ�c�n�H/�9b����j~[o�r�Q��q�~�a���]�͵R�ڍ���7:GQ�:��Bv��QЇ��}�zr_�yϫgL�O�Q�H~8����&�AS�����ϩ��)�~�EE:�֒�a���)���%�} �����-�q3�Q+R�@m?ʠ�6G`�/Fx	��xH[��W�� ~)���l�}:N�;�X[d������<�p�y)K� �|�D��˦	R��N��\�H�9a�.�R�� Mh�.�Z��^��*6(���{�.*0�bkb��{�9���Hd��r�!�D�%"�^+i�5�t�g2<������ho�X��#͏�-�U�$�ҟ��P� �n��l��D �n��u7gAb����f7��y��(uFK��s���<�p(}g�c���C~�w��N9Ǆ>h'�K�li��6��
���I�/�k���{�����iZ�)zgtV_�wR0�����Q�=|�[�v����x�u�<��C�y^�����ݗ籇<��/u�y�ӣ�7k���S�U6�f�I���A{]}�l�̓��h[9�,˳�����k��TqZ�֩<�����Z,����%�����o�ww�.�����]��|M<
�%�#���D����':��h��:�<�Uk��Z8����l�y�0a��p���<��5'ؕ�4��I���q2����%�[�w�۪x���g75Z�oXz4/;�9�7��ϢӇ�ç�B��7BW�l�ۣ���I�n~�����Sv#�4i�����F���&q�z�Q�^�|~e�\�)����)���ޣ���/��f9;�"���by�;�y�D� )�fm���v�4���#�Z�e�I=��XQ����i�
Sy��z����?��+�����:tR��/h1���e˕��i�y���f���9�~��7���1��X�4uR٥.��glO4o�ߢ�*x��u`�mi>�2�yg�J��=�u�'۳��� �+K�%O<�E&�4u�SC�S��ץ�Z�ca�m1)臲��k�w��nWN����L�-��<`V{���y6���,���b���)W�;����ڢ��p(َ��?�Ɉ[S^=�^l�>ǟI��Iu�j 7�\�U���&�p�^�wUv^��7�F�{A�����y�y�]���%i��C�J�y�oͯ9����J�:�F^���g�1��h�߄$
�-k�=uR��Y������;�1�
Ϋ�6�׿g!ܴ|���/�SO��ؚ�w�)��C���	��t�2H��K���������;Q��o�-��$��
ugK~�'�hU�I��@����n���٩�T���|�v Sj}_�~7I卼��<Sj�9�{�w���6����]&!rM���>�1=��x��ꄺ�'��xu�����������~�}��w7�[�=���7
�]ٽM�,[���@wX����`��~�����`u^ܹ����b���mT�SW����	��U��J\,L�.�u�c�esy����e+�8�-X�Z�ߙG�֬^�U��O��^�am�,��`%i1bd��#�BM�M���|�=oQ��B�b/�s�Dr�H��a`ry���1Z�@¸5��ƌ5�>�4!955y�${�Ĵ1)ic&�g�Lnps�V-t��r}�j��?�;e�H��E��/� �8߾��.��A_��P�N����%�KFct��iW������k�_s=[f�_�UzѲ�`�����e��)��/(Y\��Ƚ�X�`���W_�?y�+��Gr�K��%+�

��lݑ#G��Ӳ3�+miZI��iٙ��ib�k�ʂ� l�jՎ��%yXP!)������UEy%%w�w��;��YB���TQ
J��1?��7�%䪼B�s#� ry���Dr�Q%��]��V����w�μ�U�$Mf�`ט��"�����x
����ŞU�3��߲v��\>���%�CYr	�C�`(-[��O��Qlt�pr�AQ�`fC8<��*��`����]hX�r��+:Ȭ)v��VE@䁰������b�/���
���S�DU�n"%�zF���b���
��B�z!#�ژ�ŭ�{~����ߏ?��6
�-�ELHN�1Q�V-�c�c��k����"m�i�9Q����9{�7�?s͞�uӨ������Ozi�t�.��s+�X�����]����N3���^W>0��A�6�X�.Ҕ_u���Et��������N��A��F���1�.��g��}}���Gl�n]}����K��د�}fF�uHO>���qVݏd��Ò�Ǣ;��0�+���I-}��i��k(����ҵ��r���t!���a{wʑ-���1X�N����,�����G�+��j��U�V�~C{m(׶��?�`|�0���Y/\�Ft�'��tS�9��j+�Y�)�'��\�|U�^#��w��=��Pn����0�����>Prgߥ_�n��}�2,?����*S�g�qؗ�>��@����}p_���&�����<~�U������0f܏�����6K<����J.�⒠?�N��!��^��ӭ�R���W�9?��̺x��]��W�z/�N��U %/�;�ڄ�����A���w�D#��O�gg�;�"��F��O��K���?ӷ������n��Ü��.�}���_��[��|����8S����t?�qz^��w�X=>S��,t?�����0�^��Ѡ?�<��x}�~G���0�8��YO��L��}P}�^����J�Om7�w�/�>���?�Ɇv�u�ؗ����9W�}��^�]�S�_�F�_�ƿ��Қ���H�w��/�� 
�_�I�/���;�������
K��������-�`��0��S��{�e�\��v�bU�L���ޯkoGX�%��ʰ��a��s{�=t� ς��=����V��a�a���xX{�a����G��7",}iX:6,=:��!a�������=�����?��O��݆����$ܿoX�T���a�	K�VnX��|����%~��oX�7a�M{������a𕅽�k/=,�ǰt~X������������){���-a�����.�_��N��TX����3�����
�I�P��B���!K�SMC(nV��cBȷ1����_C(�� �B�Hb�u��8�!���P�2�b7�!�����f0��dee&C(�N�PsBٛ����PJrB��gf�b&V�JFC(�n�PT�2�"��!J/C0�r�P�70��� C(1B���
�f�P�ga��!���BI�!��Ba����v��w2���"C(Ƶ��c��5�P��da� C(��3��|�!��OB��ge��E��˾�����u�D���@ PQ����<�����2�G�>�|�>�q����Т�Jf�Nq1�R�����1.�k9(��9.nŖZ��rQ�m�&��I.��-52��ZղQ���\$X��4w��bJK�Ls����[re�;�E�F�S���\T+[2��9�%E��]T�[�2���Zl2͝�*���Ls���2�v�i�T�W�_��c]��e�;׵Q�_���]���e�;�U#�/��Ѯg��e�;۵M�_���];��e�;�U+�/������e�;�uP�_�I\���e���U/�/Ӥ.��L�2����e���.��=�'��k�L���g��L'ן�Z�&q%0�M�II\v�kd��5��2M��Ja�+Ӥ0��L�4)���t�L��h�kq�4)��GV-�&r�c:E�I�\�L�e���*���4)��bp��iR(�Z�۸W��R��r�2M��� �/Ӥ\��r�2M
��,�/Ӥd�9~�&Es=#�/Ӥl�mr�2M
��)�/Ӥt�Z9~�&�s�&�/Ӥ|��r�2M
�:,�/Ӥ��z9~�&Et���e����&�/Ӥ��v9�sL�R�ȋ[�e��ee��L�r�lL�ʴW�?��d�\�?�52�A�?�e���L{ez�\��dz�\�sez�\��2��\�2]#ן��~Z�?�v�~F�?�6�~N�?�B����g�����r���ez�\9~�~Q���L������}r���e�5��r�2��\9~�>(�_�_�ߗ�/�/Ӈ�������r���e�^���L��/ǏtebRݒ���͞;'�t��%K�V���}9��0�Q�>)ÿ�#�*K������𽯜5�r��C7Vm�9ZTf$e��'Y|#�|I����Yp���DOSپ������*���E��E�Ηl����6���%��X�(̱9��#���ai��%̯��J��K7�?�Ay�,_�M���w��܉��γ�|U^S���d��U�#�Ez��N�l'Y�3l~]�W?�5�is�d�r7s�A	�5���',V�l��;O`a�)���G�H�/��{��5�}�����}���v2��Ұ,�J��Wg:Pt�nY琻��cs�J�d%�5���s5�e��ki�����9ӍOZ�n��8�S��+����_�Y���ڼ����ވ�4����/K�֒��e_����h<'{�}�-���}���v�'vz�'���S[�.��*Ks[��z*��#��I�k��?�c���SIg-�E�SvD���������0�/���ɿn��3�#����H�kX²s&Y�siV����c���������J�/ �8�s��/�C��2׿�@�l�{��"ӷ���D�w&2�|!��iD+���ڙzz�i�����q:�9�#�����oP��c��4��{�p������\&߁��5��p����cw���D�q�iO!�2M��_13f�P�B�wX��j�՚����9�/ܑ�0t�<�ɩrw���{$�M=������WN�7��])�#|m���H[���{Q�m��[�^�m5���UZ*vbP����O�[9:��y�D�{�	OG볕%��s]��?�o9�O{\�'hu�G,=�J�|�=�Wy��=�5�o޶k*E�Kf�r�A�ӿ�Tp�bRk��,q���XE`7mnrd�n;iъ�؛���	��2�w�]��:������1�,߫�9��(��{�I�_����(��?�D*;�_����;��\��V��)qm��w���h�>���4)9��:K��	��},�_���.�E땾6�_��(�6����^<)�<���y+��A��c�=���U3�,�'�;�㆞Uy���d�<࿾=��V/p,��?	)�,b��qtQi����dO�CFUg�.a�E�)�mM�z"�:Z�ץ��ͩ�����L@��2�>�M����I�^;�c���^Q��v�?q����v��,� ��c��
�ϰjvw��Z�JH$U����4F��L�-&{V�\�ơM@+�rN����D�*�NGp-4w?��$�h���0�"B
:�XM���r����~+�-۷^�8�K}=��I��<g��S�
qFʵu��^��J�� �̞[�:���l�����MS��gLs�3'|�I���g=e�4O���ڔ�o�h5�|�S��uΜ��W�y�6�ڷ�U������oJ>sx�ԖG����u�xb�;�_N��Ä1�1_n�x��\��ǾW��Yj��8������	��ߢOQ{�ӣ����i��4 ��ษ�c^b�����Z�u�Ƿ7�}e����VM�J�R�:��A�n��}��!H��6�_�+>q��4��;/��m%}y�%��_�MIG��\����3���Qj��o'���:��/�(����6��Sq���J�bg��?;[��	��ł=�w��*X�#Y!�JC�l��TV�މ��R��'%������׊���Τ,��(�:���6�{��bU���,t��(t� ����x�#X@���ס2�fe��Y泳�P�n	Q��)�,DQp�qrDl�x��� ���O��;}�}���0���9�s�_���&%.��H�m���v�[�-f0,"��/�n̜l�5B� +܉�Z��F�WK�������v������{ek�M�D�M��ꓵ�U����v�ce�$4��-B��)�:��Ч���8�����I�����ؐ��f�nYB<��˝K����8/��$�<g�)�P���:�1)Ĝ��2��ܫ��w�6�_�������D������P��m���IQZk���S��י'�1`1�����d�2�_h�GB�9��h�����mq7������P�ߺ.e"�i��=�⫵),�{bMxX������ӏ��!B�U2 iA�����n= �<2���A
{��895���	�b�^����{�el�i�%�o}g��;�uQ��]W���i��o��sr�R��Z��@���w��w�["L��^Py�Z�Z:2�!����R�����]O�$L�V��].���_�@��Y��b�B#Jl٥�]!��uwWF�
r}����,��I��a'�r��a��>_z�]zzde-_��
���ݽ�)�w���k�H�~��#�s�G��o�� xJ����S�M�!H=hm�T}qU$��֐�&e��-�c�;��\oq8��(����ϑ\NA{���uL���ȳ�u�T��u�dg��q{�M��J�]���
�!�~��XA�S��ׂ[�3���<I�Hrx�:�_5����Qd�ٞb�tɀ]����-��в�r{�7$��TI9��+�]�N$�9]I��0�w�:>�H�@ORa��}d��g�`�������_����$���ۃx̓��������{m�4�r>kM�~D6�S\d)aUM���$Ue�N��[N�ǯ�1�1Y��%حz���,𿐨Iw�.�=�9ǲC!c��,�ϓz 4���J�~�譛���y1~v`�������n�h�s�g$���`�|���_�*�9��|��d�\z><Ie�=����hp�=�k� F��� G��������٧봸r^m�L��T|幾2y��]s�ܹN�m,�;8s�s�8]���'(">'y�̻̪��YE�3DI~V�m֬ٮ�|��
����M��SkU!�'*�e�~ԋ����<���魗:����&�����^
�?TNA�
�xt���ٮzV��� T�^�Ty=ٯm�l�������rJk���䭗 ��|���Ծ�a�Іj���v5!)�>�
Y5q���?ѭ��{��i�
Zmzǣ�q�m�uO�$sq"9��NF��|��Ӵ��~�X���Js^��w ���o�Z~�2���lԚ��g�u��N��E9�^��DQ5󍃞�i��Q��v@h�Vʆ�_�I�?���]��ʖ�K�P&����cY������T��?5���F]�lb�yN����1)��W��2�.��9h����������?̚9��.��&�>V(�kK�`�w�L�>Lh�ê�
��t&y0+(����}MƢ,<�m�|H��eq�R���i��a��������J���O���o���:��yh�rZ���
&V4�ek��{��]T^��m�yHIuIpTkG*!<ͩm\�|N��{�<,��	RMh�绖s��x�H�ʧ�ޒ'_��,�l��>�J�<I�b�	TA�u,.c��9������!纇1pd��	qV�K<���|����s�I^h%�,O�� 6^�YP��4�+�3	��hznk
B�r5�H"�43i,o{xF\]��C:ϐ��$~�!`�'ޙ=�u�hu�EJ(q�h���Ϸ��7q��@�-D�9�����@���OĨ�̷0߄|�z�嶣����`K�͞��Ja�O���X���~]:I�ы��;sh����I��_�*��K��un�I��6u��d���3�;��9{�ӐveZM�_U��H=���Z��b�\)D`�'�D\9uf�.���<�S�6�?=�m��҈��~���ґ�w � ��A�R&�2h,޿�{*��q���=�?�C@�X���1|8��_TWr:�*�/|�Y����f�l�� $q>����v��|���?���pAdR�q���X�x��k
?��J�m�er��q�`k2@��w��!��=G��uo�9�����w�k���B�;D$k�,�^�6�*�o?m���6<B6�>��kבUw�(�v6gsG������?�����[������&D��D��r%��HZLx^��ޖ����ݯ(��jiW𽺮�,{#ʶ�C�c�p��`S-q��a��� �X�����z��[Z<Q���HQy;�W���-[���s�|@~>
�=b.���8��o�1���v���J�H
��6�Fk�=_\Y�J�d�O$J<��'�k���BNE`�?񯞞������F��&�	�NZR�e:Zxc����w���R���;Aӂ�&�Vi��)޳��+��{�b%@�ß��J��@�C���_�Fv-��'����[��q�7��ĸ.�T����e�ķ��ظ��ܑ���[-��C>N=����:�p�A�+��UQُ�U�sv���k`����`�պ�A����\�Vݟ�U�?Y�D�=0Z_�l����/�	<3�� @�����j�x�mP��Vq���NE��m�����֗�$���W�F*d��JID��w��`��W�-���2,�u=ո��r������w�������@U�Iuf>�r\�f�0fU΋���g�&e��g�TZ�\L���I�\g���Z�x.������Y���l��m�:$7�{�Ф��j{�FU:b[��֪#�C���a�����z[_�x��/�*����k�+�|�V�4K���N��oZ�9q��ٜ���R5�I�����B����8�s��.5�3�>Ɍ*��J�/;֗@h�.��hM���ZOo���! f_��
M���%k]�������[��������e�)��z�ܗw�R$�M{+m�7�ྼʝ��MP}������1��|ǫ25 M@�/he����� H�e�u����n���Sm�7;8�/&=#/�?�ď��+�i��}��T��E�J�L*g���r�Rx�����b�l�&@(�uĕk�[?�5K���:����"�����}�79��ِ���䇭�خ湤k�&	6-ر-6%�Ŗ��j��!�������+'i����Vl�e�ĖR���7�"�I*��M�+���dZ����3�;&��8(6�}��'�������g��N����w]�T\�������;�?=�$���t��'%O$�z[��.�b&��|"e�X�'
�m�ңlξvnؽ�XswBvխD��ր��r�7���0�;.;���c6$Z��?��
��mQ��T���^�M&��ź䲻Eow�ƤM�eH`-o+%�EG���xM��͞Z?�{?�)O�Ǉ�{���p��R��A�
�յ�c��V���1Tz������~s�\��B� �kMq�>3��s]9	��Ⱥ� ���
����+R�9�
��*��ԍ������EZ��/C,��On�ŠC}�/V ���̭#���Im�C�b�4Kk?~Ԇ)�V�q�h�*$������Lԋ�r�ji=�q��xL��o�@^�_�O�U��/(�z<w�Y�����?���'�����Xs��X�������s����9��������{��$��%���2>m�$��G��?�����?���@ݙ�����������v���3��[�j��W;�ߎ?��@��3�ڎ@��'�Д���漵�s� ���a���������4Kh�ڠX�e��{��.7ڭ�Ӂ^��bo��ᶬS^=bLҥ��v�O��齬��^�?7����g��+�,��^��^��u�l��{Ŧ�eM���&��l��o!��xŭy)z{e�i���Q���%Q�mt�?xϱn��]�����4�O1MUt8�h�p?l��~�V[���Y��oW��ʩ�v����#��+��n���NZ��fg��g�����Z���򳅐��ת,��)?s':���b��x<������<��y���g?��|��4�ȇ,��x.�3�t<s�,���}x��{</�ُ�C<_�9�'r���x<������<��y���g?��|��4�ȇQ��x�㙎g�%x���#x~��<��|��<��D>��x.�3�t<s�,���}x��{</�ُ�C<_�9�'�Q��s9��x���+�%x���#x~��<��|�����o��t��Е_lt�F.Y��Tp�h�G���%�_����>i4����/���/�E�>�K&��hܟ^d���h���bT{��/��k ���_4�ߍ��������_��Fz����?�Fzu�wW!�&���>����~���� X�yM�r�~�H7���;�B~��3a;ʕt�M��>��9
�?Q�'������_����t0Y��F�{� IȬ��d����*�25���?V�/�.���w��k̔�wg�ͽ�x�m�s�p�U��=
N9;3���̲�^���5}����?Zo������^fDzߝ�Y��,�kC��W�͙��<Ӂ���V�^��,�N���3��vj��Zde�rΜ�+��fɜt��of -E��Ŀ�B�
����\�ץ�n�)Z�/q��/q�Gc2�L C��� ļwC����ƿ�I�2|���'�[�ǅ���Vzd��∧Ϟl�E���̎ٳ�E�C-�k�f.���*SU�Z�ڳ���#����_.b�V�Z���P��(��+���$��y �Y9�*��^���w�~U���Jvqj�Y9�Ճ�����+w�����)����!6#�/ݻ>) <�Z�dV���|g'�F%���e&��d��/���'!��JL�hw\���=����9�6Lu&=F����]�\��-����=�s��ǰ�/�Pb&�̌�ί����*3}ϥ!o��l��?�-��~l����1|�_�bt�k��;�_o�����8���ލ�3$r�N�@L�M"ԋ���3L�&�V�@l�$��<�w �|:�S�H
H����:'6��Lej���Y��?d��P��]��t�Dץ��_������ᯏ���ۛ��Q֡y��^w.�MI#짋g3*�^K=�~�Dz�
}��%R��-�~�?��y��,����V��]''��O;�O�ݮ�x;@Q��A������
٨[N�O�M�-Lϯ��ή?�Η��ӾՁ�蒕�"��:2���gg�D�?+��?�N�}�?)��c��3}�d�����"&�4�U:�Y��3cR��HJ͘.	�l:]����=�_/[�cUڑz��-]H�=y�t������L�則��o:����D�\U����E�K���݌�'���~�oO3�5��oe��oP���r����c��@��!��*}?�OG;�:���:�|{�5���@�������=7���w6�N�2�����f��^&�ȧ��y�L�ڱC[���;iLVn���,�c�ܑ�p[{��	������T�w��[f���e`p/)��|]Ԟ|��z����*N�MQ�@!��236�Q�T�
�.�\��\�^�v`���dM/<���"�k9�J=$M�����Į� HT���LZ2� `�*��E��dJ�ΙZ�,��W[�7bP1Hg��[�R�#9<:�H/��%��>�����>�}�[{�o��ݿչ�sN����x���D7?�Sҭ��Azm�J�?�%���q���i��\t!����/<�Q-���e0����Ο]��ᠷ#�Ϧ��[�G��[�ڥ:���h��Z�Vq��ǪT����[�Ɩ���f/��M�hMlg���>�?�#����e�>��r?��6"�^��-]��51���H�EE4��y�7oh��u"�Һ��Q��(��&gvh$D����|I:�P��DS��ڗ�uQ�{恈#؞�Y|��~EB9�̲��½X���5Gw���mSy��� "�+3*Pڽ
t'��d�q��$�Yg@�Mh�[f�B�M��s;۪�Y��#���>@�}��ӻ�;�ۇ3c� ���_���
�1B�lY�.��5�-���*�RʝB�k3u��,l�c[��re$2�U�n���_m�s=̗�v4m�{����(�v��El����N��L������H���CW�u���ns��+*�3���R9�vf.��q�]��T�*W?ӷ>�AC��G����n�I��I�8������#��Tr�5=����:s�JՔ��IMa
�GA:���kW�2�rrvQ�T#{�RXǟu����X'��6�n��2�m��g���x�v�F x'�p�?;��O9�+��2�}�T�^��uS�G�$ֽ��ǀu��F���_#��z�l\4+��֣�F�	�ܮP�ͱy&45�L���O+��9��ж����+���\����%��
}]7]m�տ���o������3"��a2ҀL�ɋ$Ȑ<i@|B2!ѼLfPl�a:m�ڧ_�}x����>Jk&��""(*TA�xҩm
 r��tz�Sl�3a�m
ʅ���[I|�@� K?��c�G�� ƩJ�
V蕀��^�3�x}#ᰵ��ұ��q���I|�jAw'򿒉-�� �`<�L�6�������_��:GL�;@ ��9.z�k`�\ff���]��p�s�q�=[&��ۥ�r�,�<6����a��������YȠu�������	���p=�z.����<=�hտ`��B��tk' ܴ���jb���Ib�iQ��>�;0�)�6ᝉ�j$��M��A7�rU(�
�b��L��;	g�0�,;�*~`Z�f��7���X����B�_���!��=��1�2���+���R��hĢӏ#6�=(��	����y���޸[�TqJ^G12��
�<&خ��Wj��M�g@�Bz*[�~���?�0q)��>F� ��k�-4���d�Wa�D�N��=���Ee�n^���|�ev�C���z�r��WX���Av����?J��}5_��s�
��ީ*���=��c�e�'��u���Q��P��>WF�Vî�.�r�������Vh����}=1Spl#�^/g�O��Z&;yy2��ޖ�:�L����Ɇ�/1�B���/�!�Mcҧ�xQ-�tL`^&����e�6�K��S��.Y[uX�&�!��̥�N_�n�;�F9
��6��^+�
�ؗa�yHS���V�x�
���:����r�����
��񷘡���u�܎��'����2�e��d��"Q�@y*��NHzg5R�����R@���n��"��7���/�y���1� ��;[M%:&�L͡]߆�2`n���A�ۻ���E��Dݒ����m#k�_��%�x�$�]�Fǫ��@X��0��16�M������)���S̭�4���F��P��.S�>y�`ґ�G7�G|�'o_巢�"�d���F��> �S00��[�Z���0
 8E���k�J`��P�)��dm̈́��6 �8�� �^e]X�z�w#6r��C���v1�֫=	���k�%�_��0v�t�ty�aҹ��u���q+>��Φט-�O�z�z��)��<��0���g���� ,ۥ�֣<�5���U-v�� �
f}����7�Gʞ��0o��ӄ�t�mU`YŭG���	�N�� �T�v��pMn���1����N�Zmބ��{��OA��B�\���~���Y3���b�f}9��걽��9M�n��
Z������K\���׸'q2�y�H�E�v_}��] Ȉ=�?}+l��}���!zi�, @��l��߫N��E��������~���q��J�{=7L�v�/�K�����[�O�8�����w�`��BmX[��9�qq ާD��O��,�"�q9~~�}I�ӻ.��8� ߑ�S"g'!
�A;j�l�C�Ά�8(��^`E��*7��}���I��!����9���z=Jb����
*a�I�N�M�t9U�9��YT|�0���1�?��^���ǻ��#�=˴�ۙ{�d��sύ�J���l}[� ���gxB�֙����Cɝ$�*���)A��-ة�Q�Xx�m��mO��-e
����i(�P;��{���˙v±k�z����|+'��M�A�'�Q'A
k*�̍~��gib,��I��iw�����0<�=���?��\�/��wW���x������~fZ�:�,�7v�AN������֑�����>�{U/z�cd�,J�:&��+�}5X�3�P�T�g���1��v՛r���
�����E����Z�t�N��{��>Ĉǂ�=�&f�rd!`B�P�2�d���Ӂx�Q�	���k��n*/�o pk�<>e6i@>�϶�m����9\��������F�Ÿ����x?���1��s�f��7�8���~F�y\R�bH>5�����1�H��l��֤���^�sP	�f�G�63~ƻH�J'�vH�-��PԾ�O��(ؗ����9lƯ��j$l`W��+d_C�ZEJF����>�rs���C�tw<����(�� 燽L�|%Q��ߤ������'YGX/*���Ld`��{r"{=�#ԓ/��F��J��Q|L.��xv��h�n�{��,������)�u�t��	�O��6<�.�1�-8���l�3Jt��V~�\�w�`^��Gwk�O�,��s���
�<̟��a�\�"bg��B�3�
�F|��=K��})���x��z��
w���ɐ`ZH+ ͂�Q�1U���bjoL��d����$���M�6��I�]�}���2���K�R�l<o�~+���1������Gx�%I�ߊ_����I�$���$)��bR�ݓŤ��)�I%�I��,[R��$�A�%Iz�-ǡ���~���}�9�h�c�����5�{c�Gϲ>xN�˶'	7$������_\D���J|x�W/ar�����ו��g*�/Q�;OߋM*Q�sO�$��+�n7L
���i�A~a|ʷ�����+sy@���7�o��g��=������y:5��+L�����^��a~��Jt�̟�1�7�R����t)OW񴎧<������A���� O��$OGx:�2�������t)OW񴎧<������A���� O��$OGx:��Ś��9<���R���iO;xz7O���<���A���I���t�����i>O��tO�x��ӻyzO�����0OO�t���y<��<���|�.��*��񴃧w��>�>��<��a����O'��<3y:���<]��U<��iO���}<}��;x:���<=������b�W��ޫ�ߌ�����%�OJ|�Q��$ϕӟ���0�1��A	��{W��#��ƒמ���"rB��x�G�mm�y���@R�y3�������<��`���6&���h�>���x���շ���W���f��$����?/�������41�5���<؇y��_Q_��	�Ã�1S��)��0���<�GI��j����
�8��4���� �������+�~(�1�w����"����}�~n�F���u�q�C�c�Y����z�o�o�X��������|�����(q���Ӊ��~ѿg��m���tWD}��ܫԟ4v����x܂]�;�����&Eă:��o�@!=�+����������l�-|Q}d�oA^���Hs��srt֜�ܬ�k�5[�e����넬�x�
":
*8�o������٤�^����&��ohg�-�n֠��a�U��nwk{Qf&7\e0��O�ZVG���VWMC]�|��U{�B��u2��ks�=m�BGu��UU���*u7V��lw�����d	�Vf�A]��8�HX�rohi��?2���\��QYl2�;�S.m��"���eUŦ���\�ᆲ��eNG�)������\d���
5��W]��tM����˖_S�},��)[^���tb�x���n[�����+��U:�#;V���j�cY�
�([lNG�&*O-B;��+ًT��\C��rUY�#FyW[GC�+���Tt�~{_Z^YJ`�g��J,_FOi�W����FH� �P	`�r�M&�~i��T�M���]�k*��P �HSVJ-p���,�J�P�4�:�|S,q�r�y�!�u-j�
Z�ϰ�1��s��H�n�yamښ�[]��&��D7-R0�#��� �u����ֲ�s�����|���&�F��){�I}�^�P��Z��݂b�Vs.5Z��9 ��dsm5�,^��Z�j\��|�F�Pj�]5��*�����BC�+��W�ށ�Kq�
��Ue������@#@H+C-8�Km����(�O�i�綥I3'ټP=�&(�W���Y��^]c�D��-ͮ1�c+�-GM}K��M�ji�����le}A�`q	���rrn4o��-�M%E�[�QV�ɰ�` �`k��W� �eN��u�����P���d�L�P\,���M�?�͛��rX�B�҄��QC�d�5F�:�T��Ա�4/vØ��8jӐ=N���\
��nS 7�V{�,���FP�  ��#�w(�z�c*v��.Fr����x=�R���=�bm�:��vׄ����F�e��p��`������N�Ac1(�o��N0[K�!ҙ>7���DU�Qg�:$�6�6�*���ܒ�R-��Up�f�@˨<��r��`�~�8�cߣ6�����L�*�e"�ύ^c��V�*��E��
�k5RȊU$,֠���+����z�	��p]�-V+����.;�X�
�5kVV:C�@ukC��%@��>c�[��%�AO����ZW{��L5͙M.wu�-�-ͦ��\�(�*X�ᖷ,5-�ͮ�]���՚�YX�
_rW�_�����!߄�
Y9�l���c��C�:���^���i�T2>=��ih)���h�E��qX>H�L&3��X�XՇ|�bFP�r��F��1�ժz�UC�Q�x�}�0E�Ma*�-9�RԨ�a]&�ajy"m���*��:~���D��
a�Rst �!EӖX �I7�V�:v��64s=�`�&D~�B)q�aE�Z���b�r�\}b�GYDa��S-����Z�	@01����#DD���0al�n���6�π�)�ZK�+0<Xn[�P�Gee9R�Va��$ʝ�L�)��T�ͱ����`�D n�8_��C}QFsM}SK�p�Ƙ�ZMQ1rנ
�1��(�� �٘�\�EdC�h)�+b�Çbc�R�W��g�ɷ4r��x��ثY��:�X��l4���,��#�w�4��sL������F[1�F[@s]y@����M��
�M��]��
EZa�ꇈ:��z�FK����po�lȹ/�(K�Gwl��̸5��W������" ��7�4]�[�|���h�UU߲A���[�0u�)�"d���kk���\ҚO_� �������Lk���,�g-�fd��rQ#��c�.`�#��C(ȷH�R�3�(¼�
�T��z5�x��^��؜k^��i�P�kki��Y6.E,����_%�W�"B�S{�����:�+e���03�R�;$N�S�E�UOBދwdf0��������|*	 R�h%{�)D�	�)F�A?���X�Y���_���:�h͑i�����)mb�梌 1�m����3�нv������!�]�Nhva��N�W�h5 i�[ֳ�f�����E��f��7�Y�Md`������Rۧ�پ ��4�ʸ�C�χ���T��cP?a�3ךk�t'W*W8�H�<hC'=oIuf6)�g�a��+!�X=�S�ե���A�QH�'�TH�_S
)���<Z&�b��E@������q���	������������� FW{*���1���A�wIC~�}%Hu^��@_|�AlU�J�j4OT���#�j�-V�YQ��Pq�|�8�H5���N�&3�%���=��o�+p��^�bF�4��hF%UËZ�3R@�`�zt_j7M�Q�'쏁s���u��UH��nܰ�Fۿ�dh|%U��h�Nb�<ͷ7���\��M=s���@�a��^��ތ�9�`��7v��͊Ô��rB�C���MfG�$qs��P�	�!!5`���U7����{
�i&�zM�(,�]p^�����og�M�B60j�B^X�R�L��YU�ei���U.!?�Y���P1�
�r�f"����X:�
[[��5V�o/�2�6fd��Z3k�f(SU0g��n�Z۶��>� lo��J���C;�C�n]�n����JcԵ2�N����w/>$�r����?$��#�yw���d�k.D�Շ��,n��%��(H�V@}[����aB6 9A/H�IH��R���Yq�\���󂍰	.K��~B�cZ��(�s5�L�Y �І�-��	��S��W/zOP)ڿm��#�{� =خf�p��սG���Z��&�eK�F,���S�"].<Oe��>�%�lc�%lp%~0�ZR�i�n�5�Up%�ڗvST��M�d	�|��)�$t��;�0�A�Z�k;�F�r:���"�}�X�������z�l��0dg�0���h��!c
l1_���3������ᝎF�yW�Kz�Ht����h�w�[w�n�D�J����k5�Eͽ��y�@�?:�L�0��0�Pd����	��k��70�C&Dp���^�P��@P��,<L	�.~�F��?:��iL �A�6�������\���
7/ʻ�J	ϡe��Ĝ��qd����,I��R�Q�]If,v�Q*�W����,���[�~wg
��?n��_14�����q2M��r���M$�
�?^,���T�y��f���C|�,9��l�CG���2\ ,Q���UY���s�r�⺂K��ިZO3��u&��U
j��I��=`����ǲs�a��C99z��efХ�o?=�S��h6� U^�ůU�A���fq��CI���,�ys�����[��ءC�|�r�-�"�`���d���-d�ܡQ춗�F�)�7&n�m*��TL5�8M��^M`�H{Zd^��[�-2��U����G	"�a`U����k���c��2�)nn�#0v/3�&�pA��"��=^86k�Z�s8j�Z�Qi�b��[1�运��V��5�VW�X$��-%�c]S��k;. ;H� Ք�ϥ�ct_W���kKQ�i�����c�����_�k��{��;��������������|�����-���?����_�Z�k��U��@~����䟁�C��A��d�̻���8�[�Xj^æ#2v��3�e/�ml߀o��?.ϒnF˿ �h�ԭ�ڡ�߲p��j�m +�n:E��1*�{����{:#�)�
���u�j���'�]�~���t#ݰ�/��`�߇	������_���k��w���x��;~����ϳ��_��{~���	��y��aoԬy��_%G�z�����Ӏ\����^��oQƊ����7��_�-��j����C�v��>y�l	K�)�TMD���QX]���Z��¯��F�&pJ�(�V:8��Wۦ."t8���T�����6�R2;W�E��Ɗ�nM6���1k
EM����j����8